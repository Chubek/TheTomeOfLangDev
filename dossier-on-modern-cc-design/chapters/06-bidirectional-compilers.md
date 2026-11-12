# Chapter 06 — Bidirectional Compilers

**Part of:** *The Modern Compiler Dossier* · **Concept origin:** Expanded from supplied `COMPILER_IDEAS.md`, item 6 · **Primary area:** Semantic translation and multi-target lowering

> **Central proposition.** Instead of discarding relationships as a program descends through representations, make transformations traceable in both directions. The backward direction is rarely an exact inverse; it is a view update, explanation or reconstruction constrained by recorded provenance. This enables debugging and interactive edits at higher abstractions.

## 1. Why this idea changes compiler design

Represent provenance as typed links from target nodes to one or more source origins, with a transformation ID and reason. A projection interface answers where a machine value came from; an edit-propagation interface checks whether a target edit is expressible in the source language or requires an explicit patch layer.

A useful way to approach the design is to separate a **reference meaning**, a **candidate implementation**, a **validator or legality boundary**, and a **measurement loop**. This distinction prevents performance statistics from being confused with proof of correctness. It also makes the idea compatible with languages that have different overflow, exception, concurrency and foreign-function semantics.

## 2. Internal representation and interfaces

The following sketch is a proposed notation, not the syntax of an existing compiler framework. It is intentionally compact enough to serve as the start of a DSL or IR schema.

```text
origin %m17 = {source: expr#83, rewrite: strength_reduce#4}
source: z = x * 8
machine: shl x,3
edit(machine, shift=2) -> propose(source, z = x * 4)
```

This representation needs a stable identity scheme for values, functions, versions or resources mentioned in the sketch. An implementation should state which fields are **static semantics**, which are **runtime observations**, which are **guarded assumptions**, and which are **derived caches**. Blurring those categories is a common cause of invalidation bugs. Where the notation uses estimates or profiler data, it should record the collection epoch and target as part of the record.

## 3. Mechanism: from idea to executable system

A concrete execution sequence for the proposed design is:

1. **Attach origin identities at parsing and preserve them through cloning and merging.**
2. **Record why transformations happen, not merely the old source span.**
3. **Expose a backward query that returns a set of plausible origins when mappings are many-to-one.**
4. **Define supported bidirectional edits as partial lenses with explicit failure cases.**
5. **Revalidate typing and behavior after any propagated edit.**

For a small compiler, make each step inspectable through a textual dump. The dump should include the source/IR revision, the selected candidate, the reason for selection, and any required assumptions. For a concurrent compiler, attach revision numbers to requests and results so that work produced for an obsolete program cannot be published accidentally.

## 4. Correctness contract and proof obligations

A backward edit cannot silently claim a unique source counterpart when optimization erased or merged information. Provenance is evidence about derivation, not a guarantee that an inverse exists.

A reviewer should be able to answer four questions for every transformation: **(1)** Which source-level observations must remain identical? **(2)** Which assumptions are proved statically, and which are checked dynamically? **(3)** Where does execution go if a guard, resource request or validation fails? **(4)** What previously calculated facts and artifacts must be invalidated? A design that answers only the performance question is incomplete.

The practical verification ladder is: structural IR verification; type/effect/dominance checks where applicable; differential execution against a reference; randomized or metamorphic tests over adversarial inputs; and bounded symbolic or translation validation for a tractable subset. These methods have different guarantees. Tests can find counterexamples, not prove universal equivalence. SMT-based bounded validation is only as strong as its encoding and bounds. The artifact should describe which rung was achieved rather than presenting a Boolean `verified` flag with no scope.

## 5. Engineering costs and negative cases

- **Risk 1:** Aggressive optimization creates ambiguous many-to-many mappings.
- **Risk 2:** Metadata can exceed code size if recorded naively.
- **Risk 3:** Debuggers may present misleading source-level values if they ignore rematerialization and inlining.

Compatibility costs also matter. Debuggers, profilers, coverage tools, sanitizers, binary interfaces, exception unwinders and reproducible builds consume compiler metadata. If an optimization changes control locations, representation versions or calling conventions, downstream tooling needs enough provenance to stay correct.

## 6. Implementation roadmap

**Milestone A — semantic reference.** Build a deliberately slow baseline that implements the relevant behavior exactly. Derive executable test cases from the example and document its unsupported features. Begin with **Attach origin identities at parsing and preserve them through cloning and merging**. Make the baseline capable of dumping both input state and output observations.

**Milestone B — smallest useful optimization.** Implement one well-scoped transformation that exercises **Record why transformations happen, not merely the old source span**. Prefer a single function or basic block, a single target and stable data structures. Add a verifier that runs before code is exposed to users.

**Milestone C — adaptive or incremental operation.** Introduce **Expose a backward query that returns a set of plausible origins when mappings are many-to-one**. Track which facts the optimization consumes. Add rollback, fallback or invalidation behavior as dictated by the correctness contract and test it with deliberately stale inputs.

**Milestone D — integration and observability.** Complete **Revalidate typing and behavior after any propagated edit**. Provide an inspector for alternative decisions and an event log that connects the optimization request to generated code, invalidation and measurements. Run the same correctness corpus at each milestone; do not trade away coverage for incremental speed.

An implementation is ready for integration when the compiler can explain *why* an opportunity was accepted, *what* was changed, *which* observations remain equivalent, *how* it backs out safely, and *whether* the measured result justifies the cost.

## 7. Experimental evaluation

**Proposed experiment.** Build a source↔SSA↔MIR explorer. Measure percentage of instructions with meaningful provenance, query cost, and acceptance rate of semantically valid reverse edits under optimization levels.

Report three categories separately: **semantic validity** (differential mismatches, failed guards or validator verdicts), **compiler overhead** (wall time, allocated bytes, queue delay and metadata size), and **program outcome** (end-to-end latency/throughput, code size, energy or memory traffic as relevant). Include the reference baseline and at least one deliberately unfavorable workload. Use repeatable seeds and hold the target, runtime flags and environment constant when comparing variants.

Performance should be reported with a distribution or confidence interval rather than a single best run. If the compiler is adaptive, measure the whole lifetime including profiling, compilation, migration and fallback—not just warm steady state. If the system is multi-target, distinguish results caused by hardware capabilities from those caused by the compiler algorithm.

## 8. Design exercises and open questions

1. **Specify a contract.** Rewrite the core invariant above as a precondition, an observable-state relation and a postcondition. Identify one language feature (exceptions, floats, concurrency, reflection or FFI) that would invalidate an over-simple formulation.
2. **Build a minimal counterexample.** Choose the first engineering risk and construct a test that triggers it. Explain how the system will detect it and which fallback will execute.
3. **Define a budget.** Decide how much compiler CPU, memory, code-cache space and validation time this technique may consume before declining to optimize.
4. **Explore the frontier.** Could a provenance graph serve simultaneously as debugger metadata and a proof trace? See Chapters 21, 29 and 44.

**Connections.** [Chapter 21 — Compiler Garbage Collection](21-compiler-garbage-collection.md); [Chapter 29 — Proof-Carrying IR and Certified Rewrite Contracts](29-proof-carrying-ir-and-certified-rewrite-contracts.md); [Chapter 44 — Hermetic Compilation Capsules](44-hermetic-compilation-capsules.md).

**Takeaway.** Instead of discarding relationships as a program descends through representations, make transformations traceable in both directions. The next step is not to assume it wins, but to define the observable semantics, construct a small falsifiable implementation and measure its full lifecycle.

---

**Source provenance:** Expanded from item **6**, “Bidirectional Compilers”, in [`COMPILER_IDEAS.md`](../sources/COMPILER_IDEAS.md). The source supplies the seed idea; architecture, pseudocode, contracts and experiments in this chapter are dossier elaborations. See [the source map](../appendices/SOURCE-MAP.md).
