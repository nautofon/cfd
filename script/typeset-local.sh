#! /bin/bash

# Stop execution on `return 1`
set -e


# This script may be installed on a remote server and called using
# typeset-remote.sh. Alternatively, it may be executed directly.


SCRIPTS_DIR=`dirname "$0"`

cd "$SCRIPTS_DIR"/..


parse_opts () {
  CLEANAUX=0
  DVIPDF=1
  VERBOSE=0
  OPTIND=1
  while getopts "cpv" opt
  do
    case "$opt" in
      c) CLEANAUX=1 ;;
      p) DVIPDF=0 ;;
      v) VERBOSE=1 ;;
    esac
  done
  shift $((OPTIND - 1))
  
  case "$1" in
    all | full)
      typeset_full
      ;;
    cfd | main)
      typeset_main
      ;;
    ??)
      typeset_state "$1"
      ;;
    clean)
      clean_all
      ;;
    "")
      show_usage
      ;;
    *)
      if [ -e "${1%.tex}.tex" ]
      then
        typeset_file "$1"
      else
        show_usage
      fi
      ;;
  esac
}


show_usage () {
  cat <<END
Usage: $(basename $0) [-cpv] all|cfd|<xx>|clean
    all / full = Typeset all files with latexmk
    cfd / main = Single run on main file
    xx (state) = Single run on state file for xx
    clean      = Do cleanup only
  Options:
    -c = Clean .aux / .out / .toc
    -p = Use pdflatex instead of latex+dvipdfm
    -v = Verbose output
END
  exit 2
}


clean_all () {
  if (($CLEANAUX))
  then
    (($VERBOSE)) && v="-v" || v=""
    rm -f $v *.aux *.out *.toc
    rm -f $v cities/*/_all.aux
    rm -f $v latexmkrc *.fdb_latexmk *.fls
  fi
  
  (($VERBOSE)) && (>&2 echo "Removing .pdf / .dvi / .log files.")
  rm -f *.pdf *.ps *.dvi *.log
}


# Writes out a common base name for output files based on today's date.
baseoutname () {
  perl -MTime::Piece -e 'print gmtime->strftime("cfd-%y%m%d")'
}


# Parses \ChapterForState commands from the state _all.tex files to discover
# the SCS token (state directory name) for the given two-letter code.
# Writes out the SCS token.
state_code_to_token () {
  code="$1"
  
  for f in cities/*/_all.tex
  do
    ChapterForState=$( grep '^\\ChapterForState' "$f" )
    name=$( perl -e 'print $2 if $ARGV[0] =~ /\{(..)\}\{(.+)\}/ && lc $1 eq lc $ARGV[1]' "$ChapterForState" "$code" )
    [ -z "$name" ] && continue
    
    token=$( basename "${f%/_all.tex}" )
    (($VERBOSE)) && (>&2 echo "Found token $token for state $name (code $code).")
    echo $token
    return 0
  done
  
  (>&2 echo "No _all.tex file found for state $code. Exiting.")
  return 1
}


# Creates a temporary \includeonly TeX file from the given state _all.tex file.
# Writes out the name of the temp file.
write_state_tex () {
  all_file="${1%.tex}"
  
  if [ ! -e "$all_file.tex" ]
  then
    (>&2 echo "File $all_file.tex not found for state $code. Exiting.")
    return 1
  fi
  
  code=$( perl -ne 'print lc $1 if /^\\ChapterForState(?:\[.*?\])*\{(..)\}/' "$all_file.tex" )
  statefile="$( baseoutname )-$code.tex"
  if [ -e "$statefile" ] && ! (($CLEANAUX))
  then
    (>&2 echo "File $statefile exists. Exiting.")
    return 1
  fi
  
  echo "\includeonly{$all_file} \input{locdescs}" > "$statefile"
  (($VERBOSE)) && (>&2 echo "Created $statefile with \includeonly{$all_file}.")
  echo $statefile
  return 0
}


# Produce a single-chapter PDF for one state.
# The state is identified with the two-letter code.
# Uses the latex+dvipdfm or pdflatex commands directly for a single run.
typeset_state () {
  code="$1"
  
  token=$( state_code_to_token "$1" )
  statefile=$( write_state_tex "cities/$token/_all" )
  
  typeset_file "$statefile"
  
  rm -f "$statefile"
  (($VERBOSE)) && (>&2 echo "Removed $statefile.")
  return 0
}


# Produces a single PDF from the given TeX input file.
# Uses the latex+dvipdfm or pdflatex commands directly for a single run.
typeset_file () {
  filename="${1%.tex}"
  
  for f in cities/*/_all.tex
  do
    touch "${f%.tex}.aux"  # avoid spurious "no file" warnings
  done
  clean_all
  
  (($VERBOSE)) && (>&2 echo "Running single typesetting pass on $filename.")
  
  (($DVIPDF)) && LATEX_CMD="latex" || LATEX_CMD="pdflatex"
  
  if ! $LATEX_CMD -file-line-error "$filename.tex"
  then
    (>&2 echo "$LATEX_CMD $filename.tex failed. Exiting.")
    exit 1
  fi
  if [ -f "$filename.dvi" ]
  then
    if ! dvipdfm "$filename.dvi"
    then
      (>&2 echo "dvipdfm $filename.dvi failed. Exiting.")
      exit 1
    fi
  fi
  return 0
}


# Produce the main PDF, with the entire document in a single file.
# Uses the latex+dvipdfm or pdflatex commands directly for a single run.
typeset_main () {
  cfdfile="$( baseoutname ).pdf"
  
  typeset_file "locdescs"
  
  mv "locdescs.pdf" "$cfdfile"
  (($VERBOSE)) && (>&2 echo "Created $cfdfile.")
  return 0
}


# Produce all PDFs: the main one and all single-chapter PDFs for every state.
# Uses latexmk to ensure as many runs as necessary.
typeset_full () {
  clean_all
  
  baseoutname=$( baseoutname )
  cp locdescs.tex "$baseoutname.tex"
  (($VERBOSE)) && (>&2 echo "Created $baseoutname.tex.")
  
  state_tex_files=""
  for f in cities/*/_all.tex
  do
    state_tex_files="$state_tex_files $( write_state_tex "$f" )"
  done
  
  pdfdvi=""
  if (($DVIPDF))
  then
    tee latexmkrc <<'END'
$dvipdf = 'dvipdfm %O -o %D %S';
END
    pdfdvi="-pdfdvi"
  fi
  
  latexmk $pdfdvi -file-line-error "$baseoutname.tex" "$baseoutname"-*.tex
  
  (($VERBOSE)) && v="-v" || v=""
  rm -f $v latexmkrc "$baseoutname.tex" $state_tex_files
}


parse_opts $@
