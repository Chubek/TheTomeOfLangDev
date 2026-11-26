# Chapter length audit

Run `make chapter-lengths` to measure every chapter body with Pandoc. The
report gives both total and nonblank plaintext lines at 80 columns.
Nonblank lines are the comparison metric; TeX source wrapping and extra
blank lines do not count toward it. Plaintext conversion does not render
TikZ and may omit custom environments or warn about TeX math, so this is
an editorial triage tool, not a proxy for the PDF's pagination or quality.
The report uses stable chapter **file IDs** rather than printed numbers.

The baseline with Pandoc 3.10.2 was **381 chapters, median 98 nonblank
lines**. The original 130 chapters had a median of 330.5, while chapters
131–260 had a median of 97. For this pass, the pronounced short cluster
was the 32 chapters under 65 lines, ranging from 43 to 64. The working
floor for that cluster and for the new chapters was 90 nonblank lines,
close to the longer supplements' median.

After that pass, the revised and new chapters ran from **90 to 102**
nonblank lines. Across the then-current 384 chapters, the median was 98.
The 82 chapters between 66 and 89 lines are outside this pass.

| File IDs | Baseline | Expanded material |
| --- | ---: | --- |
| 308, 310 | 62 each | Bus ownership and register-transfer traces |
| 352–361 | 43–64 | Firing and buffering, single assignment, Lucid demand and context |
| 362–371 | 44–61 | Synchronous clocks, array loops, actors, visual and reactive dataflow |
| 372–381 | 47–55 | Alternative-language IRs and differential validation |
| 382–384 | New | Typed predictive parsing, verified Lustre lowering, bounded stream queues |

Each revised or new chapter has a comparison table, explanatory TikZ
artwork, pseudocode, and a concrete input or trace to check. The two
bridge chapters are inserted after file IDs 40 and 362; the bounded-queue
chapter follows file ID 381. Existing file IDs and TeX labels remain stable.

Recheck the revised set using the same floor:

```sh
python3 -B support/chapter_lengths.py --minimum 90 308 310 $(seq 352 384)
make check-expansion
```

## Runtime interfaces and data structures

Parts XXXVI–XXXIX add 45 chapters in `tome-runtime-interfaces.ltx`.
Each includes a worked example, a table, editable TikZ artwork, annotated
pseudocode, and at least **120 nonblank Pandoc lines**.

| File IDs | Chapters | Coverage |
| --- | ---: | --- |
| 385–396 | 12 | Foreign declarations, external calls and stubs, ABI layouts, ownership, callbacks, and binding verification |
| 397–407 | 11 | Module interfaces, imports and exports, initialization, packages, static and dynamic dispatch, vtables, and witness tables |
| 408–418 | 11 | Allocation and ownership, precise roots, reference counting, tracing, copying, compaction, and collector integration |
| 419–429 | 11 | Compiler and interpreter data structures, from symbols and syntax trees through graph indexes, VM frames, and incremental queries |

`make check-expansion` checks this placement, source and citation links,
figures, walkthroughs, tables, and the 120-line floor. To see the counts
for just these chapters:

```sh
python3 -B support/chapter_lengths.py --minimum 120 $(seq 385 429)
```
