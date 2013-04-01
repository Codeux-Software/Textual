#!/bin/sh

if [ "${TEXTUAL_GITREF_BUILD_ID}" == "debug" ]; then exit; fi;

rm -rf "${PROJECT_DIR}/Build Results/"
rm -rf "${PROJECT_DIR}/.tmp/"

