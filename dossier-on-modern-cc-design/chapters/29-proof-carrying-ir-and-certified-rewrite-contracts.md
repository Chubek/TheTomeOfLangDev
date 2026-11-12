# Chapter 29 — Proof-Carrying IR and Certified Rewrite Contracts

**Part of:** *The Modern Compiler Dossier* · **Concept origin:** New proposal developed for this dossier · **Primary area:** IR knowledge and verification

> **Central proposition.** Proposed extension: every transformational stage emits machine-checkable evidence that its output refines its input. Rather than asking users to trust a large optimizer, validate small local contracts at boundaries. The proof object need not be a theorem proof in every case; it may be an SMT-checkable formula, an equivalence witness or a conservative validation result.

## 1. Why this idea changes compiler design

Each rewrite declares a semantic relation, preconditions and side-effect frame. A trusted validator checks the relation under the source IR semantics; downstream stages preserve the validation certificate hash alongside the new artifact. Unsupported constructs do not receive a fictional proof: they fall back, use restricted validators or remain explicitly unverified.

A useful way to approach the design is to separate a **reference meaning**, a **candidate implementation**, a **validator or legality boundary**, and a **measurement loop**. This distinction prevents performance statistics from being confused with proof of correctness. It also makes the idea compatible with languages that have different overflow, exception, concurrency and foreign-function semantics.

## 2. Internal representation and interfaces

The following sketch is a proposed notation, not the syntax of an existing compiler framework. It is intentionally compact enough to serve as the start of a DSL or IR schema.

```text
contract reassociate_add {
  before: add(add(a,b),c)
  after:  add(a,add(b,c))
  precondition: math_integers || fast_math_reassoc
  ensures: observably_equivalent(before,after)
}
certificate = validate(contract, source_semantics)
```

This representation needs a stable identity scheme for values, functions, versions or resources mentioned in the sketch. An implementation should state which fields are **static semantics**, which are **runtime observations**, which are **guarded assumptions**, and which are **derived caches**. Blurring those categories is a common cause of invalidation bugs. Where the notation uses estimates or profiler data, it should record the collection epoch and target as part of the record.

## 3. Mechanism: from idea to executable system

A concrete execution sequence for the proposed design is:

1. **Specify formal meaning for a tractable core subset of the IR.**
2. **Associate each rewrite with proof obligations for types, values, memory and effects.**
3. **Use SMT or an independently checked rule proof for local rewrites.**
4. **Store validated contracts by rule hash, target semantics and options.**
5. **Reject or quarantine optimizations whose proof obligations fail or time out.**

For a small compiler, make each step inspectable through a textual dump. The dump should include the source/IR revision, the selected candidate, the reason for selection, and any required assumptions. For a concurrent compiler, attach revision numbers to requests and results so that work produced for an obsolete program cannot be published accidentally.

## 4. Correctness contract and proof obligations

A successful bounded translation check proves only the bounded property actually checked. Floating-point, undefined behavior, concurrency and unmodeled external calls must be represented accurately or excluded from a claimed guarantee.

A reviewer should be able to answer four questions for every transformation: **(1)** Which source-level observations must remain identical? **(2)** Which assumptions are proved statically, and which are checked dynamically? **(3)** Where does execution go if a guard, resource request or validation fails? **(4)** What previously calculated facts and artifacts must be invalidated? A design that answers only the performance question is incomplete.

The practical verification ladder is: structural IR verification; type/effect/dominance checks where applicable; differential execution against a reference; randomized or metamorphic tests over adversarial inputs; and bounded symbolic or translation validation for a tractable subset. These methods have different guarantees. Tests can find counterexamples, not prove universal equivalence. SMT-based bounded validation is only as strong as its encoding and bounds. The artifact should describe which rung was achieved rather than presenting a Boolean `verified` flag with no scope.

## 5. Engineering costs and negative cases

- **Risk 1:** Full formal semantics are costly to maintain.
- **Risk 2:** SMT solvers can time out and produce incomplete coverage.
- **Risk 3:** A trusted checker may accidentally share the optimizer’s semantic bug.

Compatibility costs also matter. Debuggers, profilers, coverage tools, sanitizers, binary interfaces, exception unwinders and reproducible builds consume compiler metadata. If an optimization changes control locations, representation versions or calling conventions, downstream tooling needs enough provenance to stay correct.

## 6. Implementation roadmap

**Milestone A — semantic reference.** Build a deliberately slow baseline that implements the relevant behavior exactly. Derive executable test cases from the example and document its unsupported features. Begin with **Specify formal meaning for a tractable core subset of the IR**. Make the baseline capable of dumping both input state and output observations.

**Milestone B — smallest useful optimization.** Implement one well-scoped transformation that exercises **Associate each rewrite with proof obligations for types, values, memory and effects**. Prefer a single function or basic block, a single target and stable data structures. Add a verifier that runs before code is exposed to users.

**Milestone C — adaptive or incremental operation.** Introduce **Use SMT or an independently checked rule proof for local rewrites**. Track which facts the optimization consumes. Add rollback, fallback or invalidation behavior as dictated by the correctness contract and test it with deliberately stale inputs.

**Milestone D — integration and observability.** Complete **Reject or quarantine optimizations whose proof obligations fail or time out**. Provide an inspector for alternative decisions and an event log that connects the optimization request to generated code, invalidation and measurements. Run the same correctness corpus at each milestone; do not trade away coverage for incremental speed.

An implementation is ready for integration when the compiler can explain *why* an opportunity was accepted, *what* was changed, *which* observations remain equivalent, *how* it backs out safely, and *whether* the measured result justifies the cost.

## 7. Experimental evaluation

**Proposed experiment.** Start with 32-bit arithmetic rewrites and memory-free SSA. Generate thousands of random candidate rules, intentionally inject wrong rewrites and measure detected errors, checker cost and unsupported cases.

Report three categories separately: **semantic validity** (differential mismatches, failed guards or validator verdicts), **compiler overhead** (wall time, allocated bytes, queue delay and metadata size), and **program outcome** (end-to-end latency/throughput, code size, energy or memory traffic as relevant). Include the reference baseline and at least one deliberately unfavorable workload. Use repeatable seeds and hold the target, runtime flags and environment constant when comparing variants.

Performance should be reported with a distribution or confidence interval rather than a single best run. If the compiler is adaptive, measure the whole lifetime including profiling, compilation, migration and fallback—not just warm steady state. If the system is multi-target, distinguish results caused by hardware capabilities from those caused by the compiler algorithm.

## 8. Design exercises and open questions

1. **Specify a contract.** Rewrite the core invariant above as a precondition, an observable-state relation and a postcondition. Identify one language feature (exceptions, floats, concurrency, reflection or FFI) that would invalidate an over-simple formulation.
2. **Build a minimal counterexample.** Choose the first engineering risk and construct a test that triggers it. Explain how the system will detect it and which fallback will execute.
3. **Define a budget.** Decide how much compiler CPU, memory, code-cache space and validation time this technique may consume before declining to optimize.
4. **Explore the frontier.** Can proof metadata survive inlining and register allocation as composable certificates without requiring whole-program theorem proving? Chapters 3, 9, 10 and 39.

**Connections.** [Chapter 3 — Speculative IR](03-speculative-ir.md); [Chapter 9 — Query-Based Optimization](09-query-based-optimization.md); [Chapter 10 — Equality Saturation Compiler](10-equality-saturation-compiler.md); [Chapter 39 — Semantic Fingerprints and Metamorphic Compiler Testing](39-semantic-fingerprints-and-metamorphic-compiler-testing.md).

**Takeaway.** Proposed extension: every transformational stage emits machine-checkable evidence that its output refines its input. The next step is not to assume it wins, but to define the observable semantics, construct a small falsifiable implementation and measure its full lifecycle.

---

**Origin note:** This is a **proposed design developed for this dossier**, not a claim of global research priority or that no related technique has appeared in the literature. Terminology and implementation sketches here are conceptual until validated.
