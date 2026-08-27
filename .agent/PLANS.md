# ExecPlan Standard

An ExecPlan is a self-contained implementation contract for one node. A new executor with no conversation history must be able to complete it from AGENTS.md, COMMANDS.md, GRAPH.md, LOOPS.md, accepted specs, node contract, expected paths, milestone path files, source evidence, and ledger.

Every plan contains NODE-META and exactly these sections: Purpose and Big Picture; Scope; Non-goals; Context and Orientation; Files to Read First; Expected Changed Files; Interfaces and Contracts; Milestones; Validation and Acceptance; Idempotence and Recovery; Progress; Surprises and Discoveries; Decision Log; Outcomes and Retrospective.

Every milestone contains GOAL, READ, CHANGE, CONTENT, RUN, EXPECT, EVIDENCE, FALLBACK, and COMMIT. Brownfield code composition is legal only after source evidence and contract locking. Progress, discoveries, decisions, and outcomes are the ordinary mutable regions. A plan cannot weaken an accepted spec or gate.
