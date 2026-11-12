# Chapter 05 — Reverse Compilation

**Part of:** *The Modern Compiler Dossier* · **Concept origin:** Expanded from supplied `COMPILER_IDEAS.md`, item 5 · **Primary area:** Semantic translation and multi-target lowering

> **Central proposition.** Compilation need not be one-way. A binary lifter can recover an analyzable representation from instructions, transform it, and generate code for the same or a different ISA. The challenge is semantic recovery, not just decoding opcodes: flags, aliasing, calling conventions and indirect jumps must be modeled.

## 1. Why this idea changes compiler design

Use a disassembler with explicit instruction semantics to lift each basic block into micro-operations. Maintain a machine-state tuple containing registers, memory, flags and control state, then normalize into SSA. Indirect control-flow recovery is conservative; unmatched regions remain interpreted or copied as opaque native stubs.

A useful way to approach the design is to separate a **reference meaning**, a **candidate implementation**, a **validator or legality boundary**, and a **measurement loop**. This distinction prevents performance statistics from being confused with proof of correctness. It also makes the idea compatible with languages that have different overflow, exception, concurrency and foreign-function semantics.

## 2. Internal representation and interfaces

The following sketch is a proposed notation, not the syntax of an existing compiler framework. It is intentionally compact enough to serve as the start of a DSL or IR schema.

```text
x86: add rax, [rbx+8]
=> %m1 = load64 %m0, add(%rbx,8)
   %r1 = add64 %rax0,%m1
   %flags1 = flags_add64(%rax0,%m1,%r1)
=> lower(%r1,%flags1) to aarch64
```

This representation needs a stable identity scheme for values, functions, versions or resources mentioned in the sketch. An implementation should state which fields are **static semantics**, which are **runtime observations**, which are **guarded assumptions**, and which are **derived caches**. Blurring those categories is a common cause of invalidation bugs. Where the notation uses estimates or profiler data, it should record the collection epoch and target as part of the record.

## 3. Mechanism: from idea to executable system

A concrete execution sequence for the proposed design is:

1. **Decode instructions while preserving original addresses and relocation provenance.**
2. **Lift all architecturally visible state, including partial-register semantics and condition codes.**
3. **Recover control flow with conservative indirect-target handling.**
4. **Run normalization and validation passes on the lifted IR.**
5. **Lower to the destination calling convention and insert runtime services for missing ISA features.**

For a small compiler, make each step inspectable through a textual dump. The dump should include the source/IR revision, the selected candidate, the reason for selection, and any required assumptions. For a concurrent compiler, attach revision numbers to requests and results so that work produced for an obsolete program cannot be published accidentally.

## 4. Correctness contract and proof obligations

For supported instructions, the lifted semantics must simulate the original architecture at defined observation points. Unknown self-modifying code, device access and privileged operations require explicit unsupported or emulated behavior.

A reviewer should be able to answer four questions for every transformation: **(1)** Which source-level observations must remain identical? **(2)** Which assumptions are proved statically, and which are checked dynamically? **(3)** Where does execution go if a guard, resource request or validation fails? **(4)** What previously calculated facts and artifacts must be invalidated? A design that answers only the performance question is incomplete.

The practical verification ladder is: structural IR verification; type/effect/dominance checks where applicable; differential execution against a reference; randomized or metamorphic tests over adversarial inputs; and bounded symbolic or translation validation for a tractable subset. These methods have different guarantees. Tests can find counterexamples, not prove universal equivalence. SMT-based bounded validation is only as strong as its encoding and bounds. The artifact should describe which rung was achieved rather than presenting a Boolean `verified` flag with no scope.

## 5. Engineering costs and negative cases

- **Risk 1:** Code/data ambiguity can make disassembly unsound.
- **Risk 2:** Cross-architecture atomic and memory-ordering differences are difficult.
- **Risk 3:** Exception unwinding, TLS and dynamic linking require more than machine instruction translation.

Compatibility costs also matter. Debuggers, profilers, coverage tools, sanitizers, binary interfaces, exception unwinders and reproducible builds consume compiler metadata. If an optimization changes control locations, representation versions or calling conventions, downstream tooling needs enough provenance to stay correct.

## 6. Implementation roadmap

**Milestone A — semantic reference.** Build a deliberately slow baseline that implements the relevant behavior exactly. Derive executable test cases from the example and document its unsupported features. Begin with **Decode instructions while preserving original addresses and relocation provenance**. Make the baseline capable of dumping both input state and output observations.

**Milestone B — smallest useful optimization.** Implement one well-scoped transformation that exercises **Lift all architecturally visible state, including partial-register semantics and condition codes**. Prefer a single function or basic block, a single target and stable data structures. Add a verifier that runs before code is exposed to users.

**Milestone C — adaptive or incremental operation.** Introduce **Recover control flow with conservative indirect-target handling**. Track which facts the optimization consumes. Add rollback, fallback or invalidation behavior as dictated by the correctness contract and test it with deliberately stale inputs.

**Milestone D — integration and observability.** Complete **Lower to the destination calling convention and insert runtime services for missing ISA features**. Provide an inspector for alternative decisions and an event log that connects the optimization request to generated code, invalidation and measurements. Run the same correctness corpus at each milestone; do not trade away coverage for incremental speed.

An implementation is ready for integration when the compiler can explain *why* an opportunity was accepted, *what* was changed, *which* observations remain equivalent, *how* it backs out safely, and *whether* the measured result justifies the cost.

## 7. Experimental evaluation

**Proposed experiment.** Lift and re-emit small integer kernels, then differential-test them under random register/memory states against a reference emulator. Track coverage of instructions, edge targets, flags and exceptions before attempting binaries.

Report three categories separately: **semantic validity** (differential mismatches, failed guards or validator verdicts), **compiler overhead** (wall time, allocated bytes, queue delay and metadata size), and **program outcome** (end-to-end latency/throughput, code size, energy or memory traffic as relevant). Include the reference baseline and at least one deliberately unfavorable workload. Use repeatable seeds and hold the target, runtime flags and environment constant when comparing variants.

Performance should be reported with a distribution or confidence interval rather than a single best run. If the compiler is adaptive, measure the whole lifetime including profiling, compilation, migration and fallback—not just warm steady state. If the system is multi-target, distinguish results caused by hardware capabilities from those caused by the compiler algorithm.

## 8. Design exercises and open questions

1. **Specify a contract.** Rewrite the core invariant above as a precondition, an observable-state relation and a postcondition. Identify one language feature (exceptions, floats, concurrency, reflection or FFI) that would invalidate an over-simple formulation.
2. **Build a minimal counterexample.** Choose the first engineering risk and construct a test that triggers it. Explain how the system will detect it and which fallback will execute.
3. **Define a budget.** Decide how much compiler CPU, memory, code-cache space and validation time this technique may consume before declining to optimize.
4. **Explore the frontier.** Can semantic fingerprints identify equivalent blocks across ISAs without trusting an imperfect decompiler? Chapters 6, 15, 39 and 45 are relevant.

**Connections.** [Chapter 6 — Bidirectional Compilers](06-bidirectional-compilers.md); [Chapter 15 — Semantic IR](15-semantic-ir.md); [Chapter 39 — Semantic Fingerprints and Metamorphic Compiler Testing](39-semantic-fingerprints-and-metamorphic-compiler-testing.md); [Chapter 45 — Digital-Twin Compiler for Hardware Decisions](45-digital-twin-compiler-for-hardware-decisions.md).

**Takeaway.** Compilation need not be one-way. The next step is not to assume it wins, but to define the observable semantics, construct a small falsifiable implementation and measure its full lifecycle.

---

**Source provenance:** Expanded from item **5**, “Reverse Compilation”, in [`COMPILER_IDEAS.md`](../sources/COMPILER_IDEAS.md). The source supplies the seed idea; architecture, pseudocode, contracts and experiments in this chapter are dossier elaborations. See [the source map](../appendices/SOURCE-MAP.md).
