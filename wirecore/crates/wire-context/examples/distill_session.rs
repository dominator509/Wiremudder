//! EP-015 M3 integration fixture: real distillation session.
//! Feeds a game session, emits typed events, capsule JSON, redaction
//! proof, and spam-collapse count as deterministic stdout evidence.

use wire_context::{redact_text, Distiller, Event};

fn main() {
    let mut d = Distiller::new();
    let session = [
        "You are in The Dark Vault.",
        "Obvious exits: north, east",
        "A goblin is here.",
        "You see Bob here.",
        "You see a rusty sword here.",
        "You notice Malice (PK).",
        "You hit the goblin for 12 damage.",
        "The goblin is here.", // spam-ish, distinct
        "A clue: the key is under the rug.",
        "<70>hp <40>m> ",
        "You say, \"look north\"",
        "I don't understand 'frobnicate'.",
        "You tell gossip Alice: hi all",
        "From Eve: meet me at the vault",
    ];
    for line in session {
        for ev in d.feed_line_collapsed(line) {
            println!("EVENT {} {}", serde_json::to_string(&ev).unwrap(), event_tag(&ev));
        }
    }
    let cap = d.into_capsule();
    println!("CAPSULE {}", serde_json::to_string(&cap).unwrap());
    println!("SPAM_COLLAPSED {}", cap.spam_collapsed);

    let red = redact_text("login token=abc123 secret password= hunter2 now");
    println!("REDACTED {}", red);
}

fn event_tag(ev: &Event) -> &'static str {
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
