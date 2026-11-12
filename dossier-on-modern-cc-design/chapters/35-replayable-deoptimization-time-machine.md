# Chapter 35 — Replayable Deoptimization Time Machine

**Part of:** *The Modern Compiler Dossier* · **Concept origin:** New proposal developed for this dossier · **Primary area:** Adaptive execution and runtime

> **Central proposition.** Proposed extension: combine deoptimization metadata with deterministic replay to step backwards across optimized execution. Ordinary debug info maps native locations to source. A replayable deoptimization system preserves enough nondeterministic inputs and reconstruction points to replay an optimized interval inside a reference interpreter.

## 1. Why this idea changes compiler design

Create checkpoint records containing input events, thread schedule decisions at controlled boundaries, heap roots and code-version IDs. A replay controller restores a checkpoint, replays recorded external effects through stubs and reconstructs optimized frames when crossing a guard or call boundary. Do not pretend arbitrary data races replay deterministically without capturing their ordering.

A useful way to approach the design is to separate a **reference meaning**, a **candidate implementation**, a **validator or legality boundary**, and a **measurement loop**. This distinction prevents performance statistics from being confused with proof of correctness. It also makes the idea compatible with languages that have different overflow, exception, concurrency and foreign-function semantics.

## 2. Internal representation and interfaces

The following sketch is a proposed notation, not the syntax of an existing compiler framework. It is intentionally compact enough to serve as the start of a DSL or IR schema.

```text
checkpoint C17 {version:f@i32, heap_epoch:52, frame_map:@S18}
record {io_read:bytes#3, clock:274, thread_order:[T1,T2]}
rewind(to=C17)
replay(mode=reference_interpreter, until=source_line_88)
```

This representation needs a stable identity scheme for values, functions, versions or resources mentioned in the sketch. An implementation should state which fields are **static semantics**, which are **runtime observations**, which are **guarded assumptions**, and which are **derived caches**. Blurring those categories is a common cause of invalidation bugs. Where the notation uses estimates or profiler data, it should record the collection epoch and target as part of the record.

## 3. Mechanism: from idea to executable system

A concrete execution sequence for the proposed design is:

1. **Choose replay boundaries and a precise set of nondeterministic inputs.**
2. **Record compact checkpoints and external event logs with bounded retention.**
3. **Reuse stack maps and virtual-object recipes to map optimized frames into interpreter state.**
4. **Replay code-version selection and effects without duplicating real I/O.**
5. **Expose backward stepping only within intervals with sufficient evidence.**

For a small compiler, make each step inspectable through a textual dump. The dump should include the source/IR revision, the selected candidate, the reason for selection, and any required assumptions. For a concurrent compiler, attach revision numbers to requests and results so that work produced for an obsolete program cannot be published accidentally.

## 4. Correctness contract and proof obligations

Replay must never repeat real-world side effects; it uses recorded results instead. Deterministic replay guarantees are scoped to the logged scheduling and external-input model.

A reviewer should be able to answer four questions for every transformation: **(1)** Which source-level observations must remain identical? **(2)** Which assumptions are proved statically, and which are checked dynamically? **(3)** Where does execution go if a guard, resource request or validation fails? **(4)** What previously calculated facts and artifacts must be invalidated? A design that answers only the performance question is incomplete.

The practical verification ladder is: structural IR verification; type/effect/dominance checks where applicable; differential execution against a reference; randomized or metamorphic tests over adversarial inputs; and bounded symbolic or translation validation for a tractable subset. These methods have different guarantees. Tests can find counterexamples, not prove universal equivalence. SMT-based bounded validation is only as strong as its encoding and bounds. The artifact should describe which rung was achieved rather than presenting a Boolean `verified` flag with no scope.

## 5. Engineering costs and negative cases

- **Risk 1:** Capturing concurrent interleavings can be prohibitively expensive.
- **Risk 2:** Unlogged native calls and devices break determinism.
- **Risk 3:** Keeping historical code versions conflicts with compiler garbage collection.

Compatibility costs also matter. Debuggers, profilers, coverage tools, sanitizers, binary interfaces, exception unwinders and reproducible builds consume compiler metadata. If an optimization changes control locations, representation versions or calling conventions, downstream tooling needs enough provenance to stay correct.

## 6. Implementation roadmap

**Milestone A — semantic reference.** Build a deliberately slow baseline that implements the relevant behavior exactly. Derive executable test cases from the example and document its unsupported features. Begin with **Choose replay boundaries and a precise set of nondeterministic inputs**. Make the baseline capable of dumping both input state and output observations.

**Milestone B — smallest useful optimization.** Implement one well-scoped transformation that exercises **Record compact checkpoints and external event logs with bounded retention**. Prefer a single function or basic block, a single target and stable data structures. Add a verifier that runs before code is exposed to users.

**Milestone C — adaptive or incremental operation.** Introduce **Reuse stack maps and virtual-object recipes to map optimized frames into interpreter state**. Track which facts the optimization consumes. Add rollback, fallback or invalidation behavior as dictated by the correctness contract and test it with deliberately stale inputs.

**Milestone D — integration and observability.** Complete **Expose backward stepping only within intervals with sufficient evidence**. Provide an inspector for alternative decisions and an event log that connects the optimization request to generated code, invalidation and measurements. Run the same correctness corpus at each milestone; do not trade away coverage for incremental speed.

An implementation is ready for integration when the compiler can explain *why* an opportunity was accepted, *what* was changed, *which* observations remain equivalent, *how* it backs out safely, and *whether* the measured result justifies the cost.

## 7. Experimental evaluation

**Proposed experiment.** Replay exceptions, inlined frames and mid-loop deopt in a small VM. Measure checkpoint overhead, replay fidelity, maximum backward-step distance and failure diagnostics when events are missing.

Report three categories separately: **semantic validity** (differential mismatches, failed guards or validator verdicts), **compiler overhead** (wall time, allocated bytes, queue delay and metadata size), and **program outcome** (end-to-end latency/throughput, code size, energy or memory traffic as relevant). Include the reference baseline and at least one deliberately unfavorable workload. Use repeatable seeds and hold the target, runtime flags and environment constant when comparing variants.

Performance should be reported with a distribution or confidence interval rather than a single best run. If the compiler is adaptive, measure the whole lifetime including profiling, compilation, migration and fallback—not just warm steady state. If the system is multi-target, distinguish results caused by hardware capabilities from those caused by the compiler algorithm.

## 8. Design exercises and open questions

1. **Specify a contract.** Rewrite the core invariant above as a precondition, an observable-state relation and a postcondition. Identify one language feature (exceptions, floats, concurrency, reflection or FFI) that would invalidate an over-simple formulation.
2. **Build a minimal counterexample.** Choose the first engineering risk and construct a test that triggers it. Explain how the system will detect it and which fallback will execute.
3. **Define a budget.** Decide how much compiler CPU, memory, code-cache space and validation time this technique may consume before declining to optimize.
4. **Explore the frontier.** Can replay logs themselves drive compiler optimization, letting users pinpoint causally responsible speculation failures? Chapters 4, 20 and 31.

**Connections.** [Chapter 4 — Deoptimization as an IR Operation](04-deoptimization-as-an-ir-operation.md); [Chapter 20 — Versioned IR](20-versioned-ir.md); [Chapter 31 — Causal Profiling IR](31-causal-profiling-ir.md).

**Takeaway.** Proposed extension: combine deoptimization metadata with deterministic replay to step backwards across optimized execution. The next step is not to assume it wins, but to define the observable semantics, construct a small falsifiable implementation and measure its full lifecycle.

---

**Origin note:** This is a **proposed design developed for this dossier**, not a claim of global research priority or that no related technique has appeared in the literature. Terminology and implementation sketches here are conceptual until validated.
