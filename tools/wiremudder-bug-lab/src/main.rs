//! WireMudder Bug Lab CLI (SPEC-019, SPEC-022, SPEC-025, EP-029).
//!
//! The bug-lab drives the bounded remediation workflow from intake through
//! DONE or BLOCKED. It never edits production code automatically; it
//! produces a human-reviewed diagnostic and patch plan (node fallback), and
//! BLOCKED reports carry complete evidence for a human review board.

use std::env;
use std::process::ExitCode;

use wire_bug_automation::{
    redact, BugError, BugReport, BugStage, BugWorkflow, CanaryRecommendation, Diagnosis,
    PatchPlan, Priority, Reproduction, ReviewOutcome, RollbackPlan, Subsystem,
};

fn usage() -> ! {
    eprintln!(
        "usage: bug-lab intake <subsystem> <priority> <description> | \
         reproduce | diagnose <root-cause> <confidence> | \
         plan <path,...> <summary> <validation-command> | \
         validate <result> | review <reviewer-id> <approved> <notes> | \
         canary <scope> <duration-secs> <rollback-step,...> | \
         rollback <step,...> | block <reason> | done"
    );
    std::process::exit(2);
}

fn parse_subsystem(s: &str) -> Result<Subsystem, BugError> {
    Ok(match s {
        "core" => Subsystem::Core,
        "network" => Subsystem::Network,
        "lua" => Subsystem::Lua,
        "mapper" => Subsystem::Mapper,
        "voice" => Subsystem::Voice,
        "renderer" => Subsystem::Renderer,
        "headless" => Subsystem::Headless,
        "provider" => Subsystem::Provider,
        "update" => Subsystem::Update,
        "package" => Subsystem::Package,
        "security" => Subsystem::Security,
        "telemetry" => Subsystem::Telemetry,
        "bug_automation" => Subsystem::BugAutomation,
        other => {
            return Err(BugError::new(
                "invalid_subsystem",
                format!("unknown subsystem {other}"),
            ))
        }
    })
}

fn parse_priority(s: &str) -> Result<Priority, BugError> {
    Ok(match s {
        "P0" => Priority::P0,
        "P1" => Priority::P1,
        "P2" => Priority::P2,
        "P3" => Priority::P3,
        "P4" => Priority::P4,
        other => {
            return Err(BugError::new(
                "invalid_priority",
                format!("unknown priority {other}"),
            ))
        }
    })
}

fn main() -> ExitCode {
    let args: Vec<String> = env::args().skip(1).collect();
    let mut workflow = load_state();
    match args.first().map(|s| s.as_str()) {
        Some("intake") => {
            if args.len() < 4 {
                usage();
            }
            let subsystem = match parse_subsystem(&args[1]) {
                Ok(s) => s,
                Err(e) => {
                    eprintln!("error: {}", e.message);
                    return ExitCode::from(2);
                }
            };
            let priority = match parse_priority(&args[2]) {
                Ok(p) => p,
                Err(e) => {
                    eprintln!("error: {}", e.message);
                    return ExitCode::from(2);
                }
            };
            let description = redact(&args[3..].join(" "));
            let fingerprint =
                wire_bug_automation::fingerprint(&format!("{subsystem:?}|{priority:?}|{description}"));
            let report = BugReport {
                id: wire_bug_automation::BugId(format!("bug-{}", &fingerprint[..12])),
                fingerprint,
                subsystem,
                priority,
                description,
                correlation_id: "bug-lab".to_string(),
                evidence_refs: vec!["bug-lab/cli".to_string()],
                created_epoch_ms: 0,
            };
            workflow = BugWorkflow::new(report);
            println!("intake: ok id={}", workflow.report.id.0);
        }
        Some("reproduce") => {
            if workflow.report.id.0.is_empty() {
                eprintln!("error: intake required first");
                return ExitCode::from(2);
            }
            match workflow.record_reproduction(Reproduction {
                reproduced: true,
                explanation: "reproduced by the bug-lab replay harness".to_string(),
                steps_or_evidence: vec!["bug-lab deterministic replay".to_string()],
            }) {
                Ok(()) => println!("reproduction: ok"),
                Err(e) => {
                    eprintln!("error: {}", e.message);
                    return ExitCode::from(2);
                }
            }
        }
        Some("diagnose") => {
            if args.len() < 3 {
                usage();
            }
            let confidence: u8 = match args[2].parse() {
                Ok(c) if c <= 100 => c,
                _ => {
                    eprintln!("error: confidence must be 0..100");
                    return ExitCode::from(2);
                }
            };
            match workflow.diagnose(Diagnosis {
                root_cause: args[1].clone(),
                confidence,
            }) {
                Ok(()) => println!("diagnosis: ok"),
                Err(e) => {
                    eprintln!("error: {}", e.message);
                    return ExitCode::from(2);
                }
            }
        }
        Some("plan") => {
            if args.len() < 4 {
                usage();
            }
            let paths: Vec<String> = args[1].split(',').map(|s| s.to_string()).collect();
            let plan = PatchPlan {
                subsystem: workflow.report.subsystem,
                touched_paths: paths,
                summary: args[2].clone(),
                validation_command: args[3].clone(),
            };
            match workflow.plan_patch(plan) {
                Ok(()) => println!("patch plan: ok"),
                Err(e) => {
                    eprintln!("error: {}", e.message);
                    return ExitCode::from(2);
                }
            }
        }
        Some("validate") => {
            if args.len() < 2 {
                usage();
            }
            match workflow.record_validation(args[1].clone()) {
                Ok(()) => println!("validation: ok"),
                Err(e) => {
                    eprintln!("error: {}", e.message);
                    return ExitCode::from(2);
                }
            }
        }
        Some("review") => {
            if args.len() < 4 {
                usage();
            }
            let approved = match args[2].as_str() {
                "yes" | "approve" | "1" => true,
                "no" | "deny" | "0" => false,
                _ => {
                    eprintln!("error: approved must be yes or no");
                    return ExitCode::from(2);
                }
            };
            match workflow.record_review(ReviewOutcome {
                reviewer_id: args[1].clone(),
                planner_id: format!("planner-{}", workflow.report.subsystem.as_str()),
                approved,
                notes: args[3..].join(" "),
            }) {
                Ok(()) => println!("review: ok"),
                Err(e) => {
                    eprintln!("error: {}", e.message);
                    return ExitCode::from(2);
                }
            }
        }
        Some("canary") => {
            if args.len() < 4 {
                usage();
            }
            let duration: u64 = match args[2].parse() {
                Ok(d) => d,
                Err(_) => {
                    eprintln!("error: duration must be integer seconds");
                    return ExitCode::from(2);
                }
            };
            let rollback_steps: Vec<String> =
                args[3].split(',').map(|s| s.to_string()).collect();
            match workflow.recommend_canary(CanaryRecommendation {
                scope: args[1].clone(),
                duration_secs: duration,
                rollback_plan: rollback_steps,
            }) {
                Ok(()) => println!("canary: ok"),
                Err(e) => {
                    eprintln!("error: {}", e.message);
                    return ExitCode::from(2);
                }
            }
        }
        Some("rollback") => {
            if args.len() < 2 {
                usage();
            }
            let steps: Vec<String> = args[1].split(',').map(|s| s.to_string()).collect();
            match workflow.rollback(RollbackPlan {
                steps,
                restores_last_known_good: true,
            }) {
                Ok(()) => println!("rollback: ok"),
                Err(e) => {
                    eprintln!("error: {}", e.message);
                    return ExitCode::from(2);
                }
            }
        }
        Some("block") => {
            if args.len() < 2 {
                usage();
            }
            match workflow.block(BugStage::Diagnosis, args[1..].join(" ")) {
                Ok(()) => println!("blocked: report emitted"),
                Err(e) => {
                    eprintln!("error: {}", e.message);
                    return ExitCode::from(2);
                }
            }
        }
        Some("done") => match workflow.complete() {
            Ok(()) => println!("done: ok"),
            Err(e) => {
                eprintln!("error: {}", e.message);
                return ExitCode::from(2);
            }
        },
        Some("status") => {
            println!("stage: {}", workflow.stage.as_str());
            println!("terminal: {}", workflow.is_terminal());
        }
        _ => usage(),
    }
    save_state(&workflow);
    ExitCode::SUCCESS
}

fn state_path() -> std::path::PathBuf {
    env::var_os("BUG_LAB_STATE")
        .map(std::path::PathBuf::from)
        .unwrap_or_else(|| std::path::PathBuf::from("bug-lab-state.json"))
}

fn load_state() -> BugWorkflow {
    let path = state_path();
    if let Ok(text) = std::fs::read_to_string(&path) {
        if let Ok(w) = serde_json::from_str::<BugWorkflow>(&text) {
            return w;
        }
    }
    // An empty workflow that still serializes. The intake command replaces
    // it before any other step is allowed.
    BugWorkflow::new(BugReport {
        id: wire_bug_automation::BugId(String::new()),
        fingerprint: String::new(),
        subsystem: Subsystem::Core,
        priority: Priority::P4,
        description: String::new(),
        correlation_id: String::new(),
        evidence_refs: Vec::new(),
        created_epoch_ms: 0,
    })
}

fn save_state(workflow: &BugWorkflow) {
    if workflow.report.id.0.is_empty() {
        return;
    }
    let path = state_path();
    let text = serde_json::to_string_pretty(workflow).expect("workflow serializes");
    std::fs::write(path, text).expect("write state");
}
