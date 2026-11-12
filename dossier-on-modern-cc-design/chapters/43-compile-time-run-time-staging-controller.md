# Chapter 43 — Compile-Time / Run-Time Staging Controller

**Part of:** *The Modern Compiler Dossier* · **Concept origin:** New proposal developed for this dossier · **Primary area:** Semantic translation and multi-target lowering

> **Central proposition.** Proposed extension: make the boundary between compile-time and runtime computation adaptive and explicit. Some operations can be partially evaluated at build time; others should wait until data, devices or policies are known. A staging controller chooses when to specialize under code-size, security and reproducibility constraints.

## 1. Why this idea changes compiler design

Annotate values by availability stage and trust level: build-known, link-known, startup-known, request-known and unknown. A staging planner constructs specializations only when inputs are stable enough to amortize compilation. It preserves residual programs for unknown values and records the dependencies that would invalidate an earlier specialization.

A useful way to approach the design is to separate a **reference meaning**, a **candidate implementation**, a **validator or legality boundary**, and a **measurement loop**. This distinction prevents performance statistics from being confused with proof of correctness. It also makes the idea compatible with languages that have different overflow, exception, concurrency and foreign-function semantics.

## 2. Internal representation and interfaces

The following sketch is a proposed notation, not the syntax of an existing compiler framework. It is intentionally compact enough to serve as the start of a DSL or IR schema.

```text
fn filter(rows, predicate, schema)
  stage schema = link_known
  stage predicate = request_known
  specialize_at_link(filter, schema)
  specialize_at_runtime(filter$schema, predicate) if calls>500
```

This representation needs a stable identity scheme for values, functions, versions or resources mentioned in the sketch. An implementation should state which fields are **static semantics**, which are **runtime observations**, which are **guarded assumptions**, and which are **derived caches**. Blurring those categories is a common cause of invalidation bugs. Where the notation uses estimates or profiler data, it should record the collection epoch and target as part of the record.

## 3. Mechanism: from idea to executable system

A concrete execution sequence for the proposed design is:

1. **Perform binding-time analysis with conservative effect tracking.**
2. **Classify inputs by availability, mutability and confidentiality.**
3. **Estimate specialization benefit versus code growth and cache pressure.**
4. **Generate residual code and dependency/version records for each chosen stage.**
5. **Invalidate staged artifacts when an earlier assumed value changes.**

For a small compiler, make each step inspectable through a textual dump. The dump should include the source/IR revision, the selected candidate, the reason for selection, and any required assumptions. For a concurrent compiler, attach revision numbers to requests and results so that work produced for an obsolete program cannot be published accidentally.

## 4. Correctness contract and proof obligations

Moving computation earlier must not change observable effect timing or expose secrets in persistent artifacts. Specialization across nondeterministic or environmental inputs requires explicit policy and cache keys.

A reviewer should be able to answer four questions for every transformation: **(1)** Which source-level observations must remain identical? **(2)** Which assumptions are proved statically, and which are checked dynamically? **(3)** Where does execution go if a guard, resource request or validation fails? **(4)** What previously calculated facts and artifacts must be invalidated? A design that answers only the performance question is incomplete.

The practical verification ladder is: structural IR verification; type/effect/dominance checks where applicable; differential execution against a reference; randomized or metamorphic tests over adversarial inputs; and bounded symbolic or translation validation for a tractable subset. These methods have different guarantees. Tests can find counterexamples, not prove universal equivalence. SMT-based bounded validation is only as strong as its encoding and bounds. The artifact should describe which rung was achieved rather than presenting a Boolean `verified` flag with no scope.

## 5. Engineering costs and negative cases

- **Risk 1:** Code size grows combinatorially with many parameters.
- **Risk 2:** Stage errors can freeze configuration values unexpectedly.
- **Risk 3:** Build-time evaluation may perform unsafe I/O unless sandboxed.

Compatibility costs also matter. Debuggers, profilers, coverage tools, sanitizers, binary interfaces, exception unwinders and reproducible builds consume compiler metadata. If an optimization changes control locations, representation versions or calling conventions, downstream tooling needs enough provenance to stay correct.

## 6. Implementation roadmap

**Milestone A — semantic reference.** Build a deliberately slow baseline that implements the relevant behavior exactly. Derive executable test cases from the example and document its unsupported features. Begin with **Perform binding-time analysis with conservative effect tracking**. Make the baseline capable of dumping both input state and output observations.

**Milestone B — smallest useful optimization.** Implement one well-scoped transformation that exercises **Classify inputs by availability, mutability and confidentiality**. Prefer a single function or basic block, a single target and stable data structures. Add a verifier that runs before code is exposed to users.

**Milestone C — adaptive or incremental operation.** Introduce **Estimate specialization benefit versus code growth and cache pressure**. Track which facts the optimization consumes. Add rollback, fallback or invalidation behavior as dictated by the correctness contract and test it with deliberately stale inputs.

**Milestone D — integration and observability.** Complete **Invalidate staged artifacts when an earlier assumed value changes**. Provide an inspector for alternative decisions and an event log that connects the optimization request to generated code, invalidation and measurements. Run the same correctness corpus at each milestone; do not trade away coverage for incremental speed.

An implementation is ready for integration when the compiler can explain *why* an opportunity was accepted, *what* was changed, *which* observations remain equivalent, *how* it backs out safely, and *whether* the measured result justifies the cost.

## 7. Experimental evaluation

**Proposed experiment.** Implement staged regular-expression and query-processing kernels with build-, startup- and request-known parameters. Measure total lifetime CPU, code size and invalidation frequency.

Report three categories separately: **semantic validity** (differential mismatches, failed guards or validator verdicts), **compiler overhead** (wall time, allocated bytes, queue delay and metadata size), and **program outcome** (end-to-end latency/throughput, code size, energy or memory traffic as relevant). Include the reference baseline and at least one deliberately unfavorable workload. Use repeatable seeds and hold the target, runtime flags and environment constant when comparing variants.

Performance should be reported with a distribution or confidence interval rather than a single best run. If the compiler is adaptive, measure the whole lifetime including profiling, compilation, migration and fallback—not just warm steady state. If the system is multi-target, distinguish results caused by hardware capabilities from those caused by the compiler algorithm.

## 8. Design exercises and open questions

1. **Specify a contract.** Rewrite the core invariant above as a precondition, an observable-state relation and a postcondition. Identify one language feature (exceptions, floats, concurrency, reflection or FFI) that would invalidate an over-simple formulation.
2. **Build a minimal counterexample.** Choose the first engineering risk and construct a test that triggers it. Explain how the system will detect it and which fallback will execute.
3. **Define a budget.** Decide how much compiler CPU, memory, code-cache space and validation time this technique may consume before declining to optimize.
4. **Explore the frontier.** Could a staging controller partially evaluate a language interpreter into a compiler while retaining runtime adaptive compilation? Chapters 13, 14 and 28.

**Connections.** [Chapter 13 — Meta-Circular Compiler](13-meta-circular-compiler.md); [Chapter 14 — Interpreter as a Compiler](14-interpreter-as-a-compiler.md); [Chapter 28 — Runtime as the Optimizer](28-runtime-as-the-optimizer.md).

**Takeaway.** Proposed extension: make the boundary between compile-time and runtime computation adaptive and explicit. The next step is not to assume it wins, but to define the observable semantics, construct a small falsifiable implementation and measure its full lifecycle.

---

**Origin note:** This is a **proposed design developed for this dossier**, not a claim of global research priority or that no related technique has appeared in the literature. Terminology and implementation sketches here are conceptual until validated.
