#!/bin/sh

cd "${PROJECT_DIR}/Resources/Plugins/Blowfish Key Control"
xcodebuild -alltargets -configuration "Release" BUNDLE_LOADER="${CODESIGNING_FOLDER_PATH}/Contents/MacOS/${EXECUTABLE_NAME}" CODE_SIGN_IDENTITY="${CODE_SIGN_IDENTITY}"

cd "${PROJECT_DIR}/Resources/Plugins/Brag Spam"
xcodebuild -alltargets -configuration "Release" BUNDLE_LOADER="${CODESIGNING_FOLDER_PATH}/Contents/MacOS/${EXECUTABLE_NAME}" CODE_SIGN_IDENTITY="${CODE_SIGN_IDENTITY}"

cd "${PROJECT_DIR}/Resources/Plugins/System Profiler"
xcodebuild -alltargets -configuration "Release" BUNDLE_LOADER="${CODESIGNING_FOLDER_PATH}/Contents/MacOS/${EXECUTABLE_NAME}" CODE_SIGN_IDENTITY="${CODE_SIGN_IDENTITY}"

cd "${PROJECT_DIR}/Resources/Plugins/Spammer Paradise"
xcodebuild -alltargets -configuration "Release" BUNDLE_LOADER="${CODESIGNING_FOLDER_PATH}/Contents/MacOS/${EXECUTABLE_NAME}" CODE_SIGN_IDENTITY="${CODE_SIGN_IDENTITY}"

cd "${PROJECT_DIR}/Resources/Plugins/ZNC Additions"
xcodebuild -alltargets -configuration "Release" BUNDLE_LOADER="${CODESIGNING_FOLDER_PATH}/Contents/MacOS/${EXECUTABLE_NAME}" CODE_SIGN_IDENTITY="${CODE_SIGN_IDENTITY}"
