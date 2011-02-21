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

"${PERL}" -e 'require DBD::SQLite;' >/dev/null 2>&1
if [ $? != 0 ]; then echo "$0:$LINENO: error: The perl module 'DBD::SQLite' must be installed in order to build the the target '${TARGETNAME}'."; exit 1; fi;  

TIMESTAMP_FILE="${DOCUMENTATION_TEMP_DIR}/buildDocumentation_timestamp"

DOCS_UP_TO_DATE="No";

if [ -f "${TIMESTAMP_FILE}" ]; then
  DOCS_UP_TO_DATE="Yes";
  if [ ! -d "${DOCUMENTATION_TARGET_DIR}" ]; then DOCS_UP_TO_DATE="No"; fi;
  NEWER_FILES=`"${FIND}" "${PROJECT_HEADERS_DIR}" -newer "${TIMESTAMP_FILE}"`;
  if [ "${NEWER_FILES}" != "" ]; then DOCS_UP_TO_DATE="No"; fi;
  NEWER_FILES=`"${FIND}" "${DOCUMENTATION_SOURCE_DIR}" -newer "${TIMESTAMP_FILE}"`;
  if [ "${NEWER_FILES}" != "" ]; then DOCS_UP_TO_DATE="No"; fi;
  if [ $DOCS_UP_TO_DATE == "No" ]; then echo "$0:$LINENO: note: There are newer source files, rebuilding documentation."; fi;
fi;

if [ $DOCS_UP_TO_DATE == "Yes" ]; then echo "$0:$LINENO: note: Documentation files are up to date."; exit 0; fi;

# Clear the time stamp.  It will be recreated if we are successful.
rm -f "${TIMESTAMP_FILE}"

if [ ! -r "${DOCUMENTATION_SQL_INIT_FILE}" ];   then echo "$0:$LINENO: error: The sql database creation file 'init.sql' does not exist at '${DOCUMENTATION_SQL_INIT_FILE}'.";      exit 1; fi;
if [ ! -r "${DOCUMENTATION_SQL_CONFIG_FILE}" ]; then echo "$0:$LINENO: error: The sql configuration data file 'config.sql' does not exist at '${DOCUMENTATION_SQL_CONFIG_FILE}'."; exit 1; fi;

export GENERATED_HTML_DIR="${TEMP_FILES_DIR}/Documentation"

# Used by some scripts we call to report the error location as this shell script.  Sets LINENO when necessary.
export SCRIPT_NAME="$0";

# Scripts that do work for us.
if [ ! -x "${DOCUMENTATION_GENERATE_HTML_SCRIPT}" ]; then echo "$0:$LINENO: error: The command 'generateHTML.pl' does not exist at '${DOCUMENTATION_GENERATE_HTML_SCRIPT}'."; exit 1; fi;
if [ ! -x "${DOCUMENTATION_PARSE_HEADERS_SCRIPT}" ]; then echo "$0:$LINENO: error: The command 'parseHeaders.pl' does not exist at '${DOCUMENTATION_PARSE_HEADERS_SCRIPT}'."; exit 1; fi;
if [ ! -x "${DOCUMENTATION_RESOLVE_LINKS_SCRIPT}" ]; then echo "$0:$LINENO: error: The command 'resolveLinks.pl' does not exist at '${DOCUMENTATION_RESOLVE_LINKS_SCRIPT}'."; exit 1; fi;


# Set PCRE_VERSION and PCRE_DATE shell variables to their values extracted from the pcre distribution.
if [ ! -r "${PROJECT_PCRE_HEADER_FILE}" ]; then echo "$0:$LINENO: error: The header file 'pcre.h' does not exist at '${PROJECT_PCRE_HEADER_FILE}'."; exit 1; fi;
eval `${PERL} -e 'while(<>) { if(/^#define PCRE_MAJOR\s+(\S+)$/) { $major = $1; } elsif(/^#define PCRE_MINOR\s+(\S+)$/) { $minor = $1; } elsif(/^#define PCRE_PRERELEASE\s+(\S+)$/) { $prerelease = $1; } elsif (/^#define PCRE_DATE\s+(\S+)$/) { $date = $1; } } print("PCRE_VERSION=\"$major.$minor$prerelease\"\nPCRE_DATE=\"$date\"\n");' "${PROJECT_PCRE_HEADER_FILE}"`
export PCRE_VERSION
export PCRE_DATE


# Create the database directory if it doesn't exist, then the database.
if [ ! -d "${DOCUMENTATION_SQL_DATABASE_DIR}" ]; then mkdir -p "${DOCUMENTATION_SQL_DATABASE_DIR}"; fi;
rm -rf "${DOCUMENTATION_SQL_DATABASE_FILE}"

"${SQLITE}" "${DOCUMENTATION_SQL_DATABASE_FILE}" <"${DOCUMENTATION_SQL_INIT_FILE}"
if [ $? != 0 ]; then echo "$0:$LINENO: error: Build SQL database creation failed."; exit 1; fi;
if [ ! -r "${DOCUMENTATION_SQL_DATABASE_FILE}" ]; then echo "$0:$LINENO: error: Unable to create the build SQL database."; exit 1; fi;

"${SQLITE}" "${DOCUMENTATION_SQL_DATABASE_FILE}" <"${DOCUMENTATION_SQL_CONFIG_FILE}"
if [ $? != 0 ]; then echo "$0:$LINENO: error: Build SQL database data load failed."; exit 1; fi;

"${SQLITE}" "${DOCUMENTATION_SQL_DATABASE_FILE}" "INSERT INTO pcre (version, date) VALUES ('$PCRE_VERSION', '$PCRE_DATE')"
if [ $? != 0 ]; then echo "$0:$LINENO: error: Adding PCRE configuration information to the build SQL database failed."; exit 1; fi;

export GENERATED_HTML_FILES=`"${SQLITE}" -noheader -list "${DOCUMENTATION_SQL_DATABASE_FILE}" 'SELECT file FROM html ORDER BY file' | grep -v "^Loading resources"`
if [ $? != 0 ]; then echo "$0:$LINENO: error: Query for generated html files failed."; exit 1; fi;
export STATIC_HTML_FILES=`"${SQLITE}" -noheader -list "${DOCUMENTATION_SQL_DATABASE_FILE}" 'SELECT file FROM static ORDER BY file' | grep -v "^Loading resources"`
if [ $? != 0 ]; then echo "$0:$LINENO: error: Query for static html files failed."; exit 1; fi;
export STATIC_HTML_DIRS=`"${SQLITE}" -noheader -list "${DOCUMENTATION_SQL_DATABASE_FILE}" 'SELECT dir FROM dirs ORDER BY dir' | grep -v "^Loading resources"`
if [ $? != 0 ]; then echo "$0:$LINENO: error: Query for static html directories failed."; exit 1; fi;


# Create the documentation directory if it doesn't exist, and if it does clean it out and start fresh
if [ ! -d "${DOCUMENTATION_TARGET_DIR}" ]; then
    mkdir "${DOCUMENTATION_TARGET_DIR}"
else
    "${FIND}" "${DOCUMENTATION_TARGET_DIR}" -maxdepth 1 -delete
fi

#if [ ! -f "${DOCUMENTATION_TEMP_DIR}/cpp_defines.out" ]; then
  echo "Extracting C Preprocessor #defines."
  gcc -E -Wp,-dM -std=gnu99 -fobjc-gc -x objective-c "-I${PROJECT_HEADERS_ROOT}" "-Ibuild/RegexKit.build/${CONFIGURATION}/RegexKit Framework.build/DerivedSources" "${PROJECT_HEADERS_DIR}/RegexKitPrivate.h" > "${DOCUMENTATION_TEMP_DIR}/cpp_defines.out"
#fi

# Extract the documentation from the header files.
echo "$0:$LINENO: note: Parsing headerdoc information from project headers into database."
"${DOCUMENTATION_PARSE_HEADERS_SCRIPT}" "${PROJECT_HEADERS_DIR}"/*.h

"${SQLITE}" "${DOCUMENTATION_SQL_DATABASE_FILE}" <"${DOCUMENTATION_SQL_DIR}/availability.sql"
if [ $? != 0 ]; then echo "$0:$LINENO: error: API availability data load failed."; exit 1; fi;



# Copy the pcre distribution documentation in to the documentation directory.
echo "Copying pcre HTML documentation from '${PCRE_HTML_DIR}'."
if [ -d "${PCRE_HTML_DIR}" ]; then
    "${RSYNC}" -a --delete --cvs-exclude "${PCRE_HTML_DIR}/" "${DOCUMENTATION_TARGET_DIR}/pcre/"
    if [ "${PCRE_VERSION}" == "7.3" ]; then
      "${SED}" -i "" -e 's/BACTRACKING/BACKTRACKING/g' "${DOCUMENTATION_TARGET_DIR}/pcre/pcrepattern.html"
    fi;
else
    echo "$0:$LINENO: error: The pcre HTML documentation directory '${PCRE_HTML_DIR}' does not exist.";
    exit 1;
fi


# Generate the HTML documentation.  Uses the parsed database and template files.
# A notable point is the TOC template executes the pcre_toc.pl script which parses through the PCRE
# documentation files to generate a toc for it, along with the regex syntax toc section.

echo "$0:$LINENO: note: Generating documentation HTML files."

if [ ! -d "${GENERATED_HTML_DIR}" ]; then mkdir "${GENERATED_HTML_DIR}"; fi;

# Replace PCRE_VERSION / PCRE_DATE comments with extracted values.
"${PERL}" -e 'while(<>){$in.=$_;} $in =~ s/<\!-- PCRE_VERSION -->/$ENV{"PCRE_VERSION"}/sg; $in =~ s/<\!-- PCRE_DATE -->/$ENV{"PCRE_DATE"}/sg; print($in);' "${DOCUMENTATION_TEMPLATES_DIR}/content.tmpl" >"${GENERATED_HTML_DIR}/content.html"

# Execute the DOCUMENTATION_GENERATE_HTML_SCRIPT script.
export SCRIPT_LINENO="$LINENO"; "${DOCUMENTATION_GENERATE_HTML_SCRIPT}"
if [ $? != 0 ] ; then echo "$0:$LINENO: error: Documentation HTML generation failed."; exit 1; fi;

# Create non-javascript browser friendly parts.
echo "Generating all opened toc for non-JavaScript browsers."
"${PERL}" -e 'while (<>) { $in.=$_; } $in =~ s/closed/open/sgi; $in =~ s/<noscript>.*?<\/head>/<\/head>/si; $in =~ s/<div class="toc" id="tocID">/<div class="toc" id="tocID" title="The Table of Contents requires Javascript to open and close sections. Since Javascript is unavailable, all sections have been opened automatically.">/s; print $in;' "${GENERATED_HTML_DIR}/toc.html" >"${DOCUMENTATION_TARGET_DIR}/toc_opened.html"
if [ $? != 0 ] ; then echo "$0:$LINENO: error: Documentation HTML generation failed."; exit 1; fi;
"${PERL}" -e 'while(<>){$in.=$_;} ($without_noscript = $in) =~ s#<\!--\s+NOSCRIPT_BLOCK\s+(.*?)-->##sm; open($WITHOUT, ">", "$ENV{DOCUMENTATION_TARGET_DIR}/content.html"); print($WITHOUT $without_noscript); close($WITHOUT); ($with_noscript = $in) =~ s#<\!--\s+NOSCRIPT_BLOCK\s+\n?(.*?)-->#$1#sm; open($WITH, ">", "$ENV{DOCUMENTATION_TARGET_DIR}/content_frame.html"); print($WITH $with_noscript); close($WITH);' "${GENERATED_HTML_DIR}/content.html"
if [ $? != 0 ] ; then echo "$0:$LINENO: error: Documentation HTML generation failed."; exit 1; fi;

# Copy various static html files in to their final locations.
echo "Resolving links in static html files."
"${DOCUMENTATION_RESOLVE_LINKS_SCRIPT}" ${STATIC_HTML_FILES}
if [ $? != 0 ] ; then echo "$0:$LINENO: error: Documentation link resolution failed."; exit 1; fi;


# Copy our temporary generated HTML files in to their final locations.
for HTML_FILE in ${GENERATED_HTML_FILES}; do
  if [ ! -r "${GENERATED_HTML_DIR}/${HTML_FILE}" ]; then
  	echo "$0:$LINENO: warning: The generated html documentation file '${HTML_FILE}' in '${GENERATED_HTML_DIR}' does not exist as expected."
  else
  	"${CP}" "${GENERATED_HTML_DIR}/${HTML_FILE}" "${DOCUMENTATION_TARGET_DIR}"
  fi
done;

# Copy various support directories (css, images, etc) in to their final locations.
for HTML_DIR in ${STATIC_HTML_DIRS}; do
  if [ ! -d "${DOCUMENTATION_RESOURCES_DIR}/${HTML_DIR}" ]; then
	  echo "$0:$LINENO: warning: The static html documentation directory '${HTML_DIR}' in '${DOCUMENTATION_RESOURCES_DIR}' does not exist as expected."
  else
    "${RSYNC}" -a --delete --cvs-exclude \
      --exclude="\.*" \
      --exclude="*~" \
      --exclude="#*#" \
      "${DOCUMENTATION_RESOURCES_DIR}/${HTML_DIR}/" \
      "${DOCUMENTATION_TARGET_DIR}/${HTML_DIR}/"
  fi
done;

# Do a search and replace of \${...} variables in the generated html files.
"${PERL}" -i -e 'while(<>) { s/\\\$\{(\w+)\}/$ENV{$1}/g; print $_; }' "${DOCUMENTATION_TARGET_DIR}"/*.html

"${DOCUMENTATION_CHECK_SPELLING_SCRIPT}" && CHECK_SPELLING_OK="Yes";
"${DOCUMENTATION_CHECK_HTML_SCRIPT}"     && CHECK_HTML_OK="Yes";

if [ "${CHECK_SPELLING_OK}" == "Yes" ] && [ "${CHECK_HTML_OK}" == "Yes" ]; then
  echo "$0:$LINENO: note: Clean build, touching timestamp.";
  touch "${TIMESTAMP_FILE}";
fi
