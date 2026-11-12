%%
%% the-tome-of-langdev.cls
%% Document class for "The Tome of Programming Language Development"
%% A comprehensive treatise on programming language theory, design, and implementation.
%%
%% Typeset with care after the tradition of Muchnick's "Advanced Compiler Design"
%% and Knuth's "Computers & Typesetting", updated for the modern era.
%%
\NeedsTeXFormat{LaTeX2e}[2020-10-01]
\ProvidesClass{the-tome-of-langdev}[2026/01/01 v1.0 The Tome of Programming Language Development]

%% ============================================================
%% Base class and core options
%% ============================================================
\LoadClass[14pt,a4paper,twoside,openright]{book}

%% ============================================================
%% Required packages
%% ============================================================
\RequirePackage{iftex}
\RequirePackage{etoolbox}
\RequirePackage{xparse}
\RequirePackage{xspace}

%% -- Geometry: generous margins for a scholarly book
\RequirePackage[
  paperwidth=210mm,
  paperheight=297mm,
  top=28mm,
  bottom=38mm,
  inner=25mm,
  outer=38mm,
  headheight=14pt,
  headsep=18pt,
  footskip=24pt,
  marginparsep=12pt,
  marginparwidth=48pt
]{geometry}

%% -- Typography fundamentals
\RequirePackage{microtype}
\RequirePackage{setspace}
\RequirePackage{parskip}
\RequirePackage{ragged2e}

%% -- Load legacy math packages before unicode-math to avoid symbol conflicts.
\RequirePackage{amsmath,amssymb,amsthm,mathtools}
\RequirePackage{stmaryrd}

%% -- Font setup (conditional on engine)
\ifTUTeX
  \RequirePackage{fontspec}
  \RequirePackage{unicode-math}
  \setmainfont[
    Ligatures=TeX,
    Numbers=OldStyle,
    SmallCapsFeatures={Letters=SmallCaps}
  ]{TeX Gyre Pagella}
  \setsansfont[
    Scale=MatchLowercase,
    LetterSpace=0.5
  ]{TeX Gyre Heros}
  \setmonofont[
    Scale=MatchLowercase
  ]{DejaVu Sans Mono}
  \setmathfont{TeX Gyre Pagella Math}
  \setmathrm{TeX Gyre Pagella}
  \setmathsf{TeX Gyre Heros}
  \setmathtt{DejaVu Sans Mono}
  \newbool{HasUnicode}\booltrue{HasUnicode}
\else
  \RequirePackage[T1]{fontenc}
  \RequirePackage[utf8]{inputenc}
  \RequirePackage{newtxtext}
  \RequirePackage{newtxmath}
  \newbool{HasUnicode}\boolfalse{HasUnicode}
\fi

\ifLuaTeX
  \RequirePackage{luacode}
  \newbool{HasLua}\booltrue{HasLua}
\else
  \newbool{HasLua}\boolfalse{HasLua}
\fi

%% -- Mathematics
%% Use the math font's punctuation spacing; mathpunctspace's active colon
%% conflicts with TikZ and its legacy mathcodes are incompatible with Unicode math.

%% -- Color infrastructure
\RequirePackage{xcolor}

%% ============================================================
%% Color palette — stately, scholarly, restrained
%% ============================================================
\definecolor{TomeInk}{HTML}{1B2A4A}        %% deep navy — primary text accent
\definecolor{TomeGold}{HTML}{B8860B}       %% dark goldenrod — secondary accent
\definecolor{TomeRule}{HTML}{4A4A4A}       %% dark gray — horizontal rules
\definecolor{TomeBg}{HTML}{F7F5F0}         %% warm cream — shaded backgrounds
\definecolor{TomeBgAlt}{HTML}{EDEAE3}      %% slightly darker cream
\definecolor{TomeLink}{HTML}{1A5276}       %% steel blue — hyperlinks
\definecolor{TomeCite}{HTML}{6C3483}       %% muted purple — citations
\definecolor{TomeCodeKw}{HTML}{8B0000}     %% dark red — code keywords
\definecolor{TomeCodeStr}{HTML}{006400}    %% dark green — strings
\definecolor{TomeCodeCmt}{HTML}{708090}    %% slate gray — comments
\definecolor{TomeChapNum}{HTML}{1B2A4A}    %% chapter number color
\definecolor{TomePartBg}{HTML}{1B2A4A}     %% part page background
\definecolor{TomePartFg}{HTML}{F7F5F0}     %% part page foreground
\definecolor{TomeThmBg}{HTML}{EEF2F7}     %% theorem background
\definecolor{TomeThmBorder}{HTML}{1B2A4A}  %% theorem border
\definecolor{TomeDefBg}{HTML}{F0F7EE}     %% definition background
\definecolor{TomeDefBorder}{HTML}{2E7D32}  %% definition border
\definecolor{TomeExBg}{HTML}{FFF8E1}      %% example background
\definecolor{TomeExBorder}{HTML}{B8860B}   %% example border
\definecolor{TomeWarnBg}{HTML}{FBE9E7}    %% warning/note background
\definecolor{TomeWarnBorder}{HTML}{C62828} %% warning border

%% ============================================================
%% tcolorbox — theorem-like and display environments
%% ============================================================
\RequirePackage[most]{tcolorbox}

%% -- Theorem styles
\newtheoremstyle{tomeplain}
  {\thm@preskip}
  {\thm@postskip}
  {\itshape}
  {}
  {\bfseries\color{TomeInk}}
  {.}
  {0.5em}
  {\thmname{#1}\thmnumber{ #2}\thmnote{ {\color{TomeRule}(#3)}}}

\newtheoremstyle{tomedefinition}
  {\thm@preskip}
  {\thm@postskip}
  {\normalfont}
  {}
  {\bfseries\color{TomeInk}}
  {.}
  {0.5em}
  {\thmname{#1}\thmnumber{ #2}\thmnote{ {\color{TomeRule}(#3)}}}

\theoremstyle{tomeplain}
\newtheorem{theorem}{Theorem}[chapter]
\newtheorem{lemma}[theorem]{Lemma}
\newtheorem{proposition}[theorem]{Proposition}
\newtheorem{corollary}[theorem]{Corollary}
\newtheorem{conjecture}[theorem]{Conjecture}

\theoremstyle{tomedefinition}
\newtheorem{definition}[theorem]{Definition}
\newtheorem{example}[theorem]{Example}
\newtheorem{remark}[theorem]{Remark}
\newtheorem{notation}[theorem]{Notation}

\theoremstyle{remark}
\newtheorem*{remark*}{Remark}
\newtheorem*{note*}{Note}

%% -- Proof environment (amsthm)
\renewenvironment{proof}[1][\proofname]{\par
  \pushQED{\qed}\normalfont
  \topsep6\p@\@plus6\p@\relax
  \trivlist\item[\hskip\labelsep\bfseries\color{TomeInk}#1\@addpunct{.}]\ignorespaces
}{\popQED\endtrivlist\@endpefalse}

%% -- Custom tcolorbox environments for display
\tcbuselibrary{skins,breakable,theorems,hooks}

\tcbset{
  tomebase/.style={
    enhanced,
    breakable,
    arc=2pt,
    boxrule=0.8pt,
    left=8pt,
    right=8pt,
    top=6pt,
    bottom=6pt,
    before skip=12pt,
    after skip=12pt,
    fonttitle=\bfseries\small\color{white},
    title style={opacity=0.9},
  }
}

%% Definition box
\newtcolorbox{tomebox}[2][]{
  tomebase,
  colback=TomeBg,
  colframe=TomeInk,
  coltitle=white,
  fonttitle=\bfseries,
  title=#2,
  #1
}

%% Key insight / important note
\newtcolorbox{insight}[1][]{
  tomebase,
  colback=TomeExBg,
  colframe=TomeGold,
  coltitle=TomeInk,
  fonttitle=\bfseries,
  title={Key Insight},
  borderline west={3pt}{0pt}{TomeGold},
  #1
}

%% Warning / caution
\newtcolorbox{caution}[1][]{
  tomebase,
  colback=TomeWarnBg,
  colframe=TomeWarnBorder,
  coltitle=white,
  title={Caution},
  #1
}

%% Historical note
\newtcolorbox{historical}[1][]{
  tomebase,
  colback=TomeBg,
  colframe=TomeRule,
  coltitle=TomeInk,
  fonttitle=\bfseries\itshape,
  title={Historical Note},
  borderline west={3pt}{0pt}{TomeRule},
  #1
}

%% ============================================================
%% Chapter heading design
%% ============================================================
\RequirePackage{titlesec}
\RequirePackage{afterpage}

%% -- Part page (full-page spread)
\titleformat{\part}[display]
  {\normalsize\thispagestyle{empty}\afterpage{\thispagestyle{empty}}}
  {\filleft\color{TomePartFg}\rule{60pt}{0.8pt}\\[8pt]
   \fontsize{14}{18}\selectfont\textsc{Part}\rule{60pt}{0.8pt}}
  {6pt}
  {\filleft\fontsize{36}{42}\selectfont\color{TomePartFg}\bfseries}
  [\thispagestyle{empty}\addtocounter{part}{0}]

\titlespacing*{\part}{0pt}{*18}{*18}

%% Redefine part page background
\renewcommand{\@part}[2][]{%
  \clearpage
  \thispagestyle{empty}
  \null\vfill
  \begin{center}
    \color{TomePartBg}
    \rule{\textwidth}{0.8pt}\par
    \vspace{12pt}
    {\fontsize{16}{20}\selectfont\textsc{Part\ \thepart}}\par
    \vspace{18pt}
    {\fontsize{36}{44}\selectfont\bfseries#2}\par
    \vspace{12pt}
    \rule{\textwidth}{0.8pt}
  \end{center}
  \vfill\clearpage
  \ifx\relax#1\relax\else
    \thispagestyle{empty}
    \null\vfill
    \begin{center}
      \fontsize{14}{20}\selectfont#1
    \end{center}
    \vfill\clearpage
  \fi
}

%% -- Chapter headings (Muchnick-inspired: clean, authoritative)
\titleformat{\chapter}[display]
  {\normalfont\fontsize{14}{18}\selectfont}
  {\filleft\color{TomeChapNum}\rule{40pt}{0.6pt}\\*
   \fontsize{48}{54}\selectfont\bfseries\thechapter}
  {12pt}
  {\filleft\fontsize{22}{28}\selectfont\bfseries\color{TomeInk}}
  [\vspace{6pt}{\color{TomeRule}\rule{80pt}{0.4pt}}]

\titlespacing*{\chapter}{0pt}{-6pt}{36pt}

%% -- Section headings
\titleformat{\section}
  {\normalfont\fontsize{16}{20}\selectfont\bfseries\color{TomeInk}}
  {\thesection}{0.75em}{}
  [{\color{TomeRule}\rule{40pt}{0.3pt}}]

\titlespacing*{\section}{0pt}{24pt}{12pt}

\titleformat{\subsection}
  {\normalfont\fontsize{13}{16}\selectfont\bfseries\color{TomeInk}}
  {\thesubsection}{0.6em}{}

\titlespacing*{\subsection}{0pt}{16pt}{8pt}

\titleformat{\subsubsection}
  {\normalfont\fontsize{12}{14}\selectfont\bfseries\itshape\color{TomeRule}}
  {\thesubsubsection}{0.5em}{}

\titlespacing*{\subsubsection}{0pt}{12pt}{6pt}

%% ============================================================
%% Headers and footers
%% ============================================================
\RequirePackage{fancyhdr}
\pagestyle{fancy}
\fancyhf{}
\fancyhead[LE]{\small\color{TomeRule}\leftmark}
\fancyhead[RO]{\small\color{TomeRule}\rightmark}
\fancyfoot[CE]{\small\color{TomeRule}\thepage}
\fancyfoot[CO]{\small\color{TomeRule}\thepage}
\renewcommand{\headrulewidth}{0pt}
\renewcommand{\footrulewidth}{0pt}

%% Plain style for chapter first pages
\fancypagestyle{plain}{
  \fancyhf{}
  \fancyfoot[C]{\small\color{TomeRule}\thepage}
  \renewcommand{\headrulewidth}{0pt}
  \renewcommand{\footrulewidth}{0pt}
}

%% ============================================================
%% Spacing and line breaks
%% ============================================================
\setstretch{1.15}
\setlength{\parindent}{1.5em}
\setlength{\parskip}{0.3em}
\frenchspacing

%% ============================================================
%% Load support packages from support/ directory
%% ============================================================
\newcommand{\TomeSupportPath}{support}
\newcommand{\loadTomeStyle}[1]{%
  \IfFileExists{\TomeSupportPath/#1.sty}{\RequirePackage{\TomeSupportPath/#1}}{%
    \ClassWarning{the-tome-of-langdev}{Support package #1.sty not found}%
  }%
}

%% Load all support packages
\loadTomeStyle{cextcc-config}
\loadTomeStyle{cextcc-table}
\loadTomeStyle{cextcc-listing}
\loadTomeStyle{cextcc-listing-color}
\loadTomeStyle{cextcc-sudocode}
\loadTomeStyle{cextcc-opsem}
\loadTomeStyle{cextcc-dynsem}
\loadTomeStyle{cextcc-semantics}
\loadTomeStyle{cextcc-tyepthm}
\loadTomeStyle{cextcc-formal-grammar}
\loadTomeStyle{cextcc-graph}
\loadTomeStyle{cextcc-diagram}
\RequirePackage{pgfplots}
\pgfplotsset{compat=1.18}
\loadTomeStyle{cextcc-automta}
\loadTomeStyle{cextcc-axiosm}
\loadTomeStyle{cextcc-bytecode}
\loadTomeStyle{cextcc-forth}
\loadTomeStyle{cextcc-heap}
\loadTomeStyle{cextcc-stack}
\loadTomeStyle{cextcc-pipeline}
\loadTomeStyle{cextcc-process}
\loadTomeStyle{cextcc-shellprompt}
\loadTomeStyle{cextcc-sexpr}
\loadTomeStyle{cextcc-syscall}
\loadTomeStyle{cextcc-threded-code}

%% ============================================================
%% Hyperref (loaded late, as required)
%% ============================================================
\RequirePackage[
  colorlinks=true,
  linkcolor=TomeLink,
  citecolor=TomeCite,
  urlcolor=TomeLink,
  filecolor=TomeLink,
  bookmarks=true,
  bookmarksdepth=3,
  bookmarksnumbered=true,
  breaklinks=true,
  plainpages=false,
  pdfpagelabels=true,
  pdfauthor={J. Ceasar},
  pdftitle={The Tome of Programming Language Development},
  pdfsubject={Programming Language Theory and Compiler Design},
  pdfkeywords={compilers, interpreters, type theory, programming languages, semantics, optimization}
]{hyperref}
\pdfstringdefDisableCommands{%
  \def\lambda{lambda}\def\pi{pi}\def\phi{phi}\def\epsilon{epsilon}%
  \def\omega{omega}\def\beta{beta}\def\eta{eta}\def\infty{infinity}%
  \def\Pi{Pi}\def\Sigma{Sigma}\def\Box{Box}%
}
\RequirePackage{cleveref}

\crefname{theorem}{Theorem}{Theorems}
\crefname{lemma}{Lemma}{Lemmas}
\crefname{definition}{Definition}{Definitions}
\crefname{example}{Example}{Examples}
\crefname{proposition}{Proposition}{Propositions}
\crefname{corollary}{Corollary}{Corollaries}

%% ============================================================
%% Title page
%% ============================================================
\newcommand{\TomeTitlePage}{%
  \thispagestyle{empty}
  \begin{center}
    \vspace*{6cm}
    {\color{TomeInk}\rule{\textwidth}{1.2pt}}\par
    \vspace{1.5cm}
    {\fontsize{36}{44}\selectfont\bfseries\color{TomeInk}
     The Tome of\\[6pt] Programming Language Development}\par
    \vspace{1.2cm}
    {\color{TomeInk}\rule{\textwidth}{1.2pt}}\par
    \vspace{2cm}
    {\fontsize{18}{24}\selectfont\textsc{J. Ceasar}}\par
    \vfill
    {\fontsize{11}{14}\selectfont\color{TomeRule}
     A comprehensive treatise on the theory, design, and implementation\\
     of programming languages, compilers, and interpreters.}\par
    \vspace{0.5cm}
  \end{center}
  \clearpage
  \thispagestyle{empty}
  \null\vfill
  \begin{center}
    {\small\color{TomeRule}
    \textit{For the builders of languages,\\
    the architects of meaning,\\
    and the keepers of the formal flame.}}\par
    \vspace{2cm}
  \end{center}
  \clearpage
}

%% ============================================================
%% Table of contents styling
%% ============================================================
\renewcommand{\tableofcontents}{%
  \clearpage
  \thispagestyle{plain}
  \chapter*{\contentsname}
  {\color{TomeRule}\rule{\textwidth}{0.4pt}}\par
  \vspace{12pt}
  \@starttoc{toc}{0}
  \clearpage
}

%% ============================================================
%% Bibliography and index
%% ============================================================
\RequirePackage[
  backend=biber,
  style=authoryear,
  sorting=nyt,
  maxcitenames=2,
  giveninits=true,
  doi=false,
  isbn=false,
  url=false,
  eprint=false
]{biblatex}
\addbibresource{references.bib}

\RequirePackage[xindy]{imakeidx}
\makeindex[columns=2, title=Index of Names and Subjects]

%% ============================================================
%% Utility commands
%% ============================================================

%% Cross-reference shorthands
\newcommand{\chref}[1]{\Cref{ch:#1}}
\newcommand{\secref}[1]{\Cref{sec:#1}}
\newcommand{\defref}[1]{\Cref{def:#1}}
\newcommand{\thmref}[1]{\Cref{thm:#1}}
\newcommand{\figref}[1]{\Cref{fig:#1}}
\newcommand{\tabref}[1]{\Cref{tab:#1}}
\newcommand{\eqnref}[1]{\Cref{eq:#1}}
\newcommand{\lstref}[1]{\Cref{lst:#1}}

%% Inline formal notation helpers
\newcommand{\sembrack}[1]{\ensuremath{\llbracket #1 \rrbracket}}
\newcommand{\typearrow}{\ensuremath{\to}}
\newcommand{\typrod}{\ensuremath{\times}}
\newcommand{\typlus}{\ensuremath{+}}
\newcommand{\alltypes}{\ensuremath{\forall}}
\newcommand{\exitypes}{\ensuremath{\exists}}
\newcommand{\turns}{\ensuremath{\vdash}}
\newcommand{\nturns}{\ensuremath{\nvdash}}
\newcommand{\evalto}{\ensuremath{\Downarrow}}
\newcommand{\stepsto}{\ensuremath{\longrightarrow}}
\newcommand{\multistepsto}{\ensuremath{\longrightarrow}^*}
\newcommand{\subst}[3]{\ensuremath{#1[#2/#3]}}
\newcommand{\freeset}[1]{\ensuremath{\mathrm{fv}(#1)}}
\newcommand{\boundset}[1]{\ensuremath{\mathrm{bv}(#1)}}

%% End of proof / QED
\newcommand{\eop}{\ensuremath{\blacksquare}}

%% "Defined as" symbol
\newcommand{\defeq}{\ensuremath{\mathrel{:\!=}}}

%% ============================================================
%% Document begin
%% ============================================================
\AtBeginDocument{
  \TomeTitlePage
}

\endinput
