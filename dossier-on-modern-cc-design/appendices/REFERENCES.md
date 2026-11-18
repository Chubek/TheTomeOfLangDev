# Selected Literature and Engineering References

These links are a **curated starting point**, not claimed as sources for every detail of every chapter. The supplied `COMPILER_IDEAS.md` is the primary seed for Chapters 01–28; Chapters 29–45 are explicitly labeled dossier proposals. Names such as “transactional optimizer” or “causal profiling IR” describe candidate architectures here and are not assertions of first publication.

1. C. Lattner et al., **MLIR: A Compiler Infrastructure for the End of Moore’s Law** (2020). https://arxiv.org/abs/2002.11054 — multi-level extensible IR, heterogeneous compilation and cross-domain representation design.
2. M. Willsey et al., **egg: Fast and Extensible Equality Saturation**, POPL 2021. https://arxiv.org/abs/2004.03082 — e-graph rebuilding, e-class analysis and saturation; closely relevant to Chapter 10.
3. Soufflé project, **Datalog language and program model**. https://souffle-lang.github.io/program — relations and declarative rules relevant to compiler-as-database and query-based analysis in Chapters 07 and 09.
4. T. Würthinger et al., **Practical Partial Evaluation for High-Performance Dynamic Language Runtimes**, PLDI 2017. https://doi.org/10.1145/3062341.3062381 — specialization of self-optimizing interpreters, relevant to Chapters 02, 12–14 and 24.
5. O. Flückiger et al., **Deoptless: Speculation with Dispatched On-Stack Replacement and Specialized Continuations**, PLDI 2022. https://doi.org/10.1145/3519939.3523729 — speculation and alternatives to conventional deoptimization; related to Chapters 03, 04 and 35.
6. **Design, Implementation and Evaluation of Adaptive Recompilation with On-Stack Replacement**, CGO 2003. https://doi.org/10.1109/CGO.2003.1191549 — foundational OSR tradeoffs relevant to Chapters 02, 04 and 20.
7. N. P. Lopes et al., **Alive2: Bounded Translation Validation for LLVM**, PLDI 2021. https://doi.org/10.1145/3453483.3454030 — bounded refinement checking, relevant to Chapters 29, 32, 39 and 40.

## Comparing runtime designs with the Tome

| Local reading | Question to carry into the dossier |
| --- | --- |
| Titzer, [*Whose baseline compiler is it anyway?*](../../sources/whose-baseline-compiler-is-it-anyways.txt); Xu and Kjolstad, [*Copy-and-Patch Compilation*](../../sources/copy-and-patch-jit.txt) | Chapters 02 and 08 propose a choice of tiers and demand-driven work. Measure the cost of building each tier as well as the quality of the emitted code. A forward compile-time stack simulation and prebuilt binary stencils solve different parts of that problem. |
| Bolz et al., [*Tracing the Meta-Level: PyPy’s Tracing JIT Compiler*](../../sources/pypy-meta-tracing-jit.txt); Chevalier-Boisvert and Feeley, [*Removing Dynamic Type Tests with Context-Driven Basic Block Versioning*](../../sources/bbv-removing-dynamic-type-tests.txt) | Chapters 03, 12, and 24 discuss runtime adaptation. Compare the unit that gets specialized: a path through interpreter execution versus a block cloned for an entry context. Count failed guards and extra code, not just eliminated checks. |
| D'Elia and Demetrescu, [*On-Stack Replacement, Distilled*](../../sources/osr-distilled-jit.txt); Barrière, [*Formal Verification of Just-in-Time Compilation*](../../sources/formal-verif-jit.txt) | Chapters 04, 20 and 35 need a precise state relation. Recovering a live value at a transfer point is different from proving the code-generation pipeline or capturing enough nondeterminism for a replay. |

See the [design review](TOME-DESIGN-REVIEW.md) for a worked contract and
cross-references for all 45 chapters. The [local source
catalogue](../../support/SOURCE-CATALOGUE.md) distinguishes chapter source
notes from extra search leads.

## Scope cautions

- Existing research covers many underlying ideas. New chapter combinations are **proposals in this document**, not asserted to be previously unpublished scientific discoveries.
- Validation and verification claims must always state their semantics, assumptions and bounds.
- The dossier's pseudocode and evaluations are thought experiments and implementation plans; the references are not endorsements of the proposed algorithms.
