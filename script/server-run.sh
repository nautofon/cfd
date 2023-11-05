#! /bin/bash

SUPPDIR=`dirname "$0"`

cd "$SUPPDIR"/..

rm -f *.pdf *.ps *.dvi *.log *.sty
if [ "$1" != "--fast" ]
then
  echo "Slow mode:"
  rm -fv *.aux *.out *.toc
fi

#cp "$SUPPDIR"/*.sty .


LATEX_CMD="latex"
#LATEX_CMD="pdflatex"

if ! $LATEX_CMD --file-line-error locdescs.tex
then
  (>&2 echo "$LATEX_CMD failed. Exiting.")
  exit 1
fi

if [ "$1" != "--fast" ]
then
  if ! $LATEX_CMD --file-line-error locdescs.tex
  then
    (>&2 echo "$LATEX_CMD run 2 failed. Exiting.")
    exit 1
  fi
fi

if [ -f locdescs.dvi ]
then
  if ! dvipdfm locdescs.dvi
  then
    (>&2 echo "dvipdfm failed. Exiting.")
    exit 1
  fi
fi


# if ! pdflatex --file-line-error locdescs.tex
# then
#   (>&2 echo "pdflatex failed. Exiting.")
#   exit 1
# fi
# 
# if [ "$1" != "--fast" ]
# then
#   if ! pdflatex --file-line-error locdescs.tex
#   then
#     (>&2 echo "pdflatex run 2 failed. Exiting.")
#     exit 1
#   fi
# fi
