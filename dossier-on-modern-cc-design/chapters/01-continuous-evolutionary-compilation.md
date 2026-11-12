# Chapter 01 — Continuous / Evolutionary Compilation

**Part of:** *The Modern Compiler Dossier* · **Concept origin:** Expanded from supplied `COMPILER_IDEAS.md`, item 1 · **Primary area:** Adaptive execution and runtime

> **Central proposition.** The compiler does not finish when a program starts. It remains a runtime service that observes shape distributions, allocation rates and hot paths, then creates better representations and safely installs them. The bold extension is representation evolution: changing an array from boxed to packed, or a map from hash-based to sorted, rather than merely regenerating instructions.

## 1. Why this idea changes compiler design

Keep a stable semantic identity for every function and heap object but allow a family of physical layouts. A profile collector publishes time-windowed histograms; a planner proposes a guarded transformation; a migration engine builds the new representation; a version manager switches readers at a safepoint or by epoch. Compilation must be budgeted so a hot application does not stall from excessive recompilation.

A useful way to approach the design is to separate a **reference meaning**, a **candidate implementation**, a **validator or legality boundary**, and a **measurement loop**. This distinction prevents performance statistics from being confused with proof of correctness. It also makes the idea compatible with languages that have different overflow, exception, concurrency and foreign-function semantics.

## 2. Internal representation and interfaces

The following sketch is a proposed notation, not the syntax of an existing compiler framework. It is intentionally compact enough to serve as the start of a DSL or IR schema.

```text
profile Array<Order> { dense=0.98; nulls=0.00 }
plan layout A0: boxed -> packed<struct Order>
requires all_live_elements_compatible(A0)
migrate_copy A0 -> A1
publish A1 at epoch 49; retire A0 after quiescence
```

This representation needs a stable identity scheme for values, functions, versions or resources mentioned in the sketch. An implementation should state which fields are **static semantics**, which are **runtime observations**, which are **guarded assumptions**, and which are **derived caches**. Blurring those categories is a common cause of invalidation bugs. Where the notation uses estimates or profiler data, it should record the collection epoch and target as part of the record.

## 3. Mechanism: from idea to executable system

A concrete execution sequence for the proposed design is:

1. **Measure behavior with bounded, privacy-aware sampling, not a permanent full trace.**
2. **Choose candidate layout and code versions from a calibrated cost model that includes conversion costs.**
3. **Prove or guard the assumptions behind the candidate and provide a generic fallback.**
4. **Construct replacement state without mutating a representation still visible to readers.**
5. **Publish atomically, collect post-installation measurements, and roll back when net benefit is negative.**

For a small compiler, make each step inspectable through a textual dump. The dump should include the source/IR revision, the selected candidate, the reason for selection, and any required assumptions. For a concurrent compiler, attach revision numbers to requests and results so that work produced for an obsolete program cannot be published accidentally.

## 4. Correctness contract and proof obligations

Every live semantic value must have a valid view during migration. Field order, object identity, exception behavior and memory visibility cannot change. A representation change may be invisible to source code while still requiring GC-barrier, FFI, reflection and debugger updates.

A reviewer should be able to answer four questions for every transformation: **(1)** Which source-level observations must remain identical? **(2)** Which assumptions are proved statically, and which are checked dynamically? **(3)** Where does execution go if a guard, resource request or validation fails? **(4)** What previously calculated facts and artifacts must be invalidated? A design that answers only the performance question is incomplete.

The practical verification ladder is: structural IR verification; type/effect/dominance checks where applicable; differential execution against a reference; randomized or metamorphic tests over adversarial inputs; and bounded symbolic or translation validation for a tractable subset. These methods have different guarantees. Tests can find counterexamples, not prove universal equivalence. SMT-based bounded validation is only as strong as its encoding and bounds. The artifact should describe which rung was achieved rather than presenting a Boolean `verified` flag with no scope.

## 5. Engineering costs and negative cases

- **Risk 1:** Thrashing between layouts when workloads alternate; use hysteresis and minimum dwell times.
- **Risk 2:** Migration latency and peak memory may dominate the projected speedup.
- **Risk 3:** Concurrent readers and foreign pointers can pin the old layout indefinitely.

Compatibility costs also matter. Debuggers, profilers, coverage tools, sanitizers, binary interfaces, exception unwinders and reproducible builds consume compiler metadata. If an optimization changes control locations, representation versions or calling conventions, downstream tooling needs enough provenance to stay correct.

## 6. Implementation roadmap

**Milestone A — semantic reference.** Build a deliberately slow baseline that implements the relevant behavior exactly. Derive executable test cases from the example and document its unsupported features. Begin with **Measure behavior with bounded, privacy-aware sampling, not a permanent full trace**. Make the baseline capable of dumping both input state and output observations.

**Milestone B — smallest useful optimization.** Implement one well-scoped transformation that exercises **Choose candidate layout and code versions from a calibrated cost model that includes conversion costs**. Prefer a single function or basic block, a single target and stable data structures. Add a verifier that runs before code is exposed to users.

**Milestone C — adaptive or incremental operation.** Introduce **Prove or guard the assumptions behind the candidate and provide a generic fallback**. Track which facts the optimization consumes. Add rollback, fallback or invalidation behavior as dictated by the correctness contract and test it with deliberately stale inputs.

**Milestone D — integration and observability.** Complete **Publish atomically, collect post-installation measurements, and roll back when net benefit is negative**. Provide an inspector for alternative decisions and an event log that connects the optimization request to generated code, invalidation and measurements. Run the same correctness corpus at each milestone; do not trade away coverage for incremental speed.

An implementation is ready for integration when the compiler can explain *why* an opportunity was accepted, *what* was changed, *which* observations remain equivalent, *how* it backs out safely, and *whether* the measured result justifies the cost.

## 7. Experimental evaluation

**Proposed experiment.** Compare a baseline tiered JIT against an evolutionary runtime on alternating dense/sparse collections. Record p50/p99 latency, compilation CPU, peak RSS, migration bytes, guard failures and time-to-break-even; include a workload where adaptation loses.

Report three categories separately: **semantic validity** (differential mismatches, failed guards or validator verdicts), **compiler overhead** (wall time, allocated bytes, queue delay and metadata size), and **program outcome** (end-to-end latency/throughput, code size, energy or memory traffic as relevant). Include the reference baseline and at least one deliberately unfavorable workload. Use repeatable seeds and hold the target, runtime flags and environment constant when comparing variants.

Performance should be reported with a distribution or confidence interval rather than a single best run. If the compiler is adaptive, measure the whole lifetime including profiling, compilation, migration and fallback—not just warm steady state. If the system is multi-target, distinguish results caused by hardware capabilities from those caused by the compiler algorithm.

## 8. Design exercises and open questions

1. **Specify a contract.** Rewrite the core invariant above as a precondition, an observable-state relation and a postcondition. Identify one language feature (exceptions, floats, concurrency, reflection or FFI) that would invalidate an over-simple formulation.
2. **Build a minimal counterexample.** Choose the first engineering risk and construct a test that triggers it. Explain how the system will detect it and which fallback will execute.
3. **Define a budget.** Decide how much compiler CPU, memory, code-cache space and validation time this technique may consume before declining to optimize.
4. **Explore the frontier.** Can a compiler learn a compact state machine of representation changes and still provide a deterministic replay of those changes? See Chapters 20, 26, 28 and 41.

**Connections.** [Chapter 20 — Versioned IR](20-versioned-ir.md); [Chapter 26 — Spatial Compiler](26-spatial-compiler.md); [Chapter 28 — Runtime as the Optimizer](28-runtime-as-the-optimizer.md); [Chapter 41 — Granularity-Adaptive Optimization](41-granularity-adaptive-optimization.md).

**Takeaway.** The compiler does not finish when a program starts. The next step is not to assume it wins, but to define the observable semantics, construct a small falsifiable implementation and measure its full lifecycle.

---

**Source provenance:** Expanded from item **1**, “Continuous / Evolutionary Compilation”, in [`COMPILER_IDEAS.md`](../sources/COMPILER_IDEAS.md). The source supplies the seed idea; architecture, pseudocode, contracts and experiments in this chapter are dossier elaborations. See [the source map](../appendices/SOURCE-MAP.md).
