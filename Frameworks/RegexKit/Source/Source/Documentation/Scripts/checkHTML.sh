#!/bin/sh

# IMPORTANT!
#
# The tidy shipped with 10.4, /usr/bin/tidy, has a version date of 12/01/2004.
# Unfortunately this version erroneously reports problems wrt/ nested <span> elements.
#
# We attempt to overcome this by looking in a few reasonable places for a more recent 'tidy' if the 
#

export DOCUMENTATION_TARGET_DIR=${DOCUMENTATION_TARGET_DIR:?"error: Environment variable DOCUMENTATION_TARGET_DIR must exist, aborting."}
export FIND=${FIND:?"Environment variable FIND must exist, aborting."}
export PROJECT_DIR=${PROJECT_DIR:?"Environment variable PROJECT_DIR must exist, aborting."}
export PERL=${PERL:-perl}

check_tidy()
{
  local -x TIDY_CMD=`command -v "$1"`;
  if [ "${TIDY_CMD}" == "" ]; then return 1; fi;
  local -x TIDY_VERSION=`"${TIDY_CMD}" -v`;
  local TIDY_VERSION_NUMBER=`"${PERL}" -e '%months = (jan=>1,feb=>2,mar=>3,apr=>4,may=>5,jun=>6,jul=>7,aug=>8,sep=>9,oct=>10,nov=>11,dec=>12); $ENV{TIDY_VERSION} =~ /\b(\d+)\w* (Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\w* (\d{2,4})\b/is; printf("%4.4d%2.2d%2.2d\n",\$3,\$months{lc(\$2)},\$1);'`
  if (( ${TIDY_VERSION_NUMBER} > 20041201 )) ; then return 0; else return 1; fi;
}

problem_exit()
{
  if [ "${PROBLEM_LEVEL}" == "warning" ]; then exit 0; else exit 1; fi;
}

PROBLEM_LEVEL="warning"

if (( $# > 1 )); then echo "error: Usage: $0 [--error]" exit 1; fi;  
if (( $# == 1 )); then if [ "$1" == "--error" ]; then PROBLEM_LEVEL="error"; else echo "error: Unrecognized option: '$1'."; exit 1; fi; fi;

TIDY_OK=0;
TIDY_LIST="tidy /usr/bin/tidy /usr/local/bin/tidy /opt/local/bin/tidy /sw/bin/tidy"

if [ ! ${TIDY:=} ]; then
    for TRY_TIDY in ${TIDY_LIST}; do
        TRY_TIDY_CMD=`command -v "${TRY_TIDY}"`;
        if [ "${TRY_TIDY_CMD}" ] ; then TIDY_CMD="${TRY_TIDY_CMD}"; TIDY_TRIED="${TRY_TIDY}"; fi;
        if check_tidy "${TRY_TIDY}"; then TIDY="${TRY_TIDY}"; TIDY_OK=1; break; fi; 
    done;
    if [ ! "${TIDY_CMD}" ] ; then echo "$0:$LINENO: ${PROBLEM_LEVEL}: Couldn't find a 'tidy' executable."; fi;
else
    TIDY_CMD_ORIGINAL="${TIDY}";
    TIDY_CMD=`command -v "${TIDY_CMD}"`;
    if check_tidy "${TIDY_CMD}"; then TIDY_OK=1; fi; 
fi;

if [ "${TIDY_CMD}" ] ; then TIDY_VERSION=`"${TIDY_CMD}" -v`; fi;

if [ ${TIDY_CMD_ORIGINAL:-0} == 0 ] && [ "${TIDY}" ]; then echo "$0:$LINENO: note: The environment variable TIDY is not set, but searched (${TIDY_LIST}) for a usable, up to date version.  Picked '${TIDY_TRIED}' which resolved to '${TIDY_CMD}'. Version check status: '${TIDY_OK}' (0 = unuseable, 1 = usable)."; fi;

# Check if we have a usable tidy..
if [ "${TIDY_CMD_ORIGINAL}" ] && [ ! "${TIDY_CMD}" ]; then
  echo "$0:$LINENO: ${PROBLEM_LEVEL}: The environment variable TIDY_CMD ('${TIDY_CMD_ORIGINAL}') does not reference a valid executable.";
  problem_exit;
fi;

# See the beginning of this file for notes regarding the version of tidy shipped with 10.4
if [ "${TIDY_CMD}" ] && [ ${TIDY_OK} == 0 ]; then
  echo "$0:$LINENO: warning: Unable to check the HTML documentation because the tidy command '${TIDY_CMD}' is too old.  '${TIDY_CMD}' version: '${TIDY_VERSION}'. Required: After 12/01/2004.";
  exit 0;
fi;

# Safety net.
if [ ${TIDY_OK} != 1 ] || [ ! "${TIDY_CMD}" ]; then
  echo "$0:$LINENO: ${PROBLEM_LEVEL}: Unable to find a usable 'tidy' executable.";
  exit 0;
fi;

echo "$0:$LINENO: note: Using '${TIDY}' which resolves to '${TIDY_CMD}'."; 

echo "$0:$LINENO: note: Checking documentation for HTML errors."

HTML_FILES=`"${FIND}" "${DOCUMENTATION_TARGET_DIR}" -name "*.html" -and -not -name "toc.html" -maxdepth 1`
PRINTED_TIDY_BANNER="No";

for FILE in ${HTML_FILES}; do
  export FILE
  "${TIDY_CMD}" -eq "${FILE}" >/dev/null 2>&1
  if [ $? != 0 ]; then
    if [ "${PRINTED_TIDY_BANNER}" == "No" ]; then echo "${PROBLEM_LEVEL}: Tidy detected the following issues."; PRINTED_TIDY_BANNER="Yes"; fi;
    "${TIDY_CMD}" -eq "${FILE}" 2>&1 | "${PERL}" -e '($FILE = $ENV{"FILE"}) =~ s/$ENV{"PROJECT_DIR"}\///; while(<>) { if(/^line\s+(\d+)\s.*\s+(warning|error):\s+(.*)/i) { printf("%s: $FILE @ line $1 - $3\n", lc($2)); } else { print("warning: $FILE: $_"); } }'
  fi
done;

if [ "${PRINTED_TIDY_BANNER}" != "Yes" ]; then
  echo "$0:$LINENO: note: HTML documentation check complete, no errors.";
else
  exit 1;
fi;

exit 0;
