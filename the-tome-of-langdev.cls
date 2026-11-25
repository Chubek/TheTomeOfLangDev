%%
%% the-tome-of-langdev.cls
%% Document class for "The Tome of Programming Language Development"
%% A comprehensive treatise on programming language theory, design, and implementation.
%%
%% Typeset with care after the tradition of Muchnick's "Advanced Compiler Design"
%% and Knuth's "Computers & Typesetting", updated for the modern era.
%%
\NeedsTeXFormat{LaTeX2e}[2020-10-01]
\ProvidesClass{the-tome-of-langdev}[2026/11/12 v2.0 The Tome of Programming Language Development]

%% ============================================================
%% Base class and core options
%% ============================================================
%% The standard book class silently ignores 14pt. Keep the manuscript's
%% existing option working, but use a deliberate, supported text size.
\DeclareOption{14pt}{%
  \PassOptionsToClass{12pt}{book}%
  \ClassInfo{the-tome-of-langdev}{Using 12pt book typography for the legacy 14pt option}%
}
\DeclareOption*{\PassOptionsToClass{\CurrentOption}{book}}
\ProcessOptions\relax
\LoadClass[12pt,a4paper,twoside,openright]{book}

%% ============================================================
%% Required packages
%% ============================================================
\RequirePackage{iftex}
\RequirePackage{etoolbox}
\RequirePackage{xparse}
\RequirePackage{xspace}

%% -- A readable measure, a binding allowance, and room for running heads
\RequirePackage[
  paperwidth=210mm,
  paperheight=297mm,
  top=29mm,
  bottom=32mm,
  inner=28mm,
  outer=30mm,
  bindingoffset=3mm,
  headheight=30pt,
  headsep=7mm,
  footskip=14mm,
  marginparsep=4mm,
  marginparwidth=20mm
]{geometry}

%% -- Typography fundamentals
%% Expansion is enabled automatically only on engines that support it.
\RequirePackage[protrusion=true]{microtype}
\RequirePackage{setspace}
\RequirePackage{ragged2e}
\RequirePackage{enumitem}
\RequirePackage{needspace}
\RequirePackage{fvextra}
\RequirePackage{eso-pic}

%% -- Load legacy math packages before unicode-math to avoid symbol conflicts.
\RequirePackage{amsmath,amssymb,amsthm,mathtools}
\RequirePackage{stmaryrd}

%% -- Font setup (conditional on engine)
\ifTUTeX
  \RequirePackage{fontspec}
  \RequirePackage{unicode-math}
  \ifLuaTeX
    %% Keep otherwise missing mathematical characters and multilingual
    %% identifiers visible, without replacing the book's Latin typefaces.
    \directlua{luaotfload.add_fallback("tome-text", {"file:texgyrepagella-math.otf:mode=node;"})}
    \defaultfontfeatures[TeX Gyre Pagella]{RawFeature={fallback=tome-text}}
    \IfFontExistsTF{Noto Sans Mono CJK SC}{%
      \directlua{luaotfload.add_fallback("tome-mono", {"name:Noto Sans Mono CJK SC:mode=harf;"})}%
      \defaultfontfeatures[DejaVu Sans Mono]{RawFeature={fallback=tome-mono}}%
    }{%
      \ClassWarning{the-tome-of-langdev}{Install Noto Sans Mono CJK SC for CJK identifiers}%
    }%
  \fi
  \setmainfont[
    Ligatures=TeX,
    Numbers={OldStyle,Proportional},
    SmallCapsFeatures={Letters=SmallCaps}
  ]{TeX Gyre Pagella}
  \setsansfont[
    Scale=MatchLowercase,
    Ligatures=TeX,
    Numbers={Lining,Proportional}
  ]{TeX Gyre Heros}
  \setmonofont[
    Scale=0.82,
    Ligatures=NoCommon
  ]{DejaVu Sans Mono}
  %% Resolve the math font through TeX's font tree on both Unicode engines.
  \setmathfont{texgyrepagella-math.otf}
  \setmathrm{TeX Gyre Pagella}
  \setmathsf{TeX Gyre Heros}
  \setmathtt{DejaVu Sans Mono}
  \newbool{HasUnicode}\booltrue{HasUnicode}
\else
  \RequirePackage[T1]{fontenc}
  \RequirePackage[utf8]{inputenc}
  \RequirePackage{tgpagella}
  \RequirePackage[scale=0.94]{tgheros}
  \RequirePackage[scaled=0.82]{DejaVuSansMono}
  \RequirePackage{newpxmath}
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

%% Find support packages by their actual package names, avoiding duplicate
%% loads and the "requested support/foo, but provides foo" warnings.
\newcommand{\TomeSupportPath}{support}
\providecommand{\input@path}{}
\g@addto@macro\input@path{{support/}}
\newcommand{\loadTomeStyle}[1]{%
  \IfFileExists{\TomeSupportPath/#1.sty}{\RequirePackage{#1}}{%
    \ClassError{the-tome-of-langdev}{Support package #1.sty not found}%
      {Build from the book root with the support directory present.}%
  }%
}
\loadTomeStyle{cextcc-config}

%% ============================================================
%% tcolorbox — theorem-like and display environments
%% ============================================================
%% Shared palette and box styles are defined once in cextcc-config.

%% -- Theorem styles
\newtheoremstyle{tomeplain}
  {10pt plus 3pt minus 2pt}
  {10pt plus 3pt minus 2pt}
  {\itshape}
  {}
  {\sffamily\bfseries\color{TomeInk}}
  {.}
  {0.5em}
  {\thmname{#1}\thmnumber{ #2}\thmnote{ {\normalfont\color{TomeRule}(#3)}}}

\newtheoremstyle{tomedefinition}
  {10pt plus 3pt minus 2pt}
  {10pt plus 3pt minus 2pt}
  {\normalfont}
  {}
  {\sffamily\bfseries\color{TomeInk}}
  {.}
  {0.5em}
  {\thmname{#1}\thmnumber{ #2}\thmnote{ {\normalfont\color{TomeRule}(#3)}}}

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

%% Keep a statement heading with enough of its opening to be useful.
\newcommand{\TomeKeepStatement}[1]{%
  \BeforeBeginEnvironment{#1}{\Needspace{3\baselineskip}}%
}
\forcsvlist{\TomeKeepStatement}{theorem,lemma,proposition,corollary,conjecture,definition,example,remark,notation}

%% -- Proof environment (amsthm)
\renewenvironment{proof}[1][\proofname]{\par
  \pushQED{\qed}\normalfont
  \topsep8\p@\@plus3\p@\relax
  \trivlist\item[\hskip\labelsep\sffamily\bfseries\color{TomeInk}#1\@addpunct{.}]\ignorespaces
}{\popQED\endtrivlist\@endpefalse}

%% -- Custom tcolorbox environments for display
%% Definition box
\newtcolorbox{tomebox}[2][]{
  tomebase,
  colback=TomeBg,
  colframe=TomeInk,
  title=#2,
  #1
}

%% Key insight / important note
\newtcolorbox{insight}[1][]{
  tomebase,
  colback=TomeExBg,
  colframe=TomeGold,
  colbacktitle=TomeExBg,
  title={Key Insight},
  #1
}

%% Warning / caution
\newtcolorbox{caution}[1][]{
  tomebase,
  colback=TomeWarnBg,
  colframe=TomeWarnBorder,
  colbacktitle=TomeWarnBg,
  coltitle=TomeWarnBorder,
  title={Caution},
  #1
}

%% Historical note
\newtcolorbox{historical}[1][]{
  tomebase,
  colback=TomeBg,
  colframe=TomeRule,
  colbacktitle=TomeBg,
  coltitle=TomeRule,
  title={Historical Note},
  #1
}

%% ============================================================
%% Chapter heading design
%% ============================================================
\RequirePackage{titlesec}

%% Continuous Arabic folios, including front and back matter. Do not reset
%% the counter: printed folios, PDF page labels, and link destinations agree.
\newif\ifTomeBodyStarted
\renewcommand{\frontmatter}{\cleardoublepage\@mainmatterfalse}
\renewcommand{\mainmatter}{%
  \cleardoublepage\@mainmattertrue\TomeBodyStartedtrue
}
%% This manuscript has no explicit \mainmatter. Its first numbered part is
%% the boundary; subsequent parts must not reset either chapters or pages.
\AddToHook{cmd/part/before}{\ifTomeBodyStarted\else\mainmatter\fi}
\renewcommand{\cleardoublepage}{%
  \clearpage
  \if@twoside\ifodd\c@page\else
    \hbox{}\thispagestyle{empty}\newpage
    \if@twocolumn\hbox{}\newpage\fi
  \fi\fi
}

%% -- Part dividers: retain book's counter, TOC, optional short title, and
%% recto/verso handling. The background belongs to this shipout only.
\renewcommand{\@part}[2][]{%
  \ifnum\c@secnumdepth>-2\relax
    \refstepcounter{part}%
    \addcontentsline{toc}{part}{\thepart\hspace{1em}#1}%
  \else
    \addcontentsline{toc}{part}{#1}%
  \fi
  \markboth{}{}%
  \thispagestyle{empty}%
  \AddToShipoutPictureBG*{%
    \AtPageLowerLeft{\color{TomePartBg}\rule{\paperwidth}{\paperheight}}%
  }%
  {\parindent\z@\raggedright\hyphenpenalty=10000\exhyphenpenalty=10000\color{TomePartFg}%
    {\color{TomeGold}\rule{20mm}{1.4pt}}\par
    \vspace{9mm}%
    \ifnum\c@secnumdepth>-2\relax
      {\sffamily\large\color{TomeGold}\partname\enspace\thepart\par}%
      \vspace{6mm}%
    \fi
    {\fontsize{34}{40}\selectfont\bfseries #2\par}%
    \vspace{12mm}%
    {\color{TomePartFg!35!TomePartBg}\rule{\textwidth}{0.4pt}}\par
  }%
  \vfil\@endpart
}

%% -- Chapter openings: an oversized numeral, a clear left-aligned title,
%% and one gold rule rather than competing rules at every heading level.
\titleformat{\chapter}[display]
  {\normalfont\raggedright\hyphenpenalty=10000\exhyphenpenalty=10000}
  {\sffamily\fontsize{64}{66}\selectfont\bfseries\color{TomeChapNum}\thechapter}
  {14pt}
  {\fontsize{29}{35}\selectfont\bfseries\color{TomeInk}}
  [\vspace{12pt}{\color{TomeGold}\titlerule[1pt]}]

\titleformat{name=\chapter,numberless}[display]
  {\normalfont\raggedright\hyphenpenalty=10000\exhyphenpenalty=10000}
  {}{0pt}
  {\fontsize{29}{35}\selectfont\bfseries\color{TomeInk}}
  [\vspace{12pt}{\color{TomeGold}\titlerule[1pt]}]
\titlespacing*{\chapter}{0pt}{6pt}{30pt}

%% -- Section headings
\titleformat{\section}
  {\normalfont\sffamily\fontsize{16}{20}\selectfont\bfseries\raggedright\color{TomeInk}}
  {\thesection}{0.65em}{}

\titlespacing*{\section}{0pt}{22pt plus 5pt minus 3pt}{9pt}

\titleformat{\subsection}
  {\normalfont\sffamily\fontsize{12}{16}\selectfont\bfseries\raggedright\color{TomeInk}}
  {\thesubsection}{0.6em}{}

\titlespacing*{\subsection}{0pt}{16pt plus 4pt minus 2pt}{6pt}

\titleformat{\subsubsection}
  {\normalfont\normalsize\bfseries\raggedright\color{TomeRule}}
  {\thesubsubsection}{0.5em}{}

\titlespacing*{\subsubsection}{0pt}{12pt plus 3pt minus 2pt}{5pt}
\setcounter{secnumdepth}{2}

%% ============================================================
%% Headers and footers
%% ============================================================
\RequirePackage{fancyhdr}
\pagestyle{fancy}
\fancyhf{}
\fancyhead[LE]{\parbox[b]{\textwidth}{\raggedright\footnotesize\sffamily\color{TomeRule}\nouppercase{\leftmark}\par}}
\fancyhead[RO]{\parbox[b]{\textwidth}{\raggedleft\footnotesize\sffamily\color{TomeRule}\nouppercase{\rightmark}\par}}
\newcommand{\TomeFolio}{{\sffamily\small\color{TomeInk}\TomeLining{\thepage}}}
\fancyfoot[LE,RO]{\TomeFolio}
\renewcommand{\headrulewidth}{0pt}
\renewcommand{\footrulewidth}{0pt}

%% Plain style for chapter first pages
\fancypagestyle{plain}{
  \fancyhf{}
  \fancyfoot[C]{\TomeFolio}
  \renewcommand{\headrulewidth}{0pt}
  \renewcommand{\footrulewidth}{0pt}
}
\renewcommand{\chaptermark}[1]{%
  \markboth{\if@mainmatter\thechapter\enspace\fi #1}{#1}%
}
\renewcommand{\sectionmark}[1]{\markright{\thesection\enspace #1}}

%% ============================================================
%% Spacing and line breaks
%% ============================================================
\setstretch{1.07}
\setlength{\parindent}{1.25em}
\setlength{\parskip}{0pt plus 0.6pt}
\setlength{\emergencystretch}{1.5em}
\clubpenalty=10000
\widowpenalty=10000
\displaywidowpenalty=10000
\brokenpenalty=5000
\predisplaypenalty=2500
\allowdisplaybreaks[1]
\raggedbottom
\frenchspacing
\setlist{topsep=6pt plus 2pt minus 2pt,itemsep=3pt plus 1pt,
  parsep=0pt,partopsep=0pt,leftmargin=1.8em}
\setlist[itemize,1]{label={\small\color{TomeGold}\textbullet}}
\setlist[enumerate,1]{label=\arabic*.,font=\sffamily\bfseries\color{TomeInk}}
\setlist[description]{font=\sffamily\bfseries\color{TomeInk},style=nextline}
\setlength{\skip\footins}{12pt plus 4pt minus 2pt}
\setlength{\footnotesep}{9pt}
\renewcommand{\footnoterule}{%
  \kern-3pt{\color{TomeGold}\hrule width 0.2\textwidth height 0.45pt}\kern2.55pt
}
%% Most manuscript code uses plain verbatim; it deserves the same care as
%% named listings, including safe wrapping of long, unbreakable lines.
\RecustomVerbatimEnvironment{verbatim}{Verbatim}{%
  fontsize=\small,baselinestretch=1,breaklines=true,breakanywhere=true,
  frame=leftline,framerule=0.8pt,rulecolor=\color{TomeGold},
  framesep=3mm,xleftmargin=3mm,xrightmargin=1mm,
  listparameters={\setlength{\topsep}{8pt}\setlength{\partopsep}{0pt}}%
}
\BeforeBeginEnvironment{verbatim}{\TomeBlockStart}
\setcounter{topnumber}{3}
\setcounter{bottomnumber}{2}
\setcounter{totalnumber}{4}
\renewcommand{\topfraction}{0.9}
\renewcommand{\bottomfraction}{0.8}
\renewcommand{\textfraction}{0.08}
\renewcommand{\floatpagefraction}{0.75}
\setlength{\textfloatsep}{15pt plus 4pt minus 3pt}
\setlength{\floatsep}{12pt plus 3pt minus 2pt}
\setlength{\intextsep}{12pt plus 3pt minus 2pt}

%% ============================================================
%% Load support packages from support/ directory
%% ============================================================
%% Load all support packages
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
  pdfdisplaydoctitle=true,
  pdfstartview=FitH,
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
\crefname{algorithm}{Algorithm}{Algorithms}
\crefname{lstlisting}{Listing}{Listings}

%% ============================================================
%% Title page
%% ============================================================
\newcommand{\TomeTitlePage}{%
  \thispagestyle{empty}
  \AddToShipoutPictureBG*{%
    \AtPageLowerLeft{\color{TomeInk}\rule{12mm}{\paperheight}}%
  }%
  {\parindent\z@\RaggedRight
    \vspace*{30mm}%
    {\color{TomeGold}\rule{24mm}{1.5pt}}\par
    \vspace{12mm}%
    {\fontsize{23}{29}\selectfont\color{TomeInk}The Tome of}\par
    \vspace{4mm}%
    {\fontsize{40}{46}\selectfont\bfseries\color{TomeInk}
      Programming\\Language\\Development\par}%
    \vspace{13mm}%
    {\color{TomeGold}\rule{\textwidth}{0.6pt}}\par
    \vspace{9mm}%
    {\sffamily\fontsize{15}{20}\selectfont\color{TomeInk}J. Ceasar}\par
    \vfill
    {\fontsize{11}{16}\selectfont\color{TomeRule}
      A comprehensive treatise on the theory, design, and implementation\\
      of programming languages, compilers, and interpreters.\par}%
    \vspace*{8mm}%
  }%
  \clearpage
  \thispagestyle{empty}
  \null\vfill
  \begin{center}
    {\small\color{TomeRule}
    \textit{For the builders of languages,\\
    the architects of meaning,\\
    and the keepers of the formal flame.}}\par
    \vspace{12mm}
    {\color{TomeGold}\rule{12mm}{0.6pt}}\par
    \vspace{20mm}
  \end{center}
  \clearpage
}

%% ============================================================
%% Table of contents styling
%% ============================================================
\RequirePackage[titles]{tocloft}
\setcounter{tocdepth}{1}
\renewcommand{\cftpartfont}{\sffamily\bfseries\color{TomeInk}}
\renewcommand{\cftpartpagefont}{\sffamily\bfseries\color{TomeInk}}
\renewcommand{\cftchapfont}{\bfseries\color{TomeInk}}
\renewcommand{\cftchappagefont}{\sffamily\small\color{TomeInk}}
\renewcommand{\cftsecfont}{\small}
\renewcommand{\cftsecpagefont}{\sffamily\small}
\renewcommand{\cftchapleader}{\hfill}
\renewcommand{\cftsecleader}{\cftdotfill{2}}
\setlength{\cftbeforepartskip}{16pt plus 3pt}
\setlength{\cftbeforechapskip}{8pt plus 2pt}
\setlength{\cftbeforesecskip}{1pt}
\setlength{\cftchapnumwidth}{2.8em}
\setlength{\cftsecindent}{2.8em}
\setlength{\cftsecnumwidth}{3.8em}
\setlength{\cftfignumwidth}{4em}
\setlength{\cfttabnumwidth}{4em}
\renewcommand{\cftfigfont}{\small}
\renewcommand{\cftfigpagefont}{\sffamily\small\color{TomeInk}}
\setlength{\cftbeforefigskip}{2pt}
\cftsetpnumwidth{3em}
\cftsetrmarg{4em}
\renewcommand{\tableofcontents}{%
  \chapter*{\contentsname}
  \@mkboth{\contentsname}{\contentsname}%
  \begingroup\TomeLining{\@starttoc{toc}}\endgroup
}
\renewcommand{\listoffigures}{%
  \chapter*{\listfigurename}
  \addcontentsline{toc}{chapter}{\listfigurename}%
  \@mkboth{\listfigurename}{\listfigurename}%
  \begingroup\TomeLining{\@starttoc{lof}}\endgroup
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
  uniquename=init,
  doi=false,
  isbn=false,
  url=false,
  eprint=false
]{biblatex}
\addbibresource{references.bib}
\setlength{\bibitemsep}{5pt plus 2pt}
\setlength{\bibhang}{1.5em}
\renewcommand*{\bibfont}{\small}

\RequirePackage[xindy]{imakeidx}
\makeindex[columns=2, title=Index of Names and Subjects]
\indexsetup{othercode={\small\raggedright\setlength{\columnsep}{8mm}}}

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
  \pagenumbering{arabic}%
  \TomeTitlePage
}

\endinput
