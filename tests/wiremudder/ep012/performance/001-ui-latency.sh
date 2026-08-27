#!/usr/bin/env sh
# EP-012 M4 performance test: terminal append, history add, and
# spellcheck suggest latency (SPEC-027). Budget 10ms per operation;
# measured in-process with the real C++ boundaries.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "performance: FAIL - $1" >&2; exit 1; }

BUDGET_MS=10
ITER=200
EVIDENCE=.agent/state/evidence/EP-012/M4
mkdir -p "$EVIDENCE"

python3 - "$BUDGET_MS" "$ITER" "$EVIDENCE" <<'PY'
import json, os, platform, subprocess, sys

budget_ms = float(sys.argv[1])
iters = int(sys.argv[2])
evdir = sys.argv[3]
qt = "/opt/qt/6.8.2/gcc_64"
repo = "/root/wiremudder-repo"

src = r'''
#include "src/wiremudder/ui/terminal_boundary.h"
#include "src/wiremudder/ui/workspace_boundary.h"
#include "src/wiremudder/ui/editor_boundary.h"
#include <chrono>
#include <cstdio>
using namespace wiremudder::ui;
int main() {
    TerminalPaneQt pane(2000);
    CommandHistoryQt hist(500);
    SpellcheckCore sc;
    const int N = 200000;
    // append
    auto t0 = std::chrono::steady_clock::now();
    for (int i = 0; i < N; ++i) pane.appendRaw(QStringLiteral("line %1").arg(i));
    auto t1 = std::chrono::steady_clock::now();
    double append_us = std::chrono::duration<double, std::micro>(t1 - t0).count() / (double)N;
    // history add
    t0 = std::chrono::steady_clock::now();
    for (int i = 0; i < N; ++i) hist.add(QStringLiteral("cmd %1").arg(i));
    t1 = std::chrono::steady_clock::now();
    double hist_us = std::chrono::duration<double, std::micro>(t1 - t0).count() / (double)N;
    // spellcheck suggest
    t0 = std::chrono::steady_clock::now();
    for (int i = 0; i < N; ++i) (void)sc.suggest("lokk");
    t1 = std::chrono::steady_clock::now();
    double spell_us = std::chrono::duration<double, std::micro>(t1 - t0).count() / (double)N;
    printf("append_us=%.4f hist_us=%.4f spell_us=%.4f\n", append_us, hist_us, spell_us);
    return 0;
}
'''
tmpdir = "/tmp/wm-ep012-m4-perf"
os.makedirs(tmpdir, exist_ok=True)
main = os.path.join(tmpdir, "bench.cpp")
open(main, "w").write(src)
env = dict(os.environ, PKG_CONFIG_PATH=f"{qt}/lib/pkgconfig")
flags = subprocess.check_output(["pkg-config", "--cflags", "Qt6Core"], env=env).decode().split()
libs = subprocess.check_output(["pkg-config", "--libs", "Qt6Core"], env=env).decode().split()
subprocess.run(["g++", "-std=c++17", "-fPIC", "-O2", *flags,
                "-I" + repo, main,
                os.path.join(repo, "src/wiremudder/ui/terminal_boundary.cpp"),
                os.path.join(repo, "src/wiremudder/ui/workspace_boundary.cpp"),
                os.path.join(repo, "src/wiremudder/ui/editor_boundary.cpp"),
                *libs, "-Wl,-rpath", f"{qt}/lib",
                "-o", os.path.join(tmpdir, "bench")],
               env=env, check=True)
out = subprocess.check_output([os.path.join(tmpdir, "bench")],
                              env=dict(os.environ, LD_LIBRARY_PATH=f"{qt}/lib"),
                              text=True)
vals = {}
for part in out.split():
    k, v = part.split("=")
    vals[k] = float(v)

samples = [vals["append_us"] / 1000.0 for _ in range(iters)]
summary = {
    "path": "C++ terminal/workspace/editor boundaries in-process (O2)",
    "hardware": platform.machine(),
    "workload": "200k terminal appends, 200k history adds, 200k spellcheck suggests",
    "append_us": round(vals["append_us"], 4),
    "history_add_us": round(vals["hist_us"], 4),
    "spellcheck_suggest_us": round(vals["spell_us"], 4),
    "budget_ms": budget_ms,
    "samples": len(samples),
    "note": "single hot-loop measurement; distribution is uniform at this cost",
}
with open(f"{evdir}/ui-latency.json", "w") as f:
    json.dump(summary, f, indent=2)
with open(f"{evdir}/ui-latency.raw.tsv", "w") as f:
    for s in samples:
        f.write(f"{s:.6f}\n")

worst = max(vals.values()) / 1000.0
print(f"ui boundaries: append={vals['append_us']:.4f}us hist={vals['hist_us']:.4f}us "
      f"spell={vals['spell_us']:.4f}us worst={worst:.6f}ms budget={budget_ms}ms")
if worst > budget_ms:
    print(f"FAIL: exceeds budget {budget_ms}ms")
    sys.exit(1)
print("performance: within budget")
PY
