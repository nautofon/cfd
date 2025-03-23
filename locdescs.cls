\NeedsTeXFormat{LaTeX2e}
\ProvidesClass{locdescs}[2023/02/10 Company/Facility Directory]
\LoadClass[
%	listof=nochaptergap,
%	listof=totoc,
]{scrbook}
\KOMAoptions{
	%pagesize=pdftex,
	%paper=landscape,
	paper=14cm:21cm,
	%DIV=15,  % 15 is default for 14x21 single page
	twoside=no,
	overfullrule,  % mark overflowing line boxes
	fontsize=10pt,
	headings=normal,  % chapter heading font size (default is 'big', 'small' is also available)
	numbers=noendperiod,  % 1.2.3 instead of 1.2.3. (even in the presence of appendices)
	toc=flat,
	titlepage=no,
}
\pagestyle{headings}
\recalctypearea
%\flushbottom  % only works well if I don't use manual page breaks at all
%\RequirePackage{scrhack}

% https://tex.stackexchange.com/questions/245982/differences-between-texlive-packages-in-linux

% https://www.google.com/search?q=a5+latex+print+on+a4
% https://tex.stackexchange.com/questions/142187/compile-two-a5-pages-on-one-a4-page





% --------------

\RequirePackage[nodayofweek]{datetime}
\newcommand*{\themonthandyear}{\newdateformat{monthyeardate}{\monthname[\THEMONTH] \THEYEAR}\monthyeardate\today}

%\titlehead{\centering Copyright {\small\copyright} 2023. Some rights reserved.}
\subject{City location descriptions for ATS}
\title{Company/Facility Directory}
\author{by nautofon, \themonthandyear}
\date{}

% Header style
\setkomafont{pagehead}{\normalfont\normalcolor\itshape}
\renewcommand*{\chaptermarkformat}{}  % suppress chapter number in header

\newcommand*{\copyrightblock}{{
\centering \vspace{28mm} \footnotesize \itshape
Copyright \raisebox{.2ex}{\scriptsize\copyright} \the\year\ nautofon \par
\vspace{.4ex}
\href{https://creativecommons.org/licenses/by-nc-sa/4.0/}{CC BY-NC-SA 4.0} \par
\vspace{.4ex}
Typeset in \TeX \par
\vspace{5mm}
This file was generated on \today. \par
}}

% titles for continuing section:
%\usepackage[topmarks]{titleps} % "topmarks" assures titles for continuing section 
%\def\header{}
%\newpagestyle{main}{
%  %\setheadrule{.8pt}
%  \sethead{\sectiontitle}
%  {\global\let\header\sectiontitle}
%  {\thepage}}
%\pagestyle{main}
% in scrlayer, there's the following, but the effect isn't quite the same (the count is messed up for pages that begin with a new section)
%\rohead{\righttopmark}
%\renewcommand\chaptermark[1]{\markboth{}{}}
%\renewcommand\sectionmark[1]{\markright{\thesection}}
%\clearpairofpagestyles
%% ("%\markright{#2}" can be used for manual mode)
%%\chead*{\sectionmark}
%%\automark[section]{section}
%%\automark[chapter]{chapter}
%%\automark*[section]{}



% print version only: manual binding correction
% (the BCOR option changes width of text block; a manual offset results in bad layout, but keeps the wrapping intact)
%\addtolength{\hoffset}{1.5mm}

% front matter
%\RequirePackage{hyperxmp}
%\RequirePackage{adjustbox}
%\newcommand*{\makededicationpage}[1]{\clearpage\thispagestyle{empty}\vspace*{\stretch{1}}{\centering #1 \par}\vspace{\stretch{3}}\clearpage}
%\RequirePackage{pdfpages}
% NB: we're gonna need to not use DVI mode for this
% \Ifdvioutput{true branch }{false branch }
% \Ifpdfoutput{true branch }{false branch }

% enable UTF-8 input support
%\RequireXeTeX
%\RequirePackage[no-logos]{xltxtra}
%\XeTeXinputnormalization=1

\RequirePackage[raggedrightboxes]{ragged2e}
\raggedright  % only \RaggedRight does hyphenation, which is not what we want here
\AtBeginDocument{\setlength{\parindent}{15pt}}  % zeroed by RaggedRight

\RequirePackage{xparse}
\RequirePackage{xifthen}
\RequirePackage{color}
\RequirePackage{enumitem}

\Ifdvioutput{\def\pgfsysdriver{pgfsys-dvipdfm.def}}{}
\RequirePackage{tikz}

\RequirePackage{microtype}
% optional; see http://www.khirevich.com/latex/microtype/

\newcommand*{\q}[1]{``#1''}  % "#1"; package csquotes is also nice

% word wrap and hyphenation
\tolerance=1414
\hbadness=2000
\setlength{\emergencystretch}{1.5em}
\hfuzz=.3pt
%\hyphenation{mul-ti-step}
% http://www.tex.ac.uk/FAQ-overfull.html

% use 'normal' (serif) font for all headers and captions
\setkomafont{sectioning}{\normalfont\bfseries}
\setkomafont{descriptionlabel}{\normalfont\bfseries}

\clubpenalty=10000 
\widowpenalty=10000
\displaywidowpenalty=10000

\addtokomafont{caption}{\small}



% Location list and misc macros

\newcommand*{\Location}[1]{\item[#1]}

\newenvironment{LocationList}{%\RaggedRight%
\begin{description}[
	style=unboxed,
	labelwidth=\linewidth,
	leftmargin=1.8em,
	%font=\sffamily\itshape\bfseries,
	%listparindent=0pt,
	%before=\sffamily,
	%beginpenalty=10000,
	%midpenalty=0,
	%endpenalty=10000,
]}%
{\end{description}}

%\newcommand*{\Town}[1]{\textbf{#1}}
\NewDocumentCommand{\Town}{ m O{} }{\textbf{#1#2}}
% \Town just performs highlighting, because scenery towns are important navigational info

% At present, there is no macro for street names. The rule is: Generally use generics abbreviations with ~ (e. g. Main~St), but for cities that exceptionally don't use abbreviations for a good reason (eg. Sandpoint), don't use ~.

\NewDocumentCommand{\Exit}{ m O{} }{% #1 = exit number, #2 = suffix letter
\ifthenelse{\isempty{#2}}{exit~#1}{exit~#1\,#2}%
}
\newcommand*{\Exits}[2]{% #1 = lower exit number, #2 = higher exit number
exit~#1/#2%
}
% \Exits is for cases where what's fundamentally the same single exit has multiple numbers, which is rare

\newcommand*{\GasRestNote}[1]{\noindent\textsl{#1}}
% The alternative to \noindent is to comment the empty line before the note.

\newcommand*{\TODO}[1]{%
\ifthenelse{\equal{\logTODOWarn}{1}}%
{\marginpar{\rule{1.5em}{1em}}\ClassWarning{locdescs}{TODO: "#1"}}{%
}}
\newcommand*{\logTODOWarn}{0}  % 1 for warning, 0 for ignore



% State chapters

\newboolean{isIncompleteState}

\NewDocumentCommand{\ChapterForState}{ O{} m m }{% #1 = incomplete, #2 = chapter code, #3 = chapter title
\chapter*{#3}
\markright{#3} % chapter name in page header
\ifthenelse{\equal{#1}{incomplete}}{
  \setboolean{isIncompleteState}{true}
  \addcontentsline{toc}{chapter}{\protect\numberline{#2}#3 \textsl{(incomplete)}}
  % Disclaimer for incomplete states, only to be shown in the full document
  % (single-chapter runs already have a disclaimer in the back matter)
  \makeatletter\if@partsw\else
    \textsl{The chapter on \@currentlabelname\ is currently still unfinished. Work will likely be completed within the next few weeks.}
  \par\fi\makeatother
}{
  \setboolean{isIncompleteState}{false}
  \addcontentsline{toc}{chapter}{\protect\numberline{#2}#3}
}
\renewcommand{\thepage}{#2-\arabic{page}}
\setcounter{page}{1} % reset page numbering to 1 for each chapter
\renewcommand{\thefigure}{#2-\arabic{figure}}
\setcounter{figure}{1}
\stepcounter{chapter} % increment the (unused) numeric chapter counter
}

% Hide page numbers in toc: With the state abbreviation (= chapter "number")
% included in the page numbers, the page number for chapter AA is always AA-1.
% Hence, page numbers for state chapters are no longer useful information.
% (Might need to revisit this once non-state chapters appear.)
\addtokomafont{chapterentrypagenumber}{\color{white}}

% Allow for wide page numbers in toc (for section entries)
\makeatletter
\renewcommand*{\@pnumwidth}{3.5em}
\makeatother

% Command to include a file if, and only if, \includeonly was used,
% irrespective of the list of files actually given to \includeonly.
% The purpose is to exclude a chapter file from the full document,
% but still have it available for single-chapter runs.
\makeatletter
\newcommand*{\dontinclude}[2][]{% #1 = "input" (to optionally ignore \includeonly restrictions), #2 = filename
\if@partsw
\ifthenelse{\equal{#1}{input}}{\clearpage\input{#2}}{\include{#2}}
\fi
}
\makeatother



% City names and refs

% \label and \ref don't accept control sequences, see <https://tex.stackexchange.com/a/60391>
% therefore, the labels can only be copied verbatim from the params, not be lowercased
% specifying a label in the optional param is only necessary iff two cities have the same name

%%%%%\NewDocumentCommand{\City}{ O{} m }{% #1 = label (e.g. SCS token), #2 = visible name
\newcommand*{\City}[2][]{% #1 = label (e.g. SCS token), #2 = visible name
\ifthenelse{\isempty{#1}}{\makeCity{#2}{#2}}{\makeCity{#1}{#2}}}
\newcommand*{\makeCity}[2]{\section*{#2}\label{city:#1}}

\NewDocumentCommand{\CityRef}{ O{} m O{} }{% #1 = label (e.g. SCS token), #2 = visible name, #3 = ref fallback
\ifthenelse{\isempty{#1}}{\CityRef[#2]{#2}[#3]}{%
\ifthenelse{\isempty{#3}}{\makeCityRef{#1}{#2}}{\makeCityRefOrFallback{#1}{#2}{#3}}%
}}
\newcommand*{\makeCityRef}[2]{\hyperref[city:#1]{\makeCityRefText{#2}{p.\,\pageref*{city:#1}}}}
\newcommand*{\makeCityRefText}[2]{\Town{#1} ($\rightarrow$\,#2)}

\makeatletter
\newcommand*{\makeCityRefOrFallback}[3]{\@ifundefined{r@city:#1}%
{\makeCityRefText{#2}{#3}\if@partsw\else\ClassWarning{locdescs}{\refUndefMsg{city:#1}}\fi}%
{\makeCityRef{#1}{#2}}}
\makeatother
\newcommand*{\refUndefMsg}[1]{Reference "#1" (page \thepage) undefined}

% If an individual city exceptionally appears in the TOC, don't show a section number
\setcounter{secnumdepth}{0}



% City disclaimer "not field checked" and sources

\RequirePackage{nameref}
\makeatletter
\newcommand*{\ThisCity}{\@currentlabelname}
\makeatother

\NewDocumentCommand{\CityDisclaimer}{ m O{$\ast$} }{% #1 = reason, #2 = footnote
{\ifthenelse{\equal{#1}{ATS IRL Map} \OR \equal{#1}{Directions Oregon}}%
{\textsl{The location descriptions for \ThisCity\ have not yet been field checked in ATS by the author.\textsuperscript{\scriptsize #2} Use with caution.}}%
{\ifthenelse{\equal{#1}{Quick and dirty Nevada}}%
{\textsl{This is makeshift content for \ThisCity\ in anticipation of the upcoming Nevada rebuild replacing the city entirely. Use with caution.}}%
{\ClassError{locdescs}{CityDisclaimer reason '#1' unsupported}{}}%
}}}



% Common abbreviations

\newcommand*{\MLKing}{M.\,L.\,King}



% Facility designations

\newcommand*{\GarageHQ}{Garage }
\newcommand*{\GasStation}{Gas station }
\newcommand*{\RecruitmentAgency}{Recruitment agency }
\newcommand*{\RestArea}{Rest area }
\newcommand*{\TruckDealer}{truck dealer }
\newcommand*{\TruckStop}{Truck stop }
\newcommand*{\TruckService}{Truck service }
\newcommand*{\TruckWash}{Truck wash }
\newcommand*{\UndergroundTank}{underground tank }



% Facility icons

%\newcommand*{\facilityIconFallback}[1]{ \scriptsize\uppercase{\sffamily\raisebox{.25pt}{#1}}}
\newcommand*{\facilityIconFallback}[1]{%
\hspace{2pt}\raisebox{-1.2pt}{\tikz[baseline=default]{  % baseline=(A.base)
%\draw [help lines] (-0.2,-0.2) grid (2.2,2.2);
% at (1,1) 
\node [text=white, fill=black, rounded corners=2pt, inner sep=2pt] (A) {\sffamily\scriptsize\uppercase{#1}};
}}}
% alternative: \tiny and \hspace{1.75pt}\raisebox{-.7pt}

\newcommand*{\Dealer}{\facilityIconFallback{Dealer}}
\newcommand*{\Garage}{\facilityIconFallback{Garage}}
\newcommand*{\Gas}{\facilityIconFallback{Gas}}
\newcommand*{\Recruitment}{\facilityIconFallback{Recruitment}}
\newcommand*{\Rest}{\facilityIconFallback{Rest}}
\newcommand*{\Service}{\facilityIconFallback{Service}}
\newcommand*{\Weigh}{\facilityIconFallback{Weigh}}
\newcommand*{\SpecialTransport}{\facilityIconFallback{Special\,Transport}}
\newcommand*{\Dynamic}{\facilityIconFallback{Dynamic}}
\newcommand*{\Multiple}{\facilityIconFallback{Multiple}}



% Route shields

% the uniform API for all document-facing shield commands is:
% #1 = route type (e.g. FM in Texas), #2 = number, #3 = special route (e.g. Bus)

\newcommand*{\shieldFallback}[3]{{%
\normalfont\shieldFallbackBox{\footnotesize \raisebox{.33pt}{#1#2}\small\textbf{#3}}%
}}
\definecolor{backgroundfallback}{gray}{0.9}
\newcommand*{\shieldFallbackBox}[1]{\colorbox{backgroundfallback}{\sffamily{#1}}}

\NewDocumentCommand{\shieldInterstate}{ m O{} }{\shieldFallback{I}{-}{#1#2}}
\NewDocumentCommand{\shieldFederal}{ m O{} }{\shieldFallback{US}{\:}{#1#2}}
\NewDocumentCommand{\shieldState}{ m O{\:} m O{} }{\shieldFallback{#1}{#2}{#3#4}}
\NewDocumentCommand{\shieldMinor}{ m O{\:} m O{} }{\shieldFallback{#1}{#2}{#3#4}}

\newcommand*{\shieldUndef}[1]{%
\underline{#1}\marginpar{\rule{1.5em}{1em}}%
\ifthenelse{\equal{\shieldUndefStop}{1}}%
{\ClassError{locdescs}{\shieldUndefMsg{#1}}{}}%
{\ClassWarning{locdescs}{\shieldUndefMsg{#1}}}%
}
\newcommand*{\shieldUndefMsg}[1]{Route shield definition is missing for "#1"}
\newcommand*{\shieldUndefStop}{0}  % 1 for error, 0 for warning

\newcommand*{\shieldFallbackTextAlt}{\:Alt}
\newcommand*{\shieldFallbackTextBus}{\:Bus}
\newcommand*{\shieldFallbackTextByp}{\:Byp}  % bypass
\newcommand*{\shieldFallbackTextHist}{\:Hist}  % historic



% United States

\NewDocumentCommand{\I}{ O{} m O{} }{%
\ifthenelse{\equal{#3}{Bus}}{\shieldINTBus{#2}}{%
\ifthenelse{\NOT \isempty{#3}}{\shieldUndef{I #1 #2 #3}}{%
\ifthenelse{\NOT \isempty{#1}}{\shieldUndef{I #1 #2}}{%
\shieldINT{#2}%
}}}}

\newcommand*{\shieldINTBus}[1]{\shieldInterstate{#1}[\shieldFallbackTextBus]}
\newcommand*{\shieldINT}[1]{\shieldInterstate{#1}}

\NewDocumentCommand{\US}{ O{} m O{} }{%
\ifthenelse{\equal{#3}{Alt}}{\shieldUSAlt{#2}}{%
\ifthenelse{\equal{#3}{Bus}}{\shieldUSBus{#2}}{%
\ifthenelse{\equal{#3}{Byp}}{\shieldUSByp{#2}}{%
\ifthenelse{\equal{#3}{Hist}}{\shieldUSHist{#2}}{%
\ifthenelse{\NOT \isempty{#3}}{\shieldUndef{US #1 #2 #3}}{%
\ifthenelse{\NOT \isempty{#1}}{\shieldUndef{US #1 #2}}{%
\shieldUS{#2}%
}}}}}}}

\newcommand*{\shieldUSAlt}[1]{\shieldFederal{#1}[\shieldFallbackTextAlt]}
\newcommand*{\shieldUSBus}[1]{\shieldFederal{#1}[\shieldFallbackTextBus]}
\newcommand*{\shieldUSByp}[1]{\shieldFederal{#1}[\shieldFallbackTextByp]}
\newcommand*{\shieldUSHist}[1]{\shieldFederal{#1}[\shieldFallbackTextHist]}
\newcommand*{\shieldUS}[1]{\shieldFederal{#1}}



% Arkansas

\NewDocumentCommand{\AR}{ O{} m O{} }{%
\ifthenelse{\equal{#3}{Spur}}{\shieldARS{#2}}{%
\ifthenelse{\NOT \isempty{#3}}{\shieldUndef{AR #1 #2 #3}}{%
\ifthenelse{\NOT \isempty{#1}}{\shieldUndef{AR #1 #2}}{%
\shieldARH{#2}%
}}}}

\newcommand*{\shieldARH}[1]{\shieldState{AR}{#1}}
\newcommand*{\shieldARS}[1]{\shieldState{AR}{#1\,S}}



% Arizona

\NewDocumentCommand{\AZ}{ O{} m O{} }{%
\ifthenelse{\NOT \isempty{#3}}{\shieldUndef{AZ #1 #2 #3}}{%
\ifthenelse{\NOT \isempty{#1}}{\shieldUndef{AZ #1 #2}}{%
\shieldAZSR{#2}%
}}}

\newcommand*{\shieldAZSR}[1]{\shieldState{SR}{#1}}



% California

\NewDocumentCommand{\CA}{ O{} m O{} }{%
\ifthenelse{\NOT \isempty{#3}}{\shieldUndef{CA #1 #2 #3}}{%
\ifthenelse{\NOT \isempty{#1}}{\shieldUndef{CA #1 #2}}{%
\shieldCASR{#2}%
}}}

\newcommand*{\shieldCASR}[1]{\shieldState{SR}{#1}}



% Colorado

\NewDocumentCommand{\CO}{ O{} m O{} }{%
\ifthenelse{\NOT \isempty{#3}}{\shieldUndef{CO #1 #2 #3}}{%
\ifthenelse{\NOT \isempty{#1}}{\shieldUndef{CO #1 #2}}{%
\shieldCOSH{#2}%
}}}

\newcommand*{\shieldCOSH}[1]{\shieldState{SH}{#1}}



% Idaho

\NewDocumentCommand{\ID}{ O{} m O{} }{%
\ifthenelse{\NOT \isempty{#3}}{\shieldUndef{ID #1 #2 #3}}{%
\ifthenelse{\NOT \isempty{#1}}{\shieldUndef{ID #1 #2}}{%
\shieldIDSH{#2}%
}}}

\newcommand*{\shieldIDSH}[1]{\shieldState{SH}[-]{#1}}



% Kansas

\NewDocumentCommand{\KS}{ O{} m O{} }{%
\ifthenelse{\NOT \isempty{#3}}{\shieldUndef{KS #1 #2 #3}}{%
\ifthenelse{\NOT \isempty{#1}}{\shieldUndef{KS #1 #2}}{%
\shieldKS{#2}%
}}}

\newcommand*{\shieldKS}[1]{\shieldState{K}[-]{#1}}



% Montana

\NewDocumentCommand{\MT}{ O{} m O{} }{%
\ifthenelse{\NOT \isempty{#3}}{\shieldUndef{MT #1 #2 #3}}{%
\ifthenelse{\equal{#1}{S}}{\shieldMTS{#2}}{%
\ifthenelse{\NOT \isempty{#1}}{\shieldUndef{MT #1 #2}}{%
\shieldMTH{#2}%
}}}}

\newcommand*{\shieldMTH}[1]{\shieldState{MT}{#1}}
\newcommand*{\shieldMTS}[1]{\shieldMinor{S}[-]{#1}}



% Nebraska

\NewDocumentCommand{\NE}{ O{} m O{} }{%
\ifthenelse{\NOT \isempty{#3}}{\shieldUndef{NE #1 #2 #3}}{%
\ifthenelse{\equal{#1}{Link}}{\shieldNEL{#2}}{%
\ifthenelse{\NOT \isempty{#1}}{\shieldUndef{NE #1 #2}}{%
\shieldNEH{#2}%
}}}}

\newcommand*{\shieldNEH}[1]{\shieldState{N}[-]{#1}}
\newcommand*{\shieldNEL}[1]{\shieldMinor{L}[-]{#1}}



% Nevada

\NewDocumentCommand{\NV}{ O{} m O{} }{%
\ifthenelse{\NOT \isempty{#3}}{\shieldUndef{NV #1 #2 #3}}{%
\ifthenelse{\NOT \isempty{#1}}{\shieldUndef{NV #1 #2}}{%
\shieldNVSR{#2}%
}}}

\newcommand*{\shieldNVSR}[1]{\shieldState{SR}{#1}}



% New Mexico

\NewDocumentCommand{\NM}{ O{} m O{} }{%
\ifthenelse{\NOT \isempty{#3}}{\shieldUndef{NM #1 #2 #3}}{%
\ifthenelse{\NOT \isempty{#1}}{\shieldUndef{NM #1 #2}}{%
\shieldNMSR{#2}%
}}}

\newcommand*{\shieldNMSR}[1]{\shieldState{NM}{#1}}



% Oklahoma

\NewDocumentCommand{\OK}{ O{} m O{} }{%
\ifthenelse{\NOT \isempty{#3}}{\shieldUndef{OK #1 #2 #3}}{%
\ifthenelse{\NOT \isempty{#1}}{\shieldUndef{OK #1 #2}}{%
\shieldOKSH{#2}%
}}}

\newcommand*{\shieldOKSH}[1]{\shieldState{SH}[-]{#1}}



% Oregon

\NewDocumentCommand{\OR}{ O{} m O{} }{%
\ifthenelse{\NOT \isempty{#3}}{\shieldUndef{OR #1 #2 #3}}{%
\ifthenelse{\NOT \isempty{#1}}{\shieldUndef{OR #1 #2}}{%
\shieldORSR{#2}%
}}}

\newcommand*{\shieldORSR}[1]{\shieldState{OR}{#1}}



% Texas

\NewDocumentCommand{\TX}{ O{} m O{} }{%
\ifthenelse{\isempty{#1} \AND \equal{#3}{Bus}}{\shieldTXSHBus{#2}}{%
\ifthenelse{\NOT \isempty{#3}}{\shieldUndef{TX #1 #2 #3}}{%
\ifthenelse{\equal{#1}{FM}}{\shieldTXFM{#2}}{%
\ifthenelse{\equal{#1}{Loop}}{\shieldTXLoop{#2}}{%
\ifthenelse{\equal{#1}{Spur}}{\shieldTXSpur{#2}}{%
\ifthenelse{\NOT \isempty{#1}}{\shieldUndef{TX #1 #2}}{%
\shieldTXSH{#2}%
}}}}}}}

\newcommand*{\shieldTXSHBus}[1]{\shieldState{SH}{#1}[\shieldFallbackTextBus]}
\newcommand*{\shieldTXSH}[1]{\shieldState{SH}{#1}}
\newcommand*{\shieldTXFM}[1]{\shieldMinor{FM}{#1}}
\newcommand*{\shieldTXLoop}[1]{\shieldMinor{Loop}{#1}}
\newcommand*{\shieldTXSpur}[1]{\shieldMinor{Spur}{#1}}



% Utah

\NewDocumentCommand{\UT}{ O{} m O{} }{%
\ifthenelse{\NOT \isempty{#3}}{\shieldUndef{UT #1 #2 #3}}{%
\ifthenelse{\NOT \isempty{#1}}{\shieldUndef{UT #1 #2}}{%
\shieldUTSR{#2}%
}}}

\newcommand*{\shieldUTSR}[1]{\shieldState{SR}[-]{#1}}



% Washington

\NewDocumentCommand{\WA}{ O{} m O{} }{%
\ifthenelse{\NOT \isempty{#3}}{\shieldUndef{WA #1 #2 #3}}{%
\ifthenelse{\NOT \isempty{#1}}{\shieldUndef{WA #1 #2}}{%
\shieldWASR{#2}%
}}}

\newcommand*{\shieldWASR}[1]{\shieldState{SR}{#1}}



% Wyoming

\NewDocumentCommand{\WY}{ O{} m O{} }{%
\ifthenelse{\NOT \isempty{#3}}{\shieldUndef{WY #1 #2 #3}}{%
\ifthenelse{\NOT \isempty{#1}}{\shieldUndef{WY #1 #2}}{%
\shieldWYSH{#2}%
}}}

\newcommand*{\shieldWYSH}[1]{\shieldState{WYO}{#1}}



% URLS and links
% should be one of the last packages imported to avoid issues
% docs: https://ctan.math.utah.edu/ctan/tex-archive/macros/latex/contrib/hyperref/doc/hyperref-doc.html
% hyperref output is specialized for the processing toolchain
% (we prefer dvi because it seems to produce smaller files)
\Ifdvioutput{\RequirePackage[dvipdfm]{hyperref}}{\RequirePackage{hyperref}}
\hypersetup{pdflang=en}
\hypersetup{pdfborder=0 0 0}
\hypersetup{pdfcreator=LaTeX 2e}
\hypersetup{pdfauthor=nautofon}
%\RequirePackage[all]{hypcap}
%\def\UrlFont{\fontfamily{cmvtt}\selectfont}
