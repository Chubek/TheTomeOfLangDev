# Chapter 33 — Budget-Aware Optimization Market

**Part of:** *The Modern Compiler Dossier* · **Concept origin:** New proposal developed for this dossier · **Primary area:** Adaptive execution and runtime

> **Central proposition.** Proposed extension: compiler time and runtime code-cache capacity are scarce resources. Instead of using one global hotness threshold, let optimization opportunities bid for resources according to expected total benefit, confidence and compilation cost. A scheduler allocates attention where marginal return is highest.

## 1. Why this idea changes compiler design

Define opportunities as `job` records with estimated compile CPU, memory, code bytes, speedup distribution, expiry and dependencies. A centralized allocator solves a small knapsack or online index policy each scheduling epoch. Observed gain updates estimates, while fairness constraints guarantee minimum service for interactive or correctness-critical jobs.

A useful way to approach the design is to separate a **reference meaning**, a **candidate implementation**, a **validator or legality boundary**, and a **measurement loop**. This distinction prevents performance statistics from being confused with proof of correctness. It also makes the idea compatible with languages that have different overflow, exception, concurrency and foreign-function semantics.

## 2. Internal representation and interfaces

The following sketch is a proposed notation, not the syntax of an existing compiler framework. It is intentionally compact enough to serve as the start of a DSL or IR schema.

```text
job J1 = {fn:render, compile_ms:40, bytes:6000, gain_ms_per_s:9}
job J2 = {fn:parse,  compile_ms:10, bytes:1200, gain_ms_per_s:4}
budget = {compile_ms:45, new_code_bytes:7000}
select subset maximizing expected_net_gain subject_to budget
```

This representation needs a stable identity scheme for values, functions, versions or resources mentioned in the sketch. An implementation should state which fields are **static semantics**, which are **runtime observations**, which are **guarded assumptions**, and which are **derived caches**. Blurring those categories is a common cause of invalidation bugs. Where the notation uses estimates or profiler data, it should record the collection epoch and target as part of the record.

## 3. Mechanism: from idea to executable system

A concrete execution sequence for the proposed design is:

1. **Collect candidate transformations without immediately committing compiler work.**
2. **Estimate benefit across the expected remaining execution horizon.**
3. **Enforce compile-time, memory, code-size and latency budgets.**
4. **Schedule the selected jobs and cancel obsolete ones when profiles change.**
5. **Update estimates with measured realized benefit and penalize failed predictions.**

For a small compiler, make each step inspectable through a textual dump. The dump should include the source/IR revision, the selected candidate, the reason for selection, and any required assumptions. For a concurrent compiler, attach revision numbers to requests and results so that work produced for an obsolete program cannot be published accidentally.

## 4. Correctness contract and proof obligations

A job may consume resources only within its allocated budget. Estimated profitability cannot override hard runtime correctness, safety or responsiveness requirements.

A reviewer should be able to answer four questions for every transformation: **(1)** Which source-level observations must remain identical? **(2)** Which assumptions are proved statically, and which are checked dynamically? **(3)** Where does execution go if a guard, resource request or validation fails? **(4)** What previously calculated facts and artifacts must be invalidated? A design that answers only the performance question is incomplete.

The practical verification ladder is: structural IR verification; type/effect/dominance checks where applicable; differential execution against a reference; randomized or metamorphic tests over adversarial inputs; and bounded symbolic or translation validation for a tractable subset. These methods have different guarantees. Tests can find counterexamples, not prove universal equivalence. SMT-based bounded validation is only as strong as its encoding and bounds. The artifact should describe which rung was achieved rather than presenting a Boolean `verified` flag with no scope.

## 5. Engineering costs and negative cases

- **Risk 1:** Short-term return can starve long-term optimizations.
- **Risk 2:** Bad cost estimates make the market choose the wrong jobs.
- **Risk 3:** Dependencies between optimizations violate simple additive-knapsack assumptions.

Compatibility costs also matter. Debuggers, profilers, coverage tools, sanitizers, binary interfaces, exception unwinders and reproducible builds consume compiler metadata. If an optimization changes control locations, representation versions or calling conventions, downstream tooling needs enough provenance to stay correct.

## 6. Implementation roadmap

**Milestone A — semantic reference.** Build a deliberately slow baseline that implements the relevant behavior exactly. Derive executable test cases from the example and document its unsupported features. Begin with **Collect candidate transformations without immediately committing compiler work**. Make the baseline capable of dumping both input state and output observations.

**Milestone B — smallest useful optimization.** Implement one well-scoped transformation that exercises **Estimate benefit across the expected remaining execution horizon**. Prefer a single function or basic block, a single target and stable data structures. Add a verifier that runs before code is exposed to users.

**Milestone C — adaptive or incremental operation.** Introduce **Enforce compile-time, memory, code-size and latency budgets**. Track which facts the optimization consumes. Add rollback, fallback or invalidation behavior as dictated by the correctness contract and test it with deliberately stale inputs.

**Milestone D — integration and observability.** Complete **Update estimates with measured realized benefit and penalize failed predictions**. Provide an inspector for alternative decisions and an event log that connects the optimization request to generated code, invalidation and measurements. Run the same correctness corpus at each milestone; do not trade away coverage for incremental speed.

An implementation is ready for integration when the compiler can explain *why* an opportunity was accepted, *what* was changed, *which* observations remain equivalent, *how* it backs out safely, and *whether* the measured result justifies the cost.

## 7. Experimental evaluation

**Proposed experiment.** Simulate a JIT under a fixed compilation CPU budget and real invocation traces. Compare FIFO, hotness-based and bid-based scheduling on cumulative completed work, energy and code-cache churn.

Report three categories separately: **semantic validity** (differential mismatches, failed guards or validator verdicts), **compiler overhead** (wall time, allocated bytes, queue delay and metadata size), and **program outcome** (end-to-end latency/throughput, code size, energy or memory traffic as relevant). Include the reference baseline and at least one deliberately unfavorable workload. Use repeatable seeds and hold the target, runtime flags and environment constant when comparing variants.

Performance should be reported with a distribution or confidence interval rather than a single best run. If the compiler is adaptive, measure the whole lifetime including profiling, compilation, migration and fallback—not just warm steady state. If the system is multi-target, distinguish results caused by hardware capabilities from those caused by the compiler algorithm.

## 8. Design exercises and open questions

1. **Specify a contract.** Rewrite the core invariant above as a precondition, an observable-state relation and a postcondition. Identify one language feature (exceptions, floats, concurrency, reflection or FFI) that would invalidate an over-simple formulation.
2. **Build a minimal counterexample.** Choose the first engineering risk and construct a test that triggers it. Explain how the system will detect it and which fallback will execute.
3. **Define a budget.** Decide how much compiler CPU, memory, code-cache space and validation time this technique may consume before declining to optimize.
4. **Explore the frontier.** Can auctions coordinate many optimizing agents while preserving fairness and predictable service latencies? Chapters 23, 27 and 28.

**Connections.** [Chapter 23 — Compiler as an Actor System](23-compiler-as-an-actor-system.md); [Chapter 27 — Compiler with Explicit Uncertainty](27-compiler-with-explicit-uncertainty.md); [Chapter 28 — Runtime as the Optimizer](28-runtime-as-the-optimizer.md).

**Takeaway.** Proposed extension: compiler time and runtime code-cache capacity are scarce resources. The next step is not to assume it wins, but to define the observable semantics, construct a small falsifiable implementation and measure its full lifecycle.

---

**Origin note:** This is a **proposed design developed for this dossier**, not a claim of global research priority or that no related technique has appeared in the literature. Terminology and implementation sketches here are conceptual until validated.
