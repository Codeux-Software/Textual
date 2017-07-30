#!/bin/sh

set -e

BUILD_DESTINATION_FOLDER="${PROJECT_DIR}/.tmp/SharedBuildResults-XPCServices"

rm -rf "${BUILD_DESTINATION_FOLDER}"

mkdir -p "${BUILD_DESTINATION_FOLDER}"

# Historic Log File Manager
cd "${PROJECT_DIR}/XPC Services/Historic Log File Manager/"

xcodebuild -target "Historic Log File Manager" \
 -configuration "${TEXTUAL_XPC_SERVICE_BUILD_SCHEME}" \
 CODE_SIGN_IDENTITY="${CODE_SIGN_IDENTITY}" \
 DEVELOPMENT_TEAM="${DEVELOPMENT_TEAM}" \
 PROVISIONING_PROFILE_SPECIFIER=""

cd "${PROJECT_DIR}/XPC Services/IRC Remote Connection Manager/"

xcodebuild -target "IRC Remote Connection Manager" \
 -configuration "${TEXTUAL_XPC_SERVICE_BUILD_SCHEME}" \
 CODE_SIGN_IDENTITY="${CODE_SIGN_IDENTITY}" \
 DEVELOPMENT_TEAM="${DEVELOPMENT_TEAM}" \
 PROVISIONING_PROFILE_SPECIFIER=""
