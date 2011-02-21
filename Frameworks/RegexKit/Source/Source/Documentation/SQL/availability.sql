BEGIN;

CREATE TEMP TABLE t_intro (xref TEXT);

INSERT INTO t_intro (xref) VALUES ('RKBuildConfig');
INSERT INTO t_intro (xref) VALUES ('RKBuildConfig/RKBuildConfigBackslashRAnyCRLR');
INSERT INTO t_intro (xref) VALUES ('RKBuildConfig/RKBuildConfigBackslashRUnicode');
INSERT INTO t_intro (xref) VALUES ('RKBuildConfig/RKBuildConfigNewlineAny');
INSERT INTO t_intro (xref) VALUES ('RKBuildConfig/RKBuildConfigNewlineAnyCRLF');
INSERT INTO t_intro (xref) VALUES ('RKBuildConfig/RKBuildConfigNewlineCR');
INSERT INTO t_intro (xref) VALUES ('RKBuildConfig/RKBuildConfigNewlineCRLF');
INSERT INTO t_intro (xref) VALUES ('RKBuildConfig/RKBuildConfigNewlineDefault');
INSERT INTO t_intro (xref) VALUES ('RKBuildConfig/RKBuildConfigNewlineLF');
INSERT INTO t_intro (xref) VALUES ('RKBuildConfig/RKBuildConfigNewlineMask');
INSERT INTO t_intro (xref) VALUES ('RKBuildConfig/RKBuildConfigNoOptions');
INSERT INTO t_intro (xref) VALUES ('RKBuildConfig/RKBuildConfigUTF8');
INSERT INTO t_intro (xref) VALUES ('RKBuildConfig/RKBuildConfigUnicodeProperties');

INSERT INTO t_intro (xref) VALUES ('RKCompileErrorCode');
INSERT INTO t_intro (xref) VALUES ('RKCompileErrorCode/RKCompileErrorAssertionExpectedAfterCondition');
INSERT INTO t_intro (xref) VALUES ('RKCompileErrorCode/RKCompileErrorByteEscapeAtEndOfPattern');
INSERT INTO t_intro (xref) VALUES ('RKCompileErrorCode/RKCompileErrorCalloutExceedsMaximumAllowed');
INSERT INTO t_intro (xref) VALUES ('RKCompileErrorCode/RKCompileErrorConditionalGroupContainsMoreThanTwoBranches');
INSERT INTO t_intro (xref) VALUES ('RKCompileErrorCode/RKCompileErrorDEFINEGroupContainsMoreThanOneBranch');
INSERT INTO t_intro (xref) VALUES ('RKCompileErrorCode/RKCompileErrorDuplicateSubpatternNames');
INSERT INTO t_intro (xref) VALUES ('RKCompileErrorCode/RKCompileErrorErrorOffsetPassedAsNull');
INSERT INTO t_intro (xref) VALUES ('RKCompileErrorCode/RKCompileErrorEscapeAtEndOfPattern');
INSERT INTO t_intro (xref) VALUES ('RKCompileErrorCode/RKCompileErrorHexCharacterValueTooLarge');
INSERT INTO t_intro (xref) VALUES ('RKCompileErrorCode/RKCompileErrorIllegalOctalValueOutsideUTF8');
INSERT INTO t_intro (xref) VALUES ('RKCompileErrorCode/RKCompileErrorInconsistentNewlineOptions');
INSERT INTO t_intro (xref) VALUES ('RKCompileErrorCode/RKCompileErrorInternalCodeOverflow');
INSERT INTO t_intro (xref) VALUES ('RKCompileErrorCode/RKCompileErrorInternalErrorUnexpectedRepeat');
INSERT INTO t_intro (xref) VALUES ('RKCompileErrorCode/RKCompileErrorInternalOverranCompilingWorkspace');
INSERT INTO t_intro (xref) VALUES ('RKCompileErrorCode/RKCompileErrorInternalReferencedSubpatternNotFound');
INSERT INTO t_intro (xref) VALUES ('RKCompileErrorCode/RKCompileErrorInvalidCondition');
INSERT INTO t_intro (xref) VALUES ('RKCompileErrorCode/RKCompileErrorInvalidEscapeInCharacterClass');
INSERT INTO t_intro (xref) VALUES ('RKCompileErrorCode/RKCompileErrorInvalidUTF8String');
INSERT INTO t_intro (xref) VALUES ('RKCompileErrorCode/RKCompileErrorLookbehindAssertionNotFixedLength');
INSERT INTO t_intro (xref) VALUES ('RKCompileErrorCode/RKCompileErrorMalformedNameOrNumberAfterSubpattern');
INSERT INTO t_intro (xref) VALUES ('RKCompileErrorCode/RKCompileErrorMalformedUnicodeProperty');
INSERT INTO t_intro (xref) VALUES ('RKCompileErrorCode/RKCompileErrorMissingEndParentheses');
INSERT INTO t_intro (xref) VALUES ('RKCompileErrorCode/RKCompileErrorMissingParentheses');
INSERT INTO t_intro (xref) VALUES ('RKCompileErrorCode/RKCompileErrorMissingParenthesesAfterCallout');
INSERT INTO t_intro (xref) VALUES ('RKCompileErrorCode/RKCompileErrorMissingParenthesesAfterComment');
INSERT INTO t_intro (xref) VALUES ('RKCompileErrorCode/RKCompileErrorMissingTerminatorForCharacterClass');
INSERT INTO t_intro (xref) VALUES ('RKCompileErrorCode/RKCompileErrorMissingUTF8Support');
INSERT INTO t_intro (xref) VALUES ('RKCompileErrorCode/RKCompileErrorMissingUnicodeSupport');
INSERT INTO t_intro (xref) VALUES ('RKCompileErrorCode/RKCompileErrorNoError');
INSERT INTO t_intro (xref) VALUES ('RKCompileErrorCode/RKCompileErrorNoMemory');
INSERT INTO t_intro (xref) VALUES ('RKCompileErrorCode/RKCompileErrorNotAllowedInLookbehindAssertion');
INSERT INTO t_intro (xref) VALUES ('RKCompileErrorCode/RKCompileErrorNotSupported');
INSERT INTO t_intro (xref) VALUES ('RKCompileErrorCode/RKCompileErrorNothingToRepeat');
INSERT INTO t_intro (xref) VALUES ('RKCompileErrorCode/RKCompileErrorNumbersOutOfOrder');
INSERT INTO t_intro (xref) VALUES ('RKCompileErrorCode/RKCompileErrorNumbersToBig');
INSERT INTO t_intro (xref) VALUES ('RKCompileErrorCode/RKCompileErrorPOSIXCollatingNotSupported');
INSERT INTO t_intro (xref) VALUES ('RKCompileErrorCode/RKCompileErrorPOSIXNamedClassOutsideOfClass');
INSERT INTO t_intro (xref) VALUES ('RKCompileErrorCode/RKCompileErrorRangeOutOfOrderInCharacterClass');
INSERT INTO t_intro (xref) VALUES ('RKCompileErrorCode/RKCompileErrorRecursiveInfinitLoop');
INSERT INTO t_intro (xref) VALUES ('RKCompileErrorCode/RKCompileErrorReferenceMustBeNonZeroNumberOrBraced');
INSERT INTO t_intro (xref) VALUES ('RKCompileErrorCode/RKCompileErrorReferenceToNonExistentSubpattern');
INSERT INTO t_intro (xref) VALUES ('RKCompileErrorCode/RKCompileErrorRegexTooLarge');
INSERT INTO t_intro (xref) VALUES ('RKCompileErrorCode/RKCompileErrorRelativeSubpatternNumberMustNotBeZero');
INSERT INTO t_intro (xref) VALUES ('RKCompileErrorCode/RKCompileErrorRepeatedSubpatternTooLong');
INSERT INTO t_intro (xref) VALUES ('RKCompileErrorCode/RKCompileErrorRepeatingDEFINEGroupNotAllowed');
INSERT INTO t_intro (xref) VALUES ('RKCompileErrorCode/RKCompileErrorSubpatternNameMissingTerminator');
INSERT INTO t_intro (xref) VALUES ('RKCompileErrorCode/RKCompileErrorSubpatternNameTooLong');
INSERT INTO t_intro (xref) VALUES ('RKCompileErrorCode/RKCompileErrorTooManySubpatterns');
INSERT INTO t_intro (xref) VALUES ('RKCompileErrorCode/RKCompileErrorUnknownOptionBits');
INSERT INTO t_intro (xref) VALUES ('RKCompileErrorCode/RKCompileErrorUnknownPOSIXClassName');
INSERT INTO t_intro (xref) VALUES ('RKCompileErrorCode/RKCompileErrorUnknownPropertyAfterUnicodeCharacter');
INSERT INTO t_intro (xref) VALUES ('RKCompileErrorCode/RKCompileErrorUnmatchedParentheses');
INSERT INTO t_intro (xref) VALUES ('RKCompileErrorCode/RKCompileErrorUnrecognizedCharacterAfterNamedPattern');
INSERT INTO t_intro (xref) VALUES ('RKCompileErrorCode/RKCompileErrorUnrecognizedCharacterAfterNamedSubppatern');
INSERT INTO t_intro (xref) VALUES ('RKCompileErrorCode/RKCompileErrorUnrecognizedCharacterAfterOption');
INSERT INTO t_intro (xref) VALUES ('RKCompileErrorCode/RKCompileErrorUnrecognizedCharacterFollowingEscape');


INSERT INTO t_intro (xref) VALUES ('RKCompileOption');
INSERT INTO t_intro (xref) VALUES ('RKCompileOption/RKCompileAllOptions');
INSERT INTO t_intro (xref) VALUES ('RKCompileOption/RKCompileAnchored');
INSERT INTO t_intro (xref) VALUES ('RKCompileOption/RKCompileAutoCallout');
INSERT INTO t_intro (xref) VALUES ('RKCompileOption/RKCompileBackslashRAnyCRLR');
INSERT INTO t_intro (xref) VALUES ('RKCompileOption/RKCompileBackslashRUnicode');
INSERT INTO t_intro (xref) VALUES ('RKCompileOption/RKCompileCaseless');
INSERT INTO t_intro (xref) VALUES ('RKCompileOption/RKCompileDollarEndOnly');
INSERT INTO t_intro (xref) VALUES ('RKCompileOption/RKCompileDotAll');
INSERT INTO t_intro (xref) VALUES ('RKCompileOption/RKCompileDupNames');
INSERT INTO t_intro (xref) VALUES ('RKCompileOption/RKCompileExtended');
INSERT INTO t_intro (xref) VALUES ('RKCompileOption/RKCompileExtra');
INSERT INTO t_intro (xref) VALUES ('RKCompileOption/RKCompileFirstLine');
INSERT INTO t_intro (xref) VALUES ('RKCompileOption/RKCompileMultiline');
INSERT INTO t_intro (xref) VALUES ('RKCompileOption/RKCompileNewlineAny');
INSERT INTO t_intro (xref) VALUES ('RKCompileOption/RKCompileNewlineAnyCRLF');
INSERT INTO t_intro (xref) VALUES ('RKCompileOption/RKCompileNewlineCR');
INSERT INTO t_intro (xref) VALUES ('RKCompileOption/RKCompileNewlineCRLF');
INSERT INTO t_intro (xref) VALUES ('RKCompileOption/RKCompileNewlineDefault');
INSERT INTO t_intro (xref) VALUES ('RKCompileOption/RKCompileNewlineLF');
INSERT INTO t_intro (xref) VALUES ('RKCompileOption/RKCompileNewlineMask');
INSERT INTO t_intro (xref) VALUES ('RKCompileOption/RKCompileNewlineShift');
INSERT INTO t_intro (xref) VALUES ('RKCompileOption/RKCompileNoAutoCapture');
INSERT INTO t_intro (xref) VALUES ('RKCompileOption/RKCompileNoOptions');
INSERT INTO t_intro (xref) VALUES ('RKCompileOption/RKCompileNoUTF8Check');
INSERT INTO t_intro (xref) VALUES ('RKCompileOption/RKCompileUTF8');
INSERT INTO t_intro (xref) VALUES ('RKCompileOption/RKCompileUngreedy');
INSERT INTO t_intro (xref) VALUES ('RKCompileOption/RKCompileUnsupported');

INSERT INTO t_intro (xref) VALUES ('RKMatchErrorCode');
INSERT INTO t_intro (xref) VALUES ('RKMatchErrorCode/RKMatchErrorBadCount');
INSERT INTO t_intro (xref) VALUES ('RKMatchErrorCode/RKMatchErrorBadMagic');
INSERT INTO t_intro (xref) VALUES ('RKMatchErrorCode/RKMatchErrorBadNewline');
INSERT INTO t_intro (xref) VALUES ('RKMatchErrorCode/RKMatchErrorBadOption');
INSERT INTO t_intro (xref) VALUES ('RKMatchErrorCode/RKMatchErrorBadPartial');
INSERT INTO t_intro (xref) VALUES ('RKMatchErrorCode/RKMatchErrorBadUTF8');
INSERT INTO t_intro (xref) VALUES ('RKMatchErrorCode/RKMatchErrorBadUTF8Offset');
INSERT INTO t_intro (xref) VALUES ('RKMatchErrorCode/RKMatchErrorCallout');
INSERT INTO t_intro (xref) VALUES ('RKMatchErrorCode/RKMatchErrorInternal');
INSERT INTO t_intro (xref) VALUES ('RKMatchErrorCode/RKMatchErrorMatchLimit');
INSERT INTO t_intro (xref) VALUES ('RKMatchErrorCode/RKMatchErrorNoError');
INSERT INTO t_intro (xref) VALUES ('RKMatchErrorCode/RKMatchErrorNoMatch');
INSERT INTO t_intro (xref) VALUES ('RKMatchErrorCode/RKMatchErrorNoMemory');
INSERT INTO t_intro (xref) VALUES ('RKMatchErrorCode/RKMatchErrorNoSubstring');
INSERT INTO t_intro (xref) VALUES ('RKMatchErrorCode/RKMatchErrorNull');
INSERT INTO t_intro (xref) VALUES ('RKMatchErrorCode/RKMatchErrorNullWorkSpaceLimit');
INSERT INTO t_intro (xref) VALUES ('RKMatchErrorCode/RKMatchErrorPartial');
INSERT INTO t_intro (xref) VALUES ('RKMatchErrorCode/RKMatchErrorRecursionLimit');
INSERT INTO t_intro (xref) VALUES ('RKMatchErrorCode/RKMatchErrorUnknownOpcode');


INSERT INTO t_intro (xref) VALUES ('RKMatchOption');
INSERT INTO t_intro (xref) VALUES ('RKMatchOption/RKMatchAnchored');
INSERT INTO t_intro (xref) VALUES ('RKMatchOption/RKMatchBackslashRAnyCRLR');
INSERT INTO t_intro (xref) VALUES ('RKMatchOption/RKMatchBackslashRUnicode');
INSERT INTO t_intro (xref) VALUES ('RKMatchOption/RKMatchNewlineAny');
INSERT INTO t_intro (xref) VALUES ('RKMatchOption/RKMatchNewlineAnyCRLF');
INSERT INTO t_intro (xref) VALUES ('RKMatchOption/RKMatchNewlineCR');
INSERT INTO t_intro (xref) VALUES ('RKMatchOption/RKMatchNewlineCRLF');
INSERT INTO t_intro (xref) VALUES ('RKMatchOption/RKMatchNewlineDefault');
INSERT INTO t_intro (xref) VALUES ('RKMatchOption/RKMatchNewlineLF');
INSERT INTO t_intro (xref) VALUES ('RKMatchOption/RKMatchNewlineMask');
INSERT INTO t_intro (xref) VALUES ('RKMatchOption/RKMatchNoOptions');
INSERT INTO t_intro (xref) VALUES ('RKMatchOption/RKMatchNoUTF8Check');
INSERT INTO t_intro (xref) VALUES ('RKMatchOption/RKMatchNotBeginningOfLine');
INSERT INTO t_intro (xref) VALUES ('RKMatchOption/RKMatchNotEmpty');
INSERT INTO t_intro (xref) VALUES ('RKMatchOption/RKMatchNotEndOfLine');
INSERT INTO t_intro (xref) VALUES ('RKMatchOption/RKMatchPartial');



INSERT INTO t_intro (xref) VALUES ('RKCache/-addObjectToCache:');
INSERT INTO t_intro (xref) VALUES ('RKCache/-addObjectToCache:withHash:');
INSERT INTO t_intro (xref) VALUES ('RKCache/-cacheCount');
INSERT INTO t_intro (xref) VALUES ('RKCache/-cacheSet');
INSERT INTO t_intro (xref) VALUES ('RKCache/-clearCache');
INSERT INTO t_intro (xref) VALUES ('RKCache/-description');
INSERT INTO t_intro (xref) VALUES ('RKCache/-initWithDescription:');
INSERT INTO t_intro (xref) VALUES ('RKCache/-isCacheEnabled');
INSERT INTO t_intro (xref) VALUES ('RKCache/-objectForHash:description:');
INSERT INTO t_intro (xref) VALUES ('RKCache/-objectForHash:description:autorelease:');
INSERT INTO t_intro (xref) VALUES ('RKCache/-removeObjectFromCache:');
INSERT INTO t_intro (xref) VALUES ('RKCache/-removeObjectWithHash:');
INSERT INTO t_intro (xref) VALUES ('RKCache/-setCacheEnabled:');
INSERT INTO t_intro (xref) VALUES ('RKCache/-setDescription:');
INSERT INTO t_intro (xref) VALUES ('RKCache/-status');


INSERT INTO t_intro (xref) VALUES ('RKEnumerator/+enumeratorWithRegex:string:');
INSERT INTO t_intro (xref) VALUES ('RKEnumerator/+enumeratorWithRegex:string:inRange:');
INSERT INTO t_intro (xref) VALUES ('RKEnumerator/-currentRange');
INSERT INTO t_intro (xref) VALUES ('RKEnumerator/-currentRangeForCapture:');
INSERT INTO t_intro (xref) VALUES ('RKEnumerator/-currentRangeForCaptureName:');
INSERT INTO t_intro (xref) VALUES ('RKEnumerator/-currentRanges');
INSERT INTO t_intro (xref) VALUES ('RKEnumerator/-getCapturesWithReferences:');
INSERT INTO t_intro (xref) VALUES ('RKEnumerator/-initWithRegex:string:');
INSERT INTO t_intro (xref) VALUES ('RKEnumerator/-initWithRegex:string:inRange:');
INSERT INTO t_intro (xref) VALUES ('RKEnumerator/-nextObject');
INSERT INTO t_intro (xref) VALUES ('RKEnumerator/-nextRange');
INSERT INTO t_intro (xref) VALUES ('RKEnumerator/-nextRangeForCapture:');
INSERT INTO t_intro (xref) VALUES ('RKEnumerator/-nextRangeForCaptureName:');
INSERT INTO t_intro (xref) VALUES ('RKEnumerator/-nextRanges');
INSERT INTO t_intro (xref) VALUES ('RKEnumerator/-regex');
INSERT INTO t_intro (xref) VALUES ('RKEnumerator/-string');
INSERT INTO t_intro (xref) VALUES ('RKEnumerator/-stringWithReferenceFormat:');
INSERT INTO t_intro (xref) VALUES ('RKEnumerator/-stringWithReferenceFormat:arguments:');
INSERT INTO t_intro (xref) VALUES ('RKEnumerator/-stringWithReferenceString:');

INSERT INTO t_intro (xref) VALUES ('RKRegex/+PCREBuildConfig');
INSERT INTO t_intro (xref) VALUES ('RKRegex/+PCREMajorVersion');
INSERT INTO t_intro (xref) VALUES ('RKRegex/+PCREMinorVersion');
INSERT INTO t_intro (xref) VALUES ('RKRegex/+PCREVersionString');
INSERT INTO t_intro (xref) VALUES ('RKRegex/+isValidRegexString:options:');
INSERT INTO t_intro (xref) VALUES ('RKRegex/+regexCache');
INSERT INTO t_intro (xref) VALUES ('RKRegex/+regexWithRegexString:options:');
INSERT INTO t_intro (xref) VALUES ('RKRegex/-captureCount');
INSERT INTO t_intro (xref) VALUES ('RKRegex/-captureIndexForCaptureName:');
INSERT INTO t_intro (xref) VALUES ('RKRegex/-captureIndexForCaptureName:inMatchedRanges:');
INSERT INTO t_intro (xref) VALUES ('RKRegex/-captureNameArray');
INSERT INTO t_intro (xref) VALUES ('RKRegex/-captureNameForCaptureIndex:');
INSERT INTO t_intro (xref) VALUES ('RKRegex/-compileOption');
INSERT INTO t_intro (xref) VALUES ('RKRegex/-getRanges:withCharacters:length:inRange:options:');
INSERT INTO t_intro (xref) VALUES ('RKRegex/-initWithRegexString:options:');
INSERT INTO t_intro (xref) VALUES ('RKRegex/-isValidCaptureName:');
INSERT INTO t_intro (xref) VALUES ('RKRegex/-matchesCharacters:length:inRange:options:');
INSERT INTO t_intro (xref) VALUES ('RKRegex/-rangeForCharacters:length:inRange:captureIndex:options:');
INSERT INTO t_intro (xref) VALUES ('RKRegex/-rangesForCharacters:length:inRange:options:');
INSERT INTO t_intro (xref) VALUES ('RKRegex/-regexString');


INSERT INTO t_intro (xref) VALUES ('NSArray(RegexKitAdditions)/-arrayByMatchingObjectsWithRegex:');
INSERT INTO t_intro (xref) VALUES ('NSArray(RegexKitAdditions)/-arrayByMatchingObjectsWithRegex:inRange:');
INSERT INTO t_intro (xref) VALUES ('NSArray(RegexKitAdditions)/-containsObjectMatchingRegex:');
INSERT INTO t_intro (xref) VALUES ('NSArray(RegexKitAdditions)/-containsObjectMatchingRegex:inRange:');
INSERT INTO t_intro (xref) VALUES ('NSArray(RegexKitAdditions)/-countOfObjectsMatchingRegex:');
INSERT INTO t_intro (xref) VALUES ('NSArray(RegexKitAdditions)/-countOfObjectsMatchingRegex:inRange:');
INSERT INTO t_intro (xref) VALUES ('NSArray(RegexKitAdditions)/-indexOfObjectMatchingRegex:');
INSERT INTO t_intro (xref) VALUES ('NSArray(RegexKitAdditions)/-indexOfObjectMatchingRegex:inRange:');

INSERT INTO t_intro (xref) VALUES ('NSDictionary(RegexKitAdditions)/-containsKeyMatchingRegex:');
INSERT INTO t_intro (xref) VALUES ('NSDictionary(RegexKitAdditions)/-containsObjectMatchingRegex:');
INSERT INTO t_intro (xref) VALUES ('NSDictionary(RegexKitAdditions)/-dictionaryByMatchingKeysWithRegex:');
INSERT INTO t_intro (xref) VALUES ('NSDictionary(RegexKitAdditions)/-dictionaryByMatchingObjectsWithRegex:');
INSERT INTO t_intro (xref) VALUES ('NSDictionary(RegexKitAdditions)/-keysForObjectsMatchingRegex:');
INSERT INTO t_intro (xref) VALUES ('NSDictionary(RegexKitAdditions)/-keysMatchingRegex:');
INSERT INTO t_intro (xref) VALUES ('NSDictionary(RegexKitAdditions)/-objectsForKeysMatchingRegex:');
INSERT INTO t_intro (xref) VALUES ('NSDictionary(RegexKitAdditions)/-objectsMatchingRegex:');

INSERT INTO t_intro (xref) VALUES ('NSMutableArray(RegexKitAdditions)/-addObjectsFromArray:matchingRegex:');
INSERT INTO t_intro (xref) VALUES ('NSMutableArray(RegexKitAdditions)/-removeObjectsMatchingRegex:');
INSERT INTO t_intro (xref) VALUES ('NSMutableArray(RegexKitAdditions)/-removeObjectsMatchingRegex:inRange:');

INSERT INTO t_intro (xref) VALUES ('NSMutableDictionary(RegexKitAdditions)/-addEntriesFromDictionary:withKeysMatchingRegex:');
INSERT INTO t_intro (xref) VALUES ('NSMutableDictionary(RegexKitAdditions)/-addEntriesFromDictionary:withObjectsMatchingRegex:');
INSERT INTO t_intro (xref) VALUES ('NSMutableDictionary(RegexKitAdditions)/-removeObjectsForKeysMatchingRegex:');
INSERT INTO t_intro (xref) VALUES ('NSMutableDictionary(RegexKitAdditions)/-removeObjectsMatchingRegex:');

INSERT INTO t_intro (xref) VALUES ('NSMutableSet(RegexKitAdditions)/-addObjectsFromArray:matchingRegex:');
INSERT INTO t_intro (xref) VALUES ('NSMutableSet(RegexKitAdditions)/-addObjectsFromSet:matchingRegex:');
INSERT INTO t_intro (xref) VALUES ('NSMutableSet(RegexKitAdditions)/-removeObjectsMatchingRegex:');

INSERT INTO t_intro (xref) VALUES ('NSMutableString(RegexKitAdditions)/-match:replace:withString:');

INSERT INTO t_intro (xref) VALUES ('NSObject(RegexKitAdditions)/-isMatchedByRegex:');

INSERT INTO t_intro (xref) VALUES ('NSSet(RegexKitAdditions)/-anyObjectMatchingRegex:');
INSERT INTO t_intro (xref) VALUES ('NSSet(RegexKitAdditions)/-containsObjectMatchingRegex:');
INSERT INTO t_intro (xref) VALUES ('NSSet(RegexKitAdditions)/-countOfObjectsMatchingRegex:');
INSERT INTO t_intro (xref) VALUES ('NSSet(RegexKitAdditions)/-setByMatchingObjectsWithRegex:');

INSERT INTO t_intro (xref) VALUES ('NSString(RegexKitAdditions)/-getCapturesWithRegex:inRange:references:');
INSERT INTO t_intro (xref) VALUES ('NSString(RegexKitAdditions)/-getCapturesWithRegexAndReferences:');
INSERT INTO t_intro (xref) VALUES ('NSString(RegexKitAdditions)/-isMatchedByRegex:');
INSERT INTO t_intro (xref) VALUES ('NSString(RegexKitAdditions)/-isMatchedByRegex:inRange:');
INSERT INTO t_intro (xref) VALUES ('NSString(RegexKitAdditions)/-matchEnumeratorWithRegex:');
INSERT INTO t_intro (xref) VALUES ('NSString(RegexKitAdditions)/-matchEnumeratorWithRegex:inRange:');
INSERT INTO t_intro (xref) VALUES ('NSString(RegexKitAdditions)/-rangeOfRegex:');
INSERT INTO t_intro (xref) VALUES ('NSString(RegexKitAdditions)/-rangeOfRegex:inRange:capture:');
INSERT INTO t_intro (xref) VALUES ('NSString(RegexKitAdditions)/-rangesOfRegex:');
INSERT INTO t_intro (xref) VALUES ('NSString(RegexKitAdditions)/-rangesOfRegex:inRange:');
INSERT INTO t_intro (xref) VALUES ('NSString(RegexKitAdditions)/-stringByMatching:inRange:replace:withReferenceFormat:');
INSERT INTO t_intro (xref) VALUES ('NSString(RegexKitAdditions)/-stringByMatching:inRange:replace:withReferenceString:');
INSERT INTO t_intro (xref) VALUES ('NSString(RegexKitAdditions)/-stringByMatching:inRange:withReferenceFormat:');
INSERT INTO t_intro (xref) VALUES ('NSString(RegexKitAdditions)/-stringByMatching:inRange:withReferenceString:');
INSERT INTO t_intro (xref) VALUES ('NSString(RegexKitAdditions)/-stringByMatching:replace:withReferenceFormat:');
INSERT INTO t_intro (xref) VALUES ('NSString(RegexKitAdditions)/-stringByMatching:replace:withReferenceString:');
INSERT INTO t_intro (xref) VALUES ('NSString(RegexKitAdditions)/-stringByMatching:withReferenceFormat:');
INSERT INTO t_intro (xref) VALUES ('NSString(RegexKitAdditions)/-stringByMatching:withReferenceString:');

INSERT INTO t_intro (xref) VALUES ('RKArrayFromBuildConfig');
INSERT INTO t_intro (xref) VALUES ('RKArrayFromCompileOption');
INSERT INTO t_intro (xref) VALUES ('RKArrayFromMatchOption');
INSERT INTO t_intro (xref) VALUES ('RKStringFromCompileErrorCode');
INSERT INTO t_intro (xref) VALUES ('RKStringFromMatchErrorCode');
INSERT INTO t_intro (xref) VALUES ('RKStringFromNewlineOption');


INSERT INTO t_intro (xref) VALUES ('RKRegexCaptureReferenceException');
INSERT INTO t_intro (xref) VALUES ('RKRegexSyntaxErrorException');
INSERT INTO t_intro (xref) VALUES ('RKRegexUnsupportedException');

INSERT INTO t_intro (xref) VALUES ('RKReplaceAll');

INSERT INTO t_intro (xref) VALUES ('RKREGEX_STATIC_INLINE');
INSERT INTO t_intro (xref) VALUES ('RK_ATTRIBUTES');
INSERT INTO t_intro (xref) VALUES ('RK_C99');
INSERT INTO t_intro (xref) VALUES ('RK_EXPECTED');


INSERT INTO versionCrossRef (ivid, bitSize, tbl, id) SELECT DISTINCT v.vid, 32, tx.tbl, tx.id FROM t_intro AS ti JOIN t_xtoc AS tx ON tx.xref = ti.xref, version AS v WHERE v.major = 0 AND v.minor = 2 AND v.point = 0;
INSERT INTO versionCrossRef (ivid, bitSize, tbl, id) SELECT DISTINCT v.vid, 64, tx.tbl, tx.id FROM t_intro AS ti JOIN t_xtoc AS tx ON tx.xref = ti.xref, version AS v WHERE v.major = 0 AND v.minor = 3 AND v.point = 0;

DELETE FROM t_intro;

INSERT INTO t_intro (xref) VALUES ('RKCache');
INSERT INTO t_intro (xref) VALUES ('RKEnumerator');
INSERT INTO t_intro (xref) VALUES ('RKRegex');
INSERT INTO t_intro (xref) VALUES ('NSArray');
INSERT INTO t_intro (xref) VALUES ('NSDictionary');
INSERT INTO t_intro (xref) VALUES ('NSMutableArray');
INSERT INTO t_intro (xref) VALUES ('NSMutableDictionary');
INSERT INTO t_intro (xref) VALUES ('NSMutableSet');
INSERT INTO t_intro (xref) VALUES ('NSMutableString');
INSERT INTO t_intro (xref) VALUES ('NSObject');
INSERT INTO t_intro (xref) VALUES ('NSSet');
INSERT INTO t_intro (xref) VALUES ('NSString');

INSERT INTO versionCrossRef (ivid, bitSize, tbl, id) SELECT DISTINCT v.vid, 32, 'objCClass', occ.occlid FROM t_intro AS ti JOIN objCClass AS occ ON occ.class = ti.xref, version AS v WHERE v.major = 0 AND v.minor = 2 AND v.point = 0;
INSERT INTO versionCrossRef (ivid, bitSize, tbl, id) SELECT DISTINCT v.vid, 64, 'objCClass', occ.occlid FROM t_intro AS ti JOIN objCClass AS occ ON occ.class = ti.xref, version AS v WHERE v.major = 0 AND v.minor = 3 AND v.point = 0;


--
--
--                0.3.0
--
--

DELETE FROM t_intro;

INSERT INTO t_intro (xref) VALUES ('ENABLE_MACOSX_GARBAGE_COLLECTION');
INSERT INTO t_intro (xref) VALUES ('RK_REQUIRES_NIL_TERMINATION');

INSERT INTO t_intro (xref) VALUES ('RKInteger');
INSERT INTO t_intro (xref) VALUES ('RKIntegerMax');
INSERT INTO t_intro (xref) VALUES ('RKIntegerMin');
INSERT INTO t_intro (xref) VALUES ('RKUInteger');
INSERT INTO t_intro (xref) VALUES ('RKUIntegerMax');


INSERT OR REPLACE INTO versionCrossRef (ivid, bitSize, tbl, id) SELECT DISTINCT v.vid, 32, tx.tbl, tx.id FROM t_intro AS ti JOIN t_xtoc AS tx ON tx.xref = ti.xref, version AS v WHERE (v.major = 0 AND v.minor = 3 AND v.point = 0);
INSERT OR REPLACE INTO versionCrossRef (ivid, bitSize, tbl, id) SELECT DISTINCT v.vid, 64, tx.tbl, tx.id FROM t_intro AS ti JOIN t_xtoc AS tx ON tx.xref = ti.xref, version AS v WHERE (v.major = 0 AND v.minor = 3 AND v.point = 0);



--
--
--                0.4.0
--
--

DELETE FROM t_intro;

INSERT INTO t_intro (xref) VALUES ('RKConvertUTF16ToUTF8RangeForString');
INSERT INTO t_intro (xref) VALUES ('RKConvertUTF8ToUTF16RangeForString');


INSERT OR REPLACE INTO versionCrossRef (ivid, bitSize, tbl, id) SELECT DISTINCT v.vid, 32, tx.tbl, tx.id FROM t_intro AS ti JOIN t_xtoc AS tx ON tx.xref = ti.xref, version AS v WHERE (v.major = 0 AND v.minor = 4 AND v.point = 0);
INSERT OR REPLACE INTO versionCrossRef (ivid, bitSize, tbl, id) SELECT DISTINCT v.vid, 64, tx.tbl, tx.id FROM t_intro AS ti JOIN t_xtoc AS tx ON tx.xref = ti.xref, version AS v WHERE (v.major = 0 AND v.minor = 4 AND v.point = 0);

--
--
--                0.5.0
--
--

DELETE FROM t_intro;

INSERT INTO t_intro (xref) VALUES ('ENABLE_DTRACE_INSTRUMENTATION');

INSERT INTO t_intro (xref) VALUES ('NSArray(RegexKitAdditions)/-indexSetOfObjectsMatchingRegex:');
INSERT INTO t_intro (xref) VALUES ('NSArray(RegexKitAdditions)/-indexSetOfObjectsMatchingRegex:inRange:');

INSERT INTO t_intro (xref) VALUES ('NSData(RegexKitAdditions)/-isMatchedByRegex:');
INSERT INTO t_intro (xref) VALUES ('NSData(RegexKitAdditions)/-isMatchedByRegex:inRange:');
INSERT INTO t_intro (xref) VALUES ('NSData(RegexKitAdditions)/-rangeOfRegex:');
INSERT INTO t_intro (xref) VALUES ('NSData(RegexKitAdditions)/-rangeOfRegex:inRange:capture:');
INSERT INTO t_intro (xref) VALUES ('NSData(RegexKitAdditions)/-rangesOfRegex:');
INSERT INTO t_intro (xref) VALUES ('NSData(RegexKitAdditions)/-rangesOfRegex:inRange:');
INSERT INTO t_intro (xref) VALUES ('NSData(RegexKitAdditions)/-subdataByMatching:');
INSERT INTO t_intro (xref) VALUES ('NSData(RegexKitAdditions)/-subdataByMatching:inRange:');


INSERT OR REPLACE INTO versionCrossRef (ivid, bitSize, tbl, id) SELECT DISTINCT v.vid, 32, tx.tbl, tx.id FROM t_intro AS ti JOIN t_xtoc AS tx ON tx.xref = ti.xref, version AS v WHERE (v.major = 0 AND v.minor = 5 AND v.point = 0);
INSERT OR REPLACE INTO versionCrossRef (ivid, bitSize, tbl, id) SELECT DISTINCT v.vid, 64, tx.tbl, tx.id FROM t_intro AS ti JOIN t_xtoc AS tx ON tx.xref = ti.xref, version AS v WHERE (v.major = 0 AND v.minor = 5 AND v.point = 0);


DELETE FROM t_intro;

INSERT INTO t_intro (xref) VALUES ('NSData');


INSERT INTO versionCrossRef (ivid, bitSize, tbl, id) SELECT DISTINCT v.vid, 32, 'objCClass', occ.occlid FROM t_intro AS ti JOIN objCClass AS occ ON occ.class = ti.xref, version AS v WHERE v.major = 0 AND v.minor = 5 AND v.point = 0;
INSERT INTO versionCrossRef (ivid, bitSize, tbl, id) SELECT DISTINCT v.vid, 64, 'objCClass', occ.occlid FROM t_intro AS ti JOIN objCClass AS occ ON occ.class = ti.xref, version AS v WHERE v.major = 0 AND v.minor = 5 AND v.point = 0;

--
--
--                0.6.0
--
--

DELETE FROM t_intro;


INSERT INTO t_intro (xref) VALUES ('RKEnumerator/+enumeratorWithRegex:string:inRange:error:');
INSERT INTO t_intro (xref) VALUES ('RKEnumerator/-initWithRegex:string:inRange:error:');



INSERT INTO t_intro (xref) VALUES ('RKRegex/+regexWithRegexString:library:options:error:');
INSERT INTO t_intro (xref) VALUES ('RKRegex/-captureIndexForCaptureName:inMatchedRanges:error:');
INSERT INTO t_intro (xref) VALUES ('RKRegex/-initWithRegexString:library:options:error:');


INSERT INTO t_intro (xref) VALUES ('NSObject(RegexKitAdditions)/-anyMatchingRegexInArray:');
INSERT INTO t_intro (xref) VALUES ('NSObject(RegexKitAdditions)/-anyMatchingRegexInArray:library:options:error:');
INSERT INTO t_intro (xref) VALUES ('NSObject(RegexKitAdditions)/-anyMatchingRegexInSet:');
INSERT INTO t_intro (xref) VALUES ('NSObject(RegexKitAdditions)/-anyMatchingRegexInSet:library:options:error:');
INSERT INTO t_intro (xref) VALUES ('NSObject(RegexKitAdditions)/-firstMatchingRegexInArray:');
INSERT INTO t_intro (xref) VALUES ('NSObject(RegexKitAdditions)/-firstMatchingRegexInArray:library:options:error:');
INSERT INTO t_intro (xref) VALUES ('NSObject(RegexKitAdditions)/-isMatchedByAnyRegexInArray:');
INSERT INTO t_intro (xref) VALUES ('NSObject(RegexKitAdditions)/-isMatchedByAnyRegexInArray:library:options:error:');
INSERT INTO t_intro (xref) VALUES ('NSObject(RegexKitAdditions)/-isMatchedByAnyRegexInSet:');
INSERT INTO t_intro (xref) VALUES ('NSObject(RegexKitAdditions)/-isMatchedByAnyRegexInSet:library:options:error:');

INSERT INTO t_intro (xref) VALUES ('RKAbreviatedAttributedRegexStringErrorKey');
INSERT INTO t_intro (xref) VALUES ('RKAbreviatedRegexStringErrorKey');
INSERT INTO t_intro (xref) VALUES ('RKAbreviatedRegexStringErrorRangeErrorKey');
INSERT INTO t_intro (xref) VALUES ('RKArrayIndexErrorKey');
INSERT INTO t_intro (xref) VALUES ('RKAttributedRegexStringErrorKey');
INSERT INTO t_intro (xref) VALUES ('RKCollectionErrorKey');
INSERT INTO t_intro (xref) VALUES ('RKCompileErrorCodeErrorKey');
INSERT INTO t_intro (xref) VALUES ('RKCompileErrorCodeStringErrorKey');
INSERT INTO t_intro (xref) VALUES ('RKCompileOptionArrayErrorKey');
INSERT INTO t_intro (xref) VALUES ('RKCompileOptionArrayStringErrorKey');
INSERT INTO t_intro (xref) VALUES ('RKCompileOptionErrorKey');
INSERT INTO t_intro (xref) VALUES ('RKObjectErrorKey');
INSERT INTO t_intro (xref) VALUES ('RKRegexErrorDomain');
INSERT INTO t_intro (xref) VALUES ('RKRegexLibraryErrorKey');
INSERT INTO t_intro (xref) VALUES ('RKRegexLibraryErrorStringErrorKey');
INSERT INTO t_intro (xref) VALUES ('RKRegexPCRELibrary');
INSERT INTO t_intro (xref) VALUES ('RKRegexPCRELibraryErrorDomain');
INSERT INTO t_intro (xref) VALUES ('RKRegexStringErrorKey');
INSERT INTO t_intro (xref) VALUES ('RKRegexStringErrorRangeErrorKey');



INSERT OR REPLACE INTO versionCrossRef (ivid, bitSize, tbl, id) SELECT DISTINCT v.vid, 32, tx.tbl, tx.id FROM t_intro AS ti JOIN t_xtoc AS tx ON tx.xref = ti.xref, version AS v WHERE (v.major = 0 AND v.minor = 6 AND v.point = 0);
INSERT OR REPLACE INTO versionCrossRef (ivid, bitSize, tbl, id) SELECT DISTINCT v.vid, 64, tx.tbl, tx.id FROM t_intro AS ti JOIN t_xtoc AS tx ON tx.xref = ti.xref, version AS v WHERE (v.major = 0 AND v.minor = 6 AND v.point = 0);

COMMIT;
