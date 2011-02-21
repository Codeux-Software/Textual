#!/bin/sh

export BUILD_DIR=${BUILD_DIR:?"error: Environment variable BUILD_DIR must exist, aborting."}
export BUILD_SQL_DIR=${BUILD_SQL_DIR:?"error: Environment variable BUILD_SQL_DIR must exist, aborting."}
export BZIP2_CMD=${BZIP2_CMD:?"error: Environment variable BZIP2_CMD must exist, aborting."}
export CONFIGURATION=${CONFIGURATION:?"error: Environment variable CONFIGURATION must exist, aborting."}
export DISTRIBUTION_BASE_FILE_NAME=${DISTRIBUTION_BASE_FILE_NAME:?"error: Environment variable DISTRIBUTION_BASE_FILE_NAME must exist, aborting."}
export DISTRIBUTION_BASE_SOURCE_FILE_NAME=${DISTRIBUTION_BASE_SOURCE_FILE_NAME:?"error: Environment variable DISTRIBUTION_BASE_SOURCE_FILE_NAME must exist, aborting."}
export DISTRIBUTION_DEFAULT_INSTALL_DIR=${DISTRIBUTION_DEFAULT_INSTALL_DIR:?"error: Environment variable DISTRIBUTION_DEFAULT_INSTALL_DIR must exist, aborting."}
export DISTRIBUTION_TARGET_DIR=${DISTRIBUTION_TARGET_DIR:?"error: Environment variable DISTRIBUTION_TARGET_DIR must exist, aborting."}
export DISTRIBUTION_ROOT=${DISTRIBUTION_ROOT:?"error: Environment variable DISTRIBUTION_ROOT must exist, aborting."}
export DISTRIBUTION_DMG_CONVERT_OPTS=${DISTRIBUTION_DMG_CONVERT_OPTS:?"error: Environment variable DISTRIBUTION_DMG_CONVERT_OPTS must exist, aborting."}
export DISTRIBUTION_DMG_VOL_NAME=${DISTRIBUTION_DMG_VOL_NAME:?"error: Environment variable DISTRIBUTION_DMG_VOL_NAME must exist, aborting."}
export DISTRIBUTION_ROOT_NAME=${DISTRIBUTION_ROOT_NAME:?"error: Environment variable DISTRIBUTION_ROOT_NAME must exist, aborting."}
export DOCUMENTATION_TARGET_DIR=${DOCUMENTATION_TARGET_DIR:?"error: Environment variable DOCUMENTATION_TARGET_DIR must exist, aborting."}
export FIND=${FIND:?"error: Environment variable FIND must exist, aborting."}
export GZIP_CMD=${GZIP_CMD:?"error: Environment variable GZIP_CMD must exist, aborting."}
export PCRE_VERSION=${PCRE_VERSION:?"Environment variable PCRE_VERSION must exist, aborting."}
export PERL=${PERL:?"Environment variable PERL must exist, aborting."}
export PROJECT_DIR=${PROJECT_DIR:?"Environment variable PROJECT_DIR must exist, aborting."}
export PROJECT_NAME=${PROJECT_NAME:?"Environment variable PROJECT_NAME must exist, aborting."}
export RSYNC=${RSYNC:?"Environment variable RSYNC must exist, aborting."}
export SQLITE=${SQLITE:?"Environment variable SQLITE must exist, aborting."}
export TAR=${TAR:?"Environment variable TAR must exist, aborting."}
export TEMP_FILES_DIR=${TEMP_FILES_DIR:?"error: Environment variable TEMP_FILES_DIR must exist, aborting."}


if [ "${CONFIGURATION}" != "Release" ]; then echo "$0:$LINENO: error: Distribution can only be built under the 'Release' configuration."; exit 1; fi;

"${PERL}" -e 'require DBD::SQLite;' >/dev/null 2>&1
if [ $? != 0 ]; then echo "$0:$LINENO: error: The perl module 'DBD::SQLite' must be installed in order to build the the target '${TARGETNAME}'."; exit 1; fi;  

/usr/bin/renice 20 -p $$

# Get the pcre major and minor version numbers from PCRE_VERSION
eval `"${PERL}" -e '$ARGV[0] =~ /(\d+)\.(\d+)/; print("export PCRE_VERSION_MAJOR=$1; export PCRE_VERSION_MINOR=$2;\n");' ${PCRE_VERSION}`

if [ "${P7ZIP}" == "" ]; then
  if [ -x 7za ]; then P7ZIP="7za";
  elif [ -x /usr/local/bin/7za ]; then P7ZIP="/usr/local/bin/7za";
  elif [ -x /opt/local/bin/7za ]; then P7ZIP="/opt/local/bin/7za";
  elif [ -x /sw/bin/7za ]; then P7ZIP="/sw/bin/7za";
  fi
fi

if [ "${PACKAGEMAKER}" == "" ]; then
  if [ -x packagemaker ]; then PACKAGEMAKER="packagemaker";
  elif [ -x /Developer/Tools/packagemaker ]; then PACKAGEMAKER="/Developer/Tools/packagemaker";
  elif [ -x /Developer/usr/bin/packagemaker ]; then PACKAGEMAKER="/Developer/usr/bin/packagemaker";
  else echo "$0:$LINENO: error: Unable to locate the executable 'packagemaker'."; exit 1;
  fi
fi

if [ ! -x "${PACKAGEMAKER}" ] ; then echo "$0:$LINENO: error: The PackageMaker tool '${PACKAGEMAKER}' does not exist."; exit 1; fi;

create_dmg()
{
  local DMG_DIR="$1";
  local DMG_FILE="$2";
  local DMG_VOL_NAME="$3";
  local DMG_ARCHIVE="$4";
  local DMG_CONVERT_OPS="$5";
  local DMG_INTERNET_ENABLE="$6";
  
  local DMG_FILEPATH="${DMG_DIR}/${DMG_FILE}";

  local DMG_TMP_FILE="tmp_${DMG_FILE}";
  local DMG_TMP_FILEPATH="${DMG_DIR}/${DMG_TMP_FILE}";
  
  echo "$0:$LINENO: note: Creating '${DMG_FILE}' disk image."
  hdiutil makehybrid -o "${DMG_TMP_FILEPATH}" -hfs -hfs-volume-name "${DMG_VOL_NAME}" "${DMG_DIR}/${DMG_ARCHIVE}"
  if [ $? != 0 ]; then echo "$0:$LINENO: error: Error creating temporary '${DMG_FILE}' with the 'hdiutil' command."; return 1; fi;
  echo "$0:$LINENO: note: Compressing .dmg image."
  hdiutil convert ${DMG_CONVERT_OPS} -o "${DMG_FILEPATH}" "${DMG_TMP_FILEPATH}"
  if [ $? != 0 ]; then echo "$0:$LINENO: error: Error compressing '${DMG_FILE}' with the 'hdiutil' command."; return 1; fi;
  rm -f "${DMG_TMP_FILEPATH}"
  if [ ! -f "${DMG_FILEPATH}" ]; then echo "$0:$LINENO: error: Did not create the .dmg disk image '${DMG_FILE}'."; return 1; fi;
  if [ "${DMG_INTERNET_ENABLE}" == "YES" ]; then
    hdiutil internet-enable -yes "${DMG_FILEPATH}"
    if [ $? != 0 ]; then echo "$0:$LINENO: error: Unable to Internet Enable '${DMG_FILE}' with the 'hdiutil' command."; return 1; fi;
  fi;
}

updateVersion()
{
  local FILE_NAME="$1";
  local MAJOR_VERSION="$2";
  local MINOR_VERSION="$3";
  local POINT_VERSION="$4";
  local INSTALL_DIR="$5";

  "${PLISTUTIL_SCRIPT}"   "${FILE_NAME}" CFBundleGetInfoString      "${MAJOR_VERSION}.${MINOR_VERSION}.${POINT_VERSION}, Copyright © 2007-2008, John Engelhart" && \
    "${PLISTUTIL_SCRIPT}" "${FILE_NAME}" CFBundleShortVersionString "${MAJOR_VERSION}.${MINOR_VERSION}.${POINT_VERSION}" && \
    "${PLISTUTIL_SCRIPT}" "${FILE_NAME}" CFBundleVersion            "${MAJOR_VERSION}.${MINOR_VERSION}.${POINT_VERSION}" && \
    "${PLISTUTIL_SCRIPT}" "${FILE_NAME}" IFMajorVersion             "${MAJOR_VERSION}" && \
    "${PLISTUTIL_SCRIPT}" "${FILE_NAME}" IFMinorVersion             "${MINOR_VERSION}" && \
    "${PLISTUTIL_SCRIPT}" "${FILE_NAME}" IFPkgFlagDefaultLocation   "${INSTALL_DIR}"

  return $?
}

updateRegexKitMpkgVersion()
{
  local FILE_NAME="$1";
  local MAJOR_VERSION="$2";
  local MINOR_VERSION="$3";
  local POINT_VERSION="$4";

  "${PLISTUTIL_SCRIPT}"   "${FILE_NAME}" CFBundleGetInfoString      "${MAJOR_VERSION}.${MINOR_VERSION}.${POINT_VERSION}, Copyright © 2007-2008, John Engelhart" && \
    "${PLISTUTIL_SCRIPT}" "${FILE_NAME}" CFBundleShortVersionString "${MAJOR_VERSION}.${MINOR_VERSION}.${POINT_VERSION}" && \
    "${PLISTUTIL_SCRIPT}" "${FILE_NAME}" CFBundleVersion            "${MAJOR_VERSION}.${MINOR_VERSION}.${POINT_VERSION}"

  return $?
}

updatePackageInfoPlists()
{
  if [ ! -d "$1" ] ; then return 1; fi;
  updateVersion   "$1/Framework_info.plist"             ${PROJECT_VERSION_MAJOR} ${PROJECT_VERSION_MINOR} ${PROJECT_VERSION_POINT} "${DISTRIBUTION_DEFAULT_INSTALL_DIR}/Frameworks/" && \
    updateVersion "$1/Instruments_Additions_info.plist" ${PROJECT_VERSION_MAJOR} ${PROJECT_VERSION_MINOR} ${PROJECT_VERSION_POINT} "/Developer/Library/Instruments/PlugIns/" && \
    updateVersion "$1/DocSet_info.plist"                ${PROJECT_VERSION_MAJOR} ${PROJECT_VERSION_MINOR} ${PROJECT_VERSION_POINT} "/Library/Developer/Shared/Documentation/DocSets/" && \
    updateVersion "$1/Documentation_info.plist"         ${PROJECT_VERSION_MAJOR} ${PROJECT_VERSION_MINOR} ${PROJECT_VERSION_POINT} "${DISTRIBUTION_DEFAULT_INSTALL_DIR}/RegexKit/" && \
    updateVersion "$1/Sourcecode_info.plist"            ${PROJECT_VERSION_MAJOR} ${PROJECT_VERSION_MINOR} ${PROJECT_VERSION_POINT} "${DISTRIBUTION_DEFAULT_INSTALL_DIR}/RegexKit/" && \
    updateVersion "$1/pcre_info.plist"                  ${PCRE_VERSION_MAJOR}    ${PCRE_VERSION_MINOR}    0                        "${DISTRIBUTION_DEFAULT_INSTALL_DIR}/RegexKit/" && \
    "${PLISTUTIL_SCRIPT}" "$1/pcre_info.plist" CFBundleGetInfoString "${PCRE_VERSION_MAJOR}.${PCRE_VERSION_MINOR}.0, Copyright (c) 1997-2008 University of Cambridge" && \
    updateRegexKitMpkgVersion "$1/RegexKit_mpkg_info.plist" ${PROJECT_VERSION_MAJOR} ${PROJECT_VERSION_MINOR} ${PROJECT_VERSION_POINT}

  return $?
}

if [ ! -r "${DISTRIBUTION_SQL_FILES_FILE}" ]; then echo "$0:$LINENO: error: The sql database creation file 'files.sql' does not exist in '${BUILD_SQL_DIR}'."; exit 1; fi;

# Init and load the database
if [ ! -d "${DISTRIBUTION_SQL_DATABASE_DIR}" ]; then mkdir -p "${DISTRIBUTION_SQL_DATABASE_DIR}"; fi;
if [ "${DISTRIBUTION_SQL_FILES_FILE}" -nt "${DISTRIBUTION_SQL_DATABASE_FILE}" ]; then
  rm -rf "${DISTRIBUTION_SQL_DATABASE_FILE}"
  sync
  "${SQLITE}" "${DISTRIBUTION_SQL_DATABASE_FILE}" <"${DISTRIBUTION_SQL_FILES_FILE}"
  if [ $? != 0 ]; then echo "$0:$LINENO: error: Distribution SQL database 'files' data load failed."; exit 1; fi;
fi

if [ ! -x "${FILE_CHECK_SCRIPT}" ] ; then echo "$0:$LINENO: error: The file check script '${FILE_CHECK_SCRIPT}' does not exist."; exit 1; fi;

rm -rf "${DISTRIBUTION_TARGET_DIR}"

export DISTRIBUTION_TEMP_BINARY_ROOT="${DISTRIBUTION_TEMP_BINARY_DIR}/${DISTRIBUTION_ROOT_NAME}";
export DISTRIBUTION_TEMP_SOURCE_ROOT="${DISTRIBUTION_TEMP_SOURCE_DIR}/${DISTRIBUTION_ROOT_SOURCE_NAME}";
export CPUS=`sysctl -n hw.activecpu`;
export MAXLOAD=`expr "${CPUS}" + 2`;
if [ "${DISTRIBUTION_PARALLEL_BUILD}" == "YES" ] && (( ${CPUS} > 1 )); then
  echo "$0:$LINENO: note: DISTRIBUTION_PARALLEL_BUILD == 'YES', number of active CPU's: ${CPUS} max load average: ${MAXLOAD}";
  "${MAKE}" -f "${MAKEFILE_DIST}" -j "${CPUS}" -l "${MAXLOAD}" build_tarballs
else
  "${MAKE}" -f "${MAKEFILE_DIST}" build_tarballs
fi;

if [ "${XCODE_VERSION_MAJOR}" != "0200" ]; then
  echo "$0:$LINENO: note: Copying DocSet .xar file to Distribution directory."

  "${RSYNC}" -aCE "${DOCUMENTATION_DOCSET_TARGET_DIR}/${DOCUMENTATION_DOCSET_PACKAGED_FILE}" "${DISTRIBUTION_TARGET_DIR}/${DOCUMENTATION_DOCSET_PACKAGED_FILE}"
  if [ $? != 0 ]; then echo "$0:$LINENO: error: Unable to copy DocSet .xar to the Distribution directory."; exit 1; fi;
fi;

# Not yet moved to Makefile.dist

###############################################################################
echo "---------------"
echo ""
echo "$0:$LINENO: note: Creating Mac OS X Installer Package and .dmg."
echo ""
###############################################################################

export DISTRIBUTION_TEMP_PACKAGEMAKER_DIR="${DISTRIBUTION_TEMP_PACKAGES_DIR}/Packagemaker"
export DISTRIBUTION_TEMP_PACKAGE_PLISTS_DIR="${DISTRIBUTION_TEMP_PACKAGEMAKER_DIR}/plists"
export DISTRIBUTION_TEMP_INSTALLER_PACKAGE="${DISTRIBUTION_TEMP_PACKAGES_DIR}/${DISTRIBUTION_ROOT_NAME}.mpkg"

# Clean any previous attempts and prep staging area.
rm -rf "${DISTRIBUTION_TEMP_PACKAGES_DIR}" && \
  mkdir -p \
    "${DISTRIBUTION_TEMP_PACKAGES_DIR}/staging/${DOCUMENTATION_DOCSET_ID}" \
    "${DISTRIBUTION_TEMP_PACKAGES_DIR}/staging/Documentation" \
    "${DISTRIBUTION_TEMP_PACKAGES_DIR}/staging/RegexKit.framework" \
    "${DISTRIBUTION_TEMP_PACKAGES_DIR}/staging/Instruments_Additions" \
    "${DISTRIBUTION_TEMP_PACKAGES_DIR}/staging/Sourcecode" && \
  if [ "${DISTRIBUTION_INCLUDE_PCRE_PACKAGE}" == "YES" ]; then mkdir -p "${DISTRIBUTION_TEMP_PACKAGES_DIR}/staging/pcre/Sourcecode/Source/pcre"; fi
if [ $? != 0 ]; then echo "$0:$LINENO: error: Unable to delete the staging area from a previous build attempt."; exit 1; fi;

# Make a copy of the various files we need for packaging (Source/Build/PackageMaker/*).
"${RSYNC}" -aCE --delete "${BUILD_PACKAGEMAKER_DIR}/" "${DISTRIBUTION_TEMP_PACKAGEMAKER_DIR}/"
if [ $? != 0 ]; then echo "$0:$LINENO: error: Could not copy package resources to temporary staging area."; exit 1; fi;

# And update our copy of the plists files with the current version information.
updatePackageInfoPlists "${DISTRIBUTION_TEMP_PACKAGE_PLISTS_DIR}"
if [ $? != 0 ]; then echo "$0:$LINENO: error: Could not update packages Info.plist files with the current version."; exit 1; fi;

#
# Create the staging area.
#   Copy the two helper .html files (Documentation.html + Adding RegexKit to your Project.html) + build/Release/Documentation.
#     and SetFile -a E on Adding RegexKit to your Project.html to get rid of the extension when viewed from the Finder.
#   Copy build/Release/RegexKit.framework.
#     and strip any debugging symbols from it.
#   Copy the previously assembled Sourcecode directory from the source tarball build.
#   Set the files to group + write.
#     When `installed`, the user:group will be root:admin, thus allowing admin users to write to the directories/files.
#
# The reason why package grouping directories appear to be "doubled up" (ie, staging/RegexKit.framework/RegexKit.framework)
# is sort of goofy, but it's basically so that we can control what permissions the packages unarchive with.
#

echo "$0:$LINENO: note: Copying files to the packaging staging area."
"${RSYNC}" -aCE "${BUILD_DISTRIBUTION_DIR}/Documentation.html" "${BUILD_DISTRIBUTION_DIR}/Adding RegexKit to your Project.html" "${DOCUMENTATION_TARGET_DIR}" "${DISTRIBUTION_TEMP_PACKAGES_DIR}/staging/Documentation" && \
  "${SYSTEM_DEVELOPER_TOOLS}/SetFile" -a E "${DISTRIBUTION_TEMP_PACKAGES_DIR}/staging/Documentation/Adding RegexKit to your Project.html" && \
  "${RSYNC}" -aCE "${TARGET_BUILD_DIR}/RegexKit.framework/" "${DISTRIBUTION_TEMP_PACKAGES_DIR}/staging/RegexKit.framework/RegexKit.framework" && \
  "${RSYNC}" -aCE "${DISTRIBUTION_SOURCE_DTRACE_DIR}/"*.usdt "${DISTRIBUTION_SOURCE_DTRACE_DIR}/"*.instrument "${DISTRIBUTION_TEMP_PACKAGES_DIR}/staging/Instruments_Additions/" && \
  strip -S "${DISTRIBUTION_TEMP_PACKAGES_DIR}/staging/RegexKit.framework//RegexKit.framework/Versions/A/RegexKit" && \
  "${RSYNC}" -aCE "${DISTRIBUTION_TEMP_SOURCE_DIR}/Sourcecode/" "${DISTRIBUTION_TEMP_PACKAGES_DIR}/staging/Sourcecode/Sourcecode" && \
  if [ "${DISTRIBUTION_INCLUDE_PCRE_PACKAGE}" == "YES" ]; then "${RSYNC}" -a "${PCRE_TARBALL_FILE_PATH}" "${DISTRIBUTION_TEMP_PACKAGES_DIR}/staging/pcre/Sourcecode/Source/pcre/${PCRE_TARBALL_FILE_NAME}"; fi && \
  if [ "${XCODE_VERSION_MAJOR}" != "0200" ]; then "${RSYNC}" -aCE "${TARGET_BUILD_DIR}/DocSet/${DOCUMENTATION_DOCSET_ID}/" "${DISTRIBUTION_TEMP_PACKAGES_DIR}/staging/${DOCUMENTATION_DOCSET_ID}/${DOCUMENTATION_DOCSET_ID}"; fi && \
  "${CHMOD}" -R g+w "${DISTRIBUTION_TEMP_PACKAGES_DIR}/staging/Instruments_Additions" && \
  "${CHMOD}" -R g+w "${DISTRIBUTION_TEMP_PACKAGES_DIR}/staging/Documentation" && \
  "${CHMOD}" -R g+w "${DISTRIBUTION_TEMP_PACKAGES_DIR}/staging/Sourcecode" && \
  if [ "${XCODE_VERSION_MAJOR}" != "0200" ]; then "${CHMOD}" -R g+w "${DISTRIBUTION_TEMP_PACKAGES_DIR}/staging/com.zang.RegexKit.Documentation.docset"; fi
if [ $? != 0 ]; then echo "$0:$LINENO: error: Unable to copy distribution files to staging area."; exit 1; fi;

#
# Notes on PackageMaker package making...
#
# The -u flag tells PackageMaker to not gzip the Archive.pax file.  We leave it uncompressed because we put the final .mpkg bundle on a .dmg disk image.
# The .dmg disk image is compressed with bzip2 (UDBZ).  If PackageMaker gzip's it here, the resulting .dmg is ~60-70K larger because bzip2 is able
# to compress an uncompressed Archive.pax file better than a gunziped Archive.pax.gz.
#
# For the Documentation package we rebuild the .pax file completely to pick up the extension hiding SetFile -a E "Adding RegexKit to your Project.html"
#
# The odd perl scripts that alter the Archive.(pax|bom) output is the result of a compromise.
#
# What it does is set pax and bom files so that the user id and group ID are "0:80", aka "root:admin".
#
# One way to do it is to have root chown -R root:admin staging/ and let packagemaker/pax/cpio pick it up automatically.
# This, however, requires elevated privileges.  Using `sudo` has its drawbacks if your credentials aren't cached and
# you haven't updated sudoers with a pattern to let the command execute automatically without prompting for a password.
#
# There's also `-e 'do shell script "chown -R root:admin staging/" with administrator privileges'`, which will prompt
# with the standard security framework dialog panel for a password.  Certainly better when building interactively,
# but not ideal.
#
# Then there's the possibility that some malicous program could alter this script (or whatever script
# contains the elevated commands) and change it to execute some other commands at the elevated privilege.
#
# This way avoids all those pitfalls by simply re-writing the cpio .pax archive and bom file with the uid:gid pair
# we'd like to have when it un-archives, achieving the same result.
#

echo "$0:$LINENO: note: Packaging RegexKit.framework."
"${CHMOD}" -h go-w "${DISTRIBUTION_TEMP_PACKAGES_DIR}/staging/RegexKit.framework/RegexKit.framework/Headers" \
  "${DISTRIBUTION_TEMP_PACKAGES_DIR}/staging/RegexKit.framework/RegexKit.framework/RegexKit" \
  "${DISTRIBUTION_TEMP_PACKAGES_DIR}/staging/RegexKit.framework/RegexKit.framework/Resources" \
  "${DISTRIBUTION_TEMP_PACKAGES_DIR}/staging/RegexKit.framework/RegexKit.framework/Versions/Current"

"${PACKAGEMAKER}" -build \
    -p "${DISTRIBUTION_TEMP_PACKAGES_DIR}/${DISTRIBUTION_PACKAGE_FRAMEWORK}" \
    -f "${DISTRIBUTION_TEMP_PACKAGES_DIR}/staging/RegexKit.framework/" \
    -u \
    -ds \
    -i "${DISTRIBUTION_TEMP_PACKAGE_PLISTS_DIR}/Framework_info.plist" \
    -d "${DISTRIBUTION_TEMP_PACKAGE_PLISTS_DIR}/Framework_desc.plist" && \
  "${PERL}" -e 'while(<>) { s/(070707\d{18})(\d{12})(\d{40})/${1}000000000120${3}/g; print $_; }' -i "${DISTRIBUTION_TEMP_PACKAGES_DIR}/${DISTRIBUTION_PACKAGE_FRAMEWORK}/Contents/Archive.pax" && \
  if [ "${DISTRIBUTION_GZIP_PACKAGES}" == "YES" ]; then "${GZIP_CMD}" -n9 "${DISTRIBUTION_TEMP_PACKAGES_DIR}/${DISTRIBUTION_PACKAGE_FRAMEWORK}/Contents/Archive.pax" ; fi && \
  "${PERL}" -e 'while(<>) { s/\x0\x0\x1\xf5\x0\x0\x1\xf5/\x0\x0\x0\x0\x0\x0\x0\x50/g; print $_; }' -i "${DISTRIBUTION_TEMP_PACKAGES_DIR}/${DISTRIBUTION_PACKAGE_FRAMEWORK}/Contents/Archive.bom"
if [ $? != 0 ]; then echo "$0:$LINENO: error: Unable to create RegexKit.framework package."; exit 1; fi;

echo "$0:$LINENO: note: Packaging HTML Documentation."
"${PACKAGEMAKER}" -build \
  -p "${DISTRIBUTION_TEMP_PACKAGES_DIR}/${DISTRIBUTION_PACKAGE_HTML_DOCUMENTATION}" \
  -f "${DISTRIBUTION_TEMP_PACKAGES_DIR}/staging/Documentation" \
  -u \
  -ds \
  -i "${DISTRIBUTION_TEMP_PACKAGE_PLISTS_DIR}/Documentation_info.plist" \
  -d "${DISTRIBUTION_TEMP_PACKAGE_PLISTS_DIR}/Documentation_desc.plist"
if [ $? != 0 ]; then echo "$0:$LINENO: error: Unable to create HTML Documentation package."; exit 1; fi;

# bogus package maker
# So, the packagemaker -build puts together a .pax file that strips off the SetFile -a E (hide extension)
# flag for whatever reason.  So we re-build it here.
rm -f "${DISTRIBUTION_TEMP_PACKAGES_DIR}/${DISTRIBUTION_PACKAGE_HTML_DOCUMENTATION}/Contents/Archive.pax" && \
  cd "${DISTRIBUTION_TEMP_PACKAGES_DIR}/staging/Documentation" && \
  pax -w -x cpio -f "${DISTRIBUTION_TEMP_PACKAGES_DIR}/${DISTRIBUTION_PACKAGE_HTML_DOCUMENTATION}/Contents/Archive.pax" . && \
  "${PERL}" -e 'while(<>) { s/(070707\d{18})(\d{12})(\d{40})/${1}000000000120${3}/g; print $_; }' -i "${DISTRIBUTION_TEMP_PACKAGES_DIR}/${DISTRIBUTION_PACKAGE_HTML_DOCUMENTATION}/Contents/Archive.pax" && \
  if [ "${DISTRIBUTION_GZIP_PACKAGES}" == "YES" ]; then "${GZIP_CMD}" -n9 "${DISTRIBUTION_TEMP_PACKAGES_DIR}/${DISTRIBUTION_PACKAGE_HTML_DOCUMENTATION}/Contents/Archive.pax" ; fi && \
  "${PERL}" -e 'while(<>) { s/\x0\x0\x1\xf5\x0\x0\x1\xf5/\x0\x0\x0\x0\x0\x0\x0\x50/g; print $_; }' -i "${DISTRIBUTION_TEMP_PACKAGES_DIR}/${DISTRIBUTION_PACKAGE_HTML_DOCUMENTATION}/Contents/Archive.bom" && \
  cd "${PROJECT_DIR}" && \
if [ $? != 0 ]; then echo "$0:$LINENO: error: Unable to re-pax HTML Documenation (hide extension dropped work-around)."; exit 1; fi;


if [ "${XCODE_VERSION_MAJOR}" != "0200" ]; then
echo "$0:$LINENO: note: Packaging DocSet Documentation."
"${PACKAGEMAKER}" -build \
    -p "${DISTRIBUTION_TEMP_PACKAGES_DIR}/${DISTRIBUTION_PACKAGE_DOCSET_DOCUMENTATION}" \
    -f "${DISTRIBUTION_TEMP_PACKAGES_DIR}/staging/${DOCUMENTATION_DOCSET_ID}/" \
    -u \
    -ds \
    -i "${DISTRIBUTION_TEMP_PACKAGE_PLISTS_DIR}/DocSet_info.plist" \
    -d "${DISTRIBUTION_TEMP_PACKAGE_PLISTS_DIR}/DocSet_desc.plist" && \
  "${PERL}" -e 'while(<>) { s/(070707\d{18})(\d{12})(\d{40})/${1}000000000120${3}/g; print $_; }' -i "${DISTRIBUTION_TEMP_PACKAGES_DIR}/${DISTRIBUTION_PACKAGE_DOCSET_DOCUMENTATION}/Contents/Archive.pax" && \
  if [ "${DISTRIBUTION_GZIP_PACKAGES}" == "YES" ]; then "${GZIP_CMD}" -n9 "${DISTRIBUTION_TEMP_PACKAGES_DIR}/${DISTRIBUTION_PACKAGE_DOCSET_DOCUMENTATION}/Contents/Archive.pax" ; fi && \
  "${PERL}" -e 'while(<>) { s/\x0\x0\x1\xf5\x0\x0\x1\xf5/\x0\x0\x0\x0\x0\x0\x0\x50/g; print $_; }' -i "${DISTRIBUTION_TEMP_PACKAGES_DIR}/${DISTRIBUTION_PACKAGE_DOCSET_DOCUMENTATION}/Contents/Archive.bom"
if [ $? != 0 ]; then echo "$0:$LINENO: error: Unable to create DocSet Documentation package."; exit 1; fi;
fi


echo "$0:$LINENO: note: Packaging sourcecode."
"${PACKAGEMAKER}" -build \
    -p "${DISTRIBUTION_TEMP_PACKAGES_DIR}/${DISTRIBUTION_PACKAGE_SOURCECODE}" \
    -f "${DISTRIBUTION_TEMP_PACKAGES_DIR}/staging/Sourcecode/" \
    -u \
    -ds \
    -i "${DISTRIBUTION_TEMP_PACKAGE_PLISTS_DIR}/Sourcecode_info.plist" \
    -d "${DISTRIBUTION_TEMP_PACKAGE_PLISTS_DIR}/Sourcecode_desc.plist" && \
  "${PERL}" -e 'while(<>) { s/(070707\d{18})(\d{12})(\d{40})/${1}000000000120${3}/g; print $_; }' -i "${DISTRIBUTION_TEMP_PACKAGES_DIR}/${DISTRIBUTION_PACKAGE_SOURCECODE}/Contents/Archive.pax" && \
  if [ "${DISTRIBUTION_GZIP_PACKAGES}" == "YES" ]; then "${GZIP_CMD}" -n9 "${DISTRIBUTION_TEMP_PACKAGES_DIR}/${DISTRIBUTION_PACKAGE_SOURCECODE}/Contents/Archive.pax" ; fi && \
  "${PERL}" -e 'while(<>) { s/\x0\x0\x1\xf5\x0\x0\x1\xf5/\x0\x0\x0\x0\x0\x0\x0\x50/g; print $_; }' -i "${DISTRIBUTION_TEMP_PACKAGES_DIR}/${DISTRIBUTION_PACKAGE_SOURCECODE}/Contents/Archive.bom"
if [ $? != 0 ]; then echo "$0:$LINENO: error: Unable to create sourcecode package."; exit 1; fi;


echo "$0:$LINENO: note: Packaging Instrument.app Additions."
"${PACKAGEMAKER}" -build \
    -p "${DISTRIBUTION_TEMP_PACKAGES_DIR}/${DISTRIBUTION_PACKAGE_INSTRUMENTS_ADDITIONS}" \
    -f "${DISTRIBUTION_TEMP_PACKAGES_DIR}/staging/Instruments_Additions/" \
    -u \
    -ds \
    -i "${DISTRIBUTION_TEMP_PACKAGE_PLISTS_DIR}/Instruments_Additions_info.plist" \
    -d "${DISTRIBUTION_TEMP_PACKAGE_PLISTS_DIR}/Instruments_Additions_desc.plist" && \
  "${PERL}" -e 'while(<>) { s/(070707\d{18})(\d{12})(\d{40})/${1}000000000120${3}/g; print $_; }' -i "${DISTRIBUTION_TEMP_PACKAGES_DIR}/${DISTRIBUTION_PACKAGE_INSTRUMENTS_ADDITIONS}/Contents/Archive.pax" && \
  if [ "${DISTRIBUTION_GZIP_PACKAGES}" == "YES" ]; then "${GZIP_CMD}" -n9 "${DISTRIBUTION_TEMP_PACKAGES_DIR}/${DISTRIBUTION_PACKAGE_INSTRUMENTS_ADDITIONS}/Contents/Archive.pax" ; fi && \
  "${PERL}" -e 'while(<>) { s/\x0\x0\x1\xf5\x0\x0\x1\xf5/\x0\x0\x0\x0\x0\x0\x0\x50/g; print $_; }' -i "${DISTRIBUTION_TEMP_PACKAGES_DIR}/${DISTRIBUTION_PACKAGE_INSTRUMENTS_ADDITIONS}/Contents/Archive.bom"
if [ $? != 0 ]; then echo "$0:$LINENO: error: Unable to create Instruments Additions package."; exit 1; fi;


if [ "${DISTRIBUTION_INCLUDE_PCRE_PACKAGE}" == "YES" ]; then
  echo "$0:$LINENO: note: Packaging PCRE distribution."
  "${PACKAGEMAKER}" -build \
      -p "${DISTRIBUTION_TEMP_PACKAGES_DIR}/${DISTRIBUTION_PACKAGE_SOURCECODE_PCRE}" \
      -f "${DISTRIBUTION_TEMP_PACKAGES_DIR}/staging/pcre/" \
      -u \
      -ds \
      -i "${DISTRIBUTION_TEMP_PACKAGE_PLISTS_DIR}/pcre_info.plist" \
      -d "${DISTRIBUTION_TEMP_PACKAGE_PLISTS_DIR}/pcre_desc.plist" && \
    "${PERL}" -e 'while(<>) { s/(070707\d{18})(\d{12})(\d{40})/${1}000000000120${3}/g; print $_; }' -i "${DISTRIBUTION_TEMP_PACKAGES_DIR}/${DISTRIBUTION_PACKAGE_SOURCECODE_PCRE}/Contents/Archive.pax" && \
    if [ "${DISTRIBUTION_GZIP_PACKAGES}" == "YES" ]; then "${GZIP_CMD}" -n9 "${DISTRIBUTION_TEMP_PACKAGES_DIR}/${DISTRIBUTION_PACKAGE_SOURCECODE_PCRE}/Contents/Archive.pax" ; fi && \
    "${PERL}" -e 'while(<>) { s/\x0\x0\x1\xf5\x0\x0\x1\xf5/\x0\x0\x0\x0\x0\x0\x0\x50/g; print $_; }' -i "${DISTRIBUTION_TEMP_PACKAGES_DIR}/${DISTRIBUTION_PACKAGE_SOURCECODE_PCRE}/Contents/Archive.bom"
  if [ $? != 0 ]; then echo "$0:$LINENO: error: Unable to create PCRE distribution package."; exit 1; fi;
fi

# This creates/replicates the layout that packagemaker would have created.
# For whatever reason, when I would supply `packagemaker` with the .pmproj for the complete distribution, it would always segfault.
# So, we do it this way.
echo "$0:$LINENO: note: Creating installer package."
mkdir -p "${DISTRIBUTION_TEMP_INSTALLER_PACKAGE}/Contents/Packages" && \
  "${RSYNC}" -aC "${DISTRIBUTION_TEMP_PACKAGEMAKER_DIR}/Resources/" "${DISTRIBUTION_TEMP_INSTALLER_PACKAGE}/Contents/Resources/" && \
  "${FIND}" "${DISTRIBUTION_TEMP_INSTALLER_PACKAGE}/Contents/Resources" -type f -exec "${CHMOD}" 555 {} \; && \
  "${RSYNC}" -aC "${DISTRIBUTION_TEMP_PACKAGEMAKER_DIR}/plists/RegexKit_mpkg_info.plist" "${DISTRIBUTION_TEMP_INSTALLER_PACKAGE}/Contents/Info.plist" && \
  "${RSYNC}" -aC \
    "${DISTRIBUTION_TEMP_PACKAGES_DIR}/${DISTRIBUTION_PACKAGE_FRAMEWORK}" \
    "${DISTRIBUTION_TEMP_PACKAGES_DIR}/${DISTRIBUTION_PACKAGE_INSTRUMENTS_ADDITIONS}" \
    "${DISTRIBUTION_TEMP_PACKAGES_DIR}/${DISTRIBUTION_PACKAGE_HTML_DOCUMENTATION}" \
    "${DISTRIBUTION_TEMP_PACKAGES_DIR}/${DISTRIBUTION_PACKAGE_SOURCECODE}" \
    "${DISTRIBUTION_TEMP_INSTALLER_PACKAGE}/Contents/Packages" && \
  if [ "${DISTRIBUTION_INCLUDE_PCRE_PACKAGE}" == "YES" ]; then \
    "${RSYNC}" -aC "${DISTRIBUTION_TEMP_PACKAGES_DIR}/${DISTRIBUTION_PACKAGE_SOURCECODE_PCRE}" "${DISTRIBUTION_TEMP_INSTALLER_PACKAGE}/Contents/Packages"; \
  fi
  if [ "${XCODE_VERSION_MAJOR}" != "0200" ]; then \
    "${RSYNC}" -aC "${DISTRIBUTION_TEMP_PACKAGES_DIR}/${DISTRIBUTION_PACKAGE_DOCSET_DOCUMENTATION}" "${DISTRIBUTION_TEMP_INSTALLER_PACKAGE}/Contents/Packages"; \
  fi
if [ $? != 0 ]; then echo "$0:$LINENO: error: Unable to copy files in to final installer package."; exit 1; fi;

# PACKAGEDIST_SCRIPT creates the installer 'distribution.dist' installer script file.
# PackageMaker was used to create the first iteration of the distribution.dist file which was then cleaned up
# and placed in to the perl script.  The perl script extracts information from the three previously
# created packages and substitutes their values in the right places in the generated .dist file.
# Most importantly it extracts the .pkg versions and installation sizes.
"${PACKAGEDIST_SCRIPT}" > "${DISTRIBUTION_TEMP_INSTALLER_PACKAGE}/Contents/distribution.dist"
if [ $? != 0 ]; then echo "$0:$LINENO: error: Unable to create installer distribution.dist script."; exit 1; fi;

# Copy the completed .mpkg to the final build/Release/Distribution location.
"${RSYNC}" -aCE "${DISTRIBUTION_TEMP_INSTALLER_PACKAGE}" "${DISTRIBUTION_TARGET_DIR}"
if [ $? != 0 ]; then echo "$0:$LINENO: error: Unable to copy Installer Package to distribution directory."; exit 1; fi;

# Copy our completed .mpkg to the .dmg staging area and then create the .dmg.
mkdir "${DISTRIBUTION_TEMP_PACKAGES_DIR}/${DISTRIBUTION_ROOT_NAME}" && \
  "${RSYNC}" -aCE "${DISTRIBUTION_TEMP_INSTALLER_PACKAGE}" "${DISTRIBUTION_TEMP_PACKAGES_DIR}/${DISTRIBUTION_ROOT_NAME}"  
if [ $? != 0 ]; then echo "$0:$LINENO: error: Unable to copy Installer Package to .dmg staging area."; exit 1; fi;

# Create the Mac OS X Installer .dmg
create_dmg "${DISTRIBUTION_TEMP_PACKAGES_DIR}" "${DISTRIBUTION_BASE_FILE_NAME}.dmg" "${DISTRIBUTION_DMG_VOL_NAME}" "${DISTRIBUTION_ROOT_NAME}" "${DISTRIBUTION_DMG_CONVERT_OPTS}" "YES"
if [ $? != 0 ]; then echo "$0:$LINENO: error: Error creating '${DISTRIBUTION_BASE_FILE_NAME}.dmg' disk image."; exit 1; fi;

# Copy the completed .dmg to the final build/Release/Distribution location.
"${RSYNC}" -aCE "${DISTRIBUTION_TEMP_PACKAGES_DIR}/${DISTRIBUTION_BASE_FILE_NAME}.dmg" "${DISTRIBUTION_TARGET_DIR}"
if [ $? != 0 ]; then echo "$0:$LINENO: error: Unable to copy Installer Package .dmg to distribution directory."; exit 1; fi;

echo "$0:$LINENO: note: Distribution target completed successfully."
exit 0;
