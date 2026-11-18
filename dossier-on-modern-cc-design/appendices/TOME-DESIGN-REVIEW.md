# Design review: from dossier proposals to compiler contracts

The dossier's 45 chapters examine architectural choices, not a specification
that one compiler must implement. This review connects those choices to *The
Tome of Programming Language Development*. It also gives a worked example for
the [system blueprint](SYSTEM-BLUEPRINT.md): a checked, versioned optimization
whose failure can be tested without an industrial runtime. References to
“Tome” are chapter numbers in the LaTeX manuscript.

## A small executable contract

Use a source language with signed 32-bit integers. Addition traps on overflow;
`emit` appends to an observable trace. Inputs are immutable throughout an
activation. The evaluator has no concurrent execution, I/O other than `emit`,
or resource failures. Define `step` as follows:

```text
step(x):
    emit("enter")
    r = checked_add_i32(x, 1)
    emit("done")
    return r
```

Record both the final result (return or overflow trap) and the ordered sequence
of events. A profile suggests that calls with `x = INT_MAX` are rare. An
optimized artifact may use a target operation with wrapping arithmetic if
it guards `x != INT_MAX`. Before choosing a guard location, assign each
reference instruction a semantic checkpoint:

| Checkpoint | Observable prefix | State needed to continue |
| --- | --- | --- |
| `entry` | None | `x` |
| `after_enter` | `["enter"]` | `x` |
| `after_add` | `["enter"]` | `r` |
| `return` | `["enter", "done"]` | `r` |

If the guard is after the first `emit`, a failing guard must resume at
`after_enter` with `x`. Resuming at `entry` emits `"enter"` twice. Resuming
at `after_add` silently bypasses the specified overflow trap. In the
simple evaluator the trace is held by the runtime, so a frame map describes
the checkpoint and live values, not a private copy of the trace. The state
relation nonetheless requires that the visible prefixes already agree.

On success, a structural check establishes that the guard dominates the
wrapping add. A bit-vector obligation shows that the sign-extended mathematical
sum and the sign-extended wrapped result agree under the guard. On failure,
the semantic checkpoint and frame map are checked separately. Arithmetic
validation alone is not enough: it cannot detect a duplicated event or an
incorrect resume point. Use the first failing test to drive metadata design,
not to change the evaluator's definition of the effect order.

Regression inputs are `0`, `INT_MIN`, `INT_MAX - 1`, and `INT_MAX`. Also
provide a test mode that forces a transfer even when the arithmetic guard
holds; it verifies that reconstructing a state for ordinary inputs preserves
its suffix as well. A force flag belongs in the test harness and is not
part of the production language or a premise of the proof.

## Publication, retirement, and provenance

The evaluator has a stable function ID. An artifact's identity also records
the source revision, semantic schema, target/ABI, and dependency versions.
Profile data can influence what to propose; it is not a validity certificate.
Keep an interpreter artifact available and publish the optimized candidate
only when its dependencies still match. In a concurrent implementation,
the dependency check and installation must share a lock or an equivalent
linearization protocol. Checking first and performing an unrelated later
dispatch store admits stale code.

For the initial prototype, pin a version while an activation holds a code
address or its frame map. Invalidate entry for future calls before reclaiming
old metadata, and distinguish **retiring** code from **freeing** it. If
invalidation makes an in-flight assumption false, pinning alone is not enough:
use a guard, safepoint, or stricter language policy that keeps active
activations on immutable revisions. The example above uses the last policy.
An optional replay record contains the version, the checkpoint, the guard
outcome and the input. This is enough for the deterministic example; it
does not promise replay of external I/O or an arbitrary thread schedule.

## Crosswalk and acceptance evidence

### Adaptive execution and recovery

| Dossier chapters | Read in the Tome | What to check |
| --- | --- | --- |
| [01 Continuous compilation](../chapters/01-continuous-evolutionary-compilation.md), [02 Multi-level interpreter](../chapters/02-multi-level-interpreter.md), [24 Self-modifying interpreter](../chapters/24-self-modifying-interpreter.md), [28 Runtime as optimizer](../chapters/28-runtime-as-the-optimizer.md) | 241–245, 251–254 | Apply identical inputs to each tier. Separate execution savings from compilation and instrumentation time. |
| [03 Speculative IR](../chapters/03-speculative-ir.md), [04 Deoptimization as IR](../chapters/04-deoptimization-as-an-ir-operation.md), [35 Replayable deoptimization](../chapters/35-replayable-deoptimization-time-machine.md) | 194, 245, 255–256, 258 | Force failed guards at every supported checkpoint and compare effects as well as values. Replay is a separate feature with separate coverage. |
| [05 Reverse compilation](../chapters/05-reverse-compilation.md), [06 Bidirectional compilation](../chapters/06-bidirectional-compilers.md) | 137–140, 200, 226 | Keep binary lifting, recovering a semantic approximation, and editing a source view distinct. Equal machine behavior does not imply recoverable source syntax. |
| [12 Self-optimizing interpreter](../chapters/12-self-optimizing-interpreter.md), [13 Meta-circular compiler](../chapters/13-meta-circular-compiler.md), [14 Interpreter as compiler](../chapters/14-interpreter-as-a-compiler.md) | 162–170, 180, 243, 253 | Compare specialization with and without profiling. First verify the evaluator's observations independently; bootstrapping does not establish correctness. |

### Program knowledge and validation

| Dossier chapters | Read in the Tome | What to check |
| --- | --- | --- |
| [07 Compiler as database](../chapters/07-compiler-as-a-database.md), [08 Demand-driven compilation](../chapters/08-demand-driven-compilation.md), [09 Query-based optimization](../chapters/09-query-based-optimization.md), [22 Reactive compilation](../chapters/22-incremental-compiler-as-a-reactive-system.md) | 201–210, 259 | Compare cached answers against a from-scratch recomputation after edits, including changed cache dependencies. |
| [10 Equality saturation](../chapters/10-equality-saturation-compiler.md), [29 Certified rewrite contracts](../chapters/29-proof-carrying-ir-and-certified-rewrite-contracts.md), [32 Counterexample-guided synthesis](../chapters/32-counterexample-guided-compiler-synthesis.md), [37 Constraint solving](../chapters/37-compiler-as-a-constraint-solver.md) | 199, 217–224, 239–240 | Run rewrites over a specified pure algebra first. Record proof bounds, timeout, and unsupported IR explicitly; model costs only among legal variants. |
| [15 Semantic IR](../chapters/15-semantic-ir.md), [16 Effect-aware IR](../chapters/16-effect-aware-ir.md), [17 Explicit memory IR](../chapters/17-memory-as-an-explicit-ir.md), [18 Time-aware IR](../chapters/18-time-aware-ir.md), [19 Probabilistic IR](../chapters/19-probabilistic-ir.md) | 147, 192–197, 205, 212 | Define the observation before designing transformations. Cost metadata and measured distributions are not automatically semantic contracts. |
| [30 Transactional transformations](../chapters/30-transactional-compiler-transformations.md), [39 Semantic fingerprints](../chapters/39-semantic-fingerprints-and-metamorphic-compiler-testing.md), [40 Self-healing pipelines](../chapters/40-self-healing-compiler-pipeline.md) | 210, 219–220, 258–260 | Seed a wrong rewrite and an incomplete effect summary. Reject or fall back without leaving derived facts cached for an abandoned candidate. |

### Deployment, targets, and policy

| Dossier chapters | Read in the Tome | What to check |
| --- | --- | --- |
| [20 Versioned IR](../chapters/20-versioned-ir.md), [21 Compiler garbage collection](../chapters/21-compiler-garbage-collection.md), [23 Actor compilers](../chapters/23-compiler-as-an-actor-system.md), [38 Semantic summary exchange](../chapters/38-cross-program-semantic-summary-exchange.md) | 235, 245, 255, 259 | Distinguish source, IR and executable versions. Test concurrent readers, lifetime dependencies, and cache invalidation before adding distributed workers. |
| [25 Heterogeneous IR](../chapters/25-heterogeneous-ir.md), [26 Spatial compilation](../chapters/26-spatial-compiler.md), [36 Energy and thermal awareness](../chapters/36-energy-and-thermal-aware-compilation.md), [45 Digital-twin compiler](../chapters/45-digital-twin-compiler-for-hardware-decisions.md) | 197, 223, 229–230, 247 | Include transfer/synchronization cost. Validate ranking on measured target runs; report simulator bias separately from noise and run-to-run variation. |
| [11 Learned costs](../chapters/11-compiler-with-a-learned-cost-model.md), [27 Explicit uncertainty](../chapters/27-compiler-with-explicit-uncertainty.md), [31 Causal profiling](../chapters/31-causal-profiling-ir.md), [33 Budget-aware optimization](../chapters/33-budget-aware-optimization-market.md), [41 Granularity adaptation](../chapters/41-granularity-adaptive-optimization.md) | 229, 238–239, 251, 257, 260 | Use workload shifts and unseen instances. Test that stale or unconfident predictions choose the baseline; report compile CPU, peak code size, and tail latency. |
| [34 Capability-secured IR](../chapters/34-capability-secured-compiler-ir.md), [42 Adaptive ABI negotiation](../chapters/42-adaptive-abi-negotiation.md), [43 Staging controller](../chapters/43-compile-time-run-time-staging-controller.md), [44 Hermetic capsules](../chapters/44-hermetic-compilation-capsules.md) | 149, 180, 227–228, 249–250, 259 | Inspect actual dependencies and trust boundaries. Verify ABI compatibility independently of an adapter's measured speed. Artifact reproducibility is not semantic correctness. |

## An experiment that could falsify the design

Implement three variants: the reference evaluator alone, fixed baseline code,
and baseline plus guarded optimization. Use identical bytecode, trace
semantics and input distributions. First run a correctness gate with the
observable trace enabled and all guard paths taken. For performance,
separate cold runs from steady state, report compilation and instrumentation
overheads, distinguish CPU time from elapsed time when compiling in the
background, and measure code-cache residency. Include a short-lived workload,
a hot stable workload, and a late phase change that makes the prior profile
unhelpful. Compare end-to-end costs, not just speed on the successful guard
path. Declare failure if any observable trace differs, or if the adaptive
version does not recover its extra cost on the intended workload under the
same resource limits. This is an experiment design, not a report of runs.

Useful points of comparison in the local corpus include *Copy-and-Patch
Compilation* ([Xu and Kjolstad](../../sources/copy-and-patch-jit.txt)) for fast
baseline emission, *On-Stack Replacement, Distilled*
([D'Elia and Demetrescu](../../sources/osr-distilled-jit.txt)) for the
state-transfer problem, and *Formal Verification of Just-in-Time Compilation*
([Barrière](../../sources/formal-verif-jit.txt)) for mechanized
correctness arguments. None, by itself, establishes the correctness or
profitability of the combined architecture above.
