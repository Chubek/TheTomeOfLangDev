# Chapter 07 — Compiler as a Database

**Part of:** *The Modern Compiler Dossier* · **Concept origin:** Expanded from supplied `COMPILER_IDEAS.md`, item 7 · **Primary area:** IR knowledge and verification

> **Central proposition.** The compiler can be understood as an evolving database of program facts. Relations such as `Defines`, `Uses`, `Dominates`, `Aliases`, `HasType` and `DependsOn` replace ad hoc iteration over mutable objects. Optimization becomes a combination of incremental queries, transactional updates and validity rules.

## 1. Why this idea changes compiler design

Store stable entity IDs and relations in a versioned graph or relational engine. Index use-def, control-flow and symbol facts. Derived analysis tables declare which base relations they read; mutations invalidate only affected facts. A compiler database is not necessarily a SQL engine: the crucial abstraction is declarative relations with consistent snapshots.

A useful way to approach the design is to separate a **reference meaning**, a **candidate implementation**, a **validator or legality boundary**, and a **measurement loop**. This distinction prevents performance statistics from being confused with proof of correctness. It also makes the idea compatible with languages that have different overflow, exception, concurrency and foreign-function semantics.

## 2. Internal representation and interfaces

The following sketch is a proposed notation, not the syntax of an existing compiler framework. It is intentionally compact enough to serve as the start of a DSL or IR schema.

```text
.decl Uses(user: Instr, value: Value)
.decl Def(value: Value, instr: Instr)
.decl Dead(instr: Instr)
Dead(i) :- Def(v,i), !Uses(_,v), Pure(i).
```

This representation needs a stable identity scheme for values, functions, versions or resources mentioned in the sketch. An implementation should state which fields are **static semantics**, which are **runtime observations**, which are **guarded assumptions**, and which are **derived caches**. Blurring those categories is a common cause of invalidation bugs. Where the notation uses estimates or profiler data, it should record the collection epoch and target as part of the record.

## 3. Mechanism: from idea to executable system

A concrete execution sequence for the proposed design is:

1. **Normalize IR entities into relations with stable identifiers.**
2. **Choose which relations are primary and which are derived by fixpoint rules.**
3. **Track revisions and dependency edges so edits invalidate a bounded region.**
4. **Provide one consistent snapshot to each parallel analysis query.**
5. **Commit rewrites transactionally and regenerate machine-ordered blocks for lowering.**

For a small compiler, make each step inspectable through a textual dump. The dump should include the source/IR revision, the selected candidate, the reason for selection, and any required assumptions. For a concurrent compiler, attach revision numbers to requests and results so that work produced for an obsolete program cannot be published accidentally.

## 4. Correctness contract and proof obligations

Queries must observe a coherent revision; a type fact from revision 8 cannot justify a rewrite against revision 9. Recursive analysis needs well-defined lattice/fixpoint behavior, and deletion needs correct incremental maintenance.

A reviewer should be able to answer four questions for every transformation: **(1)** Which source-level observations must remain identical? **(2)** Which assumptions are proved statically, and which are checked dynamically? **(3)** Where does execution go if a guard, resource request or validation fails? **(4)** What previously calculated facts and artifacts must be invalidated? A design that answers only the performance question is incomplete.

The practical verification ladder is: structural IR verification; type/effect/dominance checks where applicable; differential execution against a reference; randomized or metamorphic tests over adversarial inputs; and bounded symbolic or translation validation for a tractable subset. These methods have different guarantees. Tests can find counterexamples, not prove universal equivalence. SMT-based bounded validation is only as strong as its encoding and bounds. The artifact should describe which rung was achieved rather than presenting a Boolean `verified` flag with no scope.

## 5. Engineering costs and negative cases

- **Risk 1:** Pointer-rich backend algorithms can be slower when every operation becomes a join.
- **Risk 2:** Invalidation across recursion and alias graphs is subtle.
- **Risk 3:** Memory costs of indices and snapshots can exceed the IR itself.

Compatibility costs also matter. Debuggers, profilers, coverage tools, sanitizers, binary interfaces, exception unwinders and reproducible builds consume compiler metadata. If an optimization changes control locations, representation versions or calling conventions, downstream tooling needs enough provenance to stay correct.

## 6. Implementation roadmap

**Milestone A — semantic reference.** Build a deliberately slow baseline that implements the relevant behavior exactly. Derive executable test cases from the example and document its unsupported features. Begin with **Normalize IR entities into relations with stable identifiers**. Make the baseline capable of dumping both input state and output observations.

**Milestone B — smallest useful optimization.** Implement one well-scoped transformation that exercises **Choose which relations are primary and which are derived by fixpoint rules**. Prefer a single function or basic block, a single target and stable data structures. Add a verifier that runs before code is exposed to users.

**Milestone C — adaptive or incremental operation.** Introduce **Track revisions and dependency edges so edits invalidate a bounded region**. Track which facts the optimization consumes. Add rollback, fallback or invalidation behavior as dictated by the correctness contract and test it with deliberately stale inputs.

**Milestone D — integration and observability.** Complete **Commit rewrites transactionally and regenerate machine-ordered blocks for lowering**. Provide an inspector for alternative decisions and an event log that connects the optimization request to generated code, invalidation and measurements. Run the same correctness corpus at each milestone; do not trade away coverage for incremental speed.

An implementation is ready for integration when the compiler can explain *why* an opportunity was accepted, *what* was changed, *which* observations remain equivalent, *how* it backs out safely, and *whether* the measured result justifies the cost.

## 7. Experimental evaluation

**Proposed experiment.** Implement reachability, liveness and constant propagation twice: conventional worklists and relational rules. Compare recomputation after single-edge edits, full-build throughput, peak memory and debugging inspectability.

Report three categories separately: **semantic validity** (differential mismatches, failed guards or validator verdicts), **compiler overhead** (wall time, allocated bytes, queue delay and metadata size), and **program outcome** (end-to-end latency/throughput, code size, energy or memory traffic as relevant). Include the reference baseline and at least one deliberately unfavorable workload. Use repeatable seeds and hold the target, runtime flags and environment constant when comparing variants.

Performance should be reported with a distribution or confidence interval rather than a single best run. If the compiler is adaptive, measure the whole lifetime including profiling, compilation, migration and fallback—not just warm steady state. If the system is multi-target, distinguish results caused by hardware capabilities from those caused by the compiler algorithm.

## 8. Design exercises and open questions

1. **Specify a contract.** Rewrite the core invariant above as a precondition, an observable-state relation and a postcondition. Identify one language feature (exceptions, floats, concurrency, reflection or FFI) that would invalidate an over-simple formulation.
2. **Build a minimal counterexample.** Choose the first engineering risk and construct a test that triggers it. Explain how the system will detect it and which fallback will execute.
3. **Define a budget.** Decide how much compiler CPU, memory, code-cache space and validation time this technique may consume before declining to optimize.
4. **Explore the frontier.** Can optimization rules be portable queries over versioned fact schemas across different language frontends? See Chapters 9, 22, 30 and 44.

**Connections.** [Chapter 9 — Query-Based Optimization](09-query-based-optimization.md); [Chapter 22 — Incremental Compiler as a Reactive System](22-incremental-compiler-as-a-reactive-system.md); [Chapter 30 — Transactional Compiler Transformations](30-transactional-compiler-transformations.md); [Chapter 44 — Hermetic Compilation Capsules](44-hermetic-compilation-capsules.md).

**Takeaway.** The compiler can be understood as an evolving database of program facts. The next step is not to assume it wins, but to define the observable semantics, construct a small falsifiable implementation and measure its full lifecycle.

---

**Source provenance:** Expanded from item **7**, “Compiler as a Database”, in [`COMPILER_IDEAS.md`](../sources/COMPILER_IDEAS.md). The source supplies the seed idea; architecture, pseudocode, contracts and experiments in this chapter are dossier elaborations. See [the source map](../appendices/SOURCE-MAP.md).
