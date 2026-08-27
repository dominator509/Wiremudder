//! WireMudder command policy core (SPEC-009).
//!
//! Per-world command schema and risk tiers (WM-FEAT-0174), known-safe
//! and known-dangerous command policies (WM-FEAT-0175), argument
//! validation and deny/allow rules (WM-FEAT-0176), destructive-action
//! confirmation (WM-FEAT-0177), and Human-Tempo anti-spam pacing
//! (WM-SPEC-009-R07). Policy is deterministic: the same command, args,
//! and state always produce the same decision.

use serde::{Deserialize, Serialize};
use std::collections::VecDeque;

pub const POLICY_SCHEMA_VERSION: u32 = 1;

/// Deterministic risk tiers for automated commands.
#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Serialize, Deserialize)]
#[serde(rename_all = "kebab-case")]
pub enum RiskTier {
    Safe,
    Standard,
    Risky,
    Destructive,
}

impl RiskTier {
    pub fn label(self) -> &'static str {
        match self {
            RiskTier::Safe => "safe",
            RiskTier::Standard => "standard",
            RiskTier::Risky => "risky",
            RiskTier::Destructive => "destructive",
        }
    }

    /// Destructive, social, trade, PvP, account, privacy, and
    /// irreversible actions require explicit confirmation unless a
    /// narrow user allowlist says otherwise (WM-SPEC-009-R04).
    pub fn requires_confirmation(self) -> bool {
        matches!(self, RiskTier::Risky | RiskTier::Destructive)
    }
}

/// A single command policy rule.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct CommandRule {
    /// Normalized command name (lowercase, no leading slash).
    pub command: String,
    pub tier: RiskTier,
    /// Hard deny: never allowed from non-manual sources.
    pub deny: bool,
    /// Narrow user allowlist: allowed without confirmation even when
    /// the tier would require it (WM-SPEC-009-R04).
    pub allowlisted: bool,
    /// Optional argument validation pattern: "eq:value", "min:N",
    /// "max:N", or "any".
    pub arg_policy: String,
}

impl CommandRule {
    pub fn new(command: &str, tier: RiskTier) -> Self {
        Self {
            command: command.to_string(),
            tier,
            deny: false,
            allowlisted: false,
            arg_policy: "any".to_string(),
        }
    }

    pub fn deny(mut self) -> Self {
        self.deny = true;
        self
    }

    pub fn allowlist(mut self) -> Self {
        self.allowlisted = true;
        self
    }

    pub fn arg_policy(mut self, policy: &str) -> Self {
        self.arg_policy = policy.to_string();
        self
    }
}

/// The deterministic result of evaluating a command against the policy.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct CommandPolicy {
    pub command: String,
    pub tier: RiskTier,
    pub denied: bool,
    pub requires_confirmation: bool,
    pub arg_ok: bool,
    pub arg_reason: String,
}

/// Per-world command database (WM-FEAT-0174).
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct CommandDatabase {
    pub world: String,
    pub schema_version: u32,
    pub rules: Vec<CommandRule>,
}

impl CommandDatabase {
    pub fn new(world: &str) -> Self {
        Self {
            world: world.to_string(),
            schema_version: POLICY_SCHEMA_VERSION,
            rules: Vec::new(),
        }
    }

    pub fn add_rule(&mut self, rule: CommandRule) {
        self.rules.push(rule);
    }

    /// Evaluate a normalized command with args. Deterministic:
    /// deny wins, then allowlist, then tier confirmation.
    pub fn evaluate(&self, command: &str, args: &[&str]) -> CommandPolicy {
        for rule in self.rules.iter().filter(|r| r.command == command) {
            if rule.deny {
                return CommandPolicy {
                    command: command.to_string(),
                    tier: rule.tier,
                    denied: true,
                    requires_confirmation: false,
                    arg_ok: false,
                    arg_reason: "denied by command database".to_string(),
                };
            }
            let (arg_ok, arg_reason) = validate_args(&rule.arg_policy, args);
            let requires_confirmation =
                rule.tier.requires_confirmation() && !rule.allowlisted;
            return CommandPolicy {
                command: command.to_string(),
                tier: rule.tier,
                denied: false,
                requires_confirmation,
                arg_ok,
                arg_reason,
            };
        }
        // Unknown command: default to standard tier, confirmed if the
        // action is destructive-looking. Unknown commands are never
        // high-confidence shortcuts (WM-SPEC-009-R05).
        let default_confirmation = looks_destructive(command, args);
        CommandPolicy {
            command: command.to_string(),
            tier: if default_confirmation {
                RiskTier::Risky
            } else {
                RiskTier::Standard
            },
            denied: false,
            requires_confirmation: default_confirmation,
            arg_ok: true,
            arg_reason: "unknown command; standard tier".to_string(),
        }
    }

    /// A stale or unavailable command database must pause automation
    /// rather than guess (WM-SPEC-009-R10).
    pub fn is_ready(&self) -> bool {
        !self.world.is_empty() && self.schema_version == POLICY_SCHEMA_VERSION
    }
}

/// Human-Tempo pacing: anti-spam and usability control only, never
/// bot-detection evasion or terms circumvention (WM-SPEC-009-R07).
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct HumanTempo {
    pub min_interval_ms: u64,
    pub max_burst: usize,
    pub burst_window_ms: u64,
    last_send_ms: u64,
    burst_start_ms: u64,
    burst_count: usize,
}

impl HumanTempo {
    pub fn new(min_interval_ms: u64, max_burst: usize, burst_window_ms: u64) -> Self {
        Self {
            min_interval_ms,
            max_burst,
            burst_window_ms,
            last_send_ms: 0,
            burst_start_ms: 0,
            burst_count: 0,
        }
    }

    /// Deterministic pacing decision for a send at time now_ms.
    ///
    /// Semantics: up to `max_burst` sends are allowed immediately within
    /// `burst_window_ms` (a burst is a quick group of sends); once the
    /// burst budget is consumed, sends wait until the window expires.
    /// The `min_interval_ms` is the inter-group cooldown applied to the
    /// first send of a new burst window (anti-spam, WM-SPEC-009-R07).
    pub fn should_send(&mut self, now_ms: u64) -> TempoDecision {
        if now_ms - self.burst_start_ms >= self.burst_window_ms {
            self.burst_start_ms = now_ms;
            self.burst_count = 0;
            if self.last_send_ms > 0 && now_ms - self.last_send_ms < self.min_interval_ms {
                return TempoDecision::Wait(
                    self.min_interval_ms - (now_ms - self.last_send_ms),
                );
            }
        }
        if self.burst_count >= self.max_burst {
            return TempoDecision::Wait(
                self.burst_window_ms - (now_ms - self.burst_start_ms),
            );
        }
        self.last_send_ms = now_ms;
        self.burst_count += 1;
        TempoDecision::Now
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "kebab-case")]
pub enum TempoDecision {
    Now,
    Wait(u64),
}

fn validate_args(policy: &str, args: &[&str]) -> (bool, String) {
    if policy == "any" {
        return (true, "ok".to_string());
    }
    if let Some(v) = policy.strip_prefix("eq:") {
        if args.len() == 1 && args[0] == v {
            return (true, "ok".to_string());
        }
        return (false, format!("expected argument equal to {v}"));
    }
    if let Some(v) = policy.strip_prefix("min:") {
        let n: usize = v.parse().unwrap_or(0);
        if args.len() >= n {
            return (true, "ok".to_string());
        }
        return (false, format!("expected at least {n} arguments"));
    }
    if let Some(v) = policy.strip_prefix("max:") {
        let n: usize = v.parse().unwrap_or(0);
        if args.len() <= n {
            return (true, "ok".to_string());
        }
        return (false, format!("expected at most {n} arguments"));
    }
    (false, "unsupported argument policy".to_string())
}

/// Heuristic for destructive-looking unknown commands: never a
/// high-confidence shortcut; only used to pick the default tier.
fn looks_destructive(command: &str, args: &[&str]) -> bool {
    let joined = format!("{} {}", command, args.join(" "));
    let lower = joined.to_lowercase();
    ["kill", "quit", "quit!", "delete", "drop all", "sacrifice", "sell all", "give all"]
        .iter()
        .any(|k| lower.contains(k))
}

#[cfg(test)]
mod tests {
    use super::*;

    fn db() -> CommandDatabase {
        let mut db = CommandDatabase::new("midkemia");
        db.add_rule(CommandRule::new("say", RiskTier::Safe));
        db.add_rule(CommandRule::new("tell", RiskTier::Standard));
        db.add_rule(CommandRule::new("kill", RiskTier::Destructive));
        db.add_rule(CommandRule::new("quit", RiskTier::Destructive).deny());
        db.add_rule(CommandRule::new("give", RiskTier::Risky).arg_policy("min:2"));
        db.add_rule(
            CommandRule::new("drop all", RiskTier::Destructive).allowlist(),
        );
        db
    }

    #[test]
    fn tier_confirmation_is_deterministic() {
        let db = db();
        assert!(!db.evaluate("say", &["hi"]).requires_confirmation);
        assert!(!db.evaluate("tell", &["bob", "hi"]).requires_confirmation);
        assert!(db.evaluate("kill", &["orc"]).requires_confirmation);
        // Allowlist narrows confirmation for the specific command.
        assert!(!db.evaluate("drop all", &[]).requires_confirmation);
        // Deny wins.
        assert!(db.evaluate("quit", &[]).denied);
    }

    #[test]
    fn argument_validation() {
        let db = db();
        let ok = db.evaluate("give", &["bob", "sword"]);
        assert!(ok.arg_ok);
        let bad = db.evaluate("give", &["bob"]);
        assert!(!bad.arg_ok);
        assert!(bad.arg_reason.contains("at least 2"));
    }

    #[test]
    fn unknown_commands_are_never_shortcuts() {
        let db = db();
        let p = db.evaluate("frobnicate", &["x"]);
        assert!(!p.denied);
        assert_eq!(p.tier, RiskTier::Standard);
        // Destructive-looking unknown commands get confirmation.
        let p2 = db.evaluate("cast", &["sacrifice", "all"]);
        assert!(p2.requires_confirmation);
    }

    #[test]
    fn database_ready_state() {
        let db = CommandDatabase::new("midkemia");
        assert!(db.is_ready());
        let mut bad = db.clone();
        bad.schema_version = 99;
        assert!(!bad.is_ready());
    }

    #[test]
    fn human_tempo_is_anti_spam() {
        let mut tempo = HumanTempo::new(1000, 3, 5000);
        // A burst of 3 sends goes through immediately (anti-spam allows
        // a bounded quick group).
        assert_eq!(tempo.should_send(0), TempoDecision::Now);
        assert_eq!(tempo.should_send(10), TempoDecision::Now);
        assert_eq!(tempo.should_send(20), TempoDecision::Now);
        // Burst exhausted: wait until the window expires.
        let d = tempo.should_send(30);
        assert!(matches!(d, TempoDecision::Wait(_)));
        // New window: the inter-group interval is satisfied, send allowed.
        assert_eq!(tempo.should_send(5000), TempoDecision::Now);
        // Inter-group cooldown: after a burst, the next window's first
        // send is gated by min_interval_ms.
        let mut t2 = HumanTempo::new(500, 2, 10000);
        assert_eq!(t2.should_send(0), TempoDecision::Now);
        assert_eq!(t2.should_send(100), TempoDecision::Now);  // within burst budget
        assert!(matches!(t2.should_send(200), TempoDecision::Wait(_)));  // burst exhausted
        assert_eq!(t2.should_send(10000), TempoDecision::Now);  // window reset
    }
}
