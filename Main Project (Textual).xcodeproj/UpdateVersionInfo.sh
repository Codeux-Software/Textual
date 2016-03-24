#!/bin/sh

set -e

mkdir -p "${PROJECT_DIR}/.tmp/"

# Make a copy of the Info.plist file in the .tmp folder
# This will be the Info.plist file manipulated with the version
# information that is generated below.

if [ -f "${PROJECT_DIR}/.tmp/Info.plist" ]; then
	rm -f "${PROJECT_DIR}/.tmp/Info.plist"
fi

if [ "${TEXTUAL_BUILD_SCHEME_TOKEN}" == "appstore" ]; then
	cp "${PROJECT_DIR}/Resources/Property Lists/Application Properties/InfoAppStore.plist" "${PROJECT_DIR}/.tmp/Info.plist"
else
	cp "${PROJECT_DIR}/Resources/Property Lists/Application Properties/Info.plist" "${PROJECT_DIR}/.tmp/Info.plist"
fi

# Make a copy of the appropriate entitlements file.
if [ -f "${CODE_SIGN_ENTITLEMENTS}" ]; then
	rm -f "${CODE_SIGN_ENTITLEMENTS}"
fi

if [ "${TEXTUAL_BUILD_SCHEME_TOKEN}" == "appstore" ]; then
	cp "${PROJECT_DIR}/Resources/Sandbox/Entitlements/TextualAppStore.entitlements" ""
else
	if [[ "${GCC_PREPROCESSOR_DEFINITIONS}" == *"TEXTUAL_BUILT_INSIDE_SANDBOX=1"* ]]; then
		# While we are here, check to make sure that the user
		# performed the necessary configuration changes
		if [ "${TEXTUAL_BUNDLE_IDENTIFIER}" != "com.codeux.irc.textual5" ] || [ "${TEXTUAL_GROUP_CONTAINER_IDENTIFIER}" != "8482Q6EPL6.com.codeux.irc.textual" ]; then
			echo "Before changing TEXTUAL_BULIT_INSIDE_SANDBOX to 1, make the changes noted in the comments of the configuration file.";

			exit 1;
		fi

		cp "${PROJECT_DIR}/Resources/Sandbox/Entitlements/TextualWithSandbox.entitlements" "${CODE_SIGN_ENTITLEMENTS}"
	else
		cp "${PROJECT_DIR}/Resources/Sandbox/Entitlements/TextualWithoutSandbox.entitlements" "${CODE_SIGN_ENTITLEMENTS}"
	fi
fi

cd "${PROJECT_DIR}/.tmp/"

# Write the version information to the Info.plist file
# The build version is the date of the last commit in git
gitBundle=`which git`

if [ -z "${gitBundle}" ]; then
gitDateOfLastCommit="000000.00"
else 
gitDateOfLastCommit=`"${gitBundle}" log -n1 --format="%at"`
fi

bundleVersion=`/bin/date -u -r "${gitDateOfLastCommit}" "+%y%m%d.%H"`

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

echo "#define TXBundleBuildGroupContainerIdentifier			@\"${TEXTUAL_GROUP_CONTAINER_IDENTIFIER}\"" >> BuildConfig.h

echo "#define TXBundleBuildVersion							@\"${bundleVersion}\"" >> BuildConfig.h
echo "#define TXBundleBuildVersionShort						@\"${bundleVersionShort}\"" >> BuildConfig.h

echo "#define TXBundleBuildScheme							@\"${TEXTUAL_BUILD_SCHEME_TOKEN}\"" >> BuildConfig.h

if [ -z "$CODE_SIGN_IDENTITY" ]; then
echo "#define TXBundleBuiltWithoutCodeSigning				1" >> BuildConfig.h
fi
