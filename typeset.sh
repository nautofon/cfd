#! /bin/bash


# see .ssh/config
server="latex-server"

if ! rsync -ahi --partial --inplace --no-whole-file \
  --exclude '.DS_Store' --exclude '*+.tex' \
  cfd cities locdescs.cls locdescs.tex \
  "$server:tex/"
then
  (>&2 echo "rsync tex failed. Exiting.")
  exit 1
fi

if ! ssh $server 'cd tex && .locdescs/run.sh --fast'
then
  (>&2 echo "remote run failed. Exiting.")
  exit 1
fi

if ! rsync -ahi --partial --inplace --no-whole-file \
  "$server:tex/locdescs.pdf" \
  .
# tex/locdescs.log
then
  (>&2 echo "rsync pdf failed. Exiting.")
  exit 1
fi

echo "Success!"
