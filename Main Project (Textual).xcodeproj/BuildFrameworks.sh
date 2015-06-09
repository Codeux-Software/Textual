#!/bin/sh

BUILD_DESTINATION_FOLDER="${PROJECT_DIR}/.tmp/SharedBuildResults-Frameworks"

rm -rf "${BUILD_DESTINATION_FOLDER}"

mkdir -p "${BUILD_DESTINATION_FOLDER}"

cd "${PROJECT_DIR}/Frameworks/Auto Hyperlinks/"
xcodebuild -target "AutoHyperlinks.framework" -configuration "Release" CODE_SIGN_IDENTITY="${CODE_SIGN_IDENTITY}"
mv "${PROJECT_DIR}/Frameworks/Auto Hyperlinks/Build Results/Release/AutoHyperlinks.framework" "${BUILD_DESTINATION_FOLDER}"
rm -rf "${PROJECT_DIR}/Frameworks/Auto Hyperlinks/Build Results/"
rm -rf "${PROJECT_DIR}/Frameworks/Auto Hyperlinks/.tmp/"

cd "${PROJECT_DIR}/Frameworks/Encryption Kit/"
xcodebuild -target "EncryptionKit" -configuration "Release" CODE_SIGN_IDENTITY="${CODE_SIGN_IDENTITY}"
mv "${PROJECT_DIR}/Frameworks/Encryption Kit/Build Results/Release/EncryptionKit.framework" "${BUILD_DESTINATION_FOLDER}"
rm -rf "${PROJECT_DIR}/Frameworks/Encryption Kit/Build Results/"
rm -rf "${PROJECT_DIR}/Frameworks/Encryption Kit/.tmp/"

cd "${PROJECT_DIR}/Frameworks/Cocoa Extensions/"
xcodebuild -target "CocoaExtensions (OS X)" -configuration "Release" CODE_SIGN_IDENTITY="${CODE_SIGN_IDENTITY}"
mv "${PROJECT_DIR}/Frameworks/Cocoa Extensions/Build Results/Release/CocoaExtensions.framework" "${BUILD_DESTINATION_FOLDER}"
rm -rf "${PROJECT_DIR}/Frameworks/Cocoa Extensions/Build Results/"
rm -rf "${PROJECT_DIR}/Frameworks/Cocoa Extensions/.tmp/"
