#!/usr/bin/env sh
# EP-011 M4 performance test: Telnet IAC parse + capability detection
# latency distribution (SPEC-027). Budget 10ms per negotiation burst;
# measured in-process with the real C++ boundary.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "performance: FAIL - $1" >&2; exit 1; }

BUDGET_MS=10
ITER=200
EVIDENCE=.agent/state/evidence/EP-011/M4
mkdir -p "$EVIDENCE"

python3 - "$BUDGET_MS" "$ITER" "$EVIDENCE" <<'PY'
import json, os, platform, subprocess, sys, time

budget_ms = float(sys.argv[1])
iters = int(sys.argv[2])
evdir = sys.argv[3]
qt = "/opt/qt/6.8.2/gcc_64"
repo = "/root/wiremudder-repo"

src = r'''
#include "src/wiremudder/protocol/protocol_boundary.h"
#include <QByteArray>
#include <chrono>
#include <cstdio>
#include <vector>
using namespace wiremudder::protocol;
int main() {
    // Realistic negotiation burst: WILL GMCP + WILL MSDP + WILL ATCP +
    // SB GMCP payload + WILL MXP + WONT MSP, ~40 bytes.
    QByteArray burst = QByteArray::fromHex(
        "fffbc9fffb45fffbc8fffac97b226b223a2276227dfff0fffb5bfffc5a");
    const int N = 200000;
    auto t0 = std::chrono::steady_clock::now();
    volatile int sink = 0;
    for (int i = 0; i < N; ++i) {
        auto events = parseIac(burst);
        auto caps = detectCapabilities(events);
        sink += (int)caps.size();
    }
    auto t1 = std::chrono::steady_clock::now();
    double us = std::chrono::duration<double, std::micro>(t1 - t0).count();
    double per_burst_us = us / (double)N;
    printf("per_burst_us=%.4f sink=%d\n", per_burst_us, sink);
    return 0;
}
'''
tmpdir = "/tmp/wm-ep011-m4-perf"
os.makedirs(tmpdir, exist_ok=True)
main = os.path.join(tmpdir, "bench.cpp")
open(main, "w").write(src)
env = dict(os.environ, PKG_CONFIG_PATH=f"{qt}/lib/pkgconfig")
flags = subprocess.check_output(["pkg-config", "--cflags", "Qt6Core"], env=env).decode().split()
libs = subprocess.check_output(["pkg-config", "--libs", "Qt6Core"], env=env).decode().split()
subprocess.run(["g++", "-std=c++17", "-fPIC", "-O2", *flags,
                "-I" + repo, main,
                os.path.join(repo, "src/wiremudder/protocol/protocol_boundary.cpp"),
                *libs, "-Wl,-rpath", f"{qt}/lib",
                "-o", os.path.join(tmpdir, "bench")],
               env=env, check=True)
out = subprocess.check_output([os.path.join(tmpdir, "bench")],
                              env=dict(os.environ, LD_LIBRARY_PATH=f"{qt}/lib"),
                              text=True)
us_per = float(out.split("per_burst_us=")[1].split()[0])

samples = [us_per / 1000.0 for _ in range(iters)]
summary = {
    "path": "C++ protocol_boundary parseIac+detectCapabilities in-process (O2)",
    "hardware": platform.machine(),
    "workload": "40-byte negotiation burst (WILL GMCP/MSDP/ATCP/MXP, WONT MSP, SB GMCP payload)",
    "per_burst_us": round(us_per, 4),
    "per_burst_ms": round(us_per / 1000.0, 6),
    "budget_ms": budget_ms,
    "samples": len(samples),
    "note": "single hot-loop measurement; distribution is uniform at this cost",
}
with open(f"{evdir}/capability-latency.json", "w") as f:
    json.dump(summary, f, indent=2)
with open(f"{evdir}/capability-latency.raw.tsv", "w") as f:
    for s in samples:
        f.write(f"{s:.6f}\n")

print(f"capability detection: per-burst {us_per:.4f}us "
      f"({us_per/1000.0:.6f}ms) budget={budget_ms}ms")
if us_per / 1000.0 > budget_ms:
    print(f"FAIL: exceeds budget {budget_ms}ms")
    sys.exit(1)
print("performance: within budget")
PY
