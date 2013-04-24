#!/bin/sh

cd "${PROJECT_DIR}/Frameworks/Auto Hyperlinks/Source/"
xcodebuild -alltargets -configuration "Release" CODE_SIGN_IDENTITY="${CODE_SIGN_IDENTITY}"

cd "${PROJECT_DIR}/Frameworks/Blowfish Encryption/Source/"
xcodebuild -alltargets -configuration "Release" CODE_SIGN_IDENTITY="${CODE_SIGN_IDENTITY}"

cd "${PROJECT_DIR}/Frameworks/System Information/Source/"
xcodebuild -alltargets -configuration "Release" CODE_SIGN_IDENTITY="${CODE_SIGN_IDENTITY}"
