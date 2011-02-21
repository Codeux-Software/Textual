#!/bin/sh

export DOCUMENTATION_TARGET_DIR=${DOCUMENTATION_TARGET_DIR:?"error: Environment variable DOCUMENTATION_TARGET_DIR must exist, aborting."}
export DOCUMENTATION_MISC_DIR=${DOCUMENTATION_MISC_DIR:?"error: Environment variable DOCUMENTATION_MISC_DIR must exist, aborting."}
export FIND=${FIND:?"error: Environment variable FIND must exist, aborting."}
export PROJECT_DIR=${PROJECT_DIR:?"Environment variable PROJECT_DIR must exist, aborting."}

MISSPELL_LEVEL="warning"

if (( $# > 1 )); then echo "error: Usage: $0 [--error]" exit 1; fi;  
if (( $# == 1 )); then if [ "$1" == "--error" ]; then MISSPELL_LEVEL="error"; else echo "error: Unrecognized option: '$1'."; exit 1; fi; fi;

if [ "${ASPELL}" == "" ]; then
  if [ -x aspell ]; then ASPELL="aspell";
  elif [ -x /usr/local/bin/aspell ]; then ASPELL="/usr/local/bin/aspell";
  elif [ -x /opt/local/bin/aspell ]; then ASPELL="/opt/local/bin/aspell";
  elif [ -x /sw/bin/aspell ]; then ASPELL="/sw/bin/aspell";
  fi
fi

if [ "${ASPELL}" == "" ]; then
  echo "$0:$LINENO: warning: Unable to locate the spell checking program 'aspell', documentation will not be spell checked.";
  exit 0;
fi

BAD_SPELLING="";
BAD_COUNT=0;

echo "$0:$LINENO: note: Spell checking documentation."

BAD_SPELLING=`"${FIND}" "${DOCUMENTATION_TARGET_DIR}" -maxdepth 1 -name "*.html" -exec cat {} \; | "${ASPELL}" --conf=/dev/null --per-conf=/dev/null --extra-dicts="${PROJECT_DIR}/${DOCUMENTATION_MISC_DIR}/spelling_words" --personal=nonDefaultFileName -C -H --add-html-check=title --ignore=2 list | sort | uniq`

if [ "${BAD_SPELLING}" != "" ]; then
  for WORD in ${BAD_SPELLING}; do let BAD_COUNT++; done;
  echo "${MISSPELL_LEVEL}: There are ${BAD_COUNT} unique words misspelled.";
  echo "-----"
  for WORD in ${BAD_SPELLING}; do
    echo "Files containing misspelled word: '${WORD}'";
    grep -c "${WORD}" "${DOCUMENTATION_TARGET_DIR}"/*.html | grep -v ':0$'
    echo "-----"
  done;
fi;

if (( "${BAD_COUNT}" == 0 )); then
  echo "$0:$LINENO: note: Spell checking complete, no errors.";
else
  EXIT_CODE=1;
fi;

exit ${EXIT_CODE:-0}

