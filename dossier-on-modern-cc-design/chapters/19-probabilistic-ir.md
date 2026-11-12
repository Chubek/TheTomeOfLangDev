# Chapter 19 — Probabilistic IR

**Part of:** *The Modern Compiler Dossier* · **Concept origin:** Expanded from supplied `COMPILER_IDEAS.md`, item 19 · **Primary area:** IR knowledge and verification

> **Central proposition.** Represent distributions, not only point facts, in the profiling layer of IR. Branch likelihood, dynamic type proportions, allocation sizes and loop trip counts can be first-class annotations, giving a common language to code layout, specialization and cost-model decisions.

## 1. Why this idea changes compiler design

Associate probability estimates with sample counts, time windows and uncertainty intervals. A branch annotation and its successors form a normalized distribution; type histograms include an unknown bucket so unobserved types are not silently ruled out. Static correctness is still provided by guards and conservative analyses.

A useful way to approach the design is to separate a **reference meaning**, a **candidate implementation**, a **validator or legality boundary**, and a **measurement loop**. This distinction prevents performance statistics from being confused with proof of correctness. It also makes the idea compatible with languages that have different overflow, exception, concurrency and foreign-function semantics.

## 2. Internal representation and interfaces

The following sketch is a proposed notation, not the syntax of an existing compiler framework. It is intentionally compact enough to serve as the start of a DSL or IR schema.

```text
branch %cond {
  true: @fast [p=0.97, n=50000]
  false: @slow [p=0.03, n=50000]
}
type_profile %obj = {Point:0.91, Vec:0.07, other:0.02}
```

This representation needs a stable identity scheme for values, functions, versions or resources mentioned in the sketch. An implementation should state which fields are **static semantics**, which are **runtime observations**, which are **guarded assumptions**, and which are **derived caches**. Blurring those categories is a common cause of invalidation bugs. Where the notation uses estimates or profiler data, it should record the collection epoch and target as part of the record.

## 3. Mechanism: from idea to executable system

A concrete execution sequence for the proposed design is:

1. **Define probability-bearing entities and normalized histogram schemas.**
2. **Gather low-overhead counts and retain uncertainty for small samples.**
3. **Translate profiles across inlining, cloning and CFG rewrites with provenance.**
4. **Use probabilities for layout, expected-cost extraction and guarded specialization.**
5. **Detect distribution drift and decay stale observations.**

For a small compiler, make each step inspectable through a textual dump. The dump should include the source/IR revision, the selected candidate, the reason for selection, and any required assumptions. For a concurrent compiler, attach revision numbers to requests and results so that work produced for an obsolete program cannot be published accidentally.

## 4. Correctness contract and proof obligations

Probability estimates describe past behavior; they never prove a condition always true. A type with a measured probability of zero remains semantically possible unless ruled out statically.

A reviewer should be able to answer four questions for every transformation: **(1)** Which source-level observations must remain identical? **(2)** Which assumptions are proved statically, and which are checked dynamically? **(3)** Where does execution go if a guard, resource request or validation fails? **(4)** What previously calculated facts and artifacts must be invalidated? A design that answers only the performance question is incomplete.

The practical verification ladder is: structural IR verification; type/effect/dominance checks where applicable; differential execution against a reference; randomized or metamorphic tests over adversarial inputs; and bounded symbolic or translation validation for a tractable subset. These methods have different guarantees. Tests can find counterexamples, not prove universal equivalence. SMT-based bounded validation is only as strong as its encoding and bounds. The artifact should describe which rung was achieved rather than presenting a Boolean `verified` flag with no scope.

## 5. Engineering costs and negative cases

- **Risk 1:** Naive transfer of branch counts after CFG rewrites creates inconsistent totals.
- **Risk 2:** Input-dependent workloads violate stationarity assumptions.
- **Risk 3:** Per-edge probabilities cannot express every correlated path behavior.

Compatibility costs also matter. Debuggers, profilers, coverage tools, sanitizers, binary interfaces, exception unwinders and reproducible builds consume compiler metadata. If an optimization changes control locations, representation versions or calling conventions, downstream tooling needs enough provenance to stay correct.

## 6. Implementation roadmap

**Milestone A — semantic reference.** Build a deliberately slow baseline that implements the relevant behavior exactly. Derive executable test cases from the example and document its unsupported features. Begin with **Define probability-bearing entities and normalized histogram schemas**. Make the baseline capable of dumping both input state and output observations.

**Milestone B — smallest useful optimization.** Implement one well-scoped transformation that exercises **Gather low-overhead counts and retain uncertainty for small samples**. Prefer a single function or basic block, a single target and stable data structures. Add a verifier that runs before code is exposed to users.

**Milestone C — adaptive or incremental operation.** Introduce **Translate profiles across inlining, cloning and CFG rewrites with provenance**. Track which facts the optimization consumes. Add rollback, fallback or invalidation behavior as dictated by the correctness contract and test it with deliberately stale inputs.

**Milestone D — integration and observability.** Complete **Detect distribution drift and decay stale observations**. Provide an inspector for alternative decisions and an event log that connects the optimization request to generated code, invalidation and measurements. Run the same correctness corpus at each milestone; do not trade away coverage for incremental speed.

An implementation is ready for integration when the compiler can explain *why* an opportunity was accepted, *what* was changed, *which* observations remain equivalent, *how* it backs out safely, and *whether* the measured result justifies the cost.

## 7. Experimental evaluation

**Proposed experiment.** Compare hot/cold code layout and inline caching decisions under synthetic branch distributions. Report actual versus predicted costs and recalibration after input distribution shifts.

Report three categories separately: **semantic validity** (differential mismatches, failed guards or validator verdicts), **compiler overhead** (wall time, allocated bytes, queue delay and metadata size), and **program outcome** (end-to-end latency/throughput, code size, energy or memory traffic as relevant). Include the reference baseline and at least one deliberately unfavorable workload. Use repeatable seeds and hold the target, runtime flags and environment constant when comparing variants.

Performance should be reported with a distribution or confidence interval rather than a single best run. If the compiler is adaptive, measure the whole lifetime including profiling, compilation, migration and fallback—not just warm steady state. If the system is multi-target, distinguish results caused by hardware capabilities from those caused by the compiler algorithm.

## 8. Design exercises and open questions

1. **Specify a contract.** Rewrite the core invariant above as a precondition, an observable-state relation and a postcondition. Identify one language feature (exceptions, floats, concurrency, reflection or FFI) that would invalidate an over-simple formulation.
2. **Build a minimal counterexample.** Choose the first engineering risk and construct a test that triggers it. Explain how the system will detect it and which fallback will execute.
3. **Define a budget.** Decide how much compiler CPU, memory, code-cache space and validation time this technique may consume before declining to optimize.
4. **Explore the frontier.** Could probability annotations be modeled as distributions over whole traces instead of independent local edges? Chapters 18, 27 and 31.

**Connections.** [Chapter 18 — Time-Aware IR](18-time-aware-ir.md); [Chapter 27 — Compiler with Explicit Uncertainty](27-compiler-with-explicit-uncertainty.md); [Chapter 31 — Causal Profiling IR](31-causal-profiling-ir.md).

**Takeaway.** Represent distributions, not only point facts, in the profiling layer of IR. The next step is not to assume it wins, but to define the observable semantics, construct a small falsifiable implementation and measure its full lifecycle.

---

**Source provenance:** Expanded from item **19**, “Probabilistic IR”, in [`COMPILER_IDEAS.md`](../sources/COMPILER_IDEAS.md). The source supplies the seed idea; architecture, pseudocode, contracts and experiments in this chapter are dossier elaborations. See [the source map](../appendices/SOURCE-MAP.md).
