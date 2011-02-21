#!/bin/sh

# Certain parts of this could be a lot better.

# The header doc parser -> db script will actually check modification
# date/times of the header file vs. whats in the database, which
# was added to do make style only update on change.  But the whole
# thing, from db creation, parsing, to generating the html files
# only takes a few seconds so it rebuilds the whole thing from
# scratch each time.  headerdoc2html + gatherheaderdoc would
# drag on and on and on...



export DOCUMENTATION_CHECK_HTML_SCRIPT=${DOCUMENTATION_CHECK_HTML_SCRIPT:?"error: Environment variable DOCUMENTATION_CHECK_HTML_SCRIPT must exist, aborting."}
export DOCUMENTATION_CHECK_SPELLING_SCRIPT=${DOCUMENTATION_CHECK_SPELLING_SCRIPT:?"error: Environment variable DOCUMENTATION_CHECK_SPELLING_SCRIPT must exist, aborting."}
export DOCUMENTATION_GENERATE_HTML_SCRIPT=${DOCUMENTATION_GENERATE_HTML_SCRIPT:?"error: Environment variable DOCUMENTATION_GENERATE_HTML_SCRIPT must exist, aborting."}
export DOCUMENTATION_PARSE_HEADERS_SCRIPT=${DOCUMENTATION_PARSE_HEADERS_SCRIPT:?"error: Environment variable DOCUMENTATION_PARSE_HEADERS_SCRIPT must exist, aborting."}
export DOCUMENTATION_RESOLVE_LINKS_SCRIPT=${DOCUMENTATION_RESOLVE_LINKS_SCRIPT:?"error: Environment variable DOCUMENTATION_RESOLVE_LINKS_SCRIPT must exist, aborting."}
export DOCUMENTATION_RESOURCES_DIR=${DOCUMENTATION_RESOURCES_DIR:?"error: Environment variable DOCUMENTATION_RESOURCES_DIR must exist, aborting."}
export DOCUMENTATION_SOURCE_DIR=${DOCUMENTATION_SOURCE_DIR:?"error: Environment variable DOCUMENTATION_SOURCE_DIR must exist, aborting."}
export DOCUMENTATION_SQL_DATABASE_DIR=${DOCUMENTATION_SQL_DATABASE_DIR:?"error: Environment variable DOCUMENTATION_SQL_DATABASE_DIR must exist, aborting."}
export DOCUMENTATION_SQL_DATABASE_FILE=${DOCUMENTATION_SQL_DATABASE_FILE:?"error: Environment variable DOCUMENTATION_SQL_DATABASE_FILE must exist, aborting."}
export DOCUMENTATION_SQL_DIR=${DOCUMENTATION_SQL_DIR:?"error: Environment variable DOCUMENTATION_SQL_DIR must exist, aborting."}
export DOCUMENTATION_SQL_INIT_FILE=${DOCUMENTATION_SQL_INIT_FILE:?"error: Environment variable DOCUMENTATION_SQL_INIT_FILE must exist, aborting."}
export DOCUMENTATION_SQL_CONFIG_FILE=${DOCUMENTATION_SQL_CONFIG_FILE:?"error: Environment variable DOCUMENTATION_SQL_CONFIG_FILE must exist, aborting."}
export DOCUMENTATION_TARGET_DIR=${DOCUMENTATION_TARGET_DIR:?"error: Environment variable DOCUMENTATION_TARGET_DIR must exist, aborting."}
export DOCUMENTATION_TEMP_DIR=${DOCUMENTATION_TEMP_DIR:?"error: Environment variable DOCUMENTATION_TEMP_DIR must exist, aborting."}
export DOCUMENTATION_TEMPLATES_DIR=${DOCUMENTATION_TEMPLATES_DIR:?"error: Environment variable DOCUMENTATION_TEMPLATES_DIR must exist, aborting."}
export PCRE_INSTALL_DIR=${PCRE_INSTALL_DIR:?"error: Environment variable PCRE_INSTALL_DIR must exist, aborting."}
export PCRE_HTML_DIR=${PCRE_HTML_DIR:?"error: Environment variable PCRE_HTML_DIR must exist, aborting."}
export PERL=${PERL:?"Environment variable PERL must exist, aborting."}
export PROJECT_HEADERS_DIR=${PROJECT_HEADERS_DIR:?"Environment variable PROJECT_HEADERS_DIR must exist, aborting."}
export PROJECT_NAME=${PROJECT_NAME:?"Environment variable PROJECT_NAME must exist, aborting."}
export RSYNC=${RSYNC:?"Environment variable RSYNC must exist, aborting."}
export SQLITE=${SQLITE:?"Environment variable SQLITE must exist, aborting."}

if [ "${XCODE_VERSION_MAJOR}" == "0200" ]; then
  echo "$0:$LINENO: warning: DocSet is only supported on Xcode 3.0 and above.";
  exit 0;
fi

"${PERL}" -e 'require DBD::SQLite;' >/dev/null 2>&1
if [ $? != 0 ]; then echo "$0:$LINENO: error: The perl module 'DBD::SQLite' must be installed in order to build the the target '${TARGETNAME}'."; exit 1; fi;  


TIMESTAMP_FILE="${DOCUMENTATION_DOCSET_TEMP_DIR}/buildDocSet_timestamp"

DOCS_UP_TO_DATE="No";

if [ -f "${TIMESTAMP_FILE}" ]; then
  DOCS_UP_TO_DATE="Yes";
  if [ ! -d "${DOCUMENTATION_DOCSET_TARGET_DIR}" ]; then DOCS_UP_TO_DATE="No"; fi;
  NEWER_FILES=`"${FIND}" "${PROJECT_HEADERS_DIR}" -newer "${TIMESTAMP_FILE}"`;
  if [ "${NEWER_FILES}" != "" ]; then DOCS_UP_TO_DATE="No"; fi;
  NEWER_FILES=`"${FIND}" "${DOCUMENTATION_DOCSET_SOURCE_HTML}" -newer "${TIMESTAMP_FILE}"`;
  if [ "${NEWER_FILES}" != "" ]; then DOCS_UP_TO_DATE="No"; fi;
  NEWER_FILES=`"${FIND}" "${DOCUMENTATION_SOURCE_DIR}" -newer "${TIMESTAMP_FILE}"`;
  if [ "${NEWER_FILES}" != "" ]; then DOCS_UP_TO_DATE="No"; fi;
  if [ $DOCS_UP_TO_DATE == "No" ]; then echo "$0:$LINENO: note: There are newer source files, rebuilding DocSet."; fi;
fi;

if [ $DOCS_UP_TO_DATE == "Yes" ]; then echo "$0:$LINENO: note: DocSet files are up to date."; exit 0; fi;

# Clear the time stamp.  It will be recreated if we are successful.
rm -f "${TIMESTAMP_FILE}"

DOCSETUTIL="${DEVELOPER_BIN_DIR}/docsetutil"

# Used by some scripts we call to report the error location as this shell script.  Sets LINENO when necessary.
export SCRIPT_NAME="$0";

# Scripts that do work for us.
if [ ! -x "${DOCUMENTATION_CREATE_DOCSET_SCRIPT}" ]; then echo "$0:$LINENO: error: The command 'createDocSet.pl' does not exist at '${DOCUMENTATION_CREATE_DOCSET_SCRIPT}'."; exit 1; fi;

# Create the documentation directory if it doesn't exist, and if it does clean it out and start fresh
if [ ! -d "${DOCUMENTATION_DOCSET_TARGET_DIR}" ]; then
    mkdir "${DOCUMENTATION_DOCSET_TARGET_DIR}"
else
  rm -rf "${DOCUMENTATION_DOCSET_TARGET_DIR}"
  mkdir "${DOCUMENTATION_DOCSET_TARGET_DIR}"
fi

rm -rf "${DOCUMENTATION_DOCSET_TEMP_DOCS_DIR}"

mkdir -p "${DOCUMENTATION_DOCSET_TEMP_DOCS_DIR}" && \
  "${RSYNC}" -a --delete --cvs-exclude "${DOCUMENTATION_DOCSET_SOURCE_HTML}/" "${DOCUMENTATION_DOCSET_TEMP_DOCS_DIR}"
if [ $? != 0 ] ; then echo "$0:$LINENO: error: Unable to create temporary DocSet build area directory."; exit 1; fi;

# We always wipe our tables and start fresh so we have semi-consistant ID's
"${SQLITE}" "${DOCUMENTATION_SQL_DATABASE_FILE}" < "${DOCUMENTATION_SQL_DIR}/docset.sql"
if [ $? != 0 ] ; then echo "$0:$LINENO: error: SQL database prep for DocSet failed."; exit 1; fi;

# Execute the DOCUMENTATION_CREATE_DOCSET_SCRIPT script.
echo "$0:$LINENO: note: Creating DocSet '${DOCUMENTATION_DOCSET_ID}'."
"${DOCUMENTATION_CREATE_DOCSET_SCRIPT}"
if [ $? != 0 ] ; then echo "$0:$LINENO: error: DocSet generation failed."; exit 1; fi;

# We lint what we've generated through the docset relaxng schemas to catch
# any mistakes.

DOCSETACCESS_FRAMEWORK="/Developer/Library/PrivateFrameworks/DocSetAccess.framework/Resources"

if [ -x xmllint ] && [ -r "${DOCSETACCESS_FRAMEWORK}/NodesSchema.rng" ]; then
  xmllint --noout --relaxng "${DOCSETACCESS_FRAMEWORK}/NodesSchema.rng" "${DOCUMENTATION_DOCSET_TEMP_DIR}/${DOCUMENTATION_DOCSET_ID}/Contents/Resources/Nodes.xml"
  if [ $? != 0 ] ; then echo "$0:$LINENO: error: DocSet Nodes.xml failed validation test."; exit 1; fi;
fi;

if [ -x xmllint ] && [ -r "${DOCSETACCESS_FRAMEWORK}/TokensSchema.rng" ]; then
  xmllint --noout --relaxng "${DOCSETACCESS_FRAMEWORK}/TokensSchema.rng" "${DOCUMENTATION_DOCSET_TEMP_DIR}/${DOCUMENTATION_DOCSET_ID}/Contents/Resources/Tokens.xml"
  if [ $? != 0 ] ; then echo "$0:$LINENO: error: DocSet Tokens.xml failed validation test."; exit 1; fi;
fi

# 'validate' complains about a lot of things.  I think it's from the very poor
# 'nodes' schema.  It doesn't seem to be broken in practice.
"${DOCSETUTIL}" validate "${DOCUMENTATION_DOCSET_TEMP_DIR}/${DOCUMENTATION_DOCSET_ID}"
if [ $? != 0 ] ; then echo "$0:$LINENO: error: The 'docsetutil' command did not successfully validate the DocSet."; exit 1; fi;


echo "$0:$LINENO: note: Indexing DocSet '${DOCUMENTATION_DOCSET_ID}'."
"${DOCSETUTIL}" index "${DOCUMENTATION_DOCSET_TEMP_DIR}/${DOCUMENTATION_DOCSET_ID}" &&
  mv "${DOCUMENTATION_DOCSET_TEMP_DIR}/${DOCUMENTATION_DOCSET_ID}/Contents/Resources/Nodes.xml" "${DOCUMENTATION_DOCSET_TEMP_DIR}" &&
  mv "${DOCUMENTATION_DOCSET_TEMP_DIR}/${DOCUMENTATION_DOCSET_ID}/Contents/Resources/Tokens.xml" "${DOCUMENTATION_DOCSET_TEMP_DIR}"
if [ $? != 0 ] ; then echo "$0:$LINENO: error: DocSet indexing failed."; exit 1; fi;


echo "$0:$LINENO: note: Packaging DocSet as '${DOCUMENTATION_DOCSET_PACKAGED_FILE}'."
"${DOCSETUTIL}" package -output "${DOCUMENTATION_DOCSET_TEMP_DIR}/${DOCUMENTATION_DOCSET_PACKAGED_FILE}" "${DOCUMENTATION_DOCSET_TEMP_DIR}/${DOCUMENTATION_DOCSET_ID}"
if [ $? != 0 ] ; then echo "$0:$LINENO: error: DocSet packaging failed."; exit 1; fi;

mkdir -p "${DOCUMENTATION_DOCSET_TARGET_DIR}/${DOCUMENTATION_DOCSET_ID}" &&
  "${RSYNC}" -a --delete --cvs-exclude "${DOCUMENTATION_DOCSET_TEMP_DIR}/${DOCUMENTATION_DOCSET_ID}/" "${DOCUMENTATION_DOCSET_TARGET_DIR}/${DOCUMENTATION_DOCSET_ID}" &&
  "${RSYNC}" -a --delete --cvs-exclude "${DOCUMENTATION_DOCSET_TEMP_DIR}/${DOCUMENTATION_DOCSET_PACKAGED_FILE}" "${DOCUMENTATION_DOCSET_TARGET_DIR}"
if [ $? != 0 ] ; then echo "$0:$LINENO: error: Unable top copy the created DocSet to its final location."; exit 1; fi;


echo "$0:$LINENO: note: Clean build, touching timestamp.";
touch "${TIMESTAMP_FILE}";
