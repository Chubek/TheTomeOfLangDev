# System Blueprint — An Evolving, Verifiable Compiler Runtime

The concluding section of the source document imagines a runtime-managed graph of semantic IR, SSA, memory/effect state, profiles, guards, versions and native code. This appendix turns that seed into a staged integration plan, keeping semantic meaning and deployment policy separate.

## A six-plane architecture

```text
Source / DSL / external binary
            |
            v
 [1] SEMANTICS  -- typed core IR, effects, memory model, reference evaluator
            |
            v
 [2] KNOWLEDGE  -- versioned IR relations, analyses, provenance, summaries
            |
            v
 [3] EXPLORATION -- rewrites, e-graphs, synthesis, candidate variants
            |
            v
 [4] ASSURANCE  -- verifier, guards, snapshots, translation validation
            |
            v
 [5] EXECUTION  -- bytecode, native code, heterogeneous runtime, OSR
            |
            v
 [6] ADAPTATION -- profiles, causal experiments, budgets, invalidation
            |                     |
            +-------- feedback ---+
```

The arrows indicate principal data flow, not mandatory process boundaries. A small implementation may be a single address space with immutable data records. An ambitious one may use actors or compiler services, but distributed architecture should be a later optimization, not a starting requirement.

## Plane 1: the semantic core

Start with exact language semantics for arithmetic, memory, calls, exceptions and concurrency supported by the reference interpreter. A *semantic operation* has a type, an effect signature and a defined observation relation. Keep source provenance and a stable identity for functions and blocks. The semantic layer must not contain machine-specific profitability assumptions.

A useful minimal dialect includes constants, arithmetic with explicitly selected overflow behavior, comparison, branching, calls, values, memory access and side effects. Add allocation, exception unwinding and coroutines only after the reference interpreter and differential tests work. Semantic IR is not necessarily the best final optimizing representation; it is the common explanation of what every lowering must preserve.

## Plane 2: knowledge and revisioning

Maintain a graph of primary facts (`Defines`, `Uses`, `Blocks`, `Edges`, `Type`, `Effect`, `Origin`) and derived facts (`Dominates`, `MayAlias`, `Hotness`, `Cost`). Track which facts were consumed by each analysis. Store program revisions as immutable snapshots or verified transactions. Where analysis caches rely on environmental properties, include target, optimization flags and dependency versions in cache keys.

The database is a logical model: its underlying implementation can be index arrays, a graph store or a relational runtime. Data models should be chosen against profile measurements, not by committing prematurely to SQL or Datalog everywhere.

## Plane 3: exploration of legal alternatives

Run cheap deterministic simplifications first, then bounded rewrite exploration or e-graph saturation on selected regions. Learned models rank candidates **only after** legality is established. For more ambitious work, a synthesizer may produce sequences from instruction semantics, and a constraint solver may search over registers, schedules or device placement. Each alternative retains its semantic root, target requirements and budget estimate.

The runtime sends exploration requests with deadlines and code-size limits. An optimization market or scheduler compares expected benefit against time to compile and likely remaining executions. This makes “do nothing” an explicit permitted result.

## Plane 4: assurance and recovery

Before a candidate becomes executable, check structural invariants, semantic refinement for supported forms, required guard dominance, and materialization recipes for every deoptimization point. Record proof or validation *scope* in metadata. If validation fails, abort the transaction; keep the previous artifact. Snapshot maps must identify all live locals, inlined frames and virtual objects needed to resume the reference interpreter. A proven rule is different from a passing test suite, and both are different from a predicted speedup.

## Plane 5: execution and resource mapping

A stable function identity resolves through a dispatch cell to a valid interpreter or native version. OSR entry and exit require explicit frame-transfer maps. The machine backend handles ABI constraints, register allocation, instruction scheduling, unwind tables and stack maps. Heterogeneous support additionally requires explicit data transfers and synchronization. Publish code atomically and retain old versions until no active thread or tooling reference can reach them.

## Plane 6: adaptation

Profile runtime behavior with bounded overhead, record confidence and epoch, and distinguish observations from assumptions. The runtime may request new code, new data layouts or code-cache retirement. Use minimum dwell times and benefit thresholds so small workload changes do not cause thrashing. Measured outcomes update the optimization policy and trigger experiments but never relax the semantic correctness contract.

## Critical interfaces

```text
SemanticAPI:    evaluate(revision, inputs) -> observations
QueryAPI:       facts(revision, query) -> data + dependencies
ProposeAPI:     transform(revision, rule_or_plan) -> candidate
ValidateAPI:    check(before, after, semantics, bound) -> scoped_result
CompileAPI:     compile(candidate, target, budget) -> artifact + metadata
PublishAPI:     install(artifact, guards, revision) -> version_id | reject
RuntimeAPI:     profile(version_id, window) -> distributions
RecoveryAPI:    deopt(frame, descriptor) -> reference_state
```

These are **interface sketches**, not actual standardized APIs. For a proof-of-concept, `ValidateAPI` can initially provide only structural, typed and differential validation; it must report that limitation accurately.

## A staged vertical slice

**Stage 0: meaning.** Implement a tiny typed bytecode VM with a reference evaluator. Produce deterministic trace outputs including exceptions and memory writes.

**Stage 1: one optimized representation.** Lower to SSA, add use-def chains and a verifier, then compile arithmetic to one target or execute optimized SSA in another interpreter.

**Stage 2: speculation and recovery.** Add profile-guided integer specialization, guards, deopt descriptors and a test that forces every guard to fail. Never continue without correct frame reconstruction.

**Stage 3: persistent versions.** Add immutable revisions, code variants, revisioned dispatcher and artifact reclamation with concurrency tests.

**Stage 4: exploration.** Add declarative rewrites/equality saturation on pure regions, candidate cost ranking and scoped translation validation.

**Stage 5: adaptive policy.** Add runtime budgets, measured cost, hysteresis and code-cache pressure, then compare full-life performance with a nonadaptive baseline.

**Stage 6: research extensions.** Evaluate causally informed profiles, resource constraints, cross-program summaries, proof-carrying artifacts or digital-twin ranking one at a time. Do not introduce all at once or experiments cannot attribute outcomes.

See the [Tome design review](TOME-DESIGN-REVIEW.md) for a concrete Stage 2–3
example: the exact checkpoint at which a failed guard must resume, the
metadata a live activation pins, and the tests that distinguish those
correctness obligations from performance measurements.

## Scope and non-goals

A self-hosted optimizing compiler, a portable binary lifter, a multi-device scheduler and a formally validated runtime are each major independent projects. This blueprint makes them interoperable through contracts; it does not assert they can all be completed as one minimal prototype. Concurrency and FFI substantially increase proof and recovery obligations. Focus on a small semantics and one useful path before broadening target support.
