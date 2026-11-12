# Chapter 34 — Capability-Secured Compiler IR

**Part of:** *The Modern Compiler Dossier* · **Concept origin:** New proposal developed for this dossier · **Primary area:** IR knowledge and verification

> **Central proposition.** Proposed extension: treat compiler passes and plugins as principals with narrowly scoped authority. A pass allowed to fold arithmetic must not silently rewrite security-sensitive control flow, access secrets in profiling data or mutate ABI contracts. Capabilities govern which IR objects and semantic operations a plugin may observe or change.

## 1. Why this idea changes compiler design

Wrap every IR read and edit in an explicit capability. A plugin receives a view containing only authorized functions and facts; mutations are submitted through a checked API rather than raw pointers. A policy engine validates capability provenance, revision and effect scope before accepting proposed transformations.

A useful way to approach the design is to separate a **reference meaning**, a **candidate implementation**, a **validator or legality boundary**, and a **measurement loop**. This distinction prevents performance statistics from being confused with proof of correctness. It also makes the idea compatible with languages that have different overflow, exception, concurrency and foreign-function semantics.

## 2. Internal representation and interfaces

The following sketch is a proposed notation, not the syntax of an existing compiler framework. It is intentionally compact enough to serve as the start of a DSL or IR schema.

```text
capability @foldpass {
  read: {values,types,consts}
  write: {pure_arith_nodes}
  deny: {io_effects,secret_taint,abi_metadata}
}
apply_rule(@foldpass, add(x,0)->x) -> checked_edit
```

This representation needs a stable identity scheme for values, functions, versions or resources mentioned in the sketch. An implementation should state which fields are **static semantics**, which are **runtime observations**, which are **guarded assumptions**, and which are **derived caches**. Blurring those categories is a common cause of invalidation bugs. Where the notation uses estimates or profiler data, it should record the collection epoch and target as part of the record.

## 3. Mechanism: from idea to executable system

A concrete execution sequence for the proposed design is:

1. **Classify IR entities and metadata by confidentiality and integrity boundaries.**
2. **Create capability tokens with declared read/write scopes.**
3. **Run extensible passes through an API that checks scope on every transaction.**
4. **Review mutation logs and semantic validation results before commit.**
5. **Revoke capabilities and invalidate outputs of compromised plugins.**

For a small compiler, make each step inspectable through a textual dump. The dump should include the source/IR revision, the selected candidate, the reason for selection, and any required assumptions. For a concurrent compiler, attach revision numbers to requests and results so that work produced for an obsolete program cannot be published accidentally.

## 4. Correctness contract and proof obligations

Authorization is separate from semantic correctness: an authorized optimization can still be wrong and needs normal validation. A sandbox must also constrain native memory access and file/network capabilities, not merely use in-memory IR tokens.

A reviewer should be able to answer four questions for every transformation: **(1)** Which source-level observations must remain identical? **(2)** Which assumptions are proved statically, and which are checked dynamically? **(3)** Where does execution go if a guard, resource request or validation fails? **(4)** What previously calculated facts and artifacts must be invalidated? A design that answers only the performance question is incomplete.

The practical verification ladder is: structural IR verification; type/effect/dominance checks where applicable; differential execution against a reference; randomized or metamorphic tests over adversarial inputs; and bounded symbolic or translation validation for a tractable subset. These methods have different guarantees. Tests can find counterexamples, not prove universal equivalence. SMT-based bounded validation is only as strong as its encoding and bounds. The artifact should describe which rung was achieved rather than presenting a Boolean `verified` flag with no scope.

## 5. Engineering costs and negative cases

- **Risk 1:** Fine-grained authorization adds overhead to hot compiler paths.
- **Risk 2:** Plugin isolation is difficult in a shared native process.
- **Risk 3:** Security labels can become stale after inlining or symbol merging.

Compatibility costs also matter. Debuggers, profilers, coverage tools, sanitizers, binary interfaces, exception unwinders and reproducible builds consume compiler metadata. If an optimization changes control locations, representation versions or calling conventions, downstream tooling needs enough provenance to stay correct.

## 6. Implementation roadmap

**Milestone A — semantic reference.** Build a deliberately slow baseline that implements the relevant behavior exactly. Derive executable test cases from the example and document its unsupported features. Begin with **Classify IR entities and metadata by confidentiality and integrity boundaries**. Make the baseline capable of dumping both input state and output observations.

**Milestone B — smallest useful optimization.** Implement one well-scoped transformation that exercises **Create capability tokens with declared read/write scopes**. Prefer a single function or basic block, a single target and stable data structures. Add a verifier that runs before code is exposed to users.

**Milestone C — adaptive or incremental operation.** Introduce **Run extensible passes through an API that checks scope on every transaction**. Track which facts the optimization consumes. Add rollback, fallback or invalidation behavior as dictated by the correctness contract and test it with deliberately stale inputs.

**Milestone D — integration and observability.** Complete **Revoke capabilities and invalidate outputs of compromised plugins**. Provide an inspector for alternative decisions and an event log that connects the optimization request to generated code, invalidation and measurements. Run the same correctness corpus at each milestone; do not trade away coverage for incremental speed.

An implementation is ready for integration when the compiler can explain *why* an opportunity was accepted, *what* was changed, *which* observations remain equivalent, *how* it backs out safely, and *whether* the measured result justifies the cost.

## 7. Experimental evaluation

**Proposed experiment.** Run benign, buggy and adversarial optimization plugins against a capability-scoped IR API. Measure unauthorized accesses blocked, legitimate pass throughput, auditability and correctness after revocation.

Report three categories separately: **semantic validity** (differential mismatches, failed guards or validator verdicts), **compiler overhead** (wall time, allocated bytes, queue delay and metadata size), and **program outcome** (end-to-end latency/throughput, code size, energy or memory traffic as relevant). Include the reference baseline and at least one deliberately unfavorable workload. Use repeatable seeds and hold the target, runtime flags and environment constant when comparing variants.

Performance should be reported with a distribution or confidence interval rather than a single best run. If the compiler is adaptive, measure the whole lifetime including profiling, compilation, migration and fallback—not just warm steady state. If the system is multi-target, distinguish results caused by hardware capabilities from those caused by the compiler algorithm.

## 8. Design exercises and open questions

1. **Specify a contract.** Rewrite the core invariant above as a precondition, an observable-state relation and a postcondition. Identify one language feature (exceptions, floats, concurrency, reflection or FFI) that would invalidate an over-simple formulation.
2. **Build a minimal counterexample.** Choose the first engineering risk and construct a test that triggers it. Explain how the system will detect it and which fallback will execute.
3. **Define a budget.** Decide how much compiler CPU, memory, code-cache space and validation time this technique may consume before declining to optimize.
4. **Explore the frontier.** Can the compiler safely outsource optimization to third parties while revealing only non-sensitive semantic summaries? Chapters 28, 29 and 38.

**Connections.** [Chapter 28 — Runtime as the Optimizer](28-runtime-as-the-optimizer.md); [Chapter 29 — Proof-Carrying IR and Certified Rewrite Contracts](29-proof-carrying-ir-and-certified-rewrite-contracts.md); [Chapter 38 — Cross-Program Semantic Summary Exchange](38-cross-program-semantic-summary-exchange.md).

**Takeaway.** Proposed extension: treat compiler passes and plugins as principals with narrowly scoped authority. The next step is not to assume it wins, but to define the observable semantics, construct a small falsifiable implementation and measure its full lifecycle.

---

**Origin note:** This is a **proposed design developed for this dossier**, not a claim of global research priority or that no related technique has appeared in the literature. Terminology and implementation sketches here are conceptual until validated.
