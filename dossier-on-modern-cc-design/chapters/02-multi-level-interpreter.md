# Chapter 02 — Multi-Level Interpreter

**Part of:** *The Modern Compiler Dossier* · **Concept origin:** Expanded from supplied `COMPILER_IDEAS.md`, item 2 · **Primary area:** Adaptive execution and runtime

> **Central proposition.** Replace the usual interpreter-versus-JIT dichotomy with a lattice of executable representations: syntax tree, normalized IR, bytecode, specialized bytecode, trace, machine IR and native code. A method may ascend or descend according to observed benefit, debugging needs, platform restrictions or memory pressure. Transitions, not a single top tier, become the architectural focus.

## 1. Why this idea changes compiler design

Associate each executable with a semantic function ID, a tier, validity predicates, metadata to reconstruct live variables and an estimated warm-up cost. A tier policy compares compilation time, anticipated remaining invocations and code-cache footprint. Calls enter through indirection cells so version switches do not require patching arbitrary call sites.

A useful way to approach the design is to separate a **reference meaning**, a **candidate implementation**, a **validator or legality boundary**, and a **measurement loop**. This distinction prevents performance statistics from being confused with proof of correctness. It also makes the idea compatible with languages that have different overflow, exception, concurrency and foreign-function semantics.

## 2. Internal representation and interfaces

The following sketch is a proposed notation, not the syntax of an existing compiler framework. It is intentionally compact enough to serve as the start of a DSL or IR schema.

```text
tier F = ast; counts = 0
on_call F:
  counts += 1
  if counts == 200: queue(bytecode(F))
  if counts == 20000 and stable_types(F): queue(native(F))
  execute best_valid(F, debug_mode, code_cache_budget)
```

This representation needs a stable identity scheme for values, functions, versions or resources mentioned in the sketch. An implementation should state which fields are **static semantics**, which are **runtime observations**, which are **guarded assumptions**, and which are **derived caches**. Blurring those categories is a common cause of invalidation bugs. Where the notation uses estimates or profiler data, it should record the collection epoch and target as part of the record.

## 3. Mechanism: from idea to executable system

A concrete execution sequence for the proposed design is:

1. **Specify a reference interpreter as the semantic oracle and define explicit transfer maps between tiers.**
2. **Preserve source locations and local variables in each representation to support exceptions and debugging.**
3. **Track queue delay, compile cost and code size alongside runtime counters.**
4. **Make the entry stub select the highest expected-value currently valid implementation.**
5. **Demote functions during memory pressure, invalidation or interactive stepping.**

For a small compiler, make each step inspectable through a textual dump. The dump should include the source/IR revision, the selected candidate, the reason for selection, and any required assumptions. For a concurrent compiler, attach revision numbers to requests and results so that work produced for an obsolete program cannot be published accidentally.

## 4. Correctness contract and proof obligations

All tiers must agree on observable results for a defined language semantics, including numerical edge cases and exception ordering. Transfers in the middle of a function require an on-stack replacement protocol, not merely a new entry pointer.

A reviewer should be able to answer four questions for every transformation: **(1)** Which source-level observations must remain identical? **(2)** Which assumptions are proved statically, and which are checked dynamically? **(3)** Where does execution go if a guard, resource request or validation fails? **(4)** What previously calculated facts and artifacts must be invalidated? A design that answers only the performance question is incomplete.

The practical verification ladder is: structural IR verification; type/effect/dominance checks where applicable; differential execution against a reference; randomized or metamorphic tests over adversarial inputs; and bounded symbolic or translation validation for a tractable subset. These methods have different guarantees. Tests can find counterexamples, not prove universal equivalence. SMT-based bounded validation is only as strong as its encoding and bounds. The artifact should describe which rung was achieved rather than presenting a Boolean `verified` flag with no scope.

## 5. Engineering costs and negative cases

- **Risk 1:** Tier explosion can consume compiler engineering resources for marginal gains.
- **Risk 2:** An ill-tuned policy can spend more time compiling than running.
- **Risk 3:** Lower tiers often have richer debug information than native tiers, creating inconsistent user experience.

Compatibility costs also matter. Debuggers, profilers, coverage tools, sanitizers, binary interfaces, exception unwinders and reproducible builds consume compiler metadata. If an optimization changes control locations, representation versions or calling conventions, downstream tooling needs enough provenance to stay correct.

## 6. Implementation roadmap

**Milestone A — semantic reference.** Build a deliberately slow baseline that implements the relevant behavior exactly. Derive executable test cases from the example and document its unsupported features. Begin with **Specify a reference interpreter as the semantic oracle and define explicit transfer maps between tiers**. Make the baseline capable of dumping both input state and output observations.

**Milestone B — smallest useful optimization.** Implement one well-scoped transformation that exercises **Preserve source locations and local variables in each representation to support exceptions and debugging**. Prefer a single function or basic block, a single target and stable data structures. Add a verifier that runs before code is exposed to users.

**Milestone C — adaptive or incremental operation.** Introduce **Track queue delay, compile cost and code size alongside runtime counters**. Track which facts the optimization consumes. Add rollback, fallback or invalidation behavior as dictated by the correctness contract and test it with deliberately stale inputs.

**Milestone D — integration and observability.** Complete **Demote functions during memory pressure, invalidation or interactive stepping**. Provide an inspector for alternative decisions and an event log that connects the optimization request to generated code, invalidation and measurements. Run the same correctness corpus at each milestone; do not trade away coverage for incremental speed.

An implementation is ready for integration when the compiler can explain *why* an opportunity was accepted, *what* was changed, *which* observations remain equivalent, *how* it backs out safely, and *whether* the measured result justifies the cost.

## 7. Experimental evaluation

**Proposed experiment.** Use microservices with many cold methods and a few hot loops. Plot cumulative execution time versus compilation CPU and resident code bytes for two-, three- and six-tier variants; inject debugger attach and memory pressure.

Report three categories separately: **semantic validity** (differential mismatches, failed guards or validator verdicts), **compiler overhead** (wall time, allocated bytes, queue delay and metadata size), and **program outcome** (end-to-end latency/throughput, code size, energy or memory traffic as relevant). Include the reference baseline and at least one deliberately unfavorable workload. Use repeatable seeds and hold the target, runtime flags and environment constant when comparing variants.

Performance should be reported with a distribution or confidence interval rather than a single best run. If the compiler is adaptive, measure the whole lifetime including profiling, compilation, migration and fallback—not just warm steady state. If the system is multi-target, distinguish results caused by hardware capabilities from those caused by the compiler algorithm.

## 8. Design exercises and open questions

1. **Specify a contract.** Rewrite the core invariant above as a precondition, an observable-state relation and a postcondition. Identify one language feature (exceptions, floats, concurrency, reflection or FFI) that would invalidate an over-simple formulation.
2. **Build a minimal counterexample.** Choose the first engineering risk and construct a test that triggers it. Explain how the system will detect it and which fallback will execute.
3. **Define a budget.** Decide how much compiler CPU, memory, code-cache space and validation time this technique may consume before declining to optimize.
4. **Explore the frontier.** What minimal transition metadata permits an arbitrary execution edge in the representation lattice? Chapters 3, 4, 12 and 24 supply the building blocks.

**Connections.** [Chapter 3 — Speculative IR](03-speculative-ir.md); [Chapter 4 — Deoptimization as an IR Operation](04-deoptimization-as-an-ir-operation.md); [Chapter 12 — Self-Optimizing Interpreter](12-self-optimizing-interpreter.md); [Chapter 24 — Self-Modifying Interpreter](24-self-modifying-interpreter.md).

**Takeaway.** Replace the usual interpreter-versus-JIT dichotomy with a lattice of executable representations: syntax tree, normalized IR, bytecode, specialized bytecode, trace, machine IR and native code. The next step is not to assume it wins, but to define the observable semantics, construct a small falsifiable implementation and measure its full lifecycle.

---

**Source provenance:** Expanded from item **2**, “Multi-Level Interpreter”, in [`COMPILER_IDEAS.md`](../sources/COMPILER_IDEAS.md). The source supplies the seed idea; architecture, pseudocode, contracts and experiments in this chapter are dossier elaborations. See [the source map](../appendices/SOURCE-MAP.md).
