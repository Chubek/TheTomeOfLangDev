# Chapter 32 — Counterexample-Guided Compiler Synthesis

**Part of:** *The Modern Compiler Dossier* · **Concept origin:** New proposal developed for this dossier · **Primary area:** IR knowledge and verification

> **Central proposition.** Proposed extension: develop optimizations as a search process where each rejected candidate returns a concrete counterexample. The compiler synthesizes a candidate lowering from templates, checks it against a reference semantics, and refines the candidate space using the failing input. This is a compiler-authoring technique as much as a runtime optimizer.

## 1. Why this idea changes compiler design

The synthesis engine combines a grammar of target instructions, semantic constraints and an objective. A checker uses symbolic reasoning or bounded exhaustive execution to find mismatches. Counterexamples become persistent tests and restrict subsequent search. Only a candidate proven under the selected model, or explicitly validated to a stated bound, may be published.

A useful way to approach the design is to separate a **reference meaning**, a **candidate implementation**, a **validator or legality boundary**, and a **measurement loop**. This distinction prevents performance statistics from being confused with proof of correctness. It also makes the idea compatible with languages that have different overflow, exception, concurrency and foreign-function semantics.

## 2. Internal representation and interfaces

The following sketch is a proposed notation, not the syntax of an existing compiler framework. It is intentionally compact enough to serve as the start of a DSL or IR schema.

```text
synthesize rule mul3(x) -> candidate from {add,shl,lea}
check forall x:i32: candidate(x) == wrap_mul(x,3)
if counterexample x=0x80000000:
  refine(overflow_semantics)
else if proved: publish(rule, certificate)
```

This representation needs a stable identity scheme for values, functions, versions or resources mentioned in the sketch. An implementation should state which fields are **static semantics**, which are **runtime observations**, which are **guarded assumptions**, and which are **derived caches**. Blurring those categories is a common cause of invalidation bugs. Where the notation uses estimates or profiler data, it should record the collection epoch and target as part of the record.

## 3. Mechanism: from idea to executable system

A concrete execution sequence for the proposed design is:

1. **Define a compact semantic reference for each candidate operation family.**
2. **Enumerate or search candidate instruction sequences with bounded length and cost.**
3. **Query a checker for counterexamples; add them to the refinement corpus.**
4. **Stop on proof, explicit bounded guarantee or resource exhaustion.**
5. **Store discovered rules with target assumptions and reproducible validation artifacts.**

For a small compiler, make each step inspectable through a textual dump. The dump should include the source/IR revision, the selected candidate, the reason for selection, and any required assumptions. For a concurrent compiler, attach revision numbers to requests and results so that work produced for an obsolete program cannot be published accidentally.

## 4. Correctness contract and proof obligations

A candidate accepted by testing alone is not generally proven correct. The synthesis claim must specify the input domain, memory model, solver completeness and treatment of undefined behavior.

A reviewer should be able to answer four questions for every transformation: **(1)** Which source-level observations must remain identical? **(2)** Which assumptions are proved statically, and which are checked dynamically? **(3)** Where does execution go if a guard, resource request or validation fails? **(4)** What previously calculated facts and artifacts must be invalidated? A design that answers only the performance question is incomplete.

The practical verification ladder is: structural IR verification; type/effect/dominance checks where applicable; differential execution against a reference; randomized or metamorphic tests over adversarial inputs; and bounded symbolic or translation validation for a tractable subset. These methods have different guarantees. Tests can find counterexamples, not prove universal equivalence. SMT-based bounded validation is only as strong as its encoding and bounds. The artifact should describe which rung was achieved rather than presenting a Boolean `verified` flag with no scope.

## 5. Engineering costs and negative cases

- **Risk 1:** State-space explosion makes long instruction sequences impractical.
- **Risk 2:** Solver encodings for floats, vectors and memory are expensive.
- **Risk 3:** Nondeterministic search can harm build reproducibility without seeded configuration.

Compatibility costs also matter. Debuggers, profilers, coverage tools, sanitizers, binary interfaces, exception unwinders and reproducible builds consume compiler metadata. If an optimization changes control locations, representation versions or calling conventions, downstream tooling needs enough provenance to stay correct.

## 6. Implementation roadmap

**Milestone A — semantic reference.** Build a deliberately slow baseline that implements the relevant behavior exactly. Derive executable test cases from the example and document its unsupported features. Begin with **Define a compact semantic reference for each candidate operation family**. Make the baseline capable of dumping both input state and output observations.

**Milestone B — smallest useful optimization.** Implement one well-scoped transformation that exercises **Enumerate or search candidate instruction sequences with bounded length and cost**. Prefer a single function or basic block, a single target and stable data structures. Add a verifier that runs before code is exposed to users.

**Milestone C — adaptive or incremental operation.** Introduce **Query a checker for counterexamples; add them to the refinement corpus**. Track which facts the optimization consumes. Add rollback, fallback or invalidation behavior as dictated by the correctness contract and test it with deliberately stale inputs.

**Milestone D — integration and observability.** Complete **Store discovered rules with target assumptions and reproducible validation artifacts**. Provide an inspector for alternative decisions and an event log that connects the optimization request to generated code, invalidation and measurements. Run the same correctness corpus at each milestone; do not trade away coverage for incremental speed.

An implementation is ready for integration when the compiler can explain *why* an opportunity was accepted, *what* was changed, *which* observations remain equivalent, *how* it backs out safely, and *whether* the measured result justifies the cost.

## 7. Experimental evaluation

**Proposed experiment.** Synthesize arithmetic strength reductions and bit-manipulation idioms for two ISAs. Report coverage, time per proven rule, counterexample count and generated-code performance versus manually selected patterns.

Report three categories separately: **semantic validity** (differential mismatches, failed guards or validator verdicts), **compiler overhead** (wall time, allocated bytes, queue delay and metadata size), and **program outcome** (end-to-end latency/throughput, code size, energy or memory traffic as relevant). Include the reference baseline and at least one deliberately unfavorable workload. Use repeatable seeds and hold the target, runtime flags and environment constant when comparing variants.

Performance should be reported with a distribution or confidence interval rather than a single best run. If the compiler is adaptive, measure the whole lifetime including profiling, compilation, migration and fallback—not just warm steady state. If the system is multi-target, distinguish results caused by hardware capabilities from those caused by the compiler algorithm.

## 8. Design exercises and open questions

1. **Specify a contract.** Rewrite the core invariant above as a precondition, an observable-state relation and a postcondition. Identify one language feature (exceptions, floats, concurrency, reflection or FFI) that would invalidate an over-simple formulation.
2. **Build a minimal counterexample.** Choose the first engineering risk and construct a test that triggers it. Explain how the system will detect it and which fallback will execute.
3. **Define a budget.** Decide how much compiler CPU, memory, code-cache space and validation time this technique may consume before declining to optimize.
4. **Explore the frontier.** Could synthesis produce interpreters and instruction selectors from one semantic specification? Chapters 14, 15 and 29.

**Connections.** [Chapter 14 — Interpreter as a Compiler](14-interpreter-as-a-compiler.md); [Chapter 15 — Semantic IR](15-semantic-ir.md); [Chapter 29 — Proof-Carrying IR and Certified Rewrite Contracts](29-proof-carrying-ir-and-certified-rewrite-contracts.md).

**Takeaway.** Proposed extension: develop optimizations as a search process where each rejected candidate returns a concrete counterexample. The next step is not to assume it wins, but to define the observable semantics, construct a small falsifiable implementation and measure its full lifecycle.

---

**Origin note:** This is a **proposed design developed for this dossier**, not a claim of global research priority or that no related technique has appeared in the literature. Terminology and implementation sketches here are conceptual until validated.
