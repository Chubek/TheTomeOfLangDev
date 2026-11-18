#!/usr/bin/env python3
"""Check chapter walkthroughs and integration, dossier integrity, and the source map."""

import hashlib
import json
import re
from collections import Counter

import source_catalogue


ROOT = source_catalogue.ROOT
CHAPTERS = range(131, 261)
ALL_CHAPTERS = range(1, CHAPTERS.stop)
LABEL = re.compile(r"\\label\{([^}]+)\}")
REFERENCE = re.compile(r"\\(?:ref|pageref|autoref|[cC]ref)\{([^}]+)\}")
CITATION = re.compile(r"\\(?:cite|textcite|parencite)(?:\[[^\]]*\]){0,2}\{([^}]+)\}")
BIB_ENTRY = re.compile(r"^@\w+\s*\{\s*([^,\s]+),", re.M)
NUMBERED_INPUT = re.compile(
    r"\\chapter\{[^{}\n]+\}\\label\{ch:ext-(\d+)\}\s*"
    r"\\input\{chapters/chapter-(\d+)\.ltx\}"
)
LOCAL_LINK = re.compile(r"\]\((\.\.?/[^()]+\.(?:md|txt))\)")
WALKTHROUGH_MARKER = re.compile(r"^% Annotated walkthrough[ \t]*$", re.M)
SECTION = re.compile(r"^[ \t]*\\((?:sub)*)section\*?(?:\[[^\n]*\])?\{", re.M)
PSEUDOCODE_BLOCK = re.compile(
    r"\\begin\{(sudocode|algorithmic|verbatim|Verbatim|lstlisting)\}"
    r".*?\\end\{\1\}",
    re.S,
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
        for name in ("the-tome-of-langdev.ltx", "tome-extensions.ltx")
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


def check_tome(errors):
    root = contents(ROOT / "the-tome-of-langdev.ltx")
    ext = contents(ROOT / "tome-extensions.ltx")
    if root.count(r"\input{tome-extensions.ltx}") != 1:
        errors.append("main manuscript must include tome-extensions.ltx once")
    elif root.index(r"\input{tome-extensions.ltx}") > root.index(r"\backmatter"):
        errors.append("new chapters must precede the back matter")

    expected = [(str(n), str(n)) for n in CHAPTERS]
    if NUMBERED_INPUT.findall(ext) != expected:
        errors.append("new chapter headings, labels and inputs must match 131–260 in order")
    if len(re.findall(r"^\\part\{", ext, flags=re.M)) != 13:
        errors.append("expected thirteen new parts")

    old_labels = set(LABEL.findall(root))
    for n in range(1, CHAPTERS.start):
        old_labels.update(LABEL.findall(contents(ROOT / f"chapters/chapter-{n}.ltx")))
    new_labels = Counter(LABEL.findall(ext))
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
            errors.append(f"{path.name}: use the heading in tome-extensions.ltx")
        if not source_catalogue.SOURCE_NOTE.search(text):
            errors.append(f"{path.name}: no local source notes")
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
    print("260 chapter walkthroughs, 45 dossier chapter links, and local source catalogue checked.")


if __name__ == "__main__":
    main()
