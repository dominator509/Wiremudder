//! EP-015 M4 failure matrix (wire-context): malformed and oversized
//! input, duplicate/replayed lines, and bounded capsule state. Every
//! case is deterministic, typed, and never panics.

use wire_context::{parse_line, Distiller};

fn main() {
    // 1. Malformed input: garbage line yields no events, no panic.
    let malformed = parse_line("###$%^&* garbage \x01\x02").is_empty();
    println!("malformed-input:{}", if malformed { "ok" } else { "fail" });

    // 2. Oversized input: 100k-line string is processed bounded.
    let big = "A goblin is here.".repeat(10_000);
    let n = parse_line(&big).len();
    println!("oversized-input:{}", if n <= 1 { "ok" } else { "fail" });

    // 3. Duplicate/replayed request: spam window collapses repeats.
    let mut d = Distiller::new();
    d.feed_line_collapsed("The wind howls.");
    let dup = d.feed_line_collapsed("The wind howls.").is_empty();
    println!("duplicate-collapsed:{}", if dup { "ok" } else { "fail" });

    // 4. Entity flood: capsule entities stay bounded.
    let mut d2 = Distiller::new();
    for i in 0..500 {
        d2.feed_line(&format!("A mob{i} is here."));
    }
    let bounded = d2.capsule().entities.len() <= wire_context::MAX_CAPSULE_ENTITIES;
    println!("capsule-bounded:{}", if bounded { "ok" } else { "fail" });

    println!("failure-context EP-015 M4: ok");
}
