#!/bin/sh

cd "${PROJECT_DIR}/Resources/"

buildNumber=$(/usr/libexec/PlistBuddy -c "Print \"TXBundleBuildNumber\"" Info.plist)
bundleVersion=$(/usr/libexec/PlistBuddy -c "Print \"CFBundleShortVersionString\"" Info.plist)

buildNumber=$(($buildNumber + 1))

gitBundle=`which git`
gitDescribe=`${gitBundle} describe`
gitRefInfo=$(echo $gitDescribe | grep -oE "([0-9]{1,3})\-([a-zA-Z0-9]{8})")
gitCommitCount=`${gitBundle} rev-list HEAD --count`

buildRef="${bundleVersion}-${gitRefInfo}-${TEXTUAL_GITREF_BUILD_ID}"

echo "Building Textual (Build Reference: ${gitRefInfo})"

if [ ${#gitRefInfo} -gt 5 ]; then
    /usr/libexec/PlistBuddy -c "Set :\"CFBundleIdentifier\" ${TEXTUAL_BUNDLE_ID}" Info.plist
    /usr/libexec/PlistBuddy -c "Set :\"TXBundleBuildReference\" ${buildRef}" Info.plist
    /usr/libexec/PlistBuddy -c "Set :\"TXBundleBuildNumber\" ${buildNumber}" Info.plist
    /usr/libexec/PlistBuddy -c "Set :\"TXBundleCommitCount\" ${gitCommitCount}" Info.plist
fi
