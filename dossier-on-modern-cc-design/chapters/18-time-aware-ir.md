# Chapter 18 — Time-Aware IR

**Part of:** *The Modern Compiler Dossier* · **Concept origin:** Expanded from supplied `COMPILER_IDEAS.md`, item 18 · **Primary area:** IR knowledge and verification

> **Central proposition.** Ordinary IR records control and data dependence, but the runtime also produces temporal correlations: operations or objects repeatedly used close together. Time-aware IR can preserve these observations as weighted, decaying edges to guide prefetching, layout, batching and scheduling, without mistaking correlation for a proof of dependence.

## 1. Why this idea changes compiler design

Store temporal edges in a profile layer keyed by stable IR IDs. Each edge carries observation window, frequency, latency distribution, target and confidence. Keep the graph separate from legality edges: optimization may reorder code based on temporal information only when semantic dependencies still permit it.

A useful way to approach the design is to separate a **reference meaning**, a **candidate implementation**, a **validator or legality boundary**, and a **measurement loop**. This distinction prevents performance statistics from being confused with proof of correctness. It also makes the idea compatible with languages that have different overflow, exception, concurrency and foreign-function semantics.

## 2. Internal representation and interfaces

The following sketch is a proposed notation, not the syntax of an existing compiler framework. It is intentionally compact enough to serve as the start of a DSL or IR schema.

```text
temporal_edge A -> B {
  p_within_200_cycles: 0.84
  median_gap_cycles: 67
  samples: 32000
  profile_epoch: 11
}
layout_hint cluster(A,B) unless branch_target_constraints
```

This representation needs a stable identity scheme for values, functions, versions or resources mentioned in the sketch. An implementation should state which fields are **static semantics**, which are **runtime observations**, which are **guarded assumptions**, and which are **derived caches**. Blurring those categories is a common cause of invalidation bugs. Where the notation uses estimates or profiler data, it should record the collection epoch and target as part of the record.

## 3. Mechanism: from idea to executable system

A concrete execution sequence for the proposed design is:

1. **Sample execution windows with bounded overhead and retain context IDs.**
2. **Estimate co-occurrence and conditional temporal proximity, not only global frequency.**
3. **Aggregate edges into an affinity graph with age decay.**
4. **Use graph partitioning or layout optimization to propose code/data clusters.**
5. **Validate layout against branch reachability and rerun under changed workloads.**

For a small compiler, make each step inspectable through a textual dump. The dump should include the source/IR revision, the selected candidate, the reason for selection, and any required assumptions. For a concurrent compiler, attach revision numbers to requests and results so that work produced for an obsolete program cannot be published accidentally.

## 4. Correctness contract and proof obligations

Temporal affinity is a performance hint, not a semantic edge. A profile cannot justify deleting checks, assuming alias freedom or changing exception order.

A reviewer should be able to answer four questions for every transformation: **(1)** Which source-level observations must remain identical? **(2)** Which assumptions are proved statically, and which are checked dynamically? **(3)** Where does execution go if a guard, resource request or validation fails? **(4)** What previously calculated facts and artifacts must be invalidated? A design that answers only the performance question is incomplete.

The practical verification ladder is: structural IR verification; type/effect/dominance checks where applicable; differential execution against a reference; randomized or metamorphic tests over adversarial inputs; and bounded symbolic or translation validation for a tractable subset. These methods have different guarantees. Tests can find counterexamples, not prove universal equivalence. SMT-based bounded validation is only as strong as its encoding and bounds. The artifact should describe which rung was achieved rather than presenting a Boolean `verified` flag with no scope.

## 5. Engineering costs and negative cases

- **Risk 1:** Sampling bias can favor long-running traces over rare critical paths.
- **Risk 2:** Affinity can contradict cache capacity and NUMA placement.
- **Risk 3:** Temporal relationships shift under concurrency and input changes.

Compatibility costs also matter. Debuggers, profilers, coverage tools, sanitizers, binary interfaces, exception unwinders and reproducible builds consume compiler metadata. If an optimization changes control locations, representation versions or calling conventions, downstream tooling needs enough provenance to stay correct.

## 6. Implementation roadmap

**Milestone A — semantic reference.** Build a deliberately slow baseline that implements the relevant behavior exactly. Derive executable test cases from the example and document its unsupported features. Begin with **Sample execution windows with bounded overhead and retain context IDs**. Make the baseline capable of dumping both input state and output observations.

**Milestone B — smallest useful optimization.** Implement one well-scoped transformation that exercises **Estimate co-occurrence and conditional temporal proximity, not only global frequency**. Prefer a single function or basic block, a single target and stable data structures. Add a verifier that runs before code is exposed to users.

**Milestone C — adaptive or incremental operation.** Introduce **Aggregate edges into an affinity graph with age decay**. Track which facts the optimization consumes. Add rollback, fallback or invalidation behavior as dictated by the correctness contract and test it with deliberately stale inputs.

**Milestone D — integration and observability.** Complete **Validate layout against branch reachability and rerun under changed workloads**. Provide an inspector for alternative decisions and an event log that connects the optimization request to generated code, invalidation and measurements. Run the same correctness corpus at each milestone; do not trade away coverage for incremental speed.

An implementation is ready for integration when the compiler can explain *why* an opportunity was accepted, *what* was changed, *which* observations remain equivalent, *how* it backs out safely, and *whether* the measured result justifies the cost.

## 7. Experimental evaluation

**Proposed experiment.** Instrument a server with request classes and large instruction footprint. Compare basic-block ordering with/without temporal edges; report cache misses, branch misses, p99 latency and sensitivity to phase changes.

Report three categories separately: **semantic validity** (differential mismatches, failed guards or validator verdicts), **compiler overhead** (wall time, allocated bytes, queue delay and metadata size), and **program outcome** (end-to-end latency/throughput, code size, energy or memory traffic as relevant). Include the reference baseline and at least one deliberately unfavorable workload. Use repeatable seeds and hold the target, runtime flags and environment constant when comparing variants.

Performance should be reported with a distribution or confidence interval rather than a single best run. If the compiler is adaptive, measure the whole lifetime including profiling, compilation, migration and fallback—not just warm steady state. If the system is multi-target, distinguish results caused by hardware capabilities from those caused by the compiler algorithm.

## 8. Design exercises and open questions

1. **Specify a contract.** Rewrite the core invariant above as a precondition, an observable-state relation and a postcondition. Identify one language feature (exceptions, floats, concurrency, reflection or FFI) that would invalidate an over-simple formulation.
2. **Build a minimal counterexample.** Choose the first engineering risk and construct a test that triggers it. Explain how the system will detect it and which fallback will execute.
3. **Define a budget.** Decide how much compiler CPU, memory, code-cache space and validation time this technique may consume before declining to optimize.
4. **Explore the frontier.** Can a unified spatiotemporal model choose both code layout and heap object layout while accounting for contention? Chapters 26, 27 and 45.

**Connections.** [Chapter 26 — Spatial Compiler](26-spatial-compiler.md); [Chapter 27 — Compiler with Explicit Uncertainty](27-compiler-with-explicit-uncertainty.md); [Chapter 45 — Digital-Twin Compiler for Hardware Decisions](45-digital-twin-compiler-for-hardware-decisions.md).

**Takeaway.** Ordinary IR records control and data dependence, but the runtime also produces temporal correlations: operations or objects repeatedly used close together. The next step is not to assume it wins, but to define the observable semantics, construct a small falsifiable implementation and measure its full lifecycle.

---

**Source provenance:** Expanded from item **18**, “Time-Aware IR”, in [`COMPILER_IDEAS.md`](../sources/COMPILER_IDEAS.md). The source supplies the seed idea; architecture, pseudocode, contracts and experiments in this chapter are dossier elaborations. See [the source map](../appendices/SOURCE-MAP.md).
