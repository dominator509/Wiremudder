//! EP-015 M5 feature probe (wire-context): asserts one owned feature per
//! invocation. Prints the feature sentinel only when real behavior holds.

use wire_context::{parse_line, redact_text, ContextCapsule, Distiller, Event};

fn main() {
    let feature = std::env::args().nth(1).expect("feature id");
    let ok = match feature.as_str() {
        // WM-FEAT-0048: context distillation engine produces a capsule.
        "WM-FEAT-0048" => {
            let mut d = Distiller::new();
            d.feed_line("You are in The Dark Vault.");
            d.feed_line("Obvious exits: north");
            d.feed_line("A goblin is here.");
            d.feed_line("<70>hp <40>m> ");
            let c = d.into_capsule();
            c.room.as_deref() == Some("The Dark Vault")
                && c.exits.contains(&"north".to_string())
                && c.entities.contains(&"goblin".to_string())
                && c.health == Some(70)
        }
        // WM-FEAT-0196: typed RoomSeen event.
        "WM-FEAT-0196" => matches!(
            parse_line("You are in The Dark Vault.").first(),
            Some(Event::RoomSeen { ref name, .. }) if name == "The Dark Vault"
        ),
        // WM-FEAT-0197: typed ExitSeen event.
        "WM-FEAT-0197" => parse_line("Obvious exits: north, east")
            .iter()
            .any(|e| matches!(e, Event::ExitSeen { ref direction, .. } if direction == "east")),
        // WM-FEAT-0198: typed MobSeen event.
        "WM-FEAT-0198" => matches!(
            parse_line("A goblin is here.").first(),
            Some(Event::MobSeen { ref name }) if name == "goblin"
        ),
        // WM-FEAT-0199: typed PlayerSeen event.
        "WM-FEAT-0199" => matches!(
            parse_line("You see Bob here.").first(),
            Some(Event::PlayerSeen { ref name }) if name == "Bob"
        ),
        // WM-FEAT-0200: typed AnimalSeen event.
        "WM-FEAT-0200" => matches!(
            parse_line("An eagle is here.").first(),
            Some(Event::AnimalSeen { ref name }) if name == "eagle"
        ),
        // WM-FEAT-0201: typed PKerOrPvPerSeen event.
        "WM-FEAT-0201" => matches!(
            parse_line("You notice Malice (PK).").first(),
            Some(Event::PKerOrPvPerSeen { ref name }) if name == "Malice"
        ),
        // WM-FEAT-0202: typed CombatStarted and CombatEnded events.
        "WM-FEAT-0202" => {
            matches!(parse_line("You hit the goblin for 5 damage.").first(), Some(Event::CombatStarted { .. }))
                && matches!(parse_line("You kill the goblin.").first(), Some(Event::CombatEnded { .. }))
                && matches!(parse_line("Combat ends.").first(), Some(Event::CombatEnded { target: None }))
        }
        // WM-FEAT-0203: typed ItemSeen and QuestClueSeen events.
        "WM-FEAT-0203" => {
            matches!(parse_line("You see a rusty sword here.").first(), Some(Event::ItemSeen { ref name }) if name == "rusty sword")
                && matches!(parse_line("A clue: the vault opens at midnight.").first(), Some(Event::QuestClueSeen { .. }))
        }
        // WM-FEAT-0204: typed PromptSeen and HealthChanged events.
        "WM-FEAT-0204" => {
            matches!(parse_line("<80>hp <50>m> ").first(), Some(Event::PromptSeen { health: Some(80), mana: Some(50), .. }))
                && matches!(parse_line("Your health is 75/100.").first(), Some(Event::HealthChanged { current: 75, .. }))
        }
        // WM-FEAT-0205: typed CommandSucceeded and CommandFailed events.
        "WM-FEAT-0205" => {
            matches!(parse_line("You say, \"look north\"").first(), Some(Event::CommandSucceeded { .. }))
                && matches!(parse_line("I don't understand 'frobnicate'.").first(), Some(Event::CommandFailed { ref command, .. }) if command == "frobnicate")
        }
        // WM-FEAT-0206: typed SocialMessageSeen and redacted private event.
        "WM-FEAT-0206" => {
            matches!(parse_line("You tell gossip Alice: hi all").first(), Some(Event::SocialMessageSeen { ref channel, .. }) if channel == "gossip")
                && matches!(parse_line("From Eve: secret").first(), Some(Event::PrivateMessageRedacted { ref sender }) if sender == "Eve")
                && !redact_text("token=abc").contains("abc")
        }
        _ => {
            eprintln!("unknown feature {feature}");
            false
        }
    };
    if ok {
        println!("{feature}: ok");
    } else {
        println!("{feature}: fail");
        std::process::exit(1);
    }
    let _ = ContextCapsule::empty();
}
