#!/bin/sh

# If the version of Textual being built is not the debug version,
# then erase all build data that may already exist.

if [ "${TEXTUAL_GITREF_BUILD_ID}" == "debug" ]; then exit; fi;

rm -rf "${PROJECT_DIR}/Build Results/"
rm -rf "${PROJECT_DIR}/.tmp/"

