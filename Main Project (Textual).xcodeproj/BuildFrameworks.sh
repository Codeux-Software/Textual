#!/bin/sh

set -e

BUILD_DESTINATION_FOLDER="${PROJECT_DIR}/.tmp/SharedBuildResults-Frameworks"

rm -rf "${BUILD_DESTINATION_FOLDER}"

mkdir -p "${BUILD_DESTINATION_FOLDER}"

# Apple Receipt Loader

if [ "${TEXTUAL_BUILD_SCHEME_TOKEN}" == "appstore" ]; then
cd "${PROJECT_DIR}/Frameworks/Apple Receipt Loader/"

xcodebuild -target "libreceipt" \
 -configuration "${TEXTUAL_FRAMEWORK_BUILD_SCHEME}" \
 CODE_SIGN_IDENTITY="${CODE_SIGN_IDENTITY}" \
 DEVELOPMENT_TEAM="${DEVELOPMENT_TEAM}" \
 PROVISIONING_PROFILE_SPECIFIER=""

mv "${PROJECT_DIR}/Frameworks/Apple Receipt Loader/Build Results/${TEXTUAL_FRAMEWORK_BUILD_SCHEME}/libreceipt.a" "${BUILD_DESTINATION_FOLDER}"
rm -rf "${PROJECT_DIR}/Frameworks/Apple Receipt Loader/Build Results/"
rm -rf "${PROJECT_DIR}/Frameworks/Apple Receipt Loader/.tmp/"
fi

# Auto Hyperlinks
cd "${PROJECT_DIR}/Frameworks/Auto Hyperlinks/"

xcodebuild -target "AutoHyperlinks.framework" \
 -configuration "${TEXTUAL_FRAMEWORK_BUILD_SCHEME}" \
 CODE_SIGN_IDENTITY="${CODE_SIGN_IDENTITY}" \
 DEVELOPMENT_TEAM="${DEVELOPMENT_TEAM}" \
 PROVISIONING_PROFILE_SPECIFIER=""

mv "${PROJECT_DIR}/Frameworks/Auto Hyperlinks/Build Results/${TEXTUAL_FRAMEWORK_BUILD_SCHEME}/AutoHyperlinks.framework" "${BUILD_DESTINATION_FOLDER}"
rm -rf "${PROJECT_DIR}/Frameworks/Auto Hyperlinks/Build Results/"
rm -rf "${PROJECT_DIR}/Frameworks/Auto Hyperlinks/.tmp/"

# Encryption Kit
cd "${PROJECT_DIR}/Frameworks/Encryption Kit/"

xcodebuild -target "EncryptionKit" \
 -configuration "${TEXTUAL_FRAMEWORK_BUILD_SCHEME}" \
 CODE_SIGN_IDENTITY="${CODE_SIGN_IDENTITY}" \
 DEVELOPMENT_TEAM="${DEVELOPMENT_TEAM}" \
 PROVISIONING_PROFILE_SPECIFIER=""

mv "${PROJECT_DIR}/Frameworks/Encryption Kit/Build Results/${TEXTUAL_FRAMEWORK_BUILD_SCHEME}/EncryptionKit.framework" "${BUILD_DESTINATION_FOLDER}"
rm -rf "${PROJECT_DIR}/Frameworks/Encryption Kit/Build Results/"
rm -rf "${PROJECT_DIR}/Frameworks/Encryption Kit/.tmp/"

# Cocoa Extensions
cd "${PROJECT_DIR}/Frameworks/Cocoa Extensions/"

xcodebuild -target "CocoaExtensions (OS X)" \
 -configuration "${TEXTUAL_FRAMEWORK_BUILD_SCHEME}" \
 CODE_SIGN_IDENTITY="${CODE_SIGN_IDENTITY}" \
 DEVELOPMENT_TEAM="${DEVELOPMENT_TEAM}" \
 PROVISIONING_PROFILE_SPECIFIER=""

mv "${PROJECT_DIR}/Frameworks/Cocoa Extensions/Build Results/${TEXTUAL_FRAMEWORK_BUILD_SCHEME}/CocoaExtensions.framework" "${BUILD_DESTINATION_FOLDER}"
rm -rf "${PROJECT_DIR}/Frameworks/Cocoa Extensions/Build Results/"
rm -rf "${PROJECT_DIR}/Frameworks/Cocoa Extensions/.tmp/"

exit 0;
