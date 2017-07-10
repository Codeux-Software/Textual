#!/bin/sh

set -e

BUILD_DESTINATION_FOLDER="${PROJECT_DIR}/.tmp/SharedBuildResults-XPCServices"

rm -rf "${BUILD_DESTINATION_FOLDER}"

mkdir -p "${BUILD_DESTINATION_FOLDER}"

if [ "${TEXTUAL_BUILD_SCHEME_TOKEN}" == "appstore" ]; then
	BUILD_CONFIGURATION_TITLE="Release (App Store)"
else
	BUILD_CONFIGURATION_TITLE="Release"
fi

# Historic Log File Manager
cd "${PROJECT_DIR}/XPC Services/Historic Log File Manager/"

xcodebuild -target "Historic Log File Manager" \
 -configuration "${BUILD_CONFIGURATION_TITLE}" \
 CODE_SIGN_IDENTITY="${CODE_SIGN_IDENTITY}" \
 DEVELOPMENT_TEAM="${DEVELOPMENT_TEAM}" \
 PROVISIONING_PROFILE_SPECIFIER=""

cd "${PROJECT_DIR}/XPC Services/IRC Remote Connection Manager/"

xcodebuild -target "IRC Remote Connection Manager" \
 -configuration "${BUILD_CONFIGURATION_TITLE}" \
 CODE_SIGN_IDENTITY="${CODE_SIGN_IDENTITY}" \
 DEVELOPMENT_TEAM="${DEVELOPMENT_TEAM}" \
 PROVISIONING_PROFILE_SPECIFIER=""
