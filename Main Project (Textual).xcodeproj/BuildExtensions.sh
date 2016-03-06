#!/bin/sh

cd "${PROJECT_DIR}/Resources/Plugins/Chat Filter"
xcodebuild -target "ChatFilterExtension" -configuration "Release" BUNDLE_LOADER="${CODESIGNING_FOLDER_PATH}/Contents/MacOS/${EXECUTABLE_NAME}" CODE_SIGN_IDENTITY="${CODE_SIGN_IDENTITY}"

cd "${PROJECT_DIR}/Resources/Plugins/Smiley Converter"
xcodebuild -target "SmileyConverter" -configuration "Release" BUNDLE_LOADER="${CODESIGNING_FOLDER_PATH}/Contents/MacOS/${EXECUTABLE_NAME}" CODE_SIGN_IDENTITY="${CODE_SIGN_IDENTITY}"

cd "${PROJECT_DIR}/Resources/Plugins/ZNC Additions"
xcodebuild -target "ZNCAdditions" -configuration "Release" BUNDLE_LOADER="${CODESIGNING_FOLDER_PATH}/Contents/MacOS/${EXECUTABLE_NAME}" CODE_SIGN_IDENTITY="${CODE_SIGN_IDENTITY}"
