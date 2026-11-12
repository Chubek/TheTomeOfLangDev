# Chapter 27 — Compiler with Explicit Uncertainty

**Part of:** *The Modern Compiler Dossier* · **Concept origin:** Expanded from supplied `COMPILER_IDEAS.md`, item 27 · **Primary area:** Adaptive execution and runtime

> **Central proposition.** Compilers already operate on uncertain evidence but often hide this behind arbitrary thresholds. Explicit uncertainty records confidence, evidence quality and downside risk so optimization decisions can be made with measurable caution. Correctness remains deterministic: probabilistic beliefs never replace required proofs.

## 1. Why this idea changes compiler design

Represent a hypothesis as an estimate plus provenance, sample size, confidence interval and expiry. A decision engine computes expected utility using potential speedup, compile cost, bailout cost and worst-case service objectives. When uncertainty is too high, gather more observations or choose a proven generic path.

A useful way to approach the design is to separate a **reference meaning**, a **candidate implementation**, a **validator or legality boundary**, and a **measurement loop**. This distinction prevents performance statistics from being confused with proof of correctness. It also makes the idea compatible with languages that have different overflow, exception, concurrency and foreign-function semantics.

## 2. Internal representation and interfaces

The following sketch is a proposed notation, not the syntax of an existing compiler framework. It is intentionally compact enough to serve as the start of a DSL or IR schema.

```text
hypothesis h = {kind: type_is, value:i32, p:0.94, n:80}
utility(speculate(h)) = p*gain - (1-p)*bailout_cost - compile_cost
if lower_bound(utility) > 0 and guardable(h): specialize()
else: collect_more_profile()
```

This representation needs a stable identity scheme for values, functions, versions or resources mentioned in the sketch. An implementation should state which fields are **static semantics**, which are **runtime observations**, which are **guarded assumptions**, and which are **derived caches**. Blurring those categories is a common cause of invalidation bugs. Where the notation uses estimates or profiler data, it should record the collection epoch and target as part of the record.

## 3. Mechanism: from idea to executable system

A concrete execution sequence for the proposed design is:

1. **Identify uncertain facts and attach evidence metadata at observation sites.**
2. **Quantify both expected gain and tail-risk rather than only mean throughput.**
3. **Require explicit guarding or conservative semantics for every risky decision.**
4. **Choose explore, exploit or defer under a compilation budget.**
5. **Recalibrate estimates after workload changes and version transitions.**

For a small compiler, make each step inspectable through a textual dump. The dump should include the source/IR revision, the selected candidate, the reason for selection, and any required assumptions. For a concurrent compiler, attach revision numbers to requests and results so that work produced for an obsolete program cannot be published accidentally.

## 4. Correctness contract and proof obligations

No level of probabilistic confidence licenses an unsound transformation. If a fact is needed for legality, it must be proven or checked dynamically, irrespective of its estimated probability.

A reviewer should be able to answer four questions for every transformation: **(1)** Which source-level observations must remain identical? **(2)** Which assumptions are proved statically, and which are checked dynamically? **(3)** Where does execution go if a guard, resource request or validation fails? **(4)** What previously calculated facts and artifacts must be invalidated? A design that answers only the performance question is incomplete.

The practical verification ladder is: structural IR verification; type/effect/dominance checks where applicable; differential execution against a reference; randomized or metamorphic tests over adversarial inputs; and bounded symbolic or translation validation for a tractable subset. These methods have different guarantees. Tests can find counterexamples, not prove universal equivalence. SMT-based bounded validation is only as strong as its encoding and bounds. The artifact should describe which rung was achieved rather than presenting a Boolean `verified` flag with no scope.

## 5. Engineering costs and negative cases

- **Risk 1:** Correlated observations can make confidence look stronger than it is.
- **Risk 2:** Rare failures can cause catastrophic latency not captured by mean cost.
- **Risk 3:** Overly cautious policies may never explore profitable alternatives.

Compatibility costs also matter. Debuggers, profilers, coverage tools, sanitizers, binary interfaces, exception unwinders and reproducible builds consume compiler metadata. If an optimization changes control locations, representation versions or calling conventions, downstream tooling needs enough provenance to stay correct.

## 6. Implementation roadmap

**Milestone A — semantic reference.** Build a deliberately slow baseline that implements the relevant behavior exactly. Derive executable test cases from the example and document its unsupported features. Begin with **Identify uncertain facts and attach evidence metadata at observation sites**. Make the baseline capable of dumping both input state and output observations.

**Milestone B — smallest useful optimization.** Implement one well-scoped transformation that exercises **Quantify both expected gain and tail-risk rather than only mean throughput**. Prefer a single function or basic block, a single target and stable data structures. Add a verifier that runs before code is exposed to users.

**Milestone C — adaptive or incremental operation.** Introduce **Require explicit guarding or conservative semantics for every risky decision**. Track which facts the optimization consumes. Add rollback, fallback or invalidation behavior as dictated by the correctness contract and test it with deliberately stale inputs.

**Milestone D — integration and observability.** Complete **Recalibrate estimates after workload changes and version transitions**. Provide an inspector for alternative decisions and an event log that connects the optimization request to generated code, invalidation and measurements. Run the same correctness corpus at each milestone; do not trade away coverage for incremental speed.

An implementation is ready for integration when the compiler can explain *why* an opportunity was accepted, *what* was changed, *which* observations remain equivalent, *how* it backs out safely, and *whether* the measured result justifies the cost.

## 7. Experimental evaluation

**Proposed experiment.** Construct workload phase shifts and rare guard failures. Compare fixed-threshold and uncertainty-aware policies on cumulative speedup, bailout frequency and p99 service time.

Report three categories separately: **semantic validity** (differential mismatches, failed guards or validator verdicts), **compiler overhead** (wall time, allocated bytes, queue delay and metadata size), and **program outcome** (end-to-end latency/throughput, code size, energy or memory traffic as relevant). Include the reference baseline and at least one deliberately unfavorable workload. Use repeatable seeds and hold the target, runtime flags and environment constant when comparing variants.

Performance should be reported with a distribution or confidence interval rather than a single best run. If the compiler is adaptive, measure the whole lifetime including profiling, compilation, migration and fallback—not just warm steady state. If the system is multi-target, distinguish results caused by hardware capabilities from those caused by the compiler algorithm.

## 8. Design exercises and open questions

1. **Specify a contract.** Rewrite the core invariant above as a precondition, an observable-state relation and a postcondition. Identify one language feature (exceptions, floats, concurrency, reflection or FFI) that would invalidate an over-simple formulation.
2. **Build a minimal counterexample.** Choose the first engineering risk and construct a test that triggers it. Explain how the system will detect it and which fallback will execute.
3. **Define a budget.** Decide how much compiler CPU, memory, code-cache space and validation time this technique may consume before declining to optimize.
4. **Explore the frontier.** Can decision-theoretic optimization formally bound the risk of compilation work on latency-critical systems? Chapters 11, 19 and 33.

**Connections.** [Chapter 11 — Compiler with a Learned Cost Model](11-compiler-with-a-learned-cost-model.md); [Chapter 19 — Probabilistic IR](19-probabilistic-ir.md); [Chapter 33 — Budget-Aware Optimization Market](33-budget-aware-optimization-market.md).

**Takeaway.** Compilers already operate on uncertain evidence but often hide this behind arbitrary thresholds. The next step is not to assume it wins, but to define the observable semantics, construct a small falsifiable implementation and measure its full lifecycle.

---

**Source provenance:** Expanded from item **27**, “Compiler with Explicit Uncertainty”, in [`COMPILER_IDEAS.md`](../sources/COMPILER_IDEAS.md). The source supplies the seed idea; architecture, pseudocode, contracts and experiments in this chapter are dossier elaborations. See [the source map](../appendices/SOURCE-MAP.md).
