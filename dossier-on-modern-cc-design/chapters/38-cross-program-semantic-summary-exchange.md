# Chapter 38 — Cross-Program Semantic Summary Exchange

**Part of:** *The Modern Compiler Dossier* · **Concept origin:** New proposal developed for this dossier · **Primary area:** IR knowledge and verification

> **Central proposition.** Proposed extension: share optimization-relevant knowledge across builds and binaries without sharing private source or execution traces. A compiler might learn that a public library function has a stable effect signature, allocation behavior or vectorizable contract from signed, versioned summaries, then use those facts during linking or JIT compilation.

## 1. Why this idea changes compiler design

Define portable summary capsules with symbol identity, version hash, target-independent semantics, conservative effect and alias facts, optional profile ranges and a verification signature. Consumers check the exact dependency and ABI versions before trusting a summary. Privacy-preserving aggregates are suggestions, not legality certificates.

A useful way to approach the design is to separate a **reference meaning**, a **candidate implementation**, a **validator or legality boundary**, and a **measurement loop**. This distinction prevents performance statistics from being confused with proof of correctness. It also makes the idea compatible with languages that have different overflow, exception, concurrency and foreign-function semantics.

## 2. Internal representation and interfaces

The following sketch is a proposed notation, not the syntax of an existing compiler framework. It is intentionally compact enough to serve as the start of a DSL or IR schema.

```text
summary lib.sort@H {
  effects:{Read(array),Write(array)}
  preconditions:{comparator_is_pure}
  properties:{permutation,sorted_on_return}
  target_independent:true
  evidence:{checked_contract_hash:C24}
}
```

This representation needs a stable identity scheme for values, functions, versions or resources mentioned in the sketch. An implementation should state which fields are **static semantics**, which are **runtime observations**, which are **guarded assumptions**, and which are **derived caches**. Blurring those categories is a common cause of invalidation bugs. Where the notation uses estimates or profiler data, it should record the collection epoch and target as part of the record.

## 3. Mechanism: from idea to executable system

A concrete execution sequence for the proposed design is:

1. **Define a schema for stable symbol, ABI and semantic identity.**
2. **Export conservative analysis summaries at library build boundaries.**
3. **Sign or hash summaries and bind them to the exact library artifact.**
4. **Import summaries for interprocedural optimization only after dependency verification.**
5. **Invalidate transitive consumers when a summary or library version changes.**

For a small compiler, make each step inspectable through a textual dump. The dump should include the source/IR revision, the selected candidate, the reason for selection, and any required assumptions. For a concurrent compiler, attach revision numbers to requests and results so that work produced for an obsolete program cannot be published accidentally.

## 4. Correctness contract and proof obligations

A summary may be trusted for legality only if backed by a sound derivation or validated contract. Privacy-filtered workload statistics cannot assert universal facts about unseen inputs.

A reviewer should be able to answer four questions for every transformation: **(1)** Which source-level observations must remain identical? **(2)** Which assumptions are proved statically, and which are checked dynamically? **(3)** Where does execution go if a guard, resource request or validation fails? **(4)** What previously calculated facts and artifacts must be invalidated? A design that answers only the performance question is incomplete.

The practical verification ladder is: structural IR verification; type/effect/dominance checks where applicable; differential execution against a reference; randomized or metamorphic tests over adversarial inputs; and bounded symbolic or translation validation for a tractable subset. These methods have different guarantees. Tests can find counterexamples, not prove universal equivalence. SMT-based bounded validation is only as strong as its encoding and bounds. The artifact should describe which rung was achieved rather than presenting a Boolean `verified` flag with no scope.

## 5. Engineering costs and negative cases

- **Risk 1:** Summary compatibility across compilers and languages is hard.
- **Risk 2:** Binary upgrades can invalidate hidden assumptions.
- **Risk 3:** Sharing profiles may leak workload information unless carefully aggregated.

Compatibility costs also matter. Debuggers, profilers, coverage tools, sanitizers, binary interfaces, exception unwinders and reproducible builds consume compiler metadata. If an optimization changes control locations, representation versions or calling conventions, downstream tooling needs enough provenance to stay correct.

## 6. Implementation roadmap

**Milestone A — semantic reference.** Build a deliberately slow baseline that implements the relevant behavior exactly. Derive executable test cases from the example and document its unsupported features. Begin with **Define a schema for stable symbol, ABI and semantic identity**. Make the baseline capable of dumping both input state and output observations.

**Milestone B — smallest useful optimization.** Implement one well-scoped transformation that exercises **Export conservative analysis summaries at library build boundaries**. Prefer a single function or basic block, a single target and stable data structures. Add a verifier that runs before code is exposed to users.

**Milestone C — adaptive or incremental operation.** Introduce **Sign or hash summaries and bind them to the exact library artifact**. Track which facts the optimization consumes. Add rollback, fallback or invalidation behavior as dictated by the correctness contract and test it with deliberately stale inputs.

**Milestone D — integration and observability.** Complete **Invalidate transitive consumers when a summary or library version changes**. Provide an inspector for alternative decisions and an event log that connects the optimization request to generated code, invalidation and measurements. Run the same correctness corpus at each milestone; do not trade away coverage for incremental speed.

An implementation is ready for integration when the compiler can explain *why* an opportunity was accepted, *what* was changed, *which* observations remain equivalent, *how* it backs out safely, and *whether* the measured result justifies the cost.

## 7. Experimental evaluation

**Proposed experiment.** Build two modules independently and link with/without effect and escape summaries. Compare optimization gains, rebuild invalidations and behavior when one dependency is intentionally changed.

Report three categories separately: **semantic validity** (differential mismatches, failed guards or validator verdicts), **compiler overhead** (wall time, allocated bytes, queue delay and metadata size), and **program outcome** (end-to-end latency/throughput, code size, energy or memory traffic as relevant). Include the reference baseline and at least one deliberately unfavorable workload. Use repeatable seeds and hold the target, runtime flags and environment constant when comparing variants.

Performance should be reported with a distribution or confidence interval rather than a single best run. If the compiler is adaptive, measure the whole lifetime including profiling, compilation, migration and fallback—not just warm steady state. If the system is multi-target, distinguish results caused by hardware capabilities from those caused by the compiler algorithm.

## 8. Design exercises and open questions

1. **Specify a contract.** Rewrite the core invariant above as a precondition, an observable-state relation and a postcondition. Identify one language feature (exceptions, floats, concurrency, reflection or FFI) that would invalidate an over-simple formulation.
2. **Build a minimal counterexample.** Choose the first engineering risk and construct a test that triggers it. Explain how the system will detect it and which fallback will execute.
3. **Define a budget.** Decide how much compiler CPU, memory, code-cache space and validation time this technique may consume before declining to optimize.
4. **Explore the frontier.** What minimal summary schema would allow independent compiler vendors to exchange useful reasoning without standardizing their entire IR? Chapters 6, 7, 29 and 44.

**Connections.** [Chapter 6 — Bidirectional Compilers](06-bidirectional-compilers.md); [Chapter 7 — Compiler as a Database](07-compiler-as-a-database.md); [Chapter 29 — Proof-Carrying IR and Certified Rewrite Contracts](29-proof-carrying-ir-and-certified-rewrite-contracts.md); [Chapter 44 — Hermetic Compilation Capsules](44-hermetic-compilation-capsules.md).

**Takeaway.** Proposed extension: share optimization-relevant knowledge across builds and binaries without sharing private source or execution traces. The next step is not to assume it wins, but to define the observable semantics, construct a small falsifiable implementation and measure its full lifecycle.

---

**Origin note:** This is a **proposed design developed for this dossier**, not a claim of global research priority or that no related technique has appeared in the literature. Terminology and implementation sketches here are conceptual until validated.
