#!/bin/sh

cd "${PROJECT_DIR}/Resources/"

mkdir -p "${PROJECT_DIR}/.tmp/"

# Make a copy of the Info.plist file in the .tmp folder
# This will be the Info.plist file manipulated with the version
# information that is generated below.
cp "${PROJECT_DIR}/Resources/Info.plist" "${PROJECT_DIR}/.tmp/Info.plist"

# Make a copy of the appropriate entitlements file.
if [ "${TEXTUAL_BUILD_SCHEME_TOKEN}" == "appstore" ]; then
	cp "${PROJECT_DIR}/Resources/Sandbox/Entitlements/TextualAppStore.entitlements" "${CODE_SIGN_ENTITLEMENTS}"
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
		echo "Butt ${GCC_PREPROCESSOR_DEFINITIONS}"

		cp "${PROJECT_DIR}/Resources/Sandbox/Entitlements/TextualWithoutSandbox.entitlements" "${CODE_SIGN_ENTITLEMENTS}"
	fi
fi

cd "${PROJECT_DIR}/.tmp/"

# Write the version information to the Info.plist file
# The build version is the date of the last commit in git

gitBundle=`which git`
gitDateOfLastCommit=`"${gitBundle}" log -n1 --format="%at"`

bundleVersion=`/bin/date -r "${gitDateOfLastCommit}" "+%y%m%d.%H"`

/usr/libexec/PlistBuddy -c "Set \"CFBundleVersion\" \"${bundleVersion}\"" Info.plist

# Gather the information necessary for building Textual's BuildConfig.h
# header. This header file gives various section of the code base version
# information so it does not need to constantly access the Info.plist file.

bundleVersionShort=$(/usr/libexec/PlistBuddy -c "Print \"CFBundleShortVersionString\"" Info.plist)
bundleName=$(/usr/libexec/PlistBuddy -c "Print \"CFBundleName\"" Info.plist)

gitDescribe=`"${gitBundle}" describe --long`
gitRefInfo=$(echo $gitDescribe | grep -oE "([0-9]{1,3})\-([a-zA-Z0-9]{8})")
gitCommitCount=`"${gitBundle}" rev-list HEAD --count`

buildRef="${bundleVersion}-${gitRefInfo}-${TEXTUAL_BUILD_SCHEME_TOKEN}"

echo "Building Textual (Build Reference: ${gitRefInfo})"

buildDate=`date +%s`

echo "/* ANY CHANGES TO THIS FILE WILL NOT BE SAVED AND WILL NOT BE COMMITTED */" > BuildConfig.h
echo "" >> BuildConfig.h
echo "#define TXBundleBuildCommitCount						@\"${gitCommitCount}\"" >> BuildConfig.h
echo "#define TXBundleBuildGroupContainerIdentifier			@\"${TEXTUAL_GROUP_CONTAINER_IDENTIFIER}\"" >> BuildConfig.h
echo "#define TXBundleBuildDate								@\"${buildDate}\"" >> BuildConfig.h
echo "#define TXBundleBuildScheme							@\"${TEXTUAL_BUILD_SCHEME_TOKEN}\"" >> BuildConfig.h
echo "#define TXBundleBuildVersion							@\"${bundleVersion}\"" >> BuildConfig.h
echo "#define TXBundleBuildVersionShort						@\"${bundleVersionShort}\"" >> BuildConfig.h

if [ -n "$CODE_SIGN_IDENTITY" ]; then
echo "#define TXBundleBuildReference				@\"${buildRef}\"" >> BuildConfig.h
else
echo "#define TXBundleBuildReference				@\"${buildRef},nocdsign\"" >> BuildConfig.h
echo "#define TXBundleBuiltWithoutCodeSigning		1" >> BuildConfig.h
fi
