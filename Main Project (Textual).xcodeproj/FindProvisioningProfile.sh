#!/bin/bash

cd "${PROJECT_DIR}/Resources/"

BUNDLE_IDENTIFIER=$(/usr/libexec/PlistBuddy -c "Print \"CFBundleIdentifier\"" Info.plist)

DESIRED_NAME_1="Mac Team Provisioning Profile: ${BUNDLE_IDENTIFIER}"
DESIRED_NAME_2="MacTeam Provisioning Profile: ${BUNDLE_IDENTIFIER}"

echo "Starting search for profile with name: ${DESIRED_NAME_1} and ${DESIRED_NAME_2}"

DESTINATION_CONFIGURATION_FILE="${PROJECT_DIR}/Resources/Build Configurations/Provisioning Profile.xcconfig"

if [ -f "${DESTINATION_CONFIGURATION_FILE}" ]; then
	rm -f "${DESTINATION_CONFIGURATION_FILE}"
fi

TEMPORARY_STORE_FOLDER="/tmp/provisioningProfileEnumerator"
TEMPORARY_STORE_FILE="${TEMPORARY_STORE_FOLDER}/tempStore.plist"

FOUND_A_PROFILE=0

mkdir -p "${TEMPORARY_STORE_FOLDER}"

cd "${TEMPORARY_STORE_FOLDER}"

PROFILES=`find ~/Library/MobileDevice/Provisioning\ Profiles -name "*.provisionprofile"`

SAVEIFS=$IFS

IFS=$(echo -en "\n\b")

for PROFILE in $PROFILES; do	
	echo "Processing profile: ${PROFILE}";
	
	if [ -f "${TEMPORARY_STORE_FILE}" ]; then
		rm -f "${TEMPORARY_STORE_FILE}"
	fi
	
	security cms -D -i "${PROFILE}" > "${TEMPORARY_STORE_FILE}" 
	
	NAME_VALUE=`/usr/libexec/PlistBuddy -c "Print \"Name\"" "${TEMPORARY_STORE_FILE}"`
	UUID_VALUE=`/usr/libexec/PlistBuddy -c "Print \"UUID\"" "${TEMPORARY_STORE_FILE}"`
	
	echo "	Found name: ${NAME_VALUE}";
	echo "	Found UUID: ${UUID_VALUE}"; 
	
	if [ "${NAME_VALUE}" == "${DESIRED_NAME_1}" ] || [ "${NAME_VALUE}" == "${DESIRED_NAME_2}" ]; then
		echo "	Found desired profile.";
		
		touch "${DESTINATION_CONFIGURATION_FILE}"
		
		echo "PROVISIONING_PROFILE = ${UUID_VALUE}" > "${DESTINATION_CONFIGURATION_FILE}"
		
		FOUND_A_PROFILE=1
		
		break
	fi
done

IFS=$SAVEIFS

if [ $FOUND_A_PROFILE -eq 0 ]; then 
	echo "ERROR: Did not find a valid profile. Creating blank configuration file.";
	
	touch "${DESTINATION_CONFIGURATION_FILE}"
fi

rm -rf "${TEMPORARY_STORE_FOLDER}"

exit
