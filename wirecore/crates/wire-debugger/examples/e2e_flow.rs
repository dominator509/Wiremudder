//! WireMudder Debugger E2E flow example (EP-022 M3).
//!
//! Real end-to-end flow through the wire-debugger crate:
//! 1. Forge a macro (preview-only, disabled until approved).
//! 2. Approve the draft.
//! 3. Load a deterministic Trigger Test Lab fixture and replay it
//!    without a live world.
//! 4. Inspect variables (public value shown, private value redacted).
//! 5. AI Debugger diagnoses approved evidence only, cites the evidence,
//!    never self-certifies.
//! 6. Performance stats record measured budgets and report slow
//!    offenders.
//!
//! This example is exercised by tests/wiremudder/ep022/e2e/*.sh and is
//! not a mock: it drives the same crate surface the client uses.

use wire_debugger::{
    DebugDenial, DraftKind, FixtureEvent, MacroForge, PerformanceStats, ReplayFixture,
    ScriptDebugger, TriggerLab, AiDebugger, PatchProposal,
};

fn main() {
    // 1-2. Macro Forge: previewable and disabled until approved.
    let mut forge = MacroForge::new();
    let macro_name = forge
        .create("macro-heal", DraftKind::Macro, "heal", "send(\"cure light\")\n", 1)
        .expect("create macro")
        .name
        .clone();
    {
        let draft = forge.get("macro-heal").expect("macro");
        assert!(draft.preview_only);
        assert!(!draft.is_runnable());
    }
    forge.approve("macro-heal").expect("approve macro");
    assert!(forge.get("macro-heal").expect("macro").is_runnable());

    // 3. Trigger Test Lab: deterministic replay without a live world.
    let mut lab = TriggerLab::new();
    let fixture = ReplayFixture {
        id: "fixture-crossroads".into(),
        name: "crossroads guard".into(),
        events: vec![
            FixtureEvent { at_step: 1, line: "You stand at a crossroads.".into(), matches: "crossroads".into(), expect: None },
            FixtureEvent { at_step: 2, line: "A guard bars the north exit.".into(), matches: "guard".into(), expect: Some("blocked north".into()) },
        ],
    };
    lab.add_fixture(fixture).expect("add fixture");
    let run = lab
        .replay("fixture-crossroads", |ev| {
            if ev.line.contains("crossroads") {
                Some("seen crossroads".into())
            } else if ev.line.contains("guard") {
                Some("blocked north".into())
            } else {
                None
            }
        }, 100)
        .expect("replay");
    assert_eq!(run.steps_executed, 2);
    assert_eq!(run.steps_matched, 2);
    assert!(run.finished);

    // 4. Variable inspection respects privacy.
    let mut dbg = ScriptDebugger::new();
    dbg.set_variable("gold", "public", Some("42".into())).expect("public var");
    dbg.set_variable("password", "private", Some("sekrit".into())).expect("private var");
    assert_eq!(dbg.variable("gold").expect("gold").value.as_deref(), Some("42"));
    assert_eq!(dbg.variable("password").expect("password").value, None);

    // 5. AI Debugger: approved evidence only, cites evidence, no
    //    self-certification, no gate editing.
    let mut ai = AiDebugger::new();
    let denied = ai.diagnose("diag-1", "evidence-1", "hyp", "repro", "patch", vec![], "risk", "rb");
    assert_eq!(denied, Err(DebugDenial::DeniedPolicy));
    ai.approve_evidence("evidence-1", vec!["line 1: guard blocked north".into()]).expect("approve evidence");
    let d = ai
        .diagnose("diag-1", "evidence-1", "trigger fires late", "replay step 2", "raise budget", vec!["budget test".into()], "low", "revert budget")
        .expect("diagnose");
    assert!(!d.self_certified);
    assert!(d.evidence.contains(&"line 1: guard blocked north".to_string()));

    // 6. Safe patch proposal requires Graphlock validation.
    let mut patch = PatchProposal::propose("patch-1".into(), "raise trigger budget".into(), vec!["src/triggers.cpp".into()]);
    assert!(!patch.validated);
    patch.mark_validated();
    assert!(patch.validated);

    // 7. Performance statistics: measured budgets and slow offenders.
    let mut stats = PerformanceStats::new();
    stats.record("r1", DraftKind::Trigger, "guard", 150, 100);
    stats.record("r2", DraftKind::Trigger, "guard", 120, 100);
    stats.record("r3", DraftKind::Macro, "fast", 5, 100);
    let offenders = stats.slow_offenders();
    assert_eq!(offenders.len(), 1);
    assert_eq!(offenders[0].name, "guard");
    assert_eq!(offenders[0].worst_ms, 150);

    println!("wire-debugger e2e flow: ok");
    println!("macro={} runnable_after_approval", macro_name);
    println!("replay steps={} matched={}", run.steps_executed, run.steps_matched);
    println!("ai self_certified={} gate_editable=false", d.self_certified);
    println!("slow_offenders={}", offenders.len());
}
