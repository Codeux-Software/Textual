#!/bin/sh

set -e

mkdir -p "${TEXTUAL_WORKSPACE_TEMP_DIR}/"

# Make a copy of the Info.plist file in the .tmp folder
# This will be the Info.plist file manipulated with the version
# information that is generated below.

if [ -f "${TEXTUAL_WORKSPACE_TEMP_DIR}/Info.plist" ]; then
	rm -f "${TEXTUAL_WORKSPACE_TEMP_DIR}/Info.plist"
fi

if [ "${TEXTUAL_BUILD_SCHEME_TOKEN}" == "appstore" ]; then
	cp "${PROJECT_DIR}/Resources/Property Lists/Application Properties/InfoAppStore.plist" "${TEXTUAL_WORKSPACE_TEMP_DIR}/Info.plist"
else
	cp "${PROJECT_DIR}/Resources/Property Lists/Application Properties/Info.plist" "${TEXTUAL_WORKSPACE_TEMP_DIR}/Info.plist"
fi

cd "${TEXTUAL_WORKSPACE_TEMP_DIR}/"

# Write the version information to the Info.plist file
# The build version is the date of the last commit in git
gitBundle=`which git`

if [ -z "${gitBundle}" ]; then
bundleVersion="000000.00"
else 
gitDateOfLastCommit=`"${gitBundle}" log -n1 --format="%at"`

bundleVersion=`/bin/date -u -r "${gitDateOfLastCommit}" "+%y%m%d.%H"`
fi;

/usr/libexec/PlistBuddy -c "Set \"CFBundleVersion\" \"${bundleVersion}\"" Info.plist

# Gather the information necessary for building Textual's BuildConfig.h
# header. This header file gives various section of the code base version
# information so it does not need to constantly access the Info.plist file.
bundleVersionShort=$(/usr/libexec/PlistBuddy -c "Print \"CFBundleShortVersionString\"" Info.plist)

# ------ #

echo "/* ANY CHANGES TO THIS FILE WILL NOT BE SAVED AND WILL NOT BE COMMITTED */" > BuildConfig.h

echo "" >> BuildConfig.h

echo "#define TXBundleBuildProductName						@\"${PRODUCT_NAME}\"" >> BuildConfig.h
echo "#define TXBundleBuildProductIdentifier				@\"${PRODUCT_BUNDLE_IDENTIFIER}\"" >> BuildConfig.h
echo "#define TXBundleBuildProductIdentifierCString			\"${PRODUCT_BUNDLE_IDENTIFIER}\"" >> BuildConfig.h

echo "#define TXBundleBuildGroupContainerIdentifier			@\"${TEXTUAL_GROUP_CONTAINER_IDENTIFIER}\"" >> BuildConfig.h

echo "#define TXBundleBuildVersion							@\"${bundleVersion}\"" >> BuildConfig.h
echo "#define TXBundleBuildVersionShort						@\"${bundleVersionShort}\"" >> BuildConfig.h

echo "#define TXBundleBuildScheme							@\"${TEXTUAL_BUILD_SCHEME_TOKEN}\"" >> BuildConfig.h

echo "#define TXBundleBuildDate								@\"$(date +%s)\"" >> BuildConfig.h

if [ -z "$CODE_SIGN_IDENTITY" ]; then
echo "#define TXBundleBuiltWithoutCodeSigning				1" >> BuildConfig.h
fi

exit 0;
