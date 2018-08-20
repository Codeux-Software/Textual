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

exit 0;
