#!/bin/bash

set -e

echo "Building using architecture: ${ARCHS}"

CONFIGURATION_BUILD_DIR="${TEXTUAL_WORKSPACE_TEMP_DIR}/SharedBuildProducts-Frameworks"

xcb() {
    target=$1
    xcodebuild -target "$target" \
        -configuration "${TEXTUAL_FRAMEWORK_BUILD_SCHEME}" \
        ARCHS="${ARCHS}" \
        CODE_SIGN_IDENTITY="${CODE_SIGN_IDENTITY}" \
        CONFIGURATION_BUILD_DIR="${CONFIGURATION_BUILD_DIR}" \
        DEVELOPMENT_TEAM="${DEVELOPMENT_TEAM}" \
        PROVISIONING_PROFILE_SPECIFIER=""
}

# Assumes the name and filename of the framework is the same just without spaces.
frameworks=(
    'Auto Hyperlinks'
    'Encryption Kit'
    'Cocoa Extensions'
)

for framework in "${frameworks[@]}"; do
    cd "${TEXTUAL_WORKSPACE_DIR}/Frameworks/${framework}/"
    xcb "${framework// /}.framework"
done

exit 0
