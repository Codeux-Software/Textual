#!/bin/bash

set -e

TEXTUAL_PRODUCT_LOCATION="${TARGET_BUILD_DIR}/${FULL_PRODUCT_NAME}"
TEXTUAL_PRODUCT_BINARY="${TARGET_BUILD_DIR}/${EXECUTABLE_PATH}"

plugins=('Brag Spam'
    'Chat Filter'
    'Smiley Converter'
    'Spammer Paradise'
    'System Profiler'
    'ZNC Additions'
)

for plugin in "${plugins[@]}"; do
    cd "${TEXTUAL_WORKSPACE_DIR}/Sources/Plugins/${plugin}"
    xcodebuild -target "$plugin Extension" \
        -configuration "${TEXTUAL_EXTENSION_BUILD_SCHEME}" \
        CODE_SIGN_IDENTITY="${CODE_SIGN_IDENTITY}" \
        DEVELOPMENT_TEAM="${DEVELOPMENT_TEAM}" \
        PROVISIONING_PROFILE_SPECIFIER="" \
        TEXTUAL_WORKSPACE_DIR="${TEXTUAL_WORKSPACE_DIR}" \
        TEXTUAL_PRODUCT_LOCATION="${TEXTUAL_PRODUCT_LOCATION}" \
        TEXTUAL_PRODUCT_BINARY="${TEXTUAL_PRODUCT_BINARY}"

done

exit 0
