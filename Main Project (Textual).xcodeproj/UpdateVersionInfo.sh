#!/bin/sh

cd "${PROJECT_DIR}/Resources/"

bundleIdentifier=$(/usr/libexec/PlistBuddy -c "Print \"CFBundleIdentifier\"" Info.plist)
bundleVersionForComparisons=$(/usr/libexec/PlistBuddy -c "Print \"TXBundleVersionForComparisons\"" Info.plist)
bundleVersionShort=$(/usr/libexec/PlistBuddy -c "Print \"CFBundleShortVersionString\"" Info.plist)
bundleVersion=$(/usr/libexec/PlistBuddy -c "Print \"CFBundleVersion\"" Info.plist)
bundleName=$(/usr/libexec/PlistBuddy -c "Print \"CFBundleName\"" Info.plist)

gitBundle=`which git`
gitDescribe=`"${gitBundle}" describe --long`
gitRefInfo=$(echo $gitDescribe | grep -oE "([0-9]{1,3})\-([a-zA-Z0-9]{8})")
gitCommitCount=`"${gitBundle}" rev-list HEAD --count`

buildRef="${bundleVersionShort}-${gitRefInfo}-${TEXTUAL_GITREF_BUILD_ID}"

echo "Building Textual (Build Reference: ${gitRefInfo})"

test "${bundleIdentifier}" != "${TEXTUAL_BUNDLE_ID}" && \
	/usr/libexec/PlistBuddy -c "Set :\"CFBundleIdentifier\" ${TEXTUAL_BUNDLE_ID}" Info.plist

mkdir -p "${PROJECT_DIR}/.tmp/"

cd "${PROJECT_DIR}/.tmp/"

buildDate=`date +%s`

echo "/* ANY CHANGES TO THIS FILE WILL NOT BE SAVED AND WILL NOT BE COMMITTED */" > BuildConfig.h
echo "" >> BuildConfig.h
echo "#define TXBundleBuildCommitCount				@\"${gitCommitCount}\"" >> BuildConfig.h
echo "#define TXBundleBuildGroupIdentifier			@\"${TEXTUAL_GROUP_ID}\"" >> BuildConfig.h
echo "#define TXBundleBuildDate						@\"${buildDate}\"" >> BuildConfig.h
echo "#define TXBundleBuildVersion					@\"${bundleVersion}\"" >> BuildConfig.h
echo "#define TXBundleBuildVersionShort				@\"${bundleVersionShort}\"" >> BuildConfig.h
echo "#define TXBundleBuildVersionForComparisons	@\"${bundleVersionForComparisons}\"" >> BuildConfig.h

if [ -n "$CODE_SIGN_IDENTITY" ]; then
echo "#define TXBundleBuildReference	@\"${buildRef}\"" >> BuildConfig.h
else
echo "#define TXBundleBuildReference	@\"${buildRef},nocdsign\"" >> BuildConfig.h
echo "#define TXBundleBuiltWithoutCodeSigning                   1" >> BuildConfig.h
fi
