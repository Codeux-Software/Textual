# GNUstep Makefile for RegexKit Framework

include $(GNUSTEP_MAKEFILES)/common.make

# Assumes that the CWD is GNUstep
REGEXKIT_ROOT_DIR       = $(abspath ..)

GNUSTEP_BUILD_DIR       = ${REGEXKIT_ROOT_DIR}/GNUstep
REGEXKIT_SOURCE_DIR     = ${REGEXKIT_ROOT_DIR}/Source
REGEXKIT_HEADERS_DIR    = ${REGEXKIT_SOURCE_DIR}/Headers

PCRE_LIBS               = $(shell pcre-config --libs)
PCRE_CFLAGS             = $(shell pcre-config --cflags)
PCRE_HEADER             = $(shell perl -e '$$x = "${PCRE_CFLAGS}"; $$x =~ /\-I(.*?\/include\b)/; print("$$1/pcre.h");')

ORIGINAL_RK_PCRE_HEADER = $(shell diff -q '${REGEXKIT_HEADERS_DIR}/RegexKit/pcre.h' '${REGEXKIT_SOURCE_DIR}/Build/Distribution/distribution_pcre.h')

ifeq (${ORIGINAL_RK_PCRE_HEADER},)
$(info Copying the installed PCRE's '${PCRE_HEADER}' to RegexKit's Headers directory at '${REGEXKIT_HEADERS_DIR}/RegexKit/pcre.h')
$(shell cp '${PCRE_HEADER}' '${REGEXKIT_HEADERS_DIR}/RegexKit/pcre.h')
endif

vpath %.m ${REGEXKIT_SOURCE_DIR}
vpath %.h ${REGEXKIT_HEADERS_DIR}/RegexKit

ADDITIONAL_FLAGS += -I${REGEXKIT_HEADERS_DIR} ${PCRE_CFLAGS} -std=gnu99

LIBRARY_VAR  = REGEXKIT
LIBRARY_NAME = libRegexKit
PACKAGE_NAME = RegexKit

libRegexKit_HEADER_FILES             = NSArray.h NSData.h NSDictionary.h NSObject.h NSSet.h NSString.h RKEnumerator.h RKCache.h RKEnumerator.h RKRegex.h RKUtility.h RegexKit.h RegexKitDefines.h RegexKitTypes.h pcre.h
libRegexKit_OBJC_FILES               = NSArray.m NSData.m NSDictionary.m NSObject.m NSSet.m NSString.m RKAutoreleasedMemory.m RKCache.m RKCoder.m RKEnumerator.m RKLock.m RKPlaceholder.m RKPrivate.m RKRegex.m RKSortedRegexCollection.m RKThreadPool.m RKUtility.m
libRegexKit_HEADER_FILES_DIR         = ${REGEXKIT_HEADERS_DIR}/RegexKit
libRegexKit_HEADER_FILES_INSTALL_DIR = /RegexKit

# Include the PCRE library
libRegexKit_LIBRARIES_DEPEND_UPON   += $(FND_LIBS) ${PCRE_LIBS}

include $(GNUSTEP_MAKEFILES)/library.make
include $(GNUSTEP_MAKEFILES)/aggregate.make

-include GNUmakefile.postamble



