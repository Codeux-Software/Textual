#!/bin/sh

MAKE=${MAKE:?"Environment variable MAKE must exist, aborting."};
MAKEFILE_PCRE=${MAKEFILE_PCRE:?"Environment variable MAKEFILE_PCRE must exist, aborting."};

if [ ! -f "${MAKEFILE_PCRE}" ]; then echo "$0:$LINENO: error: The Makefile to build PCRE, '${MAKEFILE_PCRE}', does not exist, aborting." exit 1; fi;

# Determine if there has been a change that requires the pcre library to be cleaned.
if [ -f "${PCRE_BUILT_WITH_MAKEFILE}" ];   then DIFFERENT_MAKEFILE=`diff -q "${MAKEFILE_PCRE}" "${PCRE_BUILT_WITH_MAKEFILE}"`; fi;
if [ -f "${PCRE_BUILT_WITH_SCRIPT}" ];     then DIFFERENT_SCRIPT=`diff -q "$0" "${PCRE_BUILT_WITH_SCRIPT}"`; fi;
eval "${PCRE_BUILT_WITH_ENV_CMD}" > "${PCRE_BUILT_WITH_ENV_FILE}_now"
if [ -f "${PCRE_BUILT_WITH_ENV_FILE}" ];   then DIFFERENT_ENV=`diff -q "${PCRE_BUILT_WITH_ENV_FILE}" "${PCRE_BUILT_WITH_ENV_FILE}_now"`; fi;

if   [ "${DIFFERENT_ENV}"      !=  "" ];   then echo "$0:$LINENO: note: The build environment variables have changed since building the pcre library.";        NEEDS_CLEANING="Yes";
elif [ "${DIFFERENT_SCRIPT}"   !=  "" ];   then echo "$0:$LINENO: note: The build script '${PCRE_BUILD_SCRIPT}' has changed since building the pcre library."; NEEDS_CLEANING="Yes";
elif [ "${DIFFERENT_MAKEFILE}" !=  "" ];   then echo "$0:$LINENO: note: The makefile '${MAKEFILE_PCRE}' has changed since building the pcre library.";         NEEDS_CLEANING="Yes";
fi;

# Invoke Makefile.pcre with the 'clean' if needed.
if [ -r "PCRE_MAKE_OVERRIDE" ] && [ "${NEEDS_CLEANING}" == "Yes" ]; then
  echo "$0:$LINENO: warning: The file 'PCRE_MAKE_OVERRIDE' exists but PCRE cleaning required, skipping clean.";
else
  if [ "${NEEDS_CLEANING}" == "Yes" ];     then "${MAKE}" -f "${MAKEFILE_PCRE}" clean; fi;
fi

# Create the directory we use for all our temporary files.
if [ ! -d "${PCRE_TEMP_ROOT}" ];           then mkdir -p "${PCRE_TEMP_ROOT}"; fi;

# Copy the environment variables, script (this script), and Makefile used to build the pcre library.
if [ ! -f "${PCRE_BUILT_WITH_ENV_FILE}" ]; then eval "${PCRE_BUILT_WITH_ENV_CMD}" > "${PCRE_BUILT_WITH_ENV_FILE}"; fi;
if [ ! -f "${PCRE_BUILT_WITH_SCRIPT}" ];   then "${CP}" "$0" "${PCRE_BUILT_WITH_SCRIPT}"; fi;
if [ ! -f "${PCRE_BUILT_WITH_MAKEFILE}" ]; then "${CP}" "${MAKEFILE_PCRE}" "${PCRE_BUILT_WITH_MAKEFILE}"; fi;

# Finally, invoke Makefile.pcre with ${ACTION} (which is nearly always 'build').
export CPUS=`sysctl -n hw.activecpu`;
if [ "${PCRE_PARALLEL_BUILD}" == "YES" ] && (( ${CPUS} > 1 )); then
  export MAXLOAD=`expr "${CPUS}" + 2`;
  echo "$0:$LINENO: note: PCRE_PARALLEL_BUILD == 'YES', number of active CPU's: ${CPUS} max load average: ${MAXLOAD}";
  exec "${MAKE}" -f "${MAKEFILE_PCRE}" -j "${CPUS}" -l "${MAXLOAD}" ${ACTION};
else
#  echo "$0:$LINENO: note: PCRE_PARALLEL_BUILD != 'YES', using non-parallel, sequential make to build PCRE.";
  exec "${MAKE}" -f "${MAKEFILE_PCRE}" ${ACTION};
fi;

