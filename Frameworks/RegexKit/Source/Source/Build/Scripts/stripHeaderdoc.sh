#!/bin/sh

#
# Run from a 'Script Phase' for the various targets.
# Picks up via environment variables automatically supplied by Xcode to find where the headers are located that it should operate on.
#

echo "Headerdoc comment stripper."

FIND=${FIND:?"error: Environment variable FIND must exist, aborting."}
PERL=${PERL:?"error: Environment variable PERL must exist, aborting."}
PUBLIC_HEADERS_DIR="${TARGET_BUILD_DIR}/${PUBLIC_HEADERS_FOLDER_PATH}"
PUBLIC_HEADERS_FOLDER_PATH=${PUBLIC_HEADERS_FOLDER_PATH:?"error: Environment variable PUBLIC_HEADERS_FOLDER_PATH must exist, aborting."}
TARGET_BUILD_DIR=${TARGET_BUILD_DIR:?"error: Environment variable TARGET_BUILD_DIR must exist, aborting."}
TEMP_FILES_DIR=${TEMP_FILES_DIR:?"error: Environment variable TEMP_FILES_DIR must exist, aborting."}
TIMESTAMP_FILE="${TEMP_FILES_DIR}/headerdoc_striping_timestamp"
TMP_FILE="${TEMP_FILES_DIR}/headerdoc_striping.h"

if [ ! -x "${FIND}"               ]; then echo "$0:$LINENO: error: The FIND command, '${FIND}', does not exist, aborting.";                     exit 1; fi;
if [ ! -x "${PERL}"               ]; then echo "$0:$LINENO: error: The PERL command, '${PERL}', does not exist, aborting.";                     exit 1; fi;
if [ ! -d "${TARGET_BUILD_DIR}"   ]; then echo "$0:$LINENO: error: The TARGET_BUILD_DIR, '${TARGET_BUILD_DIR}', does not exist, aborting.";     exit 1; fi;
if [ ! -d "${PUBLIC_HEADERS_DIR}" ]; then echo "$0:$LINENO: error: The PUBLIC_HEADERS_DIR, '${PUBLIC_HEADERS_DIR}', does not exist, aborting."; exit 1; fi;
if [ ! -d "${TEMP_FILES_DIR}"     ]; then echo "$0:$LINENO: error: The TEMP_FILES_DIR, '${TEMP_FILES_DIR}', does not exist, aborting.";         exit 1; fi;

if [ -f "${TIMESTAMP_FILE}" ]; then
  PUBLIC_HEADERS=`"${FIND}" "${PUBLIC_HEADERS_DIR}" -name '*.h' -newer "${TIMESTAMP_FILE}"`
else
  PUBLIC_HEADERS=`"${FIND}" "${PUBLIC_HEADERS_DIR}" -name '*.h'`
fi

for HEADER in ${PUBLIC_HEADERS}; do
  "${PERL}" -e 'while(<>) { $in = $in . $_; } $in =~ s/\n\s*?\/\*\!.*?\*\///sg; print $in;' "${HEADER}" > "${TMP_FILE}"
  mv "${TMP_FILE}" "${HEADER}"
  export HEADER
  HEADER_FILE=`"${PERL}" -e '($x = "$ENV{HEADER}") =~ /\/?([^\/]+)$/; print($1);'`
  if [ "${PROJECT_HEADERS_DIR}" != "" ]; then
    touch -r "${PROJECT_HEADERS_DIR}/${HEADER_FILE}" "${HEADER}"
  fi
done;

if [ "${PUBLIC_HEADERS}" = "" ]; then
  echo "$0:$LINENO: note: All headers are up to date."
else
  echo "$0:$LINENO: note: Headerdoc comments stripped."
  touch "${TIMESTAMP_FILE}"
fi

