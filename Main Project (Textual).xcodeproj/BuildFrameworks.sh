#!/bin/sh

cd "${PROJECT_DIR}/Frameworks/Auto Hyperlinks/Source/"
xcodebuild -alltargets -configuration "Release"

cd "${PROJECT_DIR}/Frameworks/Blowfish Encryption/Source/"
xcodebuild -alltargets -configuration "Release"

cd "${PROJECT_DIR}/Frameworks/System Information/Source/"
xcodebuild -alltargets -configuration "Release"
