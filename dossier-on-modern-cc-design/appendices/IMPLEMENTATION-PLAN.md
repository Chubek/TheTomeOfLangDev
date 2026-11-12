# Implementation Plan — Research Milestones and Acceptance Gates

This plan is intentionally incremental. The dossier explores forty-five architectures; a realistic implementation should choose a small semantic substrate, implement it thoroughly, and add one idea at a time. Each milestone below has an observable result and a rejection condition.

## Phase A — Build a truth source

Implement a tiny evaluator for explicit-width integers, branches, calls, heap load/store and deterministic exceptions. Write down exact semantics for overflow, out-of-bounds, evaluation order and memory. Add randomized program generation and a deterministic state trace. **Gate:** all tests agree with an independent specification or hand-written test suite; failure diagnostics reproduce the input.

## Phase B — Build one strong IR

Introduce typed SSA, value and memory dependencies, effect summaries, stable provenance IDs and a verifier. Provide text dumps and round-trip parsing. Prefer simple mutable IR first unless snapshots are needed immediately. **Gate:** verifier rejects intentionally malformed CFGs, missing dominance, illegal effect reorderings and invalid memory uses.

## Phase C — Add a baseline backend

Produce runnable code or a fast interpreter for one target. Include ABI, stack maps and exception behavior where supported. **Gate:** differential execution agrees with the reference on random and adversarial programs under optimizations disabled.

## Phase D — Add runtime specialization

Implement type feedback, guard insertion, deopt materialization and two code versions. Force guard failure on every optimized path. **Gate:** optimized and reference traces agree including inlined frames and heap-visible effects, and memory reclamation never frees executing code.

## Phase E — Add bounded exploration

Implement ten arithmetic and control-flow rewrites with explicit preconditions. Add optional e-graph saturation on pure regions and a target-aware cost model; build a validator for the tractable subset. **Gate:** no invalid rewrite is accepted in a deliberately seeded mutant suite; unsupported cases fall back with clear diagnostics.

## Phase F — Add persistence and adaptivity

Introduce dependency-aware queries, immutable snapshots or transactions, workload profiles and a constrained compile queue. Apply a fixed compile CPU and code-cache budget. **Gate:** repeated edits, profile shifts and runtime invalidations preserve correctness while peak memory remains bounded.

## Phase G — Research extensions

Pick one of Chapters 29–45. Define a hypothesis, a valid baseline, a negative case and a reproducible measurement. Only combine proposals after their individual costs are understood. For example, pair transactional IR with proof-carrying rewrites before combining learned models, actor scheduling and digital twins.

## Continuous test suites

1. **Semantic:** differential tests; randomized generation; exception and memory-effect traces; adversarial overflow and corner inputs.
2. **Structural:** SSA dominance; CFG reachability; effect and memory ordering; invalidation consistency; stack-map and provenance integrity.
3. **Runtime:** forced deopt; version eviction; stale revision rejection; concurrent publication; FFI and debugger attachment when supported.
4. **Performance:** whole-lifecycle throughput; warm-up curves; p50/p99 latency; compile CPU; peak RSS; code-cache size; energy on appropriate targets.
5. **Reproducibility:** seeded fuzzing, controlled inputs, exact target and compiler options, preserved failing artifacts and artifact hashes.

## Recommended first prototype

Start with **Chapters 02, 03, 04, 07, 16, 17, 20 and 29**. These give a coherent experimental VM with interpreters, speculative SSA, explicit recovery, queryable facts, effects and validation. Defer cross-ISA lifting, multi-device scheduling and hardware simulation until the core runtime can reliably switch and invalidate code versions. This ordering minimizes the number of independent correctness models in the first prototype.
