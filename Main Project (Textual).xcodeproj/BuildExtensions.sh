#!/bin/sh

cd "${PROJECT_DIR}/Resources/Plugins/Blowfish Key Control"
xcodebuild -alltargets -configuration "Release" BUNDLE_LOADER="${CODESIGNING_FOLDER_PATH}/Contents/MacOS/${EXECUTABLE_NAME}"

cd "${PROJECT_DIR}/Resources/Plugins/Brag Spam"
xcodebuild -alltargets -configuration "Release" BUNDLE_LOADER="${CODESIGNING_FOLDER_PATH}/Contents/MacOS/${EXECUTABLE_NAME}"

cd "${PROJECT_DIR}/Resources/Plugins/System Profiler"
xcodebuild -alltargets -configuration "Release" BUNDLE_LOADER="${CODESIGNING_FOLDER_PATH}/Contents/MacOS/${EXECUTABLE_NAME}"

cd "${PROJECT_DIR}/Resources/Plugins/Spammer Paradise"
xcodebuild -alltargets -configuration "Release" BUNDLE_LOADER="${CODESIGNING_FOLDER_PATH}/Contents/MacOS/${EXECUTABLE_NAME}"
