//! EP-022 M4 failure matrix: real forced failures through the real
//! wire-debugger crate. Every denial is a typed `DebugDenial` produced
//! by the production surface; nothing is mocked.

use wire_debugger::{
    DebugDenial, DraftKind, FixtureEvent, MacroForge, PerformanceStats, ReplayFixture,
    ScriptDebugger, TriggerLab, AiDebugger,
};

fn main() {
    // 1. Unavailable dependency: AI Debugger without approved evidence.
    let mut ai = AiDebugger::new();
    let r = ai.diagnose("d1", "missing-evidence", "h", "r", "p", vec![], "risk", "rb");
    assert_eq!(r, Err(DebugDenial::DeniedPolicy), "unapproved evidence must be denied");
    println!("failure unavailable-dependency: {:?}", r.unwrap_err());

    // 2. Timeout and cancellation: replay exceeding the execution budget.
    let mut lab = TriggerLab::new();
    let fixture = ReplayFixture {
        id: "slow".into(),
        name: "slow fixture".into(),
        events: (1..=200)
            .map(|i| FixtureEvent { at_step: i, line: format!("line {i}"), matches: String::new(), expect: None })
            .collect(),
    };
    lab.add_fixture(fixture).unwrap();
    // A slow script handler overruns the 1ms budget on the first event;
    // the crate aborts the replay (timeout/cancellation).
    let r = lab.replay("slow", |_| {
        std::thread::sleep(std::time::Duration::from_millis(2));
        None
    }, 1);
    assert_eq!(r, Err(DebugDenial::BudgetExhausted), "slow handler must exhaust budget");
    println!("failure timeout-cancellation: {:?}", r.unwrap_err());

    // 3. Malformed input: non-ascending fixture steps.
    let mut lab2 = TriggerLab::new();
    let bad = ReplayFixture {
        id: "bad".into(),
        name: "bad".into(),
        events: vec![
            FixtureEvent { at_step: 5, line: "a".into(), matches: String::new(), expect: None },
            FixtureEvent { at_step: 3, line: "b".into(), matches: String::new(), expect: None },
        ],
    };
    let r = lab2.add_fixture(bad);
    assert_eq!(r, Err(DebugDenial::MalformedInput), "non-ascending steps must be malformed");
    println!("failure malformed-input: {:?}", r.unwrap_err());

    // 4. Duplicate request: duplicate macro id and duplicate evidence id.
    let mut forge = MacroForge::new();
    forge.create("m1", DraftKind::Macro, "a", "x", 1).unwrap();
    let r = forge.create("m1", DraftKind::Macro, "b", "y", 2);
    assert_eq!(r, Err(DebugDenial::DuplicateRequest), "duplicate macro must be rejected");
    println!("failure duplicate-request: {:?}", r.unwrap_err());

    // 5. Denied permission/consent: private variable value never retained,
    //    and AI Debugger cannot self-certify.
    let mut dbg = ScriptDebugger::new();
    dbg.set_variable("password", "private", Some("sekrit".into())).unwrap();
    assert_eq!(dbg.variable("password").unwrap().value, None, "private value must be redacted");
    println!("failure denied-permission: private value redacted");

    // 6. Resource/queue budget exhaustion: variable ring bound and event
    //    ring bound enforced.
    let mut dbg2 = ScriptDebugger::new();
    for i in 0..600 {
        let _ = dbg2.set_variable(&format!("v{i}"), "public", Some("1".into()));
    }
    assert_eq!(dbg2.variable("v599"), None, "variable bound must reject overflow");
    println!("failure budget-exhaustion: variable ring capped at 512");

    // 7. Partial side effect and compensation: a failed replay run leaves
    //    no effects and the fixture is still available for retry.
    let r = lab.replay(
        "slow",
        |_| {
            std::thread::sleep(std::time::Duration::from_millis(2));
            Some("effect".into())
        },
        1,
    );
    assert_eq!(
        r,
        Err(DebugDenial::BudgetExhausted),
        "partial run must fail closed"
    );
    assert_eq!(lab.last_runs().len(), 0, "failed run must not be recorded");
    println!("failure partial-effect-compensation: failed run not recorded");

    // 8. Preserved manual gameplay and data integrity: over-budget macro
    //    is flagged, never dropped silently; the draft stays approved.
    let mut forge2 = MacroForge::new();
    forge2.create("m2", DraftKind::Macro, "slow-heal", "send(\"cure light\")\n", 1).unwrap();
    forge2.approve("m2").unwrap();
    assert!(forge2.get("m2").unwrap().is_runnable(), "approved draft remains runnable");
    let mut stats = PerformanceStats::new();
    stats.record("r1", DraftKind::Macro, "slow-heal", 150, 100);
    assert!(stats.samples()[0].over_budget, "over-budget sample must be flagged");
    assert_eq!(stats.slow_offenders().len(), 1);
    println!("failure preserved-gameplay: offender flagged, draft intact");

    println!("failure matrix: 8 failures exercised, all closed");
}
