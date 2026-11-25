#!/usr/bin/env python3
"""Measure chapter length using fixed-width Pandoc plaintext."""

import argparse
import re
import shutil
import statistics
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CHAPTER_NAME = re.compile(r"chapter-(\d+)\.ltx")


def measure(pandoc, path):
    result = subprocess.run(
        [pandoc, "--from=latex", "--to=plain", "--wrap=auto", "--columns=80", str(path)],
        cwd=ROOT, check=True, capture_output=True, encoding="utf-8",
    )
    lines = result.stdout.splitlines()
    return len(lines), sum(bool(line.strip()) for line in lines), bool(result.stderr)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("ids", nargs="*", type=int, help="chapter file IDs; default: all")
    parser.add_argument("--minimum", type=int, help="fail if any selected chapter is shorter")
    args = parser.parse_args()
    pandoc = shutil.which("pandoc")
    if pandoc is None:
        parser.exit(1, "Pandoc is required to measure chapter lengths.\n")
    chapters = {
        int(match[1]): path for path in (ROOT / "chapters").iterdir()
        if (match := CHAPTER_NAME.fullmatch(path.name))
    }
    unknown = set(args.ids) - chapters.keys()
    if unknown:
        parser.error(f"unknown chapter IDs: {', '.join(map(str, sorted(unknown)))}")
    ids = sorted(set(args.ids) or chapters.keys())
    if not ids:
        parser.exit(1, "No chapter bodies found.\n")
    try:
        with ThreadPoolExecutor(max_workers=8) as pool:
            counts = list(pool.map(lambda n: measure(pandoc, chapters[n]), ids))
    except subprocess.CalledProcessError as error:
        parser.exit(1, f"Pandoc failed for {error.cmd[-1]}:\n{error.stderr}")

    print("chapter_id\ttotal_lines\tnonblank_lines")
    for n, (total, nonblank, _) in zip(ids, counts):
        print(f"{n}\t{total}\t{nonblank}")
    warnings = sum(warned for _, _, warned in counts)
    median = statistics.median(nonblank for _, nonblank, _ in counts)
    print(f"{len(ids)} chapters; median {median:g} nonblank lines; "
          f"{warnings} chapters produced Pandoc diagnostics.", file=sys.stderr)
    if args.minimum is not None:
        short = [f"{n} ({nonblank})" for n, (_, nonblank, _) in zip(ids, counts)
                 if nonblank < args.minimum]
        if short:
            parser.exit(1, f"Below {args.minimum} nonblank lines: {', '.join(short)}\n")


if __name__ == "__main__":
    main()
