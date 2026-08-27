//! EP-015 compatibility oracle runner: parses the locked corpus and
//! compares observed typed-event tags against the expected tags.
//! Prints a sentinel only when every case matches.

use wire_context::parse_line;
use wire_context::Event;

fn main() {
    let path = std::env::args().nth(1).expect("corpus path");
    let raw = std::fs::read_to_string(&path).expect("read corpus");
    let corpus: serde_json::Value = serde_json::from_str(&raw).expect("corpus json");
    let cases = corpus["cases"].as_array().expect("cases");
    let mut failures = 0usize;
    for (i, case) in cases.iter().enumerate() {
        let line = case["line"].as_str().unwrap_or("");
        let expected: Vec<&str> = case["tags"]
            .as_array()
            .map(|a| {
                a.iter()
                    .map(|t| t.as_str().unwrap_or(""))
                    .collect()
            })
            .unwrap_or_default();
        let observed: Vec<&str> = parse_line(line).iter().map(tag_of).collect();
        if observed != expected {
            failures += 1;
            eprintln!(
                "case {i}: line=[{line}] expected={expected:?} observed={observed:?}"
            );
        }
    }
    if failures > 0 {
        eprintln!("compat-corpus: FAIL - {failures} cases diverged");
        std::process::exit(1);
    }
    println!("compat-corpus: ok {} cases", cases.len());
}

fn tag_of(ev: &Event) -> &'static str {
    match ev {
        Event::RoomSeen { .. } => "room",
        Event::ExitSeen { .. } => "exit",
        Event::MobSeen { .. } => "mob",
        Event::PlayerSeen { .. } => "player",
        Event::AnimalSeen { .. } => "animal",
        Event::PKerOrPvPerSeen { .. } => "pker",
        Event::CombatStarted { .. } => "combat-start",
        Event::CombatEnded { .. } => "combat-end",
        Event::ItemSeen { .. } => "item",
        Event::QuestClueSeen { .. } => "clue",
        Event::PromptSeen { .. } => "prompt",
        Event::HealthChanged { .. } => "health",
        Event::CommandSucceeded { .. } => "cmd-ok",
        Event::CommandFailed { .. } => "cmd-fail",
        Event::SocialMessageSeen { .. } => "social",
        Event::PrivateMessageRedacted { .. } => "private",
    }
}
