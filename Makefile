##
## Makefile — Build system for The Tome of Programming Language Development
##
## Targets:
##   make            — Build PDF with LuaLaTeX (default)
##   make pdf        — Same as default
##   make xelatex    — Build with XeLaTeX
##   make pdflatex   — Build with pdfLaTeX
##   make watch      — Continuous rebuild on file changes
##   make clean      — Remove auxiliary files
##   make distclean  — Remove all generated files including PDF
##   make index      — Regenerate index only
##   make bib        — Regenerate bibliography only
##   make count      — Count words/pages
##   make lint       — Check for common LaTeX issues
##   make help       — Show this help
##

.PHONY: all pdf xelatex pdflatex watch clean distclean index bib count lint help

MAIN    := the-tome-of-langdev
CLASS   := $(MAIN).cls
LTX     := $(MAIN).ltx
PDF     := $(MAIN).pdf
BIB     := references.bib
SUPPORT := $(wildcard support/*.sty)
CHAPTERS := $(wildcard chapters/*.ltx)

## Default engine
LATEXMK := latexmk
ENGINE  := -lualatex

all: pdf

pdf:
	$(LATEXMK) $(ENGINE) -shell-escape $(LTX)

$(PDF): $(LTX) $(CLASS) $(SUPPORT) $(CHAPTERS) $(BIB) .latexmkrc
	$(LATEXMK) $(ENGINE) -shell-escape $(LTX)

xelatex:
	$(LATEXMK) -pdfxe -shell-escape $(LTX)

pdflatex:
	$(LATEXMK) -pdf -shell-escape $(LTX)

watch:
	$(LATEXMK) $(ENGINE) -shell-escape -pvc $(LTX)

clean:
	$(LATEXMK) -c $(LTX)
	rm -f *.synctex.gz *.synctex *.run.xml

distclean:
	$(LATEXMK) -C $(LTX)
	rm -f $(PDF) *.synctex.gz *.synctex *.run.xml

index:
	xindy -M texindy -I xelatex -C utf8 $(MAIN).idx -o $(MAIN).ind

bib:
	biber $(MAIN)

count:
	@echo "=== Word count estimate ==="
	@detex $(LTX) $(CHAPTERS) 2>/dev/null | wc -w || \
		(cat $(LTX) $(CHAPTERS) | sed 's/\\[^ ]*//g' | wc -w)
	@echo "=== Chapter count ==="
	@ls chapters/*.ltx 2>/dev/null | wc -l
	@echo "=== Source file count ==="
	@ls sources/*.txt 2>/dev/null | wc -l

lint:
	@echo "=== Checking for common issues ==="
	@echo "--- Unmatched braces ---"
	@grep -n '[^\\]{' $(LTX) $(CHAPTERS) 2>/dev/null | head -20 || true
	@echo "--- Missing labels ---"
	@grep -n '\\begin{figure}' $(CHAPTERS) 2>/dev/null | while read line; do \
		file=$$(echo "$$line" | cut -d: -f1); \
		line_num=$$(echo "$$line" | cut -d: -f2); \
		if ! sed -n "$${line_num},$$(($${line_num}+20))p" "$$file" | grep -q '\\label{'; then \
			echo "Missing label in $$file:$$line_num"; \
		fi; \
	done || true
	@echo "--- Undefined references ---"
	@grep -oh '\\ref{[^}]*}' $(CHAPTERS) 2>/dev/null | sort -u > /tmp/refs.txt || true
	@grep -oh '\\label{[^}]*}' $(CHAPTERS) $(LTX) 2>/dev/null | sed 's/\\label/\\ref/' | sort -u > /tmp/labels.txt || true
	@comm -23 /tmp/refs.txt /tmp/labels.txt | head -20 || true
	@echo "=== Lint complete ==="

help:
	@echo "The Tome of Programming Language Development — Build System"
	@echo ""
	@echo "Targets:"
	@echo "  make            Build PDF with LuaLaTeX (default)"
	@echo "  make pdf        Same as default"
	@echo "  make xelatex    Build with XeLaTeX"
	@echo "  make pdflatex   Build with pdfLaTeX"
	@echo "  make watch      Continuous rebuild on file changes"
	@echo "  make clean      Remove auxiliary files"
	@echo "  make distclean  Remove all generated files including PDF"
	@echo "  make index      Regenerate index only"
	@echo "  make bib        Regenerate bibliography only"
	@echo "  make count      Count words and chapters"
	@echo "  make lint       Check for common LaTeX issues"
	@echo "  make help       Show this help"
