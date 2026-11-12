# Chapter 36 — Energy- and Thermal-Aware Compilation

**Part of:** *The Modern Compiler Dossier* · **Concept origin:** New proposal developed for this dossier · **Primary area:** Cost, resources and architecture

> **Central proposition.** Proposed extension: optimize for joules, heat and thermal throttling as first-class objectives rather than assuming fastest code is always best. A strategy that wins on a cold CPU may lose when a fanless device throttles; a vectorized loop may save energy or increase peak power depending on the platform.

## 1. Why this idea changes compiler design

A target descriptor includes frequency states, thermal response, power estimates and accelerator activation costs. The compiler builds a Pareto frontier among time, joules, peak power and code size. A runtime controller chooses variants based on a declared operating policy while retaining a safe generic fallback.

A useful way to approach the design is to separate a **reference meaning**, a **candidate implementation**, a **validator or legality boundary**, and a **measurement loop**. This distinction prevents performance statistics from being confused with proof of correctness. It also makes the idea compatible with languages that have different overflow, exception, concurrency and foreign-function semantics.

## 2. Internal representation and interfaces

The following sketch is a proposed notation, not the syntax of an existing compiler framework. It is intentionally compact enough to serve as the start of a DSL or IR schema.

```text
policy @mobile {latency_p95 <= 16ms; minimize:joules}
variant @scalar {time:10ms, energy:4mJ}
variant @wideSIMD {time:7ms, energy:5mJ}
variant @balanced {time:9ms, energy:3mJ}
select @balanced if constraints_hold
```

This representation needs a stable identity scheme for values, functions, versions or resources mentioned in the sketch. An implementation should state which fields are **static semantics**, which are **runtime observations**, which are **guarded assumptions**, and which are **derived caches**. Blurring those categories is a common cause of invalidation bugs. Where the notation uses estimates or profiler data, it should record the collection epoch and target as part of the record.

## 3. Mechanism: from idea to executable system

A concrete execution sequence for the proposed design is:

1. **Specify energy metrics and permitted hardware measurements per target.**
2. **Measure candidates in controlled thermal and frequency conditions.**
3. **Build multi-objective models with uncertainty and code-install costs.**
4. **Emit several legal variants if runtime operating modes change.**
5. **Avoid oscillation with dwell times and enforce latency constraints.**

For a small compiler, make each step inspectable through a textual dump. The dump should include the source/IR revision, the selected candidate, the reason for selection, and any required assumptions. For a concurrent compiler, attach revision numbers to requests and results so that work produced for an obsolete program cannot be published accidentally.

## 4. Correctness contract and proof obligations

Energy measurements cannot justify breaking real-time guarantees or semantic rules. Thermal and power sensors are noisy and platform-dependent; the model must expose its calibration limits.

A reviewer should be able to answer four questions for every transformation: **(1)** Which source-level observations must remain identical? **(2)** Which assumptions are proved statically, and which are checked dynamically? **(3)** Where does execution go if a guard, resource request or validation fails? **(4)** What previously calculated facts and artifacts must be invalidated? A design that answers only the performance question is incomplete.

The practical verification ladder is: structural IR verification; type/effect/dominance checks where applicable; differential execution against a reference; randomized or metamorphic tests over adversarial inputs; and bounded symbolic or translation validation for a tractable subset. These methods have different guarantees. Tests can find counterexamples, not prove universal equivalence. SMT-based bounded validation is only as strong as its encoding and bounds. The artifact should describe which rung was achieved rather than presenting a Boolean `verified` flag with no scope.

## 5. Engineering costs and negative cases

- **Risk 1:** Power measurement resolution may be too coarse for short functions.
- **Risk 2:** Frequency transitions introduce path dependence and noisy comparisons.
- **Risk 3:** Optimizing a local routine can shift energy costs to another device.

Compatibility costs also matter. Debuggers, profilers, coverage tools, sanitizers, binary interfaces, exception unwinders and reproducible builds consume compiler metadata. If an optimization changes control locations, representation versions or calling conventions, downstream tooling needs enough provenance to stay correct.

## 6. Implementation roadmap

**Milestone A — semantic reference.** Build a deliberately slow baseline that implements the relevant behavior exactly. Derive executable test cases from the example and document its unsupported features. Begin with **Specify energy metrics and permitted hardware measurements per target**. Make the baseline capable of dumping both input state and output observations.

**Milestone B — smallest useful optimization.** Implement one well-scoped transformation that exercises **Measure candidates in controlled thermal and frequency conditions**. Prefer a single function or basic block, a single target and stable data structures. Add a verifier that runs before code is exposed to users.

**Milestone C — adaptive or incremental operation.** Introduce **Build multi-objective models with uncertainty and code-install costs**. Track which facts the optimization consumes. Add rollback, fallback or invalidation behavior as dictated by the correctness contract and test it with deliberately stale inputs.

**Milestone D — integration and observability.** Complete **Avoid oscillation with dwell times and enforce latency constraints**. Provide an inspector for alternative decisions and an event log that connects the optimization request to generated code, invalidation and measurements. Run the same correctness corpus at each milestone; do not trade away coverage for incremental speed.

An implementation is ready for integration when the compiler can explain *why* an opportunity was accepted, *what* was changed, *which* observations remain equivalent, *how* it backs out safely, and *whether* the measured result justifies the cost.

## 7. Experimental evaluation

**Proposed experiment.** Compare scalar, SIMD and device-offload variants on thermally constrained hardware over 30-minute runs. Record joules per request, latency, throttling incidence and compilation energy.

Report three categories separately: **semantic validity** (differential mismatches, failed guards or validator verdicts), **compiler overhead** (wall time, allocated bytes, queue delay and metadata size), and **program outcome** (end-to-end latency/throughput, code size, energy or memory traffic as relevant). Include the reference baseline and at least one deliberately unfavorable workload. Use repeatable seeds and hold the target, runtime flags and environment constant when comparing variants.

Performance should be reported with a distribution or confidence interval rather than a single best run. If the compiler is adaptive, measure the whole lifetime including profiling, compilation, migration and fallback—not just warm steady state. If the system is multi-target, distinguish results caused by hardware capabilities from those caused by the compiler algorithm.

## 8. Design exercises and open questions

1. **Specify a contract.** Rewrite the core invariant above as a precondition, an observable-state relation and a postcondition. Identify one language feature (exceptions, floats, concurrency, reflection or FFI) that would invalidate an over-simple formulation.
2. **Build a minimal counterexample.** Choose the first engineering risk and construct a test that triggers it. Explain how the system will detect it and which fallback will execute.
3. **Define a budget.** Decide how much compiler CPU, memory, code-cache space and validation time this technique may consume before declining to optimize.
4. **Explore the frontier.** Can energy modeling include the cost of the compiler itself and make short-lived programs choose intentionally inferior steady-state code? Chapters 11, 25 and 33.

**Connections.** [Chapter 11 — Compiler with a Learned Cost Model](11-compiler-with-a-learned-cost-model.md); [Chapter 25 — Heterogeneous IR](25-heterogeneous-ir.md); [Chapter 33 — Budget-Aware Optimization Market](33-budget-aware-optimization-market.md).

**Takeaway.** Proposed extension: optimize for joules, heat and thermal throttling as first-class objectives rather than assuming fastest code is always best. The next step is not to assume it wins, but to define the observable semantics, construct a small falsifiable implementation and measure its full lifecycle.

---

**Origin note:** This is a **proposed design developed for this dossier**, not a claim of global research priority or that no related technique has appeared in the literature. Terminology and implementation sketches here are conceptual until validated.
