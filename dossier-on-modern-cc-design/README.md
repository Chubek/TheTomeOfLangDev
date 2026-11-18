# The Modern Compiler Dossier

**45 Markdown chapters · 28 source-derived explorations + 17 additional dossier proposals**

This collection expands the attached 28-item list of compiler architecture ideas into a structured research and engineering dossier. Chapters **01–28** stay rooted in the supplied `COMPILER_IDEAS.md`; Chapters **29–45** develop additional concepts and integrations. The latter are described as **proposals developed for this dossier**, not claimed as globally unprecedented inventions.

The goal is not to prescribe a universal compiler. It is to turn each hypothesis into an inspectable architecture, a candidate IR, correctness obligations, a prototype plan, failure modes and an experiment that could falsify its usefulness. Illustrative code is **pseudocode**, not a claim of an existing implementable grammar or tested production system.

## How to read it

Read [the preface](PREFACE.md) for the shared vocabulary and boundaries. Follow the [chapters](chapters/) in order for a broad survey, or jump to one of these study tracks:

- **Managed VM and JIT:** 01 → 02 → 03 → 04 → 12 → 20 → 24 → 28 → 35 → 41.
- **IR, optimization and proof:** 07 → 09 → 10 → 15 → 16 → 17 → 29 → 30 → 32 → 39.
- **Adaptive systems and hardware:** 11 → 18 → 19 → 25 → 26 → 27 → 31 → 33 → 36 → 37 → 45.
- **Infrastructure and deployment:** 05 → 06 → 14 → 21 → 22 → 23 → 34 → 38 → 40 → 42 → 43 → 44.

Read [the system blueprint](appendices/SYSTEM-BLUEPRINT.md) for a suggested integrated architecture, [the implementation plan](appendices/IMPLEMENTATION-PLAN.md) for a staged project, and [the glossary](appendices/GLOSSARY.md) for technical terms. The [source map](appendices/SOURCE-MAP.md) ties the original 28 ideas to specific files. The [reading list](appendices/REFERENCES.md) separates published foundations from our proposed extensions.

The [Tome design review](appendices/TOME-DESIGN-REVIEW.md) connects all 45
chapters to the expanded book. It works through one guard and its fallback,
then separates state-transfer checks, artifact publication, and performance
experiments.

## Table of contents

### I. Adaptive execution and recovery

- [01. Continuous / Evolutionary Compilation](chapters/01-continuous-evolutionary-compilation.md) 
- [02. Multi-Level Interpreter](chapters/02-multi-level-interpreter.md) 
- [03. Speculative IR](chapters/03-speculative-ir.md) 
- [04. Deoptimization as an IR Operation](chapters/04-deoptimization-as-an-ir-operation.md) 
- [05. Reverse Compilation](chapters/05-reverse-compilation.md) 
- [06. Bidirectional Compilers](chapters/06-bidirectional-compilers.md) 

### II. Program knowledge and optimization

- [07. Compiler as a Database](chapters/07-compiler-as-a-database.md) 
- [08. Demand-Driven Compilation](chapters/08-demand-driven-compilation.md) 
- [09. Query-Based Optimization](chapters/09-query-based-optimization.md) 
- [10. Equality Saturation Compiler](chapters/10-equality-saturation-compiler.md) 
- [11. Compiler with a Learned Cost Model](chapters/11-compiler-with-a-learned-cost-model.md) 

### III. Language semantics and interpreters

- [12. Self-Optimizing Interpreter](chapters/12-self-optimizing-interpreter.md) 
- [13. Meta-Circular Compiler](chapters/13-meta-circular-compiler.md) 
- [14. Interpreter as a Compiler](chapters/14-interpreter-as-a-compiler.md) 
- [15. Semantic IR](chapters/15-semantic-ir.md) 
- [16. Effect-Aware IR](chapters/16-effect-aware-ir.md) 
- [17. Memory as an Explicit IR](chapters/17-memory-as-an-explicit-ir.md) 
- [18. Time-Aware IR](chapters/18-time-aware-ir.md) 
- [19. Probabilistic IR](chapters/19-probabilistic-ir.md) 

### IV. Live compilation infrastructures

- [20. Versioned IR](chapters/20-versioned-ir.md) 
- [21. Compiler Garbage Collection](chapters/21-compiler-garbage-collection.md) 
- [22. Incremental Compiler as a Reactive System](chapters/22-incremental-compiler-as-a-reactive-system.md) 
- [23. Compiler as an Actor System](chapters/23-compiler-as-an-actor-system.md) 
- [24. Self-Modifying Interpreter](chapters/24-self-modifying-interpreter.md) 
- [25. Heterogeneous IR](chapters/25-heterogeneous-ir.md) 
- [26. Spatial Compiler](chapters/26-spatial-compiler.md) 
- [27. Compiler with Explicit Uncertainty](chapters/27-compiler-with-explicit-uncertainty.md) 
- [28. Runtime as the Optimizer](chapters/28-runtime-as-the-optimizer.md) 

### V. New proposals: trust and experimental systems

- [29. Proof-Carrying IR and Certified Rewrite Contracts](chapters/29-proof-carrying-ir-and-certified-rewrite-contracts.md) *(dossier proposal)*
- [30. Transactional Compiler Transformations](chapters/30-transactional-compiler-transformations.md) *(dossier proposal)*
- [31. Causal Profiling IR](chapters/31-causal-profiling-ir.md) *(dossier proposal)*
- [32. Counterexample-Guided Compiler Synthesis](chapters/32-counterexample-guided-compiler-synthesis.md) *(dossier proposal)*
- [33. Budget-Aware Optimization Market](chapters/33-budget-aware-optimization-market.md) *(dossier proposal)*
- [34. Capability-Secured Compiler IR](chapters/34-capability-secured-compiler-ir.md) *(dossier proposal)*
- [35. Replayable Deoptimization Time Machine](chapters/35-replayable-deoptimization-time-machine.md) *(dossier proposal)*

### VI. New proposals: resources, deployment and synthesis

- [36. Energy- and Thermal-Aware Compilation](chapters/36-energy-and-thermal-aware-compilation.md) *(dossier proposal)*
- [37. Compiler as a Constraint Solver](chapters/37-compiler-as-a-constraint-solver.md) *(dossier proposal)*
- [38. Cross-Program Semantic Summary Exchange](chapters/38-cross-program-semantic-summary-exchange.md) *(dossier proposal)*
- [39. Semantic Fingerprints and Metamorphic Compiler Testing](chapters/39-semantic-fingerprints-and-metamorphic-compiler-testing.md) *(dossier proposal)*
- [40. Self-Healing Compiler Pipeline](chapters/40-self-healing-compiler-pipeline.md) *(dossier proposal)*
- [41. Granularity-Adaptive Optimization](chapters/41-granularity-adaptive-optimization.md) *(dossier proposal)*
- [42. Adaptive ABI Negotiation](chapters/42-adaptive-abi-negotiation.md) *(dossier proposal)*
- [43. Compile-Time / Run-Time Staging Controller](chapters/43-compile-time-run-time-staging-controller.md) *(dossier proposal)*
- [44. Hermetic Compilation Capsules](chapters/44-hermetic-compilation-capsules.md) *(dossier proposal)*
- [45. Digital-Twin Compiler for Hardware Decisions](chapters/45-digital-twin-compiler-for-hardware-decisions.md) *(dossier proposal)*


## Files and scope

- `chapters/`: exactly 45 standalone Markdown chapters.
- `sources/COMPILER_IDEAS.md`: unchanged copy of the supplied seed document.
- `appendices/`: mapping, design framework, experiments, glossary and selected literature.
- `MANIFEST.json`: machine-readable chapter index, origin and word counts.

No runnable compiler is included. All experiments are designs rather than executed benchmark results. The dossier does not assert measured speedups, proof coverage, or unique research priority.
