//! Oracle CLI: emit the route validation matrix for cross-implementation
//! comparison with the C++ Qt layer (EP-007 M3 e2e oracle test).
use serde_json::json;
use wire_routing::{RouteKind, RouteProfile};

fn entry(id: &str, kind: RouteKind, host: Option<&str>, port: Option<u16>) -> serde_json::Value {
    let p = match RouteProfile::new(id, id, kind, host.map(String::from), port, None) {
        Ok(p) => p,
        Err(_) => {
            return json!({
                "id": id,
                "kind": kind_name(kind),
                "valid": false,
            })
        }
    };
    json!({
        "id": id,
        "kind": kind_name(kind),
        "valid": p.validate().is_ok(),
    })
}

fn kind_name(k: RouteKind) -> String {
    serde_json::to_value(k)
        .ok()
        .and_then(|v| v.as_str().map(String::from))
        .unwrap_or_else(|| format!("{k:?}"))
}

fn main() {
    let matrix = json!([
        entry("direct", RouteKind::Direct, None, None),
        entry("system", RouteKind::System, None, None),
        entry("socks5-ok", RouteKind::Socks5, Some("127.0.0.1"), Some(1080)),
        entry("socks5-nohost", RouteKind::Socks5, None, Some(1080)),
        entry("socks4a-ok", RouteKind::Socks4a, Some("127.0.0.1"), Some(1080)),
        entry("http-ok", RouteKind::HttpConnect, Some("127.0.0.1"), Some(3128)),
        entry("tor-ok", RouteKind::TorLocalSocks, Some("127.0.0.1"), Some(9050)),
        entry("ssh-ok", RouteKind::SshDynamicForward, Some("relay.example"), None),
        entry("vpn-ok", RouteKind::VpnMetadata, None, None),
        entry("future-iface", RouteKind::InterfaceBinding, None, None),
        entry("future-netns", RouteKind::VmNetns, None, None),
        entry("future-relay", RouteKind::SelfHostedRelay, None, None),
    ]);
    println!("{}", serde_json::to_string(&matrix).unwrap());
}
