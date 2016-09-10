#!/bin/sh

set -e

BUILD_DESTINATION_FOLDER="${PROJECT_DIR}/.tmp/SharedBuildResults-Frameworks"

rm -rf "${BUILD_DESTINATION_FOLDER}"

mkdir -p "${BUILD_DESTINATION_FOLDER}"

# Auto Hyperlinks
cd "${PROJECT_DIR}/Frameworks/Auto Hyperlinks/"

xcodebuild -target "AutoHyperlinks.framework" \
 -configuration "Release" \
 CODE_SIGN_IDENTITY="${CODE_SIGN_IDENTITY}" \
 DEVELOPMENT_TEAM="${DEVELOPMENT_TEAM}" \
 PROVISIONING_PROFILE_SPECIFIER="${PROVISIONING_PROFILE_SPECIFIER}"

mv "${PROJECT_DIR}/Frameworks/Auto Hyperlinks/Build Results/Release/AutoHyperlinks.framework" "${BUILD_DESTINATION_FOLDER}"
rm -rf "${PROJECT_DIR}/Frameworks/Auto Hyperlinks/Build Results/"
rm -rf "${PROJECT_DIR}/Frameworks/Auto Hyperlinks/.tmp/"

# Encryption Kit
cd "${PROJECT_DIR}/Frameworks/Encryption Kit/"

xcodebuild -target "EncryptionKit" \
 -configuration "Release" \
 CODE_SIGN_IDENTITY="${CODE_SIGN_IDENTITY}" \
 DEVELOPMENT_TEAM="${DEVELOPMENT_TEAM}" \
 PROVISIONING_PROFILE_SPECIFIER="${PROVISIONING_PROFILE_SPECIFIER}"

mv "${PROJECT_DIR}/Frameworks/Encryption Kit/Build Results/Release/EncryptionKit.framework" "${BUILD_DESTINATION_FOLDER}"
rm -rf "${PROJECT_DIR}/Frameworks/Encryption Kit/Build Results/"
rm -rf "${PROJECT_DIR}/Frameworks/Encryption Kit/.tmp/"

# Cocoa Extensions
cd "${PROJECT_DIR}/Frameworks/Cocoa Extensions/"

xcodebuild -target "CocoaExtensions (OS X)" \
 -configuration "Release" \
 CODE_SIGN_IDENTITY="${CODE_SIGN_IDENTITY}" \
 DEVELOPMENT_TEAM="${DEVELOPMENT_TEAM}" \
 PROVISIONING_PROFILE_SPECIFIER="${PROVISIONING_PROFILE_SPECIFIER}"

mv "${PROJECT_DIR}/Frameworks/Cocoa Extensions/Build Results/Release/CocoaExtensions.framework" "${BUILD_DESTINATION_FOLDER}"
rm -rf "${PROJECT_DIR}/Frameworks/Cocoa Extensions/Build Results/"
rm -rf "${PROJECT_DIR}/Frameworks/Cocoa Extensions/.tmp/"
