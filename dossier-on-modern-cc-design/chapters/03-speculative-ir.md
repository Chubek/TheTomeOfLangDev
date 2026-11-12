# Chapter 03 — Speculative IR

**Part of:** *The Modern Compiler Dossier* · **Concept origin:** Expanded from supplied `COMPILER_IDEAS.md`, item 3 · **Primary area:** Adaptive execution and runtime

> **Central proposition.** A conventional optimizer treats facts as proved or unknown. A speculative IR makes a third kind of statement explicit: a fact is assumed and validated at runtime. Guards make a fast path legal without pretending the assumption is universally true; deoptimization or another version preserves correctness when the hypothesis fails.

## 1. Why this idea changes compiler design

Give `assume`, `guard`, `snapshot` and `invalidate` first-class semantics. A guard dominates every use relying on it, has an environment snapshot, and records an assumption ID whose lifetime is tracked by the runtime. The optimizer may hoist guards only when exceptions and memory effects remain ordered correctly.

A useful way to approach the design is to separate a **reference meaning**, a **candidate implementation**, a **validator or legality boundary**, and a **measurement loop**. This distinction prevents performance statistics from being confused with proof of correctness. It also makes the idea compatible with languages that have different overflow, exception, concurrency and foreign-function semantics.

## 2. Internal representation and interfaces

The following sketch is a proposed notation, not the syntax of an existing compiler framework. It is intentionally compact enough to serve as the start of a DSL or IR schema.

```text
%klass = class_of %obj
%ok = eq %klass, @Point
guard %ok, snapshot=@S18, assumption=@A7
%x = unchecked_load_field %obj, offset=16
%r = add_i32 %x, 1
```

This representation needs a stable identity scheme for values, functions, versions or resources mentioned in the sketch. An implementation should state which fields are **static semantics**, which are **runtime observations**, which are **guarded assumptions**, and which are **derived caches**. Blurring those categories is a common cause of invalidation bugs. Where the notation uses estimates or profiler data, it should record the collection epoch and target as part of the record.

## 3. Mechanism: from idea to executable system

A concrete execution sequence for the proposed design is:

1. **Separate speculative evidence (profiled types) from a proof of guard dominance.**
2. **Create a guarded region whose ordinary operations may rely on the predicate.**
3. **Attach a recovery state covering locals, operand stack and inlined frames.**
4. **Select between guard failure to generic code, side exit and full deoptimization.**
5. **Measure guard profitability; merge repeated checks where safe.**

For a small compiler, make each step inspectable through a textual dump. The dump should include the source/IR revision, the selected candidate, the reason for selection, and any required assumptions. For a concurrent compiler, attach revision numbers to requests and results so that work produced for an obsolete program cannot be published accidentally.

## 4. Correctness contract and proof obligations

A speculation is sound only if every dependent operation is controlled by a guard that cannot be bypassed through exceptional, indirect or concurrent paths. `unchecked_load_field` must never execute when the class differs, even if an old profile said it was rare.

A reviewer should be able to answer four questions for every transformation: **(1)** Which source-level observations must remain identical? **(2)** Which assumptions are proved statically, and which are checked dynamically? **(3)** Where does execution go if a guard, resource request or validation fails? **(4)** What previously calculated facts and artifacts must be invalidated? A design that answers only the performance question is incomplete.

The practical verification ladder is: structural IR verification; type/effect/dominance checks where applicable; differential execution against a reference; randomized or metamorphic tests over adversarial inputs; and bounded symbolic or translation validation for a tractable subset. These methods have different guarantees. Tests can find counterexamples, not prove universal equivalence. SMT-based bounded validation is only as strong as its encoding and bounds. The artifact should describe which rung was achieved rather than presenting a Boolean `verified` flag with no scope.

## 5. Engineering costs and negative cases

- **Risk 1:** Guard placement can raise latency and disrupt vectorization.
- **Risk 2:** Global class unloading or dynamic code loading invalidates assumptions asynchronously.
- **Risk 3:** Profiles can be unrepresentative; rare paths need an always-correct recovery strategy.

Compatibility costs also matter. Debuggers, profilers, coverage tools, sanitizers, binary interfaces, exception unwinders and reproducible builds consume compiler metadata. If an optimization changes control locations, representation versions or calling conventions, downstream tooling needs enough provenance to stay correct.

## 6. Implementation roadmap

**Milestone A — semantic reference.** Build a deliberately slow baseline that implements the relevant behavior exactly. Derive executable test cases from the example and document its unsupported features. Begin with **Separate speculative evidence (profiled types) from a proof of guard dominance**. Make the baseline capable of dumping both input state and output observations.

**Milestone B — smallest useful optimization.** Implement one well-scoped transformation that exercises **Create a guarded region whose ordinary operations may rely on the predicate**. Prefer a single function or basic block, a single target and stable data structures. Add a verifier that runs before code is exposed to users.

**Milestone C — adaptive or incremental operation.** Introduce **Attach a recovery state covering locals, operand stack and inlined frames**. Track which facts the optimization consumes. Add rollback, fallback or invalidation behavior as dictated by the correctness contract and test it with deliberately stale inputs.

**Milestone D — integration and observability.** Complete **Measure guard profitability; merge repeated checks where safe**. Provide an inspector for alternative decisions and an event log that connects the optimization request to generated code, invalidation and measurements. Run the same correctness corpus at each milestone; do not trade away coverage for incremental speed.

An implementation is ready for integration when the compiler can explain *why* an opportunity was accepted, *what* was changed, *which* observations remain equivalent, *how* it backs out safely, and *whether* the measured result justifies the cost.

## 7. Experimental evaluation

**Proposed experiment.** Compile a polymorphic object-access benchmark with 1, 2, 8 and 100 classes. Report guard count, optimized path speed, bailouts, recompilations and worst-case correctness under class mutation.

Report three categories separately: **semantic validity** (differential mismatches, failed guards or validator verdicts), **compiler overhead** (wall time, allocated bytes, queue delay and metadata size), and **program outcome** (end-to-end latency/throughput, code size, energy or memory traffic as relevant). Include the reference baseline and at least one deliberately unfavorable workload. Use repeatable seeds and hold the target, runtime flags and environment constant when comparing variants.

Performance should be reported with a distribution or confidence interval rather than a single best run. If the compiler is adaptive, measure the whole lifetime including profiling, compilation, migration and fallback—not just warm steady state. If the system is multi-target, distinguish results caused by hardware capabilities from those caused by the compiler algorithm.

## 8. Design exercises and open questions

1. **Specify a contract.** Rewrite the core invariant above as a precondition, an observable-state relation and a postcondition. Identify one language feature (exceptions, floats, concurrency, reflection or FFI) that would invalidate an over-simple formulation.
2. **Build a minimal counterexample.** Choose the first engineering risk and construct a test that triggers it. Explain how the system will detect it and which fallback will execute.
3. **Define a budget.** Decide how much compiler CPU, memory, code-cache space and validation time this technique may consume before declining to optimize.
4. **Explore the frontier.** Could speculation become a typed effect in the IR, preventing an optimization from forgetting its recovery obligations? Connect Chapters 4, 19, 27 and 29.

**Connections.** [Chapter 4 — Deoptimization as an IR Operation](04-deoptimization-as-an-ir-operation.md); [Chapter 19 — Probabilistic IR](19-probabilistic-ir.md); [Chapter 27 — Compiler with Explicit Uncertainty](27-compiler-with-explicit-uncertainty.md); [Chapter 29 — Proof-Carrying IR and Certified Rewrite Contracts](29-proof-carrying-ir-and-certified-rewrite-contracts.md).

**Takeaway.** A conventional optimizer treats facts as proved or unknown. The next step is not to assume it wins, but to define the observable semantics, construct a small falsifiable implementation and measure its full lifecycle.

---

**Source provenance:** Expanded from item **3**, “Speculative IR”, in [`COMPILER_IDEAS.md`](../sources/COMPILER_IDEAS.md). The source supplies the seed idea; architecture, pseudocode, contracts and experiments in this chapter are dossier elaborations. See [the source map](../appendices/SOURCE-MAP.md).
