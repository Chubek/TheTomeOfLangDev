# Chapter 37 — Compiler as a Constraint Solver

**Part of:** *The Modern Compiler Dossier* · **Concept origin:** New proposal developed for this dossier · **Primary area:** Cost, resources and architecture

> **Central proposition.** Proposed extension: expose global compiler design choices as a constraint problem instead of a sequence of independent greedy decisions. Instruction selection, register use, code size, memory placement and latency must often be negotiated together. A solver can explore feasible tradeoffs for a bounded region while heuristics handle the rest.

## 1. Why this idea changes compiler design

Generate decision variables for instruction alternatives, scheduling cycles, physical registers, resource locations and code variants. Hard constraints encode correctness and architecture; soft objectives encode estimated performance. Use ILP, CP-SAT or an SMT optimization engine on small hot regions with a strict time budget.

A useful way to approach the design is to separate a **reference meaning**, a **candidate implementation**, a **validator or legality boundary**, and a **measurement loop**. This distinction prevents performance statistics from being confused with proof of correctness. It also makes the idea compatible with languages that have different overflow, exception, concurrency and foreign-function semantics.

## 2. Internal representation and interfaces

The following sketch is a proposed notation, not the syntax of an existing compiler framework. It is intentionally compact enough to serve as the start of a DSL or IR schema.

```text
var choose_lea: Bool
var choose_mul: Bool
constraint xor(choose_lea,choose_mul)
constraint live_regs_at_cycle(t) <= 14
constraint code_bytes <= 64
minimize latency + 0.05*code_bytes + spill_cost
```

This representation needs a stable identity scheme for values, functions, versions or resources mentioned in the sketch. An implementation should state which fields are **static semantics**, which are **runtime observations**, which are **guarded assumptions**, and which are **derived caches**. Blurring those categories is a common cause of invalidation bugs. Where the notation uses estimates or profiler data, it should record the collection epoch and target as part of the record.

## 3. Mechanism: from idea to executable system

A concrete execution sequence for the proposed design is:

1. **Choose a small hot region and define exact target legality constraints.**
2. **Construct variables for meaningful alternatives, excluding semantically invalid ones.**
3. **Solve under wall-clock and memory limits with a known feasible baseline.**
4. **Validate the chosen assignment in an independent backend verifier.**
5. **Use learned heuristics to select regions where solving is likely to pay.**

For a small compiler, make each step inspectable through a textual dump. The dump should include the source/IR revision, the selected candidate, the reason for selection, and any required assumptions. For a concurrent compiler, attach revision numbers to requests and results so that work produced for an obsolete program cannot be published accidentally.

## 4. Correctness contract and proof obligations

A solver-generated assignment must still pass ABI, scheduling and semantic checks. Timeout is not a compiler failure if a valid heuristic solution exists; approximated costs are objectives, not guarantees.

A reviewer should be able to answer four questions for every transformation: **(1)** Which source-level observations must remain identical? **(2)** Which assumptions are proved statically, and which are checked dynamically? **(3)** Where does execution go if a guard, resource request or validation fails? **(4)** What previously calculated facts and artifacts must be invalidated? A design that answers only the performance question is incomplete.

The practical verification ladder is: structural IR verification; type/effect/dominance checks where applicable; differential execution against a reference; randomized or metamorphic tests over adversarial inputs; and bounded symbolic or translation validation for a tractable subset. These methods have different guarantees. Tests can find counterexamples, not prove universal equivalence. SMT-based bounded validation is only as strong as its encoding and bounds. The artifact should describe which rung was achieved rather than presenting a Boolean `verified` flag with no scope.

## 5. Engineering costs and negative cases

- **Risk 1:** Global search scales poorly to entire programs.
- **Risk 2:** Cost functions omit microarchitectural interactions.
- **Risk 3:** Inconsistent constraint models may produce feasible but unencodable schedules.

Compatibility costs also matter. Debuggers, profilers, coverage tools, sanitizers, binary interfaces, exception unwinders and reproducible builds consume compiler metadata. If an optimization changes control locations, representation versions or calling conventions, downstream tooling needs enough provenance to stay correct.

## 6. Implementation roadmap

**Milestone A — semantic reference.** Build a deliberately slow baseline that implements the relevant behavior exactly. Derive executable test cases from the example and document its unsupported features. Begin with **Choose a small hot region and define exact target legality constraints**. Make the baseline capable of dumping both input state and output observations.

**Milestone B — smallest useful optimization.** Implement one well-scoped transformation that exercises **Construct variables for meaningful alternatives, excluding semantically invalid ones**. Prefer a single function or basic block, a single target and stable data structures. Add a verifier that runs before code is exposed to users.

**Milestone C — adaptive or incremental operation.** Introduce **Solve under wall-clock and memory limits with a known feasible baseline**. Track which facts the optimization consumes. Add rollback, fallback or invalidation behavior as dictated by the correctness contract and test it with deliberately stale inputs.

**Milestone D — integration and observability.** Complete **Use learned heuristics to select regions where solving is likely to pay**. Provide an inspector for alternative decisions and an event log that connects the optimization request to generated code, invalidation and measurements. Run the same correctness corpus at each milestone; do not trade away coverage for incremental speed.

An implementation is ready for integration when the compiler can explain *why* an opportunity was accepted, *what* was changed, *which* observations remain equivalent, *how* it backs out safely, and *whether* the measured result justifies the cost.

## 7. Experimental evaluation

**Proposed experiment.** Solve instruction selection, scheduling and register allocation jointly on straight-line DSP kernels. Compare against separated greedy passes for code quality, solve time and timeout fallback rate.

Report three categories separately: **semantic validity** (differential mismatches, failed guards or validator verdicts), **compiler overhead** (wall time, allocated bytes, queue delay and metadata size), and **program outcome** (end-to-end latency/throughput, code size, energy or memory traffic as relevant). Include the reference baseline and at least one deliberately unfavorable workload. Use repeatable seeds and hold the target, runtime flags and environment constant when comparing variants.

Performance should be reported with a distribution or confidence interval rather than a single best run. If the compiler is adaptive, measure the whole lifetime including profiling, compilation, migration and fallback—not just warm steady state. If the system is multi-target, distinguish results caused by hardware capabilities from those caused by the compiler algorithm.

## 8. Design exercises and open questions

1. **Specify a contract.** Rewrite the core invariant above as a precondition, an observable-state relation and a postcondition. Identify one language feature (exceptions, floats, concurrency, reflection or FFI) that would invalidate an over-simple formulation.
2. **Build a minimal counterexample.** Choose the first engineering risk and construct a test that triggers it. Explain how the system will detect it and which fallback will execute.
3. **Define a budget.** Decide how much compiler CPU, memory, code-cache space and validation time this technique may consume before declining to optimize.
4. **Explore the frontier.** Could proof-carrying constraints make solver-driven optimization auditable and composable across heterogeneous devices? Chapters 25, 29 and 45.

**Connections.** [Chapter 25 — Heterogeneous IR](25-heterogeneous-ir.md); [Chapter 29 — Proof-Carrying IR and Certified Rewrite Contracts](29-proof-carrying-ir-and-certified-rewrite-contracts.md); [Chapter 45 — Digital-Twin Compiler for Hardware Decisions](45-digital-twin-compiler-for-hardware-decisions.md).

**Takeaway.** Proposed extension: expose global compiler design choices as a constraint problem instead of a sequence of independent greedy decisions. The next step is not to assume it wins, but to define the observable semantics, construct a small falsifiable implementation and measure its full lifecycle.

---

**Origin note:** This is a **proposed design developed for this dossier**, not a claim of global research priority or that no related technique has appeared in the literature. Terminology and implementation sketches here are conceptual until validated.
