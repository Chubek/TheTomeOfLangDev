# Chapter 04 — Deoptimization as an IR Operation

**Part of:** *The Modern Compiler Dossier* · **Concept origin:** Expanded from supplied `COMPILER_IDEAS.md`, item 4 · **Primary area:** Adaptive execution and runtime

> **Central proposition.** Deoptimization is an explicit control-transfer operation that reconstructs a less-optimized execution state. Once represented in IR, deopt stops being undocumented JIT magic and becomes something the verifier, optimizer, debugger and code generator can inspect and validate.

## 1. Why this idea changes compiler design

A deoptimization descriptor names the resume program counter, inlined call frames, virtual objects, local bindings and side-effect state. Safepoints describe where the transition is legal; a stack-map generator assigns concrete registers and slots to every live abstract value. The runtime materializes virtual objects exactly once and resumes the reference semantics.

A useful way to approach the design is to separate a **reference meaning**, a **candidate implementation**, a **validator or legality boundary**, and a **measurement loop**. This distinction prevents performance statistics from being confused with proof of correctness. It also makes the idea compatible with languages that have different overflow, exception, concurrency and foreign-function semantics.

## 2. Internal representation and interfaces

The following sketch is a proposed notation, not the syntax of an existing compiler framework. It is intentionally compact enough to serve as the start of a DSL or IR schema.

```text
guard %shape_is_array else deopt @D41
...
deopt @D41 {
  resume = @bytecode:push_item/pc=17
  frame0 = {self:%obj, item:%x, length:%len}
  virtual_objects = {%temp: array(%cap,%data)}
}
```

This representation needs a stable identity scheme for values, functions, versions or resources mentioned in the sketch. An implementation should state which fields are **static semantics**, which are **runtime observations**, which are **guarded assumptions**, and which are **derived caches**. Blurring those categories is a common cause of invalidation bugs. Where the notation uses estimates or profiler data, it should record the collection epoch and target as part of the record.

## 3. Mechanism: from idea to executable system

A concrete execution sequence for the proposed design is:

1. **Assign a stable frame-state ID to every state that might deopt.**
2. **After optimization, remap source variables through SSA renaming, rematerialization and register allocation.**
3. **Build stack maps and object-materialization recipes in machine code.**
4. **On failure, stop at a safepoint, reconstruct nested frames and jump to the lower-tier resume point.**
5. **Verify every reconstruction recipe for availability, type, ownership and effect ordering.**

For a small compiler, make each step inspectable through a textual dump. The dump should include the source/IR revision, the selected candidate, the reason for selection, and any required assumptions. For a concurrent compiler, attach revision numbers to requests and results so that work produced for an obsolete program cannot be published accidentally.

## 4. Correctness contract and proof obligations

Deoptimization must not repeat a visible effect or lose one that already occurred. Inlined frames, monitors, exceptions and virtual allocations must reconstruct a state observationally consistent with the reference interpreter.

A reviewer should be able to answer four questions for every transformation: **(1)** Which source-level observations must remain identical? **(2)** Which assumptions are proved statically, and which are checked dynamically? **(3)** Where does execution go if a guard, resource request or validation fails? **(4)** What previously calculated facts and artifacts must be invalidated? A design that answers only the performance question is incomplete.

The practical verification ladder is: structural IR verification; type/effect/dominance checks where applicable; differential execution against a reference; randomized or metamorphic tests over adversarial inputs; and bounded symbolic or translation validation for a tractable subset. These methods have different guarantees. Tests can find counterexamples, not prove universal equivalence. SMT-based bounded validation is only as strong as its encoding and bounds. The artifact should describe which rung was achieved rather than presenting a Boolean `verified` flag with no scope.

## 5. Engineering costs and negative cases

- **Risk 1:** Incorrect frame reconstruction often appears only after rare guard failures.
- **Risk 2:** Some values are optimized away; they need pure rematerialization recipes or retained spill slots.
- **Risk 3:** Long-running loops need OSR in both directions to avoid waiting for the next call.

Compatibility costs also matter. Debuggers, profilers, coverage tools, sanitizers, binary interfaces, exception unwinders and reproducible builds consume compiler metadata. If an optimization changes control locations, representation versions or calling conventions, downstream tooling needs enough provenance to stay correct.

## 6. Implementation roadmap

**Milestone A — semantic reference.** Build a deliberately slow baseline that implements the relevant behavior exactly. Derive executable test cases from the example and document its unsupported features. Begin with **Assign a stable frame-state ID to every state that might deopt**. Make the baseline capable of dumping both input state and output observations.

**Milestone B — smallest useful optimization.** Implement one well-scoped transformation that exercises **After optimization, remap source variables through SSA renaming, rematerialization and register allocation**. Prefer a single function or basic block, a single target and stable data structures. Add a verifier that runs before code is exposed to users.

**Milestone C — adaptive or incremental operation.** Introduce **Build stack maps and object-materialization recipes in machine code**. Track which facts the optimization consumes. Add rollback, fallback or invalidation behavior as dictated by the correctness contract and test it with deliberately stale inputs.

**Milestone D — integration and observability.** Complete **Verify every reconstruction recipe for availability, type, ownership and effect ordering**. Provide an inspector for alternative decisions and an event log that connects the optimization request to generated code, invalidation and measurements. Run the same correctness corpus at each milestone; do not trade away coverage for incremental speed.

An implementation is ready for integration when the compiler can explain *why* an opportunity was accepted, *what* was changed, *which* observations remain equivalent, *how* it backs out safely, and *whether* the measured result justifies the cost.

## 7. Experimental evaluation

**Proposed experiment.** Force every guard in an optimized test suite to fail and compare resulting heap, stack and exception trace with the interpreter. Include inlined recursion, allocation sinking, monitors and optimized-away variables.

Report three categories separately: **semantic validity** (differential mismatches, failed guards or validator verdicts), **compiler overhead** (wall time, allocated bytes, queue delay and metadata size), and **program outcome** (end-to-end latency/throughput, code size, energy or memory traffic as relevant). Include the reference baseline and at least one deliberately unfavorable workload. Use repeatable seeds and hold the target, runtime flags and environment constant when comparing variants.

Performance should be reported with a distribution or confidence interval rather than a single best run. If the compiler is adaptive, measure the whole lifetime including profiling, compilation, migration and fallback—not just warm steady state. If the system is multi-target, distinguish results caused by hardware capabilities from those caused by the compiler algorithm.

## 8. Design exercises and open questions

1. **Specify a contract.** Rewrite the core invariant above as a precondition, an observable-state relation and a postcondition. Identify one language feature (exceptions, floats, concurrency, reflection or FFI) that would invalidate an over-simple formulation.
2. **Build a minimal counterexample.** Choose the first engineering risk and construct a test that triggers it. Explain how the system will detect it and which fallback will execute.
3. **Define a budget.** Decide how much compiler CPU, memory, code-cache space and validation time this technique may consume before declining to optimize.
4. **Explore the frontier.** Can deopt metadata be treated as a proof obligation automatically checked after every pass? See Chapters 3, 20, 29 and 35.

**Connections.** [Chapter 3 — Speculative IR](03-speculative-ir.md); [Chapter 20 — Versioned IR](20-versioned-ir.md); [Chapter 29 — Proof-Carrying IR and Certified Rewrite Contracts](29-proof-carrying-ir-and-certified-rewrite-contracts.md); [Chapter 35 — Replayable Deoptimization Time Machine](35-replayable-deoptimization-time-machine.md).

**Takeaway.** Deoptimization is an explicit control-transfer operation that reconstructs a less-optimized execution state. The next step is not to assume it wins, but to define the observable semantics, construct a small falsifiable implementation and measure its full lifecycle.

---

**Source provenance:** Expanded from item **4**, “Deoptimization as an IR Operation”, in [`COMPILER_IDEAS.md`](../sources/COMPILER_IDEAS.md). The source supplies the seed idea; architecture, pseudocode, contracts and experiments in this chapter are dossier elaborations. See [the source map](../appendices/SOURCE-MAP.md).
