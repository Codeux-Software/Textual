#!/bin/sh

set -e

EXPORT_PATH="${TEXTUAL_WORKSPACE_TEMP_DIR}/ArchiveTan"

mkdir -p "${EXPORT_PATH}"

xcodebuild -exportArchive \
-exportOptionsPlist "${TEXTUAL_WORKSPACE_DIR}/Configurations/ExportArchiveConfiguration.plist" \
-archivePath "${ARCHIVE_PATH}" \
-exportPath "${EXPORT_PATH}"

cd "${EXPORT_PATH}"

GIT_COMMIT_HASH=`git rev-parse --short HEAD`

if [ "${TEXTUAL_BUILT_AS_UNIVERSAL_BINARY}" == "1" ]; then
	ZIP_FILE_NAME="Textual-${GIT_COMMIT_HASH}-universal.zip"
else
	ZIP_FILE_NAME="Textual-${GIT_COMMIT_HASH}.zip"
fi

zip -y -r -X "./${ZIP_FILE_NAME}" "./${FULL_PRODUCT_NAME}/"

mv -f "./${ZIP_FILE_NAME}" ~/Desktop

BUNDLE_VERSION_LONG=$(/usr/libexec/PlistBuddy -c "Print \"CFBundleVersion\"" "./${FULL_PRODUCT_NAME}/Contents/Info.plist")
BUNDLE_VERSION_SHORT=$(/usr/libexec/PlistBuddy -c "Print \"CFBundleShortVersionString\"" "./${FULL_PRODUCT_NAME}/Contents/Info.plist")

touch "./buildInfo.txt"

echo "	\$current_release_version_short = \"${BUNDLE_VERSION_SHORT}\";" >> ./buildInfo.txt
echo "	\$current_release_version_long = \"${BUNDLE_VERSION_LONG}\";" >> ./buildInfo.txt
echo "	\$current_release_version_signature = \"${GIT_COMMIT_HASH}\";" >> ./buildInfo.txt

mv -f "./buildInfo.txt" ~/Desktop

touch "./buildLog.txt"

echo "<h2>Changes in ${BUNDLE_VERSION_LONG}</h2>" >> buildLog.txt
echo "<ul>" >> buildLog.txt

git log --since='48 hours ago' --pretty=format:'<li>%s</li>' >> buildLog.txt

echo "</ul>" >> buildLog.txt

mv -f "./buildLog.txt" ~/Desktop

rm -rf "${EXPORT_PATH}"

exit 0;
