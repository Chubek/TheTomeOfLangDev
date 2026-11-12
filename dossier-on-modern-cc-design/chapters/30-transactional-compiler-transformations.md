# Chapter 30 — Transactional Compiler Transformations

**Part of:** *The Modern Compiler Dossier* · **Concept origin:** New proposal developed for this dossier · **Primary area:** IR knowledge and verification

> **Central proposition.** Proposed extension: treat each optimizer pass as a database transaction over versioned program state. A pass reads a stable IR snapshot, prepares a candidate rewrite set, validates its invariants, and commits or aborts atomically. Failed speculative optimizations become contained events rather than half-mutated compiler graphs.

## 1. Why this idea changes compiler design

Give IR edits read/write sets, revision preconditions and an undo or persistent-copy strategy. A transaction computes candidate transformations in isolation and runs verifiers before publication. Independent passes may commit concurrently if their write sets do not conflict; conflicting changes are rebased or retried.

A useful way to approach the design is to separate a **reference meaning**, a **candidate implementation**, a **validator or legality boundary**, and a **measurement loop**. This distinction prevents performance statistics from being confused with proof of correctness. It also makes the idea compatible with languages that have different overflow, exception, concurrency and foreign-function semantics.

## 2. Internal representation and interfaces

The following sketch is a proposed notation, not the syntax of an existing compiler framework. It is intentionally compact enough to serve as the start of a DSL or IR schema.

```text
txn T = begin(ir_rev=112)
T.replace(%17, simplify(%17))
T.remove(block#8) if unreachable(block#8)
assert verify_ssa(T) && verify_memoryssa(T)
commit(T) if unchanged(read_set(T)) else abort(T)
```

This representation needs a stable identity scheme for values, functions, versions or resources mentioned in the sketch. An implementation should state which fields are **static semantics**, which are **runtime observations**, which are **guarded assumptions**, and which are **derived caches**. Blurring those categories is a common cause of invalidation bugs. Where the notation uses estimates or profiler data, it should record the collection epoch and target as part of the record.

## 3. Mechanism: from idea to executable system

A concrete execution sequence for the proposed design is:

1. **Introduce immutable snapshots or copy-on-write IR pages.**
2. **Record all read assumptions and proposed node/edge changes.**
3. **Run type, dominance, ownership and effect validators against the tentative state.**
4. **Commit a new revision atomically, updating dependent caches by changed entity IDs.**
5. **Expose an audit log and deterministic replay of accepted and rejected edits.**

For a small compiler, make each step inspectable through a textual dump. The dump should include the source/IR revision, the selected candidate, the reason for selection, and any required assumptions. For a concurrent compiler, attach revision numbers to requests and results so that work produced for an obsolete program cannot be published accidentally.

## 4. Correctness contract and proof obligations

A rewrite may not leave the public IR in a partially valid state. Concurrent passes must observe serializable revisions, or an explicitly weaker consistency model with matching analysis guarantees.

A reviewer should be able to answer four questions for every transformation: **(1)** Which source-level observations must remain identical? **(2)** Which assumptions are proved statically, and which are checked dynamically? **(3)** Where does execution go if a guard, resource request or validation fails? **(4)** What previously calculated facts and artifacts must be invalidated? A design that answers only the performance question is incomplete.

The practical verification ladder is: structural IR verification; type/effect/dominance checks where applicable; differential execution against a reference; randomized or metamorphic tests over adversarial inputs; and bounded symbolic or translation validation for a tractable subset. These methods have different guarantees. Tests can find counterexamples, not prove universal equivalence. SMT-based bounded validation is only as strong as its encoding and bounds. The artifact should describe which rung was achieved rather than presenting a Boolean `verified` flag with no scope.

## 5. Engineering costs and negative cases

- **Risk 1:** Snapshot churn can increase memory usage.
- **Risk 2:** Large global passes produce broad conflicts and retries.
- **Risk 3:** Incremental verifier logic is difficult when every invariant is not declared.

Compatibility costs also matter. Debuggers, profilers, coverage tools, sanitizers, binary interfaces, exception unwinders and reproducible builds consume compiler metadata. If an optimization changes control locations, representation versions or calling conventions, downstream tooling needs enough provenance to stay correct.

## 6. Implementation roadmap

**Milestone A — semantic reference.** Build a deliberately slow baseline that implements the relevant behavior exactly. Derive executable test cases from the example and document its unsupported features. Begin with **Introduce immutable snapshots or copy-on-write IR pages**. Make the baseline capable of dumping both input state and output observations.

**Milestone B — smallest useful optimization.** Implement one well-scoped transformation that exercises **Record all read assumptions and proposed node/edge changes**. Prefer a single function or basic block, a single target and stable data structures. Add a verifier that runs before code is exposed to users.

**Milestone C — adaptive or incremental operation.** Introduce **Run type, dominance, ownership and effect validators against the tentative state**. Track which facts the optimization consumes. Add rollback, fallback or invalidation behavior as dictated by the correctness contract and test it with deliberately stale inputs.

**Milestone D — integration and observability.** Complete **Expose an audit log and deterministic replay of accepted and rejected edits**. Provide an inspector for alternative decisions and an event log that connects the optimization request to generated code, invalidation and measurements. Run the same correctness corpus at each milestone; do not trade away coverage for incremental speed.

An implementation is ready for integration when the compiler can explain *why* an opportunity was accepted, *what* was changed, *which* observations remain equivalent, *how* it backs out safely, and *whether* the measured result justifies the cost.

## 7. Experimental evaluation

**Proposed experiment.** Run 16 parallel optimization workers on modules with shared call graphs. Measure successful commits, conflicts, validation overhead, rollback cost and whether deterministic replay reproduces identical output.

Report three categories separately: **semantic validity** (differential mismatches, failed guards or validator verdicts), **compiler overhead** (wall time, allocated bytes, queue delay and metadata size), and **program outcome** (end-to-end latency/throughput, code size, energy or memory traffic as relevant). Include the reference baseline and at least one deliberately unfavorable workload. Use repeatable seeds and hold the target, runtime flags and environment constant when comparing variants.

Performance should be reported with a distribution or confidence interval rather than a single best run. If the compiler is adaptive, measure the whole lifetime including profiling, compilation, migration and fallback—not just warm steady state. If the system is multi-target, distinguish results caused by hardware capabilities from those caused by the compiler algorithm.

## 8. Design exercises and open questions

1. **Specify a contract.** Rewrite the core invariant above as a precondition, an observable-state relation and a postcondition. Identify one language feature (exceptions, floats, concurrency, reflection or FFI) that would invalidate an over-simple formulation.
2. **Build a minimal counterexample.** Choose the first engineering risk and construct a test that triggers it. Explain how the system will detect it and which fallback will execute.
3. **Define a budget.** Decide how much compiler CPU, memory, code-cache space and validation time this technique may consume before declining to optimize.
4. **Explore the frontier.** Can transactional compiler state unify IDE incrementality, runtime recompilation and safety validation? Chapters 7, 20, 22 and 23.

**Connections.** [Chapter 7 — Compiler as a Database](07-compiler-as-a-database.md); [Chapter 20 — Versioned IR](20-versioned-ir.md); [Chapter 22 — Incremental Compiler as a Reactive System](22-incremental-compiler-as-a-reactive-system.md); [Chapter 23 — Compiler as an Actor System](23-compiler-as-an-actor-system.md).

**Takeaway.** Proposed extension: treat each optimizer pass as a database transaction over versioned program state. The next step is not to assume it wins, but to define the observable semantics, construct a small falsifiable implementation and measure its full lifecycle.

---

**Origin note:** This is a **proposed design developed for this dossier**, not a claim of global research priority or that no related technique has appeared in the literature. Terminology and implementation sketches here are conceptual until validated.
