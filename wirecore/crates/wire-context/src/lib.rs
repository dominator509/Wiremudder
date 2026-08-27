//! WireMudder Context Distillation core (SPEC-003, SPEC-013, EP-015).
//!
//! Deterministic first-pass distillation: typed events from raw game
//! text (WM-FEAT-0196..0206), compact cited context capsules with spam
//! removal (WM-FEAT-0048, WM-SPEC-013-R02), and redaction before any
//! provider sees content (SPEC-010). No AI extraction runs here; that
//! bounded second pass is only enabled when deterministic rules cannot
//! resolve required state (WM-SPEC-013-R01) and stays behind EP-016.
//!
//! Zero new dependencies: serde/serde_json only, hand-rolled
//! deterministic pattern matching (no regex crate, no supply chain).

use serde::{Deserialize, Serialize};

pub const CONTEXT_SCHEMA_VERSION: u32 = 1;
pub const MAX_CAPSULE_ENTITIES: usize = 64;
pub const MAX_SPAM_WINDOW: usize = 64;

// ---------------------------------------------------------------------------
// Typed events (WM-FEAT-0196..0206)
// ---------------------------------------------------------------------------

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub enum Event {
    /// WM-FEAT-0196
    RoomSeen {
        name: String,
        exits: Vec<String>,
        description: Option<String>,
    },
    /// WM-FEAT-0197
    ExitSeen {
        direction: String,
        destination: Option<String>,
    },
    /// WM-FEAT-0198
    MobSeen { name: String },
    /// WM-FEAT-0199
    PlayerSeen { name: String },
    /// WM-FEAT-0200
    AnimalSeen { name: String },
    /// WM-FEAT-0201
    PKerOrPvPerSeen { name: String },
    /// WM-FEAT-0202
    CombatStarted { target: String },
    /// WM-FEAT-0202
    CombatEnded { target: Option<String> },
    /// WM-FEAT-0203
    ItemSeen { name: String },
    /// WM-FEAT-0203
    QuestClueSeen { clue: String },
    /// WM-FEAT-0204
    PromptSeen {
        prompt: String,
        health: Option<i64>,
        mana: Option<i64>,
    },
    /// WM-FEAT-0204
    HealthChanged { delta: i64, current: i64 },
    /// WM-FEAT-0205
    CommandSucceeded { command: String },
    /// WM-FEAT-0205
    CommandFailed { command: String, reason: String },
    /// WM-FEAT-0206
    SocialMessageSeen {
        channel: String,
        sender: String,
        text: String,
    },
    /// WM-FEAT-0206 (text always redacted before any provider)
    PrivateMessageRedacted { sender: String },
}

// ---------------------------------------------------------------------------
// Deterministic distillation (WM-SPEC-013-R01)
// ---------------------------------------------------------------------------

/// One distilled state snapshot for a context capsule (WM-SPEC-013-R02).
#[derive(Debug, Clone, Default, PartialEq, Eq, Serialize, Deserialize)]
pub struct ContextCapsule {
    pub room: Option<String>,
    pub exits: Vec<String>,
    pub entities: Vec<String>,
    pub combat: Option<String>,
    pub health: Option<i64>,
    pub mana: Option<i64>,
    pub prompt: Option<String>,
    pub quest_clues: Vec<String>,
    pub command_policy: Vec<String>,
    pub memory_citations: Vec<String>,
    pub safety_evidence: Vec<String>,
    pub user_request: Option<String>,
    /// Number of repeated lines collapsed by the spam window.
    pub spam_collapsed: usize,
}

impl ContextCapsule {
    pub fn empty() -> Self {
        Self {
            room: None,
            exits: Vec::new(),
            entities: Vec::new(),
            combat: None,
            health: None,
            mana: None,
            prompt: None,
            quest_clues: Vec::new(),
            command_policy: Vec::new(),
            memory_citations: Vec::new(),
            safety_evidence: Vec::new(),
            user_request: None,
            spam_collapsed: 0,
        }
    }

    /// Approximate serialized size in bytes (bounded for token budgets).
    pub fn approx_bytes(&self) -> usize {
        let json = serde_json::to_vec(self).unwrap_or_default();
        json.len()
    }
}

/// Distillation state machine: events in, capsule out, spam removed.
#[derive(Debug, Clone, Default)]
pub struct Distiller {
    capsule: ContextCapsule,
    recent: std::collections::VecDeque<String>,
}

impl Distiller {
    pub fn new() -> Self {
        Self::default()
    }

    /// Feed one raw game line through deterministic rules.
    pub fn feed_line(&mut self, line: &str) -> Vec<Event> {
        let events = parse_line(line);
        for ev in &events {
            self.apply(ev);
        }
        events
    }

    /// Apply a typed event to the capsule state.
    pub fn apply(&mut self, ev: &Event) {
        match ev {
            Event::RoomSeen { name, exits, .. } => {
                self.capsule.room = Some(name.clone());
                self.capsule.exits = exits.clone();
                self.capsule.entities.clear();
            }
            Event::ExitSeen { direction, .. } => {
                if !self.capsule.exits.iter().any(|e| e == direction) {
                    self.capsule.exits.push(direction.clone());
                }
            }
            Event::MobSeen { name }
            | Event::PlayerSeen { name }
            | Event::AnimalSeen { name }
            | Event::PKerOrPvPerSeen { name } => {
                self.push_entity(name);
            }
            Event::ItemSeen { name } => self.push_entity(name),
            Event::CombatStarted { target } => self.capsule.combat = Some(target.clone()),
            Event::CombatEnded { .. } => self.capsule.combat = None,
            Event::QuestClueSeen { clue } => {
                Self::push_unique(&mut self.capsule.quest_clues, clue)
            }
            Event::PromptSeen { prompt, health, mana } => {
                self.capsule.prompt = Some(prompt.clone());
                if let Some(h) = health {
                    self.capsule.health = Some(*h);
                }
                if let Some(m) = mana {
                    self.capsule.mana = Some(*m);
                }
            }
            Event::HealthChanged { current, .. } => self.capsule.health = Some(*current),
            Event::CommandSucceeded { command } => {
                self.capsule.user_request = Some(command.clone());
                Self::push_unique(
                    &mut self.capsule.safety_evidence,
                    &format!("cmd-ok:{command}"),
                );
            }
            Event::CommandFailed { command, reason } => {
                self.capsule.user_request = Some(command.clone());
                Self::push_unique(
                    &mut self.capsule.safety_evidence,
                    &format!("cmd-fail:{command}:{reason}"),
                );
            }
            Event::SocialMessageSeen { .. } | Event::PrivateMessageRedacted { .. } => {
                // socials never enter the capsule (spam); private message
                // content is redacted before any provider sees it.
            }
        }
    }

    fn push_entity(&mut self, name: &str) {
        if self.capsule.entities.len() >= MAX_CAPSULE_ENTITIES {
            return; // bounded
        }
        Self::push_unique(&mut self.capsule.entities, name);
    }

    fn push_unique(vec: &mut Vec<String>, value: &str) {
        if !vec.iter().any(|v| v == value) {
            vec.push(value.to_string());
        }
    }

    /// Collapse repeated lines within the spam window (WM-SPEC-013-R02).
    /// Returns the collapsed line (or None if the line was already seen
    /// within the window, in which case the spam counter is incremented).
    pub fn collapse_spam(&mut self, line: &str) -> Option<String> {
        if self.recent.iter().any(|r| r == line) {
            self.capsule.spam_collapsed += 1;
            return None;
        }
        self.recent.push_back(line.to_string());
        while self.recent.len() > MAX_SPAM_WINDOW {
            self.recent.pop_front();
        }
        Some(line.to_string())
    }

    /// Distill with spam removal: returns events only for non-spam lines.
    pub fn feed_line_collapsed(&mut self, line: &str) -> Vec<Event> {
        if self.collapse_spam(line).is_some() {
            self.feed_line(line)
        } else {
            Vec::new()
        }
    }

    pub fn capsule(&self) -> &ContextCapsule {
        &self.capsule
    }

    pub fn into_capsule(self) -> ContextCapsule {
        self.capsule
    }
}

// ---------------------------------------------------------------------------
// Deterministic grammar rules (no regex; bounded, ordered, typed)
// ---------------------------------------------------------------------------

/// Parse one raw game line into typed events using deterministic rules.
pub fn parse_line(line: &str) -> Vec<Event> {
    let t = line.trim();
    if t.is_empty() {
        return Vec::new();
    }
    let mut out = Vec::new();

    // Prompt with HP/Mana numbers: "<hp>h <mana>m> " or bare "<hp>/<max>hp"
    if let Some(ev) = try_prompt(t) {
        out.push(ev);
        return out;
    }

    // Room header: "You are in <name>." optionally followed by exits.
    if let Some(name) = strip_prefix(t, "You are in ") {
        let name = name.trim_end_matches('.').to_string();
        out.push(Event::RoomSeen {
            name: name.clone(),
            exits: Vec::new(),
            description: None,
        });
        return out;
    }
    if let Some(name) = strip_prefix(t, "You are standing in ") {
        let name = name.trim_end_matches('.').to_string();
        out.push(Event::RoomSeen {
            name,
            exits: Vec::new(),
            description: None,
        });
        return out;
    }

    // Exits line: "Obvious exits: north, east" or "Exits: n, s".
    // Emits ExitSeen events only; the room name is never overwritten.
    if let Some(rest) = strip_prefix(t, "Obvious exits: ") {
        for e in split_list(rest) {
            out.push(Event::ExitSeen {
                direction: e,
                destination: None,
            });
        }
        return out;
    }
    if let Some(rest) = strip_prefix(t, "Exits: ") {
        for e in split_list(rest) {
            out.push(Event::ExitSeen {
                direction: e,
                destination: None,
            });
        }
        return out;
    }

    // Mobs/animals: "A <name> is here." with trailing junk tolerated
    // (injected text after the marker stays unparsed DATA).
    if let Some(rest) = strip_prefix(t, "A ") {
        if let Some(name) = name_before_marker(rest, " is here") {
            out.push(Event::MobSeen {
                name: name.trim().to_string(),
            });
            return out;
        }
    }
    if let Some(rest) = strip_prefix(t, "An ") {
        if let Some(name) = name_before_marker(rest, " is here") {
            out.push(Event::AnimalSeen {
                name: name.trim().to_string(),
            });
            return out;
        }
    }

    // Items first ("You see a <item> here.") so item names are never
    // mistaken for players; players use the bare "You see <Name> here."
    if let Some(rest) = strip_prefix(t, "You see a ") {
        if let Some(name) = name_before_marker(rest, " here") {
            out.push(Event::ItemSeen {
                name: name.trim().to_string(),
            });
            return out;
        }
    }
    if let Some(rest) = strip_prefix(t, "You see an ") {
        if let Some(name) = name_before_marker(rest, " here") {
            out.push(Event::ItemSeen {
                name: name.trim().to_string(),
            });
            return out;
        }
    }
    // Players: "<name> is standing here."
    if let Some(rest) = strip_prefix(t, "You see ") {
        if let Some(name) = name_before_marker(rest, " here") {
            out.push(Event::PlayerSeen {
                name: name.trim().to_string(),
            });
            return out;
        }
    }
    // PKer/PvPer: "<name> is here (PK)."
    if let Some(rest) = strip_prefix(t, "You notice ") {
        if let Some(name) = name_before_marker(rest, " (PK)") {
            out.push(Event::PKerOrPvPerSeen {
                name: name.trim().to_string(),
            });
            return out;
        }
    }

    // Combat: "You hit <target> for <n> damage." / "You miss <target>."
    if let Some(rest) = strip_prefix(t, "You hit ") {
        let target = rest
            .split(" for ")
            .next()
            .unwrap_or(rest)
            .to_string();
        out.push(Event::CombatStarted { target });
        return out;
    }
    if let Some(target) = strip_prefix(t, "You miss ") {
        let target = target.trim_end_matches('.').to_string();
        out.push(Event::CombatStarted { target });
        return out;
    }
    if let Some(rest) = strip_prefix(t, "You kill ") {
        let target = rest.trim_end_matches('.').to_string();
        out.push(Event::CombatEnded {
            target: Some(target),
        });
        return out;
    }
    if t == "Combat ends." {
        out.push(Event::CombatEnded { target: None });
        return out;
    }

    // Health: "Your health is 80/100." or "Health: 80/100"
    if let Some(rest) = strip_prefix(t, "Your health is ") {
        if let Some(num) = extract_leading_number(rest) {
            out.push(Event::HealthChanged {
                delta: 0,
                current: num,
            });
            return out;
        }
    }
    if let Some(rest) = strip_prefix(t, "Health: ") {
        if let Some(num) = extract_leading_number(rest) {
            out.push(Event::HealthChanged {
                delta: 0,
                current: num,
            });
            return out;
        }
    }

    // Items handled above ("You see a <item> here."); remaining item
    // surface: "On the ground: <item>"
    if let Some(rest) = strip_prefix(t, "On the ground: ") {
        for item in split_list(rest) {
            out.push(Event::ItemSeen { name: item });
        }
        return out;
    }

    // Quest clues: "A clue: <clue>" / "You recall that <clue>"
    if let Some(clue) = strip_prefix(t, "A clue: ") {
        out.push(Event::QuestClueSeen {
            clue: clue.to_string(),
        });
        return out;
    }
    if let Some(clue) = strip_prefix(t, "You recall that ") {
        out.push(Event::QuestClueSeen {
            clue: clue.trim_end_matches('.').to_string(),
        });
        return out;
    }

    // Command results: "You say, \"...\"" succeeded; "I don't understand
    // '<cmd>'." failed.
    if let Some(cmd) = strip_prefix(t, "You say, ") {
        out.push(Event::CommandSucceeded {
            command: cmd.to_string(),
        });
        return out;
    }
    if let Some(rest) = strip_prefix(t, "I don't understand '") {
        if let Some(cmd) = rest.split('\'').next() {
            out.push(Event::CommandFailed {
                command: cmd.to_string(),
                reason: "unknown command".into(),
            });
            return out;
        }
    }

    // Socials: "You tell <channel> <sender>: <text>" (public)
    if let Some(rest) = strip_prefix(t, "You tell ") {
        let parts: Vec<&str> = rest.splitn(3, ' ').collect();
        if parts.len() == 3 {
            let channel = parts[0].to_string();
            let sender = parts[1].trim_end_matches(':').to_string();
            let text = parts[2].to_string();
            out.push(Event::SocialMessageSeen {
                channel,
                sender,
                text,
            });
            return out;
        }
    }

    // Private messages are redacted immediately (SPEC-010).
    if strip_prefix(t, "From ") != None || strip_prefix(t, "You receive a private message from ") != None {
        let sender = extract_sender(t);
        out.push(Event::PrivateMessageRedacted { sender });
        return out;
    }

    out
}

fn try_prompt(t: &str) -> Option<Event> {
    // "<80>hp <50>m> " style
    if let Some(rest) = strip_prefix(t, "<") {
        let (hp, after) = split_once(rest, '>')?;
        if let Some(after) = after.strip_prefix("hp ") {
            let (mana, after2) = split_once(after, '>')?;
            // The mana token is "<50>": strip its leading angle bracket.
            let mana = mana.trim_start_matches('<');
            if after2.starts_with('m') || after2.starts_with("m>") || after2 == "m " {
                let hp: i64 = hp.parse().ok()?;
                let mana: i64 = mana.parse().ok()?;
                return Some(Event::PromptSeen {
                    prompt: t.to_string(),
                    health: Some(hp),
                    mana: Some(mana),
                });
            }
        }
    }
    // "<hp>/<max>hp>" style
    if let Some(rest) = strip_prefix(t, "<") {
        let (hp, after) = split_once(rest, '/')?;
        let after = after.strip_suffix(">")?;
        if let Some(_max) = after.strip_suffix("hp") {
            let hp: i64 = hp.parse().ok()?;
            return Some(Event::PromptSeen {
                prompt: t.to_string(),
                health: Some(hp),
                mana: None,
            });
        }
    }
    None
}

fn extract_sender(t: &str) -> String {
    // "From <name>: ..." or "You receive a private message from <name>."
    if let Some(rest) = strip_prefix(t, "From ") {
        if let Some(name) = rest.split(':').next() {
            return name.trim().to_string();
        }
    }
    if let Some(rest) = strip_prefix(t, "You receive a private message from ") {
        return rest.trim_end_matches('.').trim().to_string();
    }
    "unknown".to_string()
}

fn strip_prefix<'a>(s: &'a str, prefix: &str) -> Option<&'a str> {
    s.strip_prefix(prefix)
}

/// Extract the name before `marker` in `rest`, tolerating trailing junk
/// (the marker must be followed by end, '.', ',', '!', or whitespace).
fn name_before_marker<'a>(rest: &'a str, marker: &str) -> Option<&'a str> {
    let idx = rest.find(marker)?;
    let after = &rest[idx + marker.len()..];
    let ok = after.is_empty()
        || after.starts_with('.')
        || after.starts_with(',')
        || after.starts_with('!')
        || after.starts_with(' ');
    if ok {
        Some(&rest[..idx])
    } else {
        None
    }
}

fn strip_suffix<'a>(s: &'a str, suffix: &str) -> Option<&'a str> {
    s.strip_suffix(suffix)
}

fn split_once(s: &str, c: char) -> Option<(&str, &str)> {
    let idx = s.find(c)?;
    Some((&s[..idx], &s[idx + 1..]))
}

fn split_list(s: &str) -> Vec<String> {
    s.split(',')
        .map(|x| x.trim().to_string())
        .filter(|x| !x.is_empty())
        .collect()
}

fn extract_leading_number(s: &str) -> Option<i64> {
    let num: String = s.chars().take_while(|c| c.is_ascii_digit()).collect();
    if num.is_empty() {
        None
    } else {
        num.parse().ok()
    }
}

// ---------------------------------------------------------------------------
// Redaction (SPEC-010, WM-FEAT-0206)
// ---------------------------------------------------------------------------

/// Redact secret-shaped substrings from a line before it leaves the
/// machine: passwords, tokens, api keys, and routing secrets.
pub fn redact_text(input: &str) -> String {
    let mut out = input.to_string();
    for marker in [
        "password=",
        "passwd=",
        "token=",
        "api_key=",
        "apikey=",
        "secret=",
        "Bearer ",
    ] {
        out = redact_after_marker(&out, marker);
    }
    out
}

fn redact_after_marker(input: &str, marker: &str) -> String {
    let mut result = String::with_capacity(input.len());
    let mut rest = input;
    while let Some(idx) = rest.find(marker) {
        result.push_str(&rest[..idx]);
        result.push_str(marker);
        let after = &rest[idx + marker.len()..];
        // Skip leading separators, then consume the value up to the next
        // separator so the secret itself is replaced, not just the gap.
        let value_start = after
            .find(|c: char| !c.is_whitespace() && c != ',' && c != '&' && c != '"')
            .unwrap_or(after.len());
        let value_end = after[value_start..]
            .find(|c: char| c.is_whitespace() || c == ',' || c == '&' || c == '"')
            .map(|i| value_start + i)
            .unwrap_or(after.len());
        result.push_str("[REDACTED]");
        rest = &after[value_end..];
    }
    result.push_str(rest);
    result
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn room_seen_typed() {
        let evs = parse_line("You are in The Market Square.");
        assert_eq!(
            evs,
            vec![Event::RoomSeen {
                name: "The Market Square".into(),
                exits: vec![],
                description: None,
            }]
        );
    }

    #[test]
    fn exits_typed() {
        let evs = parse_line("Obvious exits: north, east");
        assert!(evs.iter().any(|e| matches!(e, Event::ExitSeen { direction, .. } if direction == "north")));
        assert!(evs.iter().any(|e| matches!(e, Event::ExitSeen { direction, .. } if direction == "east")));
    }

    #[test]
    fn mob_and_animal_typed() {
        assert!(matches!(parse_line("A griffin is here.")[0], Event::MobSeen { ref name } if name == "griffin"));
        assert!(matches!(parse_line("An eagle is here.")[0], Event::AnimalSeen { ref name } if name == "eagle"));
    }

    #[test]
    fn player_and_pker_typed() {
        assert!(matches!(parse_line("You see Bob here.")[0], Event::PlayerSeen { ref name } if name == "Bob"));
        assert!(matches!(parse_line("You notice Malice (PK).")[0], Event::PKerOrPvPerSeen { ref name } if name == "Malice"));
    }

    #[test]
    fn combat_typed() {
        assert!(matches!(parse_line("You hit the goblin for 12 damage.")[0], Event::CombatStarted { ref target } if target == "the goblin"));
        assert!(matches!(parse_line("You kill the goblin.")[0], Event::CombatEnded { target: Some(_) }));
        assert!(matches!(parse_line("Combat ends.")[0], Event::CombatEnded { target: None }));
    }

    #[test]
    fn prompt_typed() {
        let evs = parse_line("<80>hp <50>m> ");
        assert!(matches!(evs[0], Event::PromptSeen { health: Some(80), mana: Some(50), .. }));
    }

    #[test]
    fn health_typed() {
        assert!(matches!(parse_line("Your health is 75/100.")[0], Event::HealthChanged { current: 75, .. }));
    }

    #[test]
    fn items_and_quest_clues_typed() {
        assert!(matches!(parse_line("You see a rusty sword here.")[0], Event::ItemSeen { ref name } if name == "rusty sword"));
        assert!(matches!(parse_line("A clue: the vault opens at midnight.")[0], Event::QuestClueSeen { .. }));
    }

    #[test]
    fn commands_typed() {
        assert!(matches!(parse_line("You say, \"hello\"").first(), Some(Event::CommandSucceeded { .. })));
        assert!(matches!(parse_line("I don't understand 'frobnicate'.")[0], Event::CommandFailed { ref command, .. } if command == "frobnicate"));
    }

    #[test]
    fn social_and_private_redacted() {
        assert!(matches!(parse_line("You tell gossip Alice: hi all")[0], Event::SocialMessageSeen { ref channel, ref sender, .. } if channel == "gossip" && sender == "Alice"));
        let evs = parse_line("From Eve: meet me at the vault");
        assert!(matches!(evs[0], Event::PrivateMessageRedacted { ref sender } if sender == "Eve"));
    }

    #[test]
    fn capsule_assembles_state() {
        let mut d = Distiller::new();
        d.feed_line("You are in The Dark Vault.");
        d.feed_line("Obvious exits: north");
        d.feed_line("A goblin is here.");
        d.feed_line("A goblin is here.");
        d.feed_line("You hit the goblin for 5 damage.");
        d.feed_line("<70>hp <40>m> ");
        d.feed_line("A clue: the key is under the rug.");
        let c = d.into_capsule();
        assert_eq!(c.room.as_deref(), Some("The Dark Vault"));
        assert!(c.exits.contains(&"north".to_string()));
        assert!(c.entities.contains(&"goblin".to_string()));
        assert_eq!(c.combat.as_deref(), Some("the goblin"));
        assert_eq!(c.health, Some(70));
        assert!(c.quest_clues.iter().any(|q| q.contains("key")));
    }

    #[test]
    fn spam_collapse_bounded() {
        let mut d = Distiller::new();
        d.feed_line_collapsed("The wind howls.");
        assert_eq!(d.feed_line_collapsed("The wind howls.").len(), 0);
        assert_eq!(d.capsule().spam_collapsed, 1);
        // a distinct line still passes
        assert_eq!(d.feed_line_collapsed("A goblin is here.").len(), 1);
    }

    #[test]
    fn capsule_bounded_entities() {
        let mut d = Distiller::new();
        for i in 0..200 {
            d.feed_line(&format!("A mob{i} is here."));
        }
        assert!(d.capsule().entities.len() <= MAX_CAPSULE_ENTITIES);
    }

    #[test]
    fn redaction_strips_secrets() {
        let r = redact_text("login token=abc123 secret password= hunter2 now");
        assert!(!r.contains("abc123"));
        assert!(r.contains("[REDACTED]"));
        assert!(!r.contains("hunter2"));
    }

    #[test]
    fn prompt_and_health_serialize() {
        let ev = Event::PromptSeen {
            prompt: "<80>hp <50>m> ".into(),
            health: Some(80),
            mana: Some(50),
        };
        let json = serde_json::to_string(&ev).unwrap();
        assert!(json.contains("PromptSeen"));
    }
}
