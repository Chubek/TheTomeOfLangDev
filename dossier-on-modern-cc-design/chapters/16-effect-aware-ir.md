# Chapter 16 — Effect-Aware IR

**Part of:** *The Modern Compiler Dossier* · **Concept origin:** Expanded from supplied `COMPILER_IDEAS.md`, item 16 · **Primary area:** IR knowledge and verification

> **Central proposition.** An optimizer needs to know more than which value a function returns: it needs to know what the function can do to the outside world. Effect-aware IR represents I/O, allocation, mutation, exception, synchronization, suspension and possibly divergence in a typed and checkable way, enabling legality checks that are precise instead of globally conservative.

## 1. Why this idea changes compiler design

Attach an effect row to operations and functions. Use linear or token-like dependencies for effects whose order matters; keep independent pure computations free to move. Interprocedural inference computes conservative summaries and progressively refines them, invalidating dependent optimizations when a callee changes.

A useful way to approach the design is to separate a **reference meaning**, a **candidate implementation**, a **validator or legality boundary**, and a **measurement loop**. This distinction prevents performance statistics from being confused with proof of correctness. It also makes the idea compatible with languages that have different overflow, exception, concurrency and foreign-function semantics.

## 2. Internal representation and interfaces

The following sketch is a proposed notation, not the syntax of an existing compiler framework. It is intentionally compact enough to serve as the start of a DSL or IR schema.

```text
fn parse(s: String) -> AST ! {Alloc,Throw}
fn log(s: String) -> Unit ! {IO}
%a, %mem1 = call @parse(%s) [mem=%mem0]
%io1 = call @log(%msg) [io=%io0]
# pure hash(%s) may move; log may not cross equivalent IO operations
```

This representation needs a stable identity scheme for values, functions, versions or resources mentioned in the sketch. An implementation should state which fields are **static semantics**, which are **runtime observations**, which are **guarded assumptions**, and which are **derived caches**. Blurring those categories is a common cause of invalidation bugs. Where the notation uses estimates or profiler data, it should record the collection epoch and target as part of the record.

## 3. Mechanism: from idea to executable system

A concrete execution sequence for the proposed design is:

1. **Identify observable effects for the source language and target memory model.**
2. **Infer summaries by call-graph fixpoint, conservatively handling foreign calls.**
3. **Represent ordering with effect tokens or explicit dependence edges.**
4. **Teach GVN, LICM and inlining to preserve required effect order.**
5. **Verify generated code against source-level exception, I/O and memory semantics.**

For a small compiler, make each step inspectable through a textual dump. The dump should include the source/IR revision, the selected candidate, the reason for selection, and any required assumptions. For a concurrent compiler, attach revision numbers to requests and results so that work produced for an obsolete program cannot be published accidentally.

## 4. Correctness contract and proof obligations

A claimed pure operation must really be free of observable effects under the language semantics, including traps when relevant. Effect summaries may be conservative but never underapproximate possible behavior.

A reviewer should be able to answer four questions for every transformation: **(1)** Which source-level observations must remain identical? **(2)** Which assumptions are proved statically, and which are checked dynamically? **(3)** Where does execution go if a guard, resource request or validation fails? **(4)** What previously calculated facts and artifacts must be invalidated? A design that answers only the performance question is incomplete.

The practical verification ladder is: structural IR verification; type/effect/dominance checks where applicable; differential execution against a reference; randomized or metamorphic tests over adversarial inputs; and bounded symbolic or translation validation for a tractable subset. These methods have different guarantees. Tests can find counterexamples, not prove universal equivalence. SMT-based bounded validation is only as strong as its encoding and bounds. The artifact should describe which rung was achieved rather than presenting a Boolean `verified` flag with no scope.

## 5. Engineering costs and negative cases

- **Risk 1:** Effect row inference grows complicated with higher-order and reflective calls.
- **Risk 2:** Disentangling independent memory regions requires alias information.
- **Risk 3:** False precision around undefined behavior or nontermination can miscompile loops.

Compatibility costs also matter. Debuggers, profilers, coverage tools, sanitizers, binary interfaces, exception unwinders and reproducible builds consume compiler metadata. If an optimization changes control locations, representation versions or calling conventions, downstream tooling needs enough provenance to stay correct.

## 6. Implementation roadmap

**Milestone A — semantic reference.** Build a deliberately slow baseline that implements the relevant behavior exactly. Derive executable test cases from the example and document its unsupported features. Begin with **Identify observable effects for the source language and target memory model**. Make the baseline capable of dumping both input state and output observations.

**Milestone B — smallest useful optimization.** Implement one well-scoped transformation that exercises **Infer summaries by call-graph fixpoint, conservatively handling foreign calls**. Prefer a single function or basic block, a single target and stable data structures. Add a verifier that runs before code is exposed to users.

**Milestone C — adaptive or incremental operation.** Introduce **Represent ordering with effect tokens or explicit dependence edges**. Track which facts the optimization consumes. Add rollback, fallback or invalidation behavior as dictated by the correctness contract and test it with deliberately stale inputs.

**Milestone D — integration and observability.** Complete **Verify generated code against source-level exception, I/O and memory semantics**. Provide an inspector for alternative decisions and an event log that connects the optimization request to generated code, invalidation and measurements. Run the same correctness corpus at each milestone; do not trade away coverage for incremental speed.

An implementation is ready for integration when the compiler can explain *why* an opportunity was accepted, *what* was changed, *which* observations remain equivalent, *how* it backs out safely, and *whether* the measured result justifies the cost.

## 7. Experimental evaluation

**Proposed experiment.** Compare a pure/impure bit with typed effect rows on async pipelines and exception-heavy code. Count safe hoists, rejected rewrites, compile time and differential correctness failures.

Report three categories separately: **semantic validity** (differential mismatches, failed guards or validator verdicts), **compiler overhead** (wall time, allocated bytes, queue delay and metadata size), and **program outcome** (end-to-end latency/throughput, code size, energy or memory traffic as relevant). Include the reference baseline and at least one deliberately unfavorable workload. Use repeatable seeds and hold the target, runtime flags and environment constant when comparing variants.

Performance should be reported with a distribution or confidence interval rather than a single best run. If the compiler is adaptive, measure the whole lifetime including profiling, compilation, migration and fallback—not just warm steady state. If the system is multi-target, distinguish results caused by hardware capabilities from those caused by the compiler algorithm.

## 8. Design exercises and open questions

1. **Specify a contract.** Rewrite the core invariant above as a precondition, an observable-state relation and a postcondition. Identify one language feature (exceptions, floats, concurrency, reflection or FFI) that would invalidate an over-simple formulation.
2. **Build a minimal counterexample.** Choose the first engineering risk and construct a test that triggers it. Explain how the system will detect it and which fallback will execute.
3. **Define a budget.** Decide how much compiler CPU, memory, code-cache space and validation time this technique may consume before declining to optimize.
4. **Explore the frontier.** What is the smallest set of primitive effects that still models exceptions, continuations, atomic memory and coroutine suspension faithfully? Chapters 17, 29 and 43.

**Connections.** [Chapter 17 — Memory as an Explicit IR](17-memory-as-an-explicit-ir.md); [Chapter 29 — Proof-Carrying IR and Certified Rewrite Contracts](29-proof-carrying-ir-and-certified-rewrite-contracts.md); [Chapter 43 — Compile-Time / Run-Time Staging Controller](43-compile-time-run-time-staging-controller.md).

**Takeaway.** An optimizer needs to know more than which value a function returns: it needs to know what the function can do to the outside world. The next step is not to assume it wins, but to define the observable semantics, construct a small falsifiable implementation and measure its full lifecycle.

---

**Source provenance:** Expanded from item **16**, “Effect-Aware IR”, in [`COMPILER_IDEAS.md`](../sources/COMPILER_IDEAS.md). The source supplies the seed idea; architecture, pseudocode, contracts and experiments in this chapter are dossier elaborations. See [the source map](../appendices/SOURCE-MAP.md).
