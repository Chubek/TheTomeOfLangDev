#!/usr/bin/env python3
"""Check chapter walkthroughs, visuals and integration, dossier integrity, and the source map."""

import hashlib
import json
import re
from collections import Counter

import source_catalogue


ROOT = source_catalogue.ROOT
EXTENSIONS = (
    ("tome-extensions.ltx", range(131, 261), (10,) * 13),
    ("tome-native-toolchain.ltx", range(261, 303), (18, 24)),
    ("tome-description-languages.ltx", range(303, 352), (20, 15, 14)),
    ("tome-alternative-languages.ltx", range(352, 382), (10, 11, 11)),
)
PLACEMENTS = (
    (382, "the-tome-of-langdev.ltx", 40, 41),
    (383, "tome-alternative-languages.ltx", 362, 363),
    (384, "tome-alternative-languages.ltx", 381, None),
)
CHAPTERS = (*range(EXTENSIONS[0][1].start, EXTENSIONS[-1][1].stop),
            *(item[0] for item in PLACEMENTS))
ALL_CHAPTERS = (*range(1, EXTENSIONS[0][1].start), *CHAPTERS)
PRIMARY_SOURCES = (
    (range(261, 279), "blindel-instrselect-book.txt", "blindell2016instruction"),
    (range(279, 303), "linkers-loaders-ocr.txt", "levine2000linkers"),
    (range(323, 338), "vienna-arch-desc-lang.txt", "himmelbauer2024vadl"),
    ((382,), "typed-algebraic-approach-to-parsing.txt", "krishnaswami2019typedparsing"),
    ((383,), "leroy-a-verif-cc-compiler-backend-for-lustre.txt", "bourke2017verifiedlustre"),
    ((384,), "adavances-in-dataflow-langs-lucid.txt", "johnston2004dataflow"),
)
LABEL = re.compile(r"\\label\{([^}]+)\}")
REFERENCE = re.compile(r"\\(?:ref|pageref|autoref|[cC]ref)\{([^}]+)\}")
CITATION = re.compile(r"\\(?:cite|textcite|parencite)(?:\[[^\]]*\]){0,2}\{([^}]+)\}")
BIB_ENTRY = re.compile(r"^@\w+\s*\{\s*([^,\s]+),", re.M)
NUMBERED_INPUT = re.compile(
    r"\\chapter\{[^{}\n]+\}\\label\{ch:ext-(\d+)\}\s*"
    r"\\input\{chapters/chapter-(\d+)\.ltx\}"
)
CHAPTER_INPUT = re.compile(r"^\\input\{chapters/chapter-(\d+)\.ltx\}", re.M)
LOCAL_LINK = re.compile(r"\]\((\.\.?/[^()]+\.(?:md|txt))\)")
WALKTHROUGH_MARKER = re.compile(r"^% Annotated walkthrough[ \t]*$", re.M)
SECTION = re.compile(r"^[ \t]*\\((?:sub)*)section\*?(?:\[[^\n]*\])?\{", re.M)
PSEUDOCODE_BLOCK = re.compile(
    r"\\begin\{(sudocode|algorithmic|verbatim|Verbatim|lstlisting)\}"
    r".*?\\end\{\1\}",
    re.S,
)
VISUAL_MARKER = re.compile(r"^% Explanatory visual[ \t]*$", re.M)
VISUAL_FLOAT = re.compile(
    r"^[ \t]*\\begin\{figure\}(?:\[[^\n]*\])?(.*?)\\end\{figure\}",
    re.M | re.S,
)


def contents(path):
    return path.read_text(encoding="utf-8")


def keys(pattern, text):
    return {key.strip() for group in pattern.findall(text) for key in group.split(",")}


def check_walkthrough(path, text, errors):
    markers = list(WALKTHROUGH_MARKER.finditer(text))
    if len(markers) != 1:
        errors.append(f"{path.name}: expected one annotated walkthrough marker")
        return
    start = markers[0].end()
    heading = SECTION.match(text, start + 1)
    if heading is None:
        errors.append(f"{path.name}: walkthrough marker must immediately precede a heading")
        return
    depth = len(heading.group(1))
    next_heading = next(
        (candidate for candidate in SECTION.finditer(text, heading.end())
         if len(candidate.group(1)) <= depth),
        None,
    )
    stop = next_heading.start() if next_heading else len(text)
    body = text[heading.end():stop]
    if not PSEUDOCODE_BLOCK.search(body):
        errors.append(f"{path.name}: walkthrough is missing a pseudocode block")
    return body


def check_walkthroughs(errors):
    labels = Counter(
        label
        for name in ("the-tome-of-langdev.ltx", *(entry[0] for entry in EXTENSIONS))
        for label in LABEL.findall(contents(ROOT / name))
    )
    walkthroughs = {}
    for n in ALL_CHAPTERS:
        path = ROOT / f"chapters/chapter-{n}.ltx"
        if not path.is_file():
            errors.append(f"missing {path.name}")
        else:
            text = contents(path)
            labels.update(LABEL.findall(text))
            body = check_walkthrough(path, text, errors)
            if body is not None:
                walkthroughs[path.name] = body

    citations = set(BIB_ENTRY.findall(contents(ROOT / "references.bib")))
    for name, body in walkthroughs.items():
        prose = PSEUDOCODE_BLOCK.sub("", body)
        for label in sorted(keys(REFERENCE, prose) - labels.keys()):
            errors.append(f"{name}: walkthrough references unknown label {label}")
        for key in sorted(keys(CITATION, prose) - citations):
            errors.append(f"{name}: walkthrough cites unknown bibliography key {key}")
        for label in sorted(set(LABEL.findall(prose))):
            if labels[label] > 1:
                errors.append(f"{name}: walkthrough label {label} is not unique")


def check_chapter_visuals(path, text, number, errors):
    """Check marked figures, not older illustrative material or LaTeX layouts."""
    primary = f"fig:visual-{number}"
    named = set()
    for marker in VISUAL_MARKER.finditer(text):
        figure = VISUAL_FLOAT.match(text, marker.end() + 1)
        if figure is None:
            errors.append(f"{path.name}: visual marker must immediately precede a figure")
            continue
        body = figure[1]
        labels = LABEL.findall(body)
        if len(labels) != 1 or not re.fullmatch(rf"{primary}(?:-[a-z])?", labels[0]):
            errors.append(f"{path.name}: expected one {primary} label (a suffix is allowed)")
            continue
        label = labels[0]
        named.add(label)
        if len(re.findall(rf"\\label\{{{re.escape(label)}\}}", text)) != 1:
            errors.append(f"{path.name}: visual label {label} must be unique")
        if not re.search(r"\\caption(?:\[[^\n]*\])?\{", body):
            errors.append(f"{path.name}: {label} is missing its caption")
        if r"\begin{tikzpicture}" not in body or r"\end{tikzpicture}" not in body:
            errors.append(f"{path.name}: {label} needs editable TikZ artwork")
        prose = text[:figure.start()] + text[figure.end():]
        if label not in keys(REFERENCE, prose):
            errors.append(f"{path.name}: no reader-facing reference to {label}")
    if primary not in named:
        errors.append(f"{path.name}: missing marked explanatory visual {primary}")
    return len(named)


def check_visuals(errors):
    count = 0
    for number in ALL_CHAPTERS:
        path = ROOT / f"chapters/chapter-{number}.ltx"
        if path.is_file():
            count += check_chapter_visuals(path, contents(path), number, errors)
    return count


def check_tome(errors):
    root = contents(ROOT / "the-tome-of-langdev.ltx")
    manuscripts = {"the-tome-of-langdev.ltx": root, **{
        name: contents(ROOT / name) for name, _, _ in EXTENSIONS
    }}
    for number, name, before, after in PLACEMENTS:
        order = [int(n) for n in CHAPTER_INPUT.findall(manuscripts[name])]
        count = sum(CHAPTER_INPUT.findall(text).count(str(number))
                    for text in manuscripts.values())
        expected = [before, number] + ([after] if after is not None else [])
        correct = (any(order[i:i + len(expected)] == expected for i in range(len(order)))
                   if after is not None else order[-2:] == expected)
        if count != 1 or not correct:
            errors.append(f"{name}: expected chapter input order {expected}")
        if (str(number), str(number)) not in NUMBERED_INPUT.findall(manuscripts[name]):
            errors.append(f"{name}: chapter {number} needs its heading and stable label")

    positions = []
    new_labels = Counter()
    for extension, chapter_range, expected_sizes in EXTENSIONS:
        registration = rf"\input{{{extension}}}"
        if root.count(registration) != 1:
            errors.append(f"main manuscript must include {extension} once")
        else:
            positions.append(root.index(registration))
        ext = manuscripts[extension]
        new_labels.update(LABEL.findall(ext))
        order = list(chapter_range)
        for number, name, before, _ in PLACEMENTS:
            if name == extension:
                order.insert(order.index(before) + 1, number)
        expected = [(str(n), str(n)) for n in order]
        if NUMBERED_INPUT.findall(ext) != expected:
            errors.append(
                f"{extension}: chapter headings, labels and inputs must match its registered order"
            )
        parts = re.split(r"^\\part\{", ext, flags=re.M)
        sizes = tuple(len(NUMBERED_INPUT.findall(part)) for part in parts[1:])
        if NUMBERED_INPUT.search(parts[0]) or sizes != expected_sizes:
            errors.append(f"{extension}: expected chapter counts per part {expected_sizes}")
    if positions != sorted(positions) or any(pos > root.index(r"\backmatter") for pos in positions):
        errors.append("extension files must appear in chapter order before the back matter")

    old_labels = set(LABEL.findall(root))
    for n in range(1, EXTENSIONS[0][1].start):
        old_labels.update(LABEL.findall(contents(ROOT / f"chapters/chapter-{n}.ltx")))
    bodies = {}
    for n in CHAPTERS:
        path = ROOT / f"chapters/chapter-{n}.ltx"
        if not path.is_file():
            errors.append(f"missing {path.name}")
            continue
        text = contents(path)
        body = re.sub(r"(?m)^\s*%[^\n]*", "", text)
        if len(re.findall(r"\\section\*?(?:\[.*?\])?\{", body)) < 3:
            errors.append(f"{path.name}: needs at least three sections")
        if re.search(r"(?m)^\s*\\(?:chapter|part)\b", body):
            errors.append(f"{path.name}: use the heading in the extension file")
        notes = set(source_catalogue.SOURCE_NOTE.findall(text))
        if not notes:
            errors.append(f"{path.name}: no local source notes")
        for source_range, source, key in PRIMARY_SOURCES:
            if n in source_range and (source not in notes or key not in keys(CITATION, body)):
                errors.append(f"{path.name}: expected its primary source note ({source}) and citation ({key})")
        new_labels.update(LABEL.findall(body))
        bodies[path.name] = body
    for label, count in sorted(new_labels.items()):
        if count > 1 or label in old_labels:
            errors.append(f"duplicate new cross-reference label: {label}")

    labels = old_labels.union(new_labels)
    citations = set(BIB_ENTRY.findall(contents(ROOT / "references.bib")))
    for name, body in bodies.items():
        for label in sorted(keys(REFERENCE, body) - labels):
            errors.append(f"{name}: unknown reference {label}")
        for key in sorted(keys(CITATION, body) - citations):
            errors.append(f"{name}: unknown bibliography key {key}")


def check_dossier(errors):
    dossier = ROOT / "dossier-on-modern-cc-design"
    manifest = json.loads(contents(dossier / "MANIFEST.json"))
    chapters = manifest["chapters"]
    if [chapter["number"] for chapter in chapters] != list(range(1, 46)):
        errors.append("dossier manifest must describe chapters 1–45 in order")
    review = dossier / "appendices/TOME-DESIGN-REVIEW.md"
    links = set(LOCAL_LINK.findall(contents(review)))
    for page in (review, dossier / "README.md", dossier / "appendices/REFERENCES.md",
                 dossier / "appendices/SYSTEM-BLUEPRINT.md"):
        # These files also use relative links without an initial ./.
        for href in re.findall(r"\]\(([^#():]+\.md|[^#():]+\.txt)\)", contents(page)):
            if not (page.parent / href).is_file():
                errors.append(f"{page.name}: broken local link {href}")
    for chapter in chapters:
        relative = chapter["path"]
        path = dossier / relative
        if f"../{relative}" not in links:
            errors.append(f"dossier review omits {relative}")
        if not path.is_file() or hashlib.sha256(path.read_bytes()).hexdigest() != chapter["sha256"]:
            errors.append(f"dossier manifest digest mismatch: {relative}")


def main():
    errors = []
    check_tome(errors)
    check_walkthroughs(errors)
    visual_count = check_visuals(errors)
    check_dossier(errors)
    catalogue = source_catalogue.CATALOGUE
    try:
        rendered = source_catalogue.render()
        if not catalogue.is_file() or contents(catalogue) != rendered:
            errors.append("run python3 support/source_catalogue.py to refresh the catalogue")
    except ValueError as error:
        errors.append(str(error))
    if errors:
        raise SystemExit("\n".join(errors))
    print(
        f"{visual_count} explanatory visuals, {len(ALL_CHAPTERS)} chapter walkthroughs, "
        "18 instruction-selection chapters, "
        "24 toolchain chapters, 20 HDL chapters, 15 architecture description chapters, "
        "14 logic-programming chapters, 30 core alternative-language chapters, "
        f"{len(PLACEMENTS)} bridge and capstone placements, "
        "45 dossier chapter links, and local source catalogue checked."
    )


if __name__ == "__main__":
    main()
