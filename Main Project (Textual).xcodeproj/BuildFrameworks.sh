#!/bin/sh

BUILD_DESTINATION_FOLDER="${PROJECT_DIR}/.tmp/SharedBuildResults-Frameworks"

mkdir -p "${BUILD_DESTINATION_FOLDER}"

cd "${PROJECT_DIR}/Frameworks/Auto Hyperlinks/"
xcodebuild -alltargets -configuration "Release" CODE_SIGN_IDENTITY="${CODE_SIGN_IDENTITY}"
cp -R "${PROJECT_DIR}/Frameworks/Auto Hyperlinks/Build Results/Release/AutoHyperlinks.framework" "${BUILD_DESTINATION_FOLDER}"
rm -rf "${PROJECT_DIR}/Frameworks/Auto Hyperlinks/Build Results/"
rm -rf "${PROJECT_DIR}/Frameworks/Auto Hyperlinks/.tmp/"

cd "${PROJECT_DIR}/Frameworks/Blowfish Encryption/"
xcodebuild -alltargets -configuration "Release" CODE_SIGN_IDENTITY="${CODE_SIGN_IDENTITY}"
cp -R "${PROJECT_DIR}/Frameworks/Blowfish Encryption/Build Results/Release/BlowfishEncryption.framework" "${BUILD_DESTINATION_FOLDER}"
rm -rf "${PROJECT_DIR}/Frameworks/Blowfish Encryption/Build Results/"
rm -rf "${PROJECT_DIR}/Frameworks/Blowfish Encryption/.tmp/"

cd "${PROJECT_DIR}/Frameworks/Cocoa Extensions/"
xcodebuild -alltargets -configuration "Release" CODE_SIGN_IDENTITY="${CODE_SIGN_IDENTITY}"
cp -R "${PROJECT_DIR}/Frameworks/Cocoa Extensions/Build Results/Release/CocoaExtensions.framework" "${BUILD_DESTINATION_FOLDER}"
rm -rf "${PROJECT_DIR}/Frameworks/Cocoa Extensions/Build Results/"
rm -rf "${PROJECT_DIR}/Frameworks/Cocoa Extensions/.tmp/"
