# Chapter 31 — Causal Profiling IR

**Part of:** *The Modern Compiler Dossier* · **Concept origin:** New proposal developed for this dossier · **Primary area:** IR knowledge and verification

> **Central proposition.** Proposed extension: replace purely observational profiling with controlled causal experiments. A runtime knows that region A is hot, but does not know whether making A faster will improve end-to-end latency; A may be off the critical path. Causal profiling IR records interventions, their scope and resulting outcomes to guide optimization toward genuinely limiting work.

## 1. Why this idea changes compiler design

Introduce experiment nodes keyed by function, input cohort, intervention and observation. Prefer safe interventions such as artificial delay or schedule changes before generating speculative replacement code. Randomly assign comparable requests to control and treatment cohorts and keep external effects identical; treat measurements as evidence, not proof of semantics.

A useful way to approach the design is to separate a **reference meaning**, a **candidate implementation**, a **validator or legality boundary**, and a **measurement loop**. This distinction prevents performance statistics from being confused with proof of correctness. It also makes the idea compatible with languages that have different overflow, exception, concurrency and foreign-function semantics.

## 2. Internal representation and interfaces

The following sketch is a proposed notation, not the syntax of an existing compiler framework. It is intentionally compact enough to serve as the start of a DSL or IR schema.

```text
experiment E12 {
  target: region @parse#91
  intervention: delay(control_only, 200us)
  outcome: request_latency_p95
  cohorts: {control:10000,treatment:10000}
}
result E12: estimated_criticality=0.72, ci=[0.65,0.79]
```

This representation needs a stable identity scheme for values, functions, versions or resources mentioned in the sketch. An implementation should state which fields are **static semantics**, which are **runtime observations**, which are **guarded assumptions**, and which are **derived caches**. Blurring those categories is a common cause of invalidation bugs. Where the notation uses estimates or profiler data, it should record the collection epoch and target as part of the record.

## 3. Mechanism: from idea to executable system

A concrete execution sequence for the proposed design is:

1. **Identify an end-to-end objective and a candidate execution region.**
2. **Apply controlled perturbations under safety limits, using randomly assigned comparable observations.**
3. **Estimate whether changing the region influences the objective rather than merely its own duration.**
4. **Store experiment conditions in the profile graph and reject stale measurements.**
5. **Prioritize compilation of regions with measured causal leverage.**

For a small compiler, make each step inspectable through a textual dump. The dump should include the source/IR revision, the selected candidate, the reason for selection, and any required assumptions. For a concurrent compiler, attach revision numbers to requests and results so that work produced for an obsolete program cannot be published accidentally.

## 4. Correctness contract and proof obligations

A causal estimate is valid only under the experiment’s sampling and confounding assumptions. Delaying work must not change program meaning or break externally visible service-level constraints; unsafe production interventions belong in a test harness.

A reviewer should be able to answer four questions for every transformation: **(1)** Which source-level observations must remain identical? **(2)** Which assumptions are proved statically, and which are checked dynamically? **(3)** Where does execution go if a guard, resource request or validation fails? **(4)** What previously calculated facts and artifacts must be invalidated? A design that answers only the performance question is incomplete.

The practical verification ladder is: structural IR verification; type/effect/dominance checks where applicable; differential execution against a reference; randomized or metamorphic tests over adversarial inputs; and bounded symbolic or translation validation for a tractable subset. These methods have different guarantees. Tests can find counterexamples, not prove universal equivalence. SMT-based bounded validation is only as strong as its encoding and bounds. The artifact should describe which rung was achieved rather than presenting a Boolean `verified` flag with no scope.

## 5. Engineering costs and negative cases

- **Risk 1:** Perturbations can change scheduling and memory contention, confounding results.
- **Risk 2:** Experiments consume performance budget and may affect real users.
- **Risk 3:** Results for one workload cohort may not transfer to another.

Compatibility costs also matter. Debuggers, profilers, coverage tools, sanitizers, binary interfaces, exception unwinders and reproducible builds consume compiler metadata. If an optimization changes control locations, representation versions or calling conventions, downstream tooling needs enough provenance to stay correct.

## 6. Implementation roadmap

**Milestone A — semantic reference.** Build a deliberately slow baseline that implements the relevant behavior exactly. Derive executable test cases from the example and document its unsupported features. Begin with **Identify an end-to-end objective and a candidate execution region**. Make the baseline capable of dumping both input state and output observations.

**Milestone B — smallest useful optimization.** Implement one well-scoped transformation that exercises **Apply controlled perturbations under safety limits, using randomly assigned comparable observations**. Prefer a single function or basic block, a single target and stable data structures. Add a verifier that runs before code is exposed to users.

**Milestone C — adaptive or incremental operation.** Introduce **Estimate whether changing the region influences the objective rather than merely its own duration**. Track which facts the optimization consumes. Add rollback, fallback or invalidation behavior as dictated by the correctness contract and test it with deliberately stale inputs.

**Milestone D — integration and observability.** Complete **Prioritize compilation of regions with measured causal leverage**. Provide an inspector for alternative decisions and an event log that connects the optimization request to generated code, invalidation and measurements. Run the same correctness corpus at each milestone; do not trade away coverage for incremental speed.

An implementation is ready for integration when the compiler can explain *why* an opportunity was accepted, *what* was changed, *which* observations remain equivalent, *how* it backs out safely, and *whether* the measured result justifies the cost.

## 7. Experimental evaluation

**Proposed experiment.** Compare time-based hotspot ranking and causally ranked optimization on a concurrent request pipeline. Optimize the top three regions under each policy and measure realized end-to-end gain per compiler minute.

Report three categories separately: **semantic validity** (differential mismatches, failed guards or validator verdicts), **compiler overhead** (wall time, allocated bytes, queue delay and metadata size), and **program outcome** (end-to-end latency/throughput, code size, energy or memory traffic as relevant). Include the reference baseline and at least one deliberately unfavorable workload. Use repeatable seeds and hold the target, runtime flags and environment constant when comparing variants.

Performance should be reported with a distribution or confidence interval rather than a single best run. If the compiler is adaptive, measure the whole lifetime including profiling, compilation, migration and fallback—not just warm steady state. If the system is multi-target, distinguish results caused by hardware capabilities from those caused by the compiler algorithm.

## 8. Design exercises and open questions

1. **Specify a contract.** Rewrite the core invariant above as a precondition, an observable-state relation and a postcondition. Identify one language feature (exceptions, floats, concurrency, reflection or FFI) that would invalidate an over-simple formulation.
2. **Build a minimal counterexample.** Choose the first engineering risk and construct a test that triggers it. Explain how the system will detect it and which fallback will execute.
3. **Define a budget.** Decide how much compiler CPU, memory, code-cache space and validation time this technique may consume before declining to optimize.
4. **Explore the frontier.** Could causal evidence update a cost model without confusing correlation from old code versions with the effect of a proposed change? Chapters 11, 18 and 27.

**Connections.** [Chapter 11 — Compiler with a Learned Cost Model](11-compiler-with-a-learned-cost-model.md); [Chapter 18 — Time-Aware IR](18-time-aware-ir.md); [Chapter 27 — Compiler with Explicit Uncertainty](27-compiler-with-explicit-uncertainty.md).

**Takeaway.** Proposed extension: replace purely observational profiling with controlled causal experiments. The next step is not to assume it wins, but to define the observable semantics, construct a small falsifiable implementation and measure its full lifecycle.

---

**Origin note:** This is a **proposed design developed for this dossier**, not a claim of global research priority or that no related technique has appeared in the literature. Terminology and implementation sketches here are conceptual until validated.
