# Preface — A Compiler That Can Explain Its Decisions

The conventional compiler diagram, **source → AST → intermediate representation → optimization → machine code**, is useful but incomplete. Many important compiler architectures are not simple linear pipelines. A virtual machine may retain an interpreter, multiple native tiers and live object layouts. A large build may persist semantic facts across edits. A dynamic optimizer may choose between multiple legal representations. A translation validator may refuse an apparently promising rewrite because its proof obligation fails. These systems are best understood as *compilers that manage facts, decisions, versions and execution over time*.

The supplied `COMPILER_IDEAS.md` supplies twenty-eight ideas and a concluding sketch of a runtime-managed graph of program representations. This dossier retains those seeds as Chapters 01–28 and adds seventeen proposals in Chapters 29–45. The added chapters propose ways to make compiler decisions more accountable, resource-aware, experimental and interoperable. They are original *design contributions within this dossier*, not claims that the research areas have never been explored elsewhere.

## Six questions to ask of any advanced compiler design

**What is the meaning?** Define a reference interpreter, mathematical denotation or an operational semantics sufficiently precise to distinguish legal rewrites from illegal ones. Signed overflow, floating point, traps, I/O order, undefined behavior and concurrency are not footnotes; they determine which alternatives are equivalent. Where approximate outputs are permitted, define the permitted error and what the runtime can observe.

**What is the representation?** Decide whether the compiler stores syntax trees, CFGs, SSA values, memory versions, effect tokens, e-classes, proof obligations, profile histograms or persistent artifact relations. Representations change which questions can be asked cheaply. A program graph and a profile graph are not the same thing: control dependence may constrain semantics, while temporal affinity can only guide performance.

**Which facts are believed rather than proved?** A profile-driven type hypothesis can justify speculative code *if guarded*. It cannot justify a universal semantic rewrite. Confident probabilities do not turn into static facts. As assumptions change, every reliant code version needs an invalidation or recovery route.

**How is code published and retired?** JITs, on-stack replacement, deoptimization, incremental builds and live debugging all manipulate artifacts while execution or analysis continues. Atomically changing a dispatch pointer is only one small part of correctness: active frames, unwind tables, GC roots, source maps, asynchronous signals and foreign pointers may still reference an older artifact.

**How is a performance claim measured?** Compilation consumes CPU, memory and energy. Specialized code occupies caches. Profiling has overhead. Migration can double peak memory. A fair comparison must include cold starts and unfavorable input changes, not only stable warm-up results. Runtime perturbations may be confounded by the very optimization they are meant to study.

**Can the decision be explained and replayed?** A compiler that logs candidate choice, preconditions, semantic evidence, relevant profile epoch, target assumptions, generated artifact hash and measured outcome can support scientific experiments. Without that evidence, a surprising speedup or regression is hard to reproduce.

## Four kinds of claim

1. **Semantic claim:** an optimization preserves behavior under a stated model. It needs a proof, a sound rule, or an accurately scoped validator result.
2. **Heuristic claim:** a transformation is expected to be profitable. It needs a cost model, with uncertainty when appropriate.
3. **Empirical claim:** a measured run improved an objective under particular conditions. It needs a reproducible benchmark and honest statistics.
4. **Architectural proposal:** a subsystem might enable new workflows. It needs a plausible interface, failure model and experiment; it is not yet a measured result.

Confusing these claim types makes compiler proposals much less useful. For example, equality saturation can preserve proven equalities but does not guarantee a fast extracted program; learned cost models can rank candidates but do not prove them correct; translation validation can establish bounded refinement properties but does not necessarily prove the correctness of all loops. Each chapter separates these concerns.

## A common vocabulary for the chapters

An **IR node** is a meaningful program operation or state entity. A **revision** is an immutable or transactionally consistent view of program meaning. An **artifact** is a derived representation, such as bytecode, machine code or an analysis result. An **assumption** is a condition relied upon by a specialization. A **guard** checks such a condition. A **deoptimization descriptor** maps optimized execution state back to a reference tier. A **certificate** records what a particular validator actually established. A **profile** describes observations, usually under uncertainty; it is never a proof of universal behavior.

An **optimization policy** decides when to spend compile time and which legal candidate to select. A **validation boundary** rejects or quarantines illegal candidates. A **publication boundary** determines when another compiler actor or a runtime can observe a version. An **invalidation edge** connects a changed fact to every artifact that relied on it. These boundaries recur across the dossier even when the underlying data structure is an AST, e-graph, database or machine IR.

## A minimal experimentation discipline

Always begin with a reference implementation and small tests that are independently interpretable. Introduce the new idea through one narrow transformation. Deliberately construct cases where it cannot help. Record compilation cost and runtime outcome separately. Add randomized differential testing, metamorphic tests and bounded symbolic validation where they fit the semantics. Only after the feature has a well-defined fallback should it be connected to a persistent runtime or incremental build service.

This dossier is meant as both a study text and an engineering design notebook. It intentionally favors concrete prototypes and falsifiable questions over promises of automatic speedups.
