#!/bin/sh

# If the version of Textual being built is not the debug version,
# then erase all build data that may already exist.

if [ "${TEXTUAL_BUILD_SCHEME_TOKEN}" == "debug" ]; then exit; fi;

rm -rf "${PROJECT_DIR}/Build Results/"
rm -rf "${PROJECT_DIR}/.tmp/"
