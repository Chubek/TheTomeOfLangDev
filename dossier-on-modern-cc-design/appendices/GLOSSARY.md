# Glossary

**Abstract interpretation:** Computation of sound approximations of program properties in an abstract domain; a conservative result is useful even when not exact.

**ABI (application binary interface):** Convention governing calls, registers, stack layout, symbol linkage, exceptions and binary interoperability.

**Assumption:** A fact relied on by an optimized version, whether statically proved or dynamically checked.

**Binding-time analysis:** Determining what information is available at each compilation or specialization stage.

**Causal profiling:** An experimental approach to estimating a region's effect on an objective, as distinct from merely observing frequent execution.

**CFG (control-flow graph):** Basic blocks and possible transfers of control between them.

**Compilation capsule:** In this dossier, a content-addressed package of inputs, target, compiler versions, outputs and validation evidence.

**Deoptimization:** Transfer from optimized execution to a semantically equivalent reference or less-optimized execution state.

**Dominance:** A CFG property: block A dominates B when every path from entry to B passes through A.

**E-class / e-graph:** An equivalence class and a graph of equivalence classes representing expressions known to be equivalent under supplied rules.

**Effect:** An observable or ordering-relevant behavior, such as I/O, allocation, mutation, exception or synchronization.

**Frame state:** Metadata describing live locals, inlined call frames and virtual objects at a point that may transfer execution.

**Guard:** Runtime check that validates a speculative condition and transfers control to recovery if false.

**IR (intermediate representation):** A program representation designed for analysis, transformation, execution or code generation.

**JIT (just-in-time compiler):** Compiler invoked during program execution, often guided by profiles.

**Lattice:** Ordered family of facts or representations supporting well-defined joins/meets; context determines the formal order.

**Memory SSA:** SSA-like representation of memory definitions and uses, enabling explicit reasoning about read/write dependencies.

**Metamorphic test:** Test using a known relation between related inputs or program variants when exact output is hard to predict independently.

**OSR (on-stack replacement):** Transition between execution implementations while a function or loop is already active.

**Partial evaluation:** Specializing a program given some known inputs, producing residual computation for the unknown inputs.

**Provenance:** Derivation links connecting lowered artifacts to source entities, transformations and assumptions.

**Quickening:** Replacing generic interpreter instructions with more specialized forms while retaining interpreted execution.

**Refinement:** Relation in which the transformed program preserves the permitted observations of the original under a defined semantics.

**Semantic fingerprint:** In this dossier, a finite observation-based signature for triage; it is not a universal equivalence proof.

**SSA (static single assignment):** Representation in which each SSA value is assigned once, with merges at control-flow joins.

**Temporal affinity:** Profiled correlation that operations or data are accessed close in time, not a proof of semantic dependence.

**Tiering:** Selecting between interpreter and compiled implementations based on execution conditions and budgets.

**Transactional IR:** In this dossier, compiler state updated using validated atomic revisions with conflict detection and rollback.

**Translation validation:** Checking a given transformation result against its input under stated semantics; sometimes bounded or incomplete.

**Versioned IR:** Persistent alternative program representations with recorded assumptions, dependencies and code artifacts.
