#!/bin/sh

set -e

#
# Textual and Remote Connection Manager service both use Swift.
# Textual embeds the library and the service will inherit that.
# For some reason, during development, I found that the service
# would not launch because "libswiftSwiftOnoneSupport.dylib"
# was missing in Textual's copy of the library.
#
# Textual and the service both declare -Onone optimization level
# at the same time, so I don't know why one will have it and
# the other does not.
#
# To workaround this issue and any in the future, this script exists.
# This script will find all libswift*.dylb files that aren't in the
# main copy of the library and bring those files in.
#
# TODO: Revisit this when I've had sleep (June 28, 2018)
#

cd "${TARGET_BUILD_DIR}/${CONTENTS_FOLDER_PATH}"

find . -type f -name "libswift*" \
 -not -path "./Frameworks/*" \
 -not -path "./Resources/*" \
 -not -path "*/Resources/libswiftRemoteMirror.dylib" \
 -exec cp '{}' ./Frameworks/ \; \
 -exec rm '{}' \;

#
# libswiftNetwork.dylib contains a hard link against /usr/lib/libnetwork.dylib
# which doesn't exist on Mavericks (10.9). I have filed a radar with Apple
# to change this to a soft link, but until then, this is the workaround.
# I have a utility on my Mac that will replace the loader command in the
# library with one which makes it weak.
#

FIX_LIBNETWORK_UTILITY="${HOME}/Projects/bin/patch_libswiftNetwork"

if [ -x "${FIX_LIBNETWORK_UTILITY}" ]; then
	echo "Replacing loader command for libnetwork.dylib to weak"

	"${FIX_LIBNETWORK_UTILITY}" ./Frameworks/libswiftNetwork.dylib

	/usr/bin/codesign --force --sign $EXPANDED_CODE_SIGN_IDENTITY --verbose ./Frameworks/libswiftNetwork.dylib
else
	echo "No utility in place to fix libnetwork.dylib link"
fi

exit 0;
