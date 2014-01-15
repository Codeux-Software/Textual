/* ********************************************************************* 
       _____        _               _    ___ ____   ____
      |_   _|___  _| |_ _   _  __ _| |  |_ _|  _ \ / ___|
       | |/ _ \ \/ / __| | | |/ _` | |   | || |_) | |
       | |  __/>  <| |_| |_| | (_| | |   | ||  _ <| |___
       |_|\___/_/\_\\__|\__,_|\__,_|_|  |___|_| \_\\____|

 Copyright (c) 2008 - 2010 Satoshi Nakagawa <psychs AT limechat DOT net>
 Copyright (c) 2010 — 2014 Codeux Software & respective contributors.
     Please see Acknowledgements.pdf for additional information.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of the Textual IRC Client & Codeux Software nor the
      names of its contributors may be used to endorse or promote products
      derived from this software without specific prior written permission.

 THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
 ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 SUCH DAMAGE.

 *********************************************************************** */

#import "TextualApplication.h"
#import "BuildConfig.h"

#include <unistd.h>         // -------
#include <sys/types.h>      // --- | For +userHomeDirectoryPathOutsideSandbox
#include <pwd.h>            // -------

@implementation TPCPreferences

#pragma mark -
#pragma mark Command Index

static NSArray *IRCUserAccessibleCommandIndexMap;
static NSArray *IRCInternalUseCommandIndexMap;

+ (void)populateCommandIndex
{
	IRCInternalUseCommandIndexMap = @[ // Open Key: 1054
	//		 key					  command				 index		  is special	  outgoing colon index
		@[@"action",				@"ACTION",				@(1002),		@(NO),			@(NSNotFound)],
		@[@"adchat",				@"ADCHAT",				@(1003),		@(YES),			@(0)],
		@[@"away",					@"AWAY",				@(1050),		@(YES),			@(0)],
		@[@"cap",					@"CAP",					@(1004),		@(YES),			@(NSNotFound)],
		@[@"cap_authenticate",		@"AUTHENTICATE",		@(1005),		@(YES),			@(NSNotFound)],
		@[@"chatops",				@"CHATOPS",				@(1006),		@(YES),			@(0)],
		@[@"ctcp",					@"CTCP",				@(1007),		@(NO),			@(NSNotFound)],
		@[@"ctcp_clientinfo",		@"CLIENTINFO",			@(1008),		@(NO),			@(NSNotFound)],
		@[@"ctcp_cap",				@"CAP",					@(1052),		@(NO),			@(NSNotFound)],
		@[@"ctcp_ctcpreply",		@"CTCPREPLY",			@(1009),		@(NO),			@(NSNotFound)],
		@[@"ctcp_finger",			@"FINGER",				@(1051),		@(NO),			@(NSNotFound)],
		@[@"ctcp_lagcheck",			@"LAGCHECK",			@(1010),		@(NO),			@(NSNotFound)],
		@[@"ctcp_ping",				@"PING",				@(1011),		@(NO),			@(NSNotFound)],
		@[@"ctcp_time",				@"TIME",				@(1012),		@(NO),			@(NSNotFound)],
		@[@"ctcp_userinfo",			@"USERINFO",			@(1013),		@(NO),			@(NSNotFound)],
		@[@"ctcp_version",			@"VERSION",				@(1014),		@(NO),			@(NSNotFound)],
		@[@"dcc",					@"DCC",					@(1015),		@(NO),			@(NSNotFound)],
		@[@"error",					@"ERROR",				@(1016),		@(YES),			@(0)],
		@[@"gline",					@"GLINE",				@(1047),		@(YES),			@(2)],
		@[@"globops",				@"GLOBOPS",				@(1017),		@(YES),			@(0)],
		@[@"gzline",				@"GZLINE",				@(1048),		@(YES),			@(2)],
		@[@"invite",				@"INVITE",				@(1018),		@(YES),			@(NSNotFound)],
		@[@"ison",					@"ISON",				@(1019),		@(YES),			@(NSNotFound)],
		@[@"join",					@"JOIN",				@(1020),		@(YES),			@(NSNotFound)],
		@[@"kick",					@"KICK",				@(1021),		@(YES),			@(2)],
		@[@"kill",					@"KILL",				@(1022),		@(YES),			@(1)],
		@[@"list",					@"LIST",				@(1023),		@(YES),			@(NSNotFound)],
		@[@"locops",				@"LOCOPS",				@(1024),		@(YES),			@(0)],
		@[@"mode",					@"MODE",				@(1026),		@(YES),			@(NSNotFound)],
		@[@"nachat",				@"NACHAT",				@(1027),		@(YES),			@(0)],
		@[@"names",					@"NAMES",				@(1028),		@(YES),			@(NSNotFound)],
		@[@"nick",					@"NICK",				@(1029),		@(YES),			@(NSNotFound)],
		@[@"notice",				@"NOTICE",				@(1030),		@(YES),			@(1)],
		@[@"part",					@"PART",				@(1031),		@(YES),			@(1)],
		@[@"pass",					@"PASS",				@(1032),		@(YES),			@(NSNotFound)],
		@[@"ping",					@"PING",				@(1033),		@(YES),			@(NSNotFound)],
		@[@"pong",					@"PONG",				@(1034),		@(YES),			@(NSNotFound)],
		@[@"privmsg",				@"PRIVMSG",				@(1035),		@(YES),			@(1)],
		@[@"quit",					@"QUIT",				@(1036),		@(YES),			@(0)],
		@[@"shun",					@"SHUN",				@(1045),		@(YES),			@(2)],
		@[@"tempshun",				@"TEMPSHUN",			@(1046),		@(YES),			@(1)],
		@[@"topic",					@"TOPIC",				@(1039),		@(YES),			@(1)],
		@[@"user",					@"USER",				@(1037),		@(YES),			@(3)],
		@[@"watch",					@"WATCH",				@(1053),		@(YES),			@(NSNotFound)],
		@[@"wallops",				@"WALLOPS",				@(1038),		@(YES),			@(0)],
		@[@"who",					@"WHO",					@(1040),		@(YES),			@(NSNotFound)],
		@[@"whois",					@"WHOIS",				@(1042),		@(YES),			@(NSNotFound)],
		@[@"whowas",				@"WHOWAS",				@(1041),		@(YES),			@(NSNotFound)],
		@[@"zline",					@"ZLINE",				@(1049),		@(YES),			@(2)],
	];

	IRCUserAccessibleCommandIndexMap = @[ // Open Key: 5100
	//		 key						 command				 index		developer mode
		@[@"adchat",					@"ADCHAT",				@(5001),		@(NO)],
		@[@"ame",						@"AME",					@(5002),		@(NO)],
		@[@"amsg",						@"AMSG",				@(5003),		@(NO)],
		@[@"aquote",					@"AQUOTE",				@(5095),		@(NO)],
		@[@"araw",						@"ARAW",				@(5096),		@(NO)],
		@[@"away",						@"AWAY",				@(5004),		@(NO)],
		@[@"ban",						@"BAN",					@(5005),		@(NO)],
		@[@"cap",						@"CAP",					@(5006),		@(NO)],
		@[@"caps",						@"CAPS",				@(5007),		@(NO)],
		@[@"ccbadge",					@"CCBADGE",				@(5008),		@(YES)],
		@[@"chatops",					@"CHATOPS",				@(5009),		@(NO)],
		@[@"clear",						@"CLEAR",				@(5010),		@(NO)],
		@[@"clearall",					@"CLEARALL",			@(5011),		@(NO)],
		@[@"close",						@"CLOSE",				@(5012),		@(NO)],
		@[@"conn",						@"CONN",				@(5013),		@(NO)],
		@[@"ctcp",						@"CTCP",				@(5014),		@(NO)],
		@[@"ctcpreply",					@"CTCPREPLY",			@(5015),		@(NO)],
		@[@"cycle",						@"CYCLE",				@(5016),		@(NO)],
		@[@"dcc",						@"DCC",					@(5017),		@(NO)],
		@[@"debug",						@"DEBUG",				@(5018),		@(NO)],
		@[@"dehalfop",					@"DEHALFOP",			@(5019),		@(NO)],
		@[@"deop",						@"DEOP",				@(5020),		@(NO)],
		@[@"devoice",					@"DEVOICE",				@(5021),		@(NO)],
		@[@"defaults",					@"DEFAULTS",			@(5092),		@(YES)],
		@[@"echo",						@"ECHO",				@(5022),		@(NO)],
		@[@"fakerawdata",				@"FAKERAWDATA",			@(5087),		@(YES)],
		@[@"getscripts",				@"GETSCRIPTS",			@(5098),		@(NO)],
		@[@"gline",						@"GLINE",				@(5023),		@(NO)],
		@[@"globops",					@"GLOBOPS",				@(5024),		@(NO)],
		@[@"goto",						@"GOTO",				@(5099),		@(NO)],
		@[@"gzline",					@"GZLINE",				@(5025),		@(NO)],
		@[@"halfop",					@"HALFOP",				@(5026),		@(NO)],
		@[@"hop",						@"HOP",					@(5027),		@(NO)],
		@[@"icbadge",					@"ICBADGE",				@(5028),		@(YES)],
		@[@"ignore",					@"IGNORE",				@(5029),		@(NO)],
		@[@"invite",					@"INVITE",				@(5030),		@(NO)],
		@[@"j",							@"J",					@(5031),		@(NO)],
		@[@"join",						@"JOIN",				@(5032),		@(NO)],
		@[@"kb",						@"KB"	,				@(5083),		@(NO)],
		@[@"kick",						@"KICK",				@(5033),		@(NO)],
		@[@"kickban",					@"KICKBAN",				@(5034),		@(NO)],
		@[@"kill",						@"KILL",				@(5035),		@(NO)],
		@[@"lagcheck",					@"LAGCHECK",			@(5084),		@(NO)],
		@[@"leave",						@"LEAVE",				@(5036),		@(NO)],
		@[@"list",						@"LIST",				@(5037),		@(NO)],
		@[@"loaded_plugins",			@"LOADED_PLUGINS",		@(5091),		@(YES)],
		@[@"locops",					@"LOCOPS",				@(5039),		@(NO)],
		@[@"m",							@"M",					@(5040),		@(NO)],
		@[@"me",						@"ME",					@(5041),		@(NO)],
		@[@"mode",						@"MODE",				@(5042),		@(NO)],
		@[@"msg",						@"MSG",					@(5043),		@(NO)],
		@[@"mute",						@"MUTE",				@(5044),		@(NO)],
		@[@"mylag",						@"MYLAG",				@(5045),		@(NO)],
		@[@"myversion",					@"MYVERSION",			@(5046),		@(NO)],
		@[@"names",						@"NAMES",				@(5094),		@(NO)],
		@[@"nachat",					@"NACHAT",				@(5047),		@(NO)],
		@[@"nick",						@"NICK",				@(5048),		@(NO)],
		@[@"nncoloreset",				@"NNCOLORESET",			@(5049),		@(YES)],
		@[@"notice",					@"NOTICE",				@(5050),		@(NO)],
		@[@"omsg",						@"OMSG",				@(5051),		@(NO)],
		@[@"onotice",					@"ONOTICE",				@(5052),		@(NO)],
		@[@"op",						@"OP",					@(5053),		@(NO)],
		@[@"part",						@"PART",				@(5054),		@(NO)],
		@[@"pass",						@"PASS",				@(5055),		@(NO)],
		@[@"query",						@"QUERY",				@(5056),		@(NO)],
		@[@"quit",						@"QUIT",				@(5057),		@(NO)],
		@[@"quote",						@"QUOTE",				@(5058),		@(NO)],
		@[@"raw",						@"RAW",					@(5059),		@(NO)],
		@[@"rejoin",					@"REJOIN",				@(5060),		@(NO)],
		@[@"remove",					@"REMOVE",				@(5061),		@(NO)],
		@[@"server",					@"SERVER",				@(5062),		@(NO)],
		@[@"shun",						@"SHUN",				@(5063),		@(NO)],
		@[@"sme",						@"SME",					@(5064),		@(NO)],
		@[@"smsg",						@"SMSG",				@(5065),		@(NO)],
		@[@"sslcontext",				@"SSLCONTEXT",			@(5066),		@(NO)],
		@[@"t",							@"T",					@(5067),		@(NO)],
		@[@"tage",						@"TAGE",				@(5093),		@(YES)],
		@[@"tempshun",					@"TEMPSHUN",			@(5068),		@(NO)],
		@[@"timer",						@"TIMER",				@(5069),		@(NO)],
		@[@"topic",						@"TOPIC",				@(5070),		@(NO)],
		@[@"umode",						@"UMODE",				@(5071),		@(NO)],
		@[@"unban",						@"UNBAN",				@(5072),		@(NO)],
		@[@"unignore",					@"UNIGNORE",			@(5073),		@(NO)],
		@[@"unmute",					@"UNMUTE",				@(5075),		@(NO)],
        @[@"umsg",                      @"UMSG",				@(5088),		@(NO)],
        @[@"ume",                       @"UME",                 @(5089),		@(NO)],
        @[@"unotice",					@"UNOTICE",				@(5090),		@(NO)],
		@[@"voice",						@"VOICE",				@(5076),		@(NO)],
		@[@"watch",						@"WATCH",				@(5097),		@(NO)],
		@[@"wallops",					@"WALLOPS",				@(5077),		@(NO)],
		@[@"who",						@"WHO",					@(5079),		@(NO)],
		@[@"whois",						@"WHOIS",				@(5080),		@(NO)],
		@[@"whowas",					@"WHOWAS",				@(5081),		@(NO)],
		@[@"zline",						@"ZLINE",				@(5082),		@(NO)],
	];
}

+ (NSArray *)IRCCommandIndex:(BOOL)isPublic
{
	if (isPublic == NO) {
		return IRCInternalUseCommandIndexMap;
	} else {
		return IRCUserAccessibleCommandIndexMap;
	}
}

#pragma mark -

+ (NSArray *)publicIRCCommandList
{
	NSMutableArray *index = [NSMutableArray array];

	BOOL inDevMode = [RZUserDefaults() boolForKey:TXDeveloperEnvironmentToken];

	for (NSArray *indexInfo in IRCUserAccessibleCommandIndexMap) {
		BOOL developerOnly = [indexInfo boolAtIndex:3];

		if (inDevMode == NO && developerOnly) {
			continue;
		}

		[index addObject:indexInfo[1]];
 	}

	return index;
}

#pragma mark -

+ (NSString *)IRCCommandFromIndexKey:(NSString *)key publicSearch:(BOOL)isPublic
{
	NSArray *searchPath = [TPCPreferences IRCCommandIndex:isPublic];

	for (NSArray *indexInfo in searchPath) {
		NSString *matchKey = indexInfo[0];

		if ([matchKey isEqualIgnoringCase:key]) {
			return indexInfo[1];
		}
 	}

	return nil;
}

#pragma mark -

NSString *IRCPrivateCommandIndex(const char *key)
{
	return [TPCPreferences IRCCommandFromIndexKey:[NSString stringWithUTF8String:key] publicSearch:NO];
}

NSString *IRCPublicCommandIndex(const char *key)
{
	return [TPCPreferences IRCCommandFromIndexKey:[NSString stringWithUTF8String:key] publicSearch:YES];
}

#pragma mark -

+ (NSInteger)indexOfIRCommand:(NSString *)command
{
	return [TPCPreferences indexOfIRCommand:command publicSearch:YES];
}

+ (NSInteger)indexOfIRCommand:(NSString *)command publicSearch:(BOOL)isPublic
{
	NSArray *searchPath = [TPCPreferences IRCCommandIndex:isPublic];

	BOOL inDevMode = [RZUserDefaults() boolForKey:TXDeveloperEnvironmentToken];

	for (NSArray *indexInfo in searchPath) {
		NSString *matValue = indexInfo[1];

		if ([matValue isEqualIgnoringCase:command]) {
			BOOL isNotSpecial = [indexInfo boolAtIndex:3];

			if ((isPublic == NO && isNotSpecial == NO) || (isPublic && inDevMode == NO && isNotSpecial)) {
				continue;
			}

			return [indexInfo integerAtIndex:2];
		}
 	}

	return -1;
}

#pragma mark -
#pragma mark System Information

+ (BOOL)featureAvailableToOSXLion
{
	return (floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_6);
}

+ (BOOL)featureAvailableToOSXMountainLion
{
	return (floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_7);
}

+ (BOOL)featureAvailableToOSXMavericks
{
	return (floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_8);
}

#pragma mark -
#pragma mark Application Information

+ (NSString *)applicationName
{
	NSString *name = [RZMainBundle() infoDictionary][@"CFBundleName"];

#ifdef TEXTUAL_TRIAL_BINARY
	if ([name hasSuffix:@" Trial"]) {
		NSInteger trialPos = [name stringPosition:@" Trial"];

		name = [name safeSubstringToIndex:trialPos];
	}
#endif

	return name;
}

+ (NSInteger)applicationProcessID
{
	return [RZProcessInfo() processIdentifier];
}

+ (NSString *)applicationBundleIdentifier
{
	return [RZMainBundle() bundleIdentifier];
}

+ (BOOL)runningInHighResolutionMode
{
	return self.masterController.applicationIsRunningInHighResMode;
}

+ (NSDictionary *)textualInfoPlist
{
	return [RZMainBundle() infoDictionary];
}

+ (NSString *)gitBuildReference
{
	return TXBundleBuildReference;
}

+ (NSString *)gitCommitCount
{
	return TXBundleCommitCount;
}

#pragma mark -
#pragma mark Path Index

+ (NSString *)applicationTemporaryFolderPath
{
	return NSTemporaryDirectory();
}

+ (NSString *)applicationCachesFolderPath
{
	NSArray *searchArray = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);

	NSString *basePath = [searchArray safeObjectAtIndex:0];

	NSObjectIsEmptyAssertReturn(basePath, nil);

	NSString *endPath = [NSString stringWithFormat:@"/%@/", [TPCPreferences applicationBundleIdentifier]];

	return [basePath stringByAppendingString:endPath];
}

+ (NSString *)applicationSupportFolderPath
{
	NSArray *searchArray = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);

	NSString *dest = [searchArray[0] stringByAppendingPathComponent:@"/Textual IRC/"];

	if ([RZFileManager() fileExistsAtPath:dest] == NO) {
		[RZFileManager() createDirectoryAtPath:dest withIntermediateDirectories:YES attributes:nil error:NULL];
	}

	return dest;
}

+ (NSString *)customThemeFolderPath
{
	NSString *dest = [[TPCPreferences applicationSupportFolderPath] stringByAppendingPathComponent:@"/Styles/"];

	if ([RZFileManager() fileExistsAtPath:dest] == NO) {
		[RZFileManager() createDirectoryAtPath:dest withIntermediateDirectories:YES attributes:nil error:NULL];
	}

	return dest;
}

+ (NSString *)customExtensionFolderPath
{
	NSString *dest = [[TPCPreferences applicationSupportFolderPath] stringByAppendingPathComponent:@"/Extensions/"];

	if ([RZFileManager() fileExistsAtPath:dest] == NO) {
		[RZFileManager() createDirectoryAtPath:dest withIntermediateDirectories:YES attributes:nil error:NULL];
	}

	return dest;
}

#ifdef TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT
+ (NSString *)applicationUbiquitousContainerPath
{
	return [self.masterController.cloudSyncManager ubiquitousContainerURLPath];
}

+ (NSString *)cloudCustomThemeFolderPath
{
	NSString *source = [TPCPreferences applicationUbiquitousContainerPath];
	
	NSObjectIsEmptyAssertReturn(source, NSStringEmptyPlaceholder); // We need a source folder first…
	
	NSString *dest = [source stringByAppendingPathComponent:@"/Styles/"];
	
	if ([RZFileManager() fileExistsAtPath:dest] == NO) {
		[RZFileManager() createDirectoryAtPath:dest withIntermediateDirectories:YES attributes:nil error:NULL];
	}
	
	return dest;
}

+ (NSString *)cloudCustomThemeCachedFolderPath
{
	NSString *dest = [[TPCPreferences applicationCachesFolderPath] stringByAppendingPathComponent:@"/iCloud Caches/Styles/"];

	if ([RZFileManager() fileExistsAtPath:dest] == NO) {
		[RZFileManager() createDirectoryAtPath:dest withIntermediateDirectories:YES attributes:nil error:NULL];
	}
	
	return dest;
}
#endif

+ (NSString *)bundledScriptFolderPath
{
	return [[TPCPreferences applicationResourcesFolderPath] stringByAppendingPathComponent:@"/Scripts/"];
}

+ (NSString *)bundledThemeFolderPath
{
	return [[TPCPreferences applicationResourcesFolderPath] stringByAppendingPathComponent:@"/Styles/"];
}

+ (NSString *)bundledExtensionFolderPath
{
	return [[TPCPreferences applicationResourcesFolderPath] stringByAppendingPathComponent:@"/Extensions/"];
}

+ (NSString *)applicationResourcesFolderPath
{
	return [RZMainBundle() resourcePath];
}

+ (NSString *)applicationBundlePath
{
	return [RZMainBundle() bundlePath];
}

+ (NSString *)systemUnsupervisedScriptFolderRootPath
{
	if ([self featureAvailableToOSXMountainLion]) {
		NSString *oldpath = [TPCPreferences systemUnsupervisedScriptFolderPath]; // Returns our path.
		
		return [oldpath stringByDeletingLastPathComponent]; // Remove bundle ID from path.
	}
	
	return NSStringEmptyPlaceholder;
}

+ (NSString *)systemUnsupervisedScriptFolderPath
{
	if ([TPCPreferences featureAvailableToOSXMountainLion]) {
		static NSString *path = NSStringEmptyPlaceholder;
		
		static dispatch_once_t onceToken;
		
		dispatch_once(&onceToken, ^{
			@autoreleasepool {
				NSArray *searchArray = NSSearchPathForDirectoriesInDomains(NSApplicationScriptsDirectory, NSUserDomainMask, YES);
				
				if ([searchArray count]) {
					path = [searchArray[0] copy];
				}
			}
		});
		
		return path;
	}

	/* We return an empty string instead of nil because
	 the result of this method may be inserted into an
	 array and a nil value would throw an exception. */
	return NSStringEmptyPlaceholder;
}

+ (NSString *)userDownloadFolderPath
{
	NSArray *searchArray = NSSearchPathForDirectoriesInDomains(NSDownloadsDirectory, NSUserDomainMask, YES);
	
	return searchArray[0];
}

+ (NSString *)userHomeDirectoryPathOutsideSandbox
{
	struct passwd *pw = getpwuid(getuid());
	
	return [NSString stringWithUTF8String:pw->pw_dir];
}

#pragma mark -
#pragma mark Logging

static NSURL *transcriptFolderResolvedBookmark;

+ (void)startUsingTranscriptFolderSecurityScopedBookmark
{
	// URLByResolvingBookmarkData throws some weird shit during shutdown.
	// We're just going to loose whatever long we were wanting to save.
	// Probably the disconnect message. Oh well.
	NSAssertReturn(self.masterController.terminating == NO);
	
	NSData *bookmark = [RZUserDefaults() dataForKey:@"LogTranscriptDestinationSecurityBookmark"];

	NSObjectIsEmptyAssert(bookmark);

	NSError *resolveError;

	BOOL isStale = YES;

	NSURL *resolvedBookmark = [NSURL URLByResolvingBookmarkData:bookmark
														options:NSURLBookmarkResolutionWithSecurityScope
												  relativeToURL:nil
											bookmarkDataIsStale:&isStale
														  error:&resolveError];

	if (resolveError) {
		DebugLogToConsole(@"Error creating bookmark for URL: %@", [resolveError localizedDescription]);
	} else {
		transcriptFolderResolvedBookmark = resolvedBookmark;

		if ([transcriptFolderResolvedBookmark startAccessingSecurityScopedResource] == NO) {
			DebugLogToConsole(@"Failed to access bookmark.");
		}
	}
}

#pragma mark -

+ (NSURL *)transcriptFolder
{
	return transcriptFolderResolvedBookmark;
}

+ (void)setTranscriptFolder:(id)value
{
	/* Destroy old pointer if needed. */
	if (PointerIsNotEmpty(transcriptFolderResolvedBookmark)) {
		[transcriptFolderResolvedBookmark stopAccessingSecurityScopedResource];
		 transcriptFolderResolvedBookmark = nil;
	}

	/* Set new location. */
	[RZUserDefaults() setObject:value forKey:@"LogTranscriptDestinationSecurityBookmark"];

	/* Reset our folder. */
	[TPCPreferences startUsingTranscriptFolderSecurityScopedBookmark];
}

#pragma mark -
#pragma mark Sandbox Check

+ (BOOL)sandboxEnabled
{
	NSString *suffix = [NSString stringWithFormat:@"Containers/%@/Data", [TPCPreferences applicationBundleIdentifier]];

	return [NSHomeDirectory() hasSuffix:suffix];
}

#pragma mark -
#pragma mark Export/Import Information

+ (BOOL)performValidationForKeyValues:(BOOL)duringInitialization
{
	/* Validate font. */
	BOOL keyChanged = NO;
	
	if ([NSFont fontIsAvailable:[TPCPreferences themeChannelViewFontName]] == NO) {
		[RZUserDefaults() setObject:TXDefaultTextualLogFont forKey:TPCPreferencesThemeFontNameDefaultsKey];
		
		keyChanged = YES;
	}
	
	/* Validate theme. */
	NSString *activeTheme = [TPCPreferences themeName];
	
	if (duringInitialization == NO) { // self.themeController is not available during initialization.
		if ([self.themeController actualPathForCurrentThemeIsEqualToCachedPath]) {
			return keyChanged;
		} else {
			/* If the path is invalid, but the theme still exists, then its possible
			 it moved from the cloud to the local application support path. */
			if ([TPCThemeController themeExists:activeTheme]) {
				/* If it shows up as still existing, then we just mark it as keyChanged
				 so the controller knows to reload it, but we don't have to do any other
				 checks at this point since we know it just moved somewhere else. */
				
				keyChanged = YES;
				
				return keyChanged;
			}
		}
	}
	
	/* Continue with normal checks. */
	if ([TPCThemeController themeExists:activeTheme] == NO) {
		NSString *filekind = [TPCThemeController extractThemeSource:activeTheme];
		NSString *filename = [TPCThemeController extractThemeName:activeTheme];
		
		if ([filekind isEqualToString:TPCThemeControllerBundledStyleNameBasicPrefix]) {
			[TPCPreferences setThemeName:TXDefaultTextualLogStyle];
		} else {
			activeTheme = [TPCThemeController buildResourceFilename:filename];
			
			if ([TPCThemeController themeExists:activeTheme]) {
				[TPCPreferences setThemeName:activeTheme];
			} else {
				[TPCPreferences setThemeName:TXDefaultTextualLogStyle];
			}
		}
		
		keyChanged = YES;
	}
	
	return keyChanged;
}

/* This method expects a list of key names which were changed during an 
 import or cloud sync. The method will enumrate over all the keys reloading
 specific parts of the application based on what is supplied. It an expects
 an array so that it knows only to perform each action once. */
+ (void)performReloadActionForKeyValues:(NSArray *)prefKeys
{
	NSObjectIsEmptyAssert(prefKeys);

	/* Begin the process… */
	/* Some of these keys may be repeated because they are shared amongst different elements… */

	/* Style specific reloads… */
	if ([prefKeys containsObject:TPCPreferencesThemeNameDefaultsKey] ||					/* Style name. */
		[prefKeys containsObject:TPCPreferencesThemeFontNameDefaultsKey] ||				/* Style font name. */
		[prefKeys containsObject:@"Theme -> Font Size"] ||								/* Style font size. */
		[prefKeys containsObject:@"Theme -> Nickname Format"] ||						/* Nickname format. */
		[prefKeys containsObject:@"Theme -> Timestamp Format"] ||						/* Timestamp format. */
		[prefKeys containsObject:@"Theme -> Channel Font Preference Enabled"] ||		/* Indicates whether a style overrides a specific preference. */
		[prefKeys containsObject:@"Theme -> Nickname Format Preference Enabled"] ||		/* Indicates whether a style overrides a specific preference. */
		[prefKeys containsObject:@"Theme -> Timestamp Format Preference Enabled"] ||	/* Indicates whether a style overrides a specific preference. */
		[prefKeys containsObject:@"RightToLeftTextFormatting"] ||						/* Text direction. */
		[prefKeys containsObject:@"DisableRemoteNicknameColorHashing"] ||				/* Do not colorize nicknames. */
		[prefKeys containsObject:@"DisplayEventInLogView -> Inline Media"])				/* Display inline media. */
	{
		[TPCPreferences performReloadActionForActionType:TPCPreferencesKeyReloadStyleAction];
	}

	/* Highlight lists. */
	if ([prefKeys containsObject:@"Highlight List -> Primary Matches"] ||		/* Primary keyword list. */
		[prefKeys containsObject:@"Highlight List -> Excluded Matches"])		/* Excluded keyword list. */
	{
		[TPCPreferences performReloadActionForActionType:TPCPreferencesKeyReloadHighlightKeywordsAction];
	}

	/* Highlight logging. */
	if ([prefKeys containsObject:@"LogHighlights"]) {
		[TPCPreferences performReloadActionForActionType:TPCPreferencesKeyReloadHighlightLoggingAction];
	}

	/* Text direction: right-to-left, left-to-right */
	if ([prefKeys containsObject:@"RightToLeftTextFormatting"]) {
		[TPCPreferences performReloadActionForActionType:TPCPreferencesKeyReloadTextDirectionAction];
	}

	/* Text field font size. */
	if ([prefKeys containsObject:@"Main Input Text Field -> Font Size"]) {
		[TPCPreferences performReloadActionForActionType:TPCPreferencesKeyReloadTextFieldFontSizeAction];
	}

	/* Input history scope. */
	if ([prefKeys containsObject:@"SaveInputHistoryPerSelection"]) {
		[TPCPreferences performReloadActionForActionType:TPCPreferencesKeyReloadInputHistoryScopeAction];
	}

	/* Main window segmented controller. */
	if ([prefKeys containsObject:@"DisableMainWindowSegmentedController"]) {
		[TPCPreferences performReloadActionForActionType:TPCPreferencesKeyReloadTextFieldSegmentedControllerOriginAction];
	}

	/* Main window alpha level. */
	if ([prefKeys containsObject:@"MainWindowTransparencyLevel"]) {
		[TPCPreferences performReloadActionForActionType:TPCPreferencesKeyReloadMainWindowTransparencyLevelAction];
	}

	/* Dock icon. */
	if ([prefKeys containsObject:@"DisplayDockBadges"] ||						/* Display dock badges. */
		[prefKeys containsObject:@"DisplayPublicMessageCountInDockBadge"])		/* Count public messages in dock badges. */
	{
		[TPCPreferences performReloadActionForActionType:TPCPreferencesKeyReloadDockIconBadgesAction];
	}

	/* There are actually multiple keys that could invoke a member list redraw,
	 so instead of redrawing it two or three times… we will just maintain a BOOL
	 which tells us whether to do a draw at the end. */
	BOOL memberListRequiresRedraw = NO;

	/* Server list. */
	if ([prefKeys containsObject:@"InvertSidebarColors"] ||									/* Dark or light mode UI. */
		[prefKeys containsObject:@"UseLargeFontForSidebars"] ||								/* Use large font size for list. */
		[prefKeys containsObject:@"Theme -> Invert Sidebar Colors Preference Enabled"])		/* Indicates whether a style overrides a specific preference. */
	{
		[TPCPreferences performReloadActionForActionType:TPCPreferencesKeyReloadServerListAction]; // Redraw server list.

		memberListRequiresRedraw = YES; // Prepare member list for redraw.
	}

	if ([prefKeys containsObject:@"User List Mode Badge Colors —> +y"] ||	/* User mode badge color. */
		[prefKeys containsObject:@"User List Mode Badge Colors —> +q"] ||	/* User mode badge color. */
		[prefKeys containsObject:@"User List Mode Badge Colors —> +a"] ||	/* User mode badge color. */
		[prefKeys containsObject:@"User List Mode Badge Colors —> +o"] ||	/* User mode badge color. */
		[prefKeys containsObject:@"User List Mode Badge Colors —> +h"] ||	/* User mode badge color. */
		[prefKeys containsObject:@"User List Mode Badge Colors —> +v"])		/* User mode badge color. */
	{
		/* Prepare member list for redraw. */
		memberListRequiresRedraw = YES;

		/* Invalidate the cached colors. */
		[TPCPreferences performReloadActionForActionType:TPCPreferencesKeyReloadMemberListUserBadgesAction];
	}

	if ([prefKeys containsObject:@"MemberListSortFavorsServerStaff"]) { // Place server staff at top of list…
		[TPCPreferences performReloadActionForActionType:TPCPreferencesKeyReloadMemberListSortOrderAction];

		memberListRequiresRedraw = NO; // Sort changes will reload it for us…
	}

	/* Member list redraw time. */
	if (memberListRequiresRedraw) {
		[TPCPreferences performReloadActionForActionType:TPCPreferencesKeyReloadMemberListAction];
	}

	/* After this is all complete; we call preferencesChanged just to take care
	 of everything else that does not need specific reloads. */
	[TPCPreferences performReloadActionForActionType:TPCPreferencesKeyReloadPreferencesChangedAction];
}

+ (void)performReloadActionForActionType:(TPCPreferencesKeyReloadAction)reloadAction
{
	/* Reload style. */
	if (reloadAction == TPCPreferencesKeyReloadStyleAction ||
		reloadAction == TPCPreferencesKeyReloadStyleWithTableViewsAction ||
		reloadAction == TPCPreferencesKeyReloadTextDirectionAction)
	{
		[self.worldController reloadTheme:NO];
	}

	/* Highlight lists. */
	if (reloadAction == TPCPreferencesKeyReloadHighlightKeywordsAction) {
		[TPCPreferences cleanUpHighlightKeywords];
	}

	/* Highlight logging. */
	if (reloadAction == TPCPreferencesKeyReloadHighlightLoggingAction) {
		IRCWorld *world = self.masterController.world;

		if ([TPCPreferences logHighlights] == NO) {
			for (IRCClient *u in world.clients) {
				[u.highlights removeAllObjects];
			}
		}
	}

	/* Text direction: right-to-left, left-to-right */
	if (reloadAction == TPCPreferencesKeyReloadTextDirectionAction) {
		[self.masterController.inputTextField updateTextDirection];
	}

	/* Text field font size. */
	if (reloadAction == TPCPreferencesKeyReloadTextFieldFontSizeAction) {
		[self.masterController.inputTextField updateTextBoxBasedOnPreferredFontSize];
	}

	/* Input history scope. */
	if (reloadAction == TPCPreferencesKeyReloadInputHistoryScopeAction) {
		TXMasterController *master = self.masterController;

		if (master.inputHistory) {
			master.inputHistory = nil;
		}

		for (IRCClient *c in self.worldController.clients) {
			if (c.inputHistory) {
				c.inputHistory = nil;
			}

			if ([TPCPreferences inputHistoryIsChannelSpecific]) {
				c.inputHistory = [TLOInputHistory new];
			}

			for (IRCChannel *u in c.channels) {
				if (u.inputHistory) {
					u.inputHistory = nil;
				}

				if ([TPCPreferences inputHistoryIsChannelSpecific]) {
					u.inputHistory = [TLOInputHistory new];
				}
			}
		}

		if ([TPCPreferences inputHistoryIsChannelSpecific] == NO) {
			master.inputHistory = [TLOInputHistory new];
		}
	}

	/* Main window segmented controller. */
	if (reloadAction == TPCPreferencesKeyReloadTextFieldSegmentedControllerOriginAction) {
		[self.masterController reloadSegmentedControllerOrigin];
	}

	/* Main window alpha level. */
	if (reloadAction == TPCPreferencesKeyReloadMainWindowTransparencyLevelAction) {
		[self.masterController.mainWindow setAlphaValue:[TPCPreferences themeTransparency]];
	}

	/* Dock icon. */
	if (reloadAction == TPCPreferencesKeyReloadDockIconBadgesAction) {
		[self.worldController updateIcon];
	}

	/* Server list. */
	if (reloadAction == TPCPreferencesKeyReloadServerListAction ||
		reloadAction == TPCPreferencesKeyReloadStyleWithTableViewsAction)
	{
		[self.masterController.serverList updateBackgroundColor];
		[self.masterController.serverList reloadAllDrawingsIgnoringOtherReloads];

		[self.masterController.serverSplitView setNeedsDisplay:YES];
	}

	/* Member list user mode badges. */
	if (reloadAction == TPCPreferencesKeyReloadMemberListUserBadgesAction) {
		[self.masterController.memberList.badgeRenderer invalidateBadgeImageCacheAndRebuild];
	}

	/* Member list sort order. */
	if (reloadAction == TPCPreferencesKeyReloadMemberListSortOrderAction) {
		/* This reload will handle the redraw for us… */
		IRCChannel *channel = self.worldController.selectedChannel;

		if (channel && channel.isChannel) {
			[channel reloadDataForTableViewBySortingMembers];
		}
	}

	/* Member list redraw. */
	if (reloadAction == TPCPreferencesKeyReloadMemberListAction ||
		reloadAction == TPCPreferencesKeyReloadStyleWithTableViewsAction)
	{
		[self.masterController.memberList reloadAllUserInterfaceElements];

		[self.masterController.memberSplitView setNeedsDisplay:YES];
	}

	/* World controller preferences changed. */
	if (reloadAction == TPCPreferencesKeyReloadPreferencesChangedAction) {
		[self.worldController preferencesChanged];
	}
}

#pragma mark -
#pragma mark Default Identity

+ (NSString *)defaultNickname
{
	return [RZUserDefaults() objectForKey:@"DefaultIdentity -> Nickname"];
}

+ (NSString *)defaultAwayNickname
{
	return [RZUserDefaults() objectForKey:@"DefaultIdentity -> AwayNickname"];
}

+ (NSString *)defaultUsername
{
	return [RZUserDefaults() objectForKey:@"DefaultIdentity -> Username"];
}

+ (NSString *)defaultRealname
{
	return [RZUserDefaults() objectForKey:@"DefaultIdentity -> Realname"];
}

#pragma mark -
#pragma mark General Preferences

/* There is no specific order to these. */

+ (NSInteger)autojoinMaxChannelJoins
{
	return [RZUserDefaults() integerForKey:@"AutojoinMaximumChannelJoinCount"];
}

+ (NSString *)defaultKickMessage
{
	return [RZUserDefaults() objectForKey:@"ChannelOperatorDefaultLocalization -> Kick Reason"];
}

+ (NSString *)IRCopDefaultKillMessage
{
	return [RZUserDefaults() objectForKey:@"IRCopDefaultLocalizaiton -> Kill Reason"];
}

+ (NSString *)IRCopDefaultGlineMessage
{
	return [RZUserDefaults() objectForKey:@"IRCopDefaultLocalizaiton -> G:Line Reason"];
}

+ (NSString *)IRCopDefaultShunMessage
{
	return [RZUserDefaults() objectForKey:@"IRCopDefaultLocalizaiton -> Shun Reason"];
}

+ (NSString *)masqueradeCTCPVersion
{
	return [RZUserDefaults() objectForKey:@"ApplicationCTCPVersionMasquerade"];
}

+ (BOOL)channelNavigationIsServerSpecific
{
	return [RZUserDefaults() boolForKey:@"ChannelNavigationIsServerSpecific"];
}

+ (BOOL)setAwayOnScreenSleep
{
	return [RZUserDefaults() boolForKey:@"SetAwayOnScreenSleep"];
}

+ (BOOL)invertSidebarColors
{
	if ([self.themeController.customSettings forceInvertSidebarColors]) {
		return YES;
	}

	return [RZUserDefaults() boolForKey:@"InvertSidebarColors"];
}

+ (BOOL)hideMainWindowSegmentedController
{
	return [RZUserDefaults() boolForKey:@"DisableMainWindowSegmentedController"];
}

+ (BOOL)autojoinWaitsForNickServ
{
	return [RZUserDefaults() boolForKey:@"AutojoinWaitsForNickservIdentification"];
}

+ (BOOL)logHighlights
{
	return [RZUserDefaults() boolForKey:@"LogHighlights"];
}

+ (BOOL)clearAllOnlyOnActiveServer
{
	return [RZUserDefaults() boolForKey:@"ApplyCommandToAllConnections -> clearall"];
}

+ (BOOL)displayServerMOTD
{
	return [RZUserDefaults() boolForKey:@"DisplayServerMessageOfTheDayOnConnect"];
}

#ifdef TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT
+ (BOOL)syncPreferencesToTheCloud
{
	NSAssertReturnR([TPCPreferences featureAvailableToOSXMountainLion], NO);
	
	return [RZUserDefaults() boolForKey:TPCPreferencesCloudSyncKeyValueStoreServicesDefaultsKey];
}

+ (BOOL)syncPreferencesToTheCloudLimitedToServers
{
	NSAssertReturnR([TPCPreferences featureAvailableToOSXMountainLion], NO);
	
	return [RZUserDefaults() boolForKey:TPCPreferencesCloudSyncKeyValueStoreServicesLimitedToServersDefaultsKey];
}
#endif

+ (BOOL)copyOnSelect
{
	return [RZUserDefaults() boolForKey:@"CopyTextSelectionOnMouseUp"];
}

+ (BOOL)replyToCTCPRequests
{
	return [RZUserDefaults() boolForKey:@"ReplyUnignoredExternalCTCPRequests"];
}

+ (BOOL)autoAddScrollbackMark
{
	return [RZUserDefaults() boolForKey:@"AutomaticallyAddScrollbackMarker"];
}

+ (BOOL)removeAllFormatting
{
	return [RZUserDefaults() boolForKey:@"RemoveIRCTextFormatting"];
}

+ (BOOL)automaticallyDetectHighlightSpam
{
	return [RZUserDefaults() boolForKey:@"AutomaticallyDetectHighlightSpam"];
}

+ (BOOL)disableNicknameColorHashing
{
	return [RZUserDefaults() boolForKey:@"DisableRemoteNicknameColorHashing"];
}

+ (BOOL)useLargeFontForSidebars
{
	return [RZUserDefaults() boolForKey:@"UseLargeFontForSidebars"];
}

+ (BOOL)conversationTrackingIncludesUserModeSymbol
{
	return [RZUserDefaults() boolForKey:@"ConversationTrackingIncludesUserModeSymbol"];
}

+ (BOOL)rightToLeftFormatting
{
	return [RZUserDefaults() boolForKey:@"RightToLeftTextFormatting"];
}

+ (NSString *)tabCompletionSuffix
{
	return [RZUserDefaults() objectForKey:@"Keyboard -> Tab Key Completion Suffix"];
}

+ (BOOL)displayDockBadge
{
	return [RZUserDefaults() boolForKey:@"DisplayDockBadges"];
}

+ (BOOL)amsgAllConnections
{
	return [RZUserDefaults() boolForKey:@"ApplyCommandToAllConnections -> amsg"];
}

+ (BOOL)awayAllConnections
{
	return [RZUserDefaults() boolForKey:@"ApplyCommandToAllConnections -> away"];
}

+ (BOOL)giveFocusOnMessageCommand
{
	return [RZUserDefaults() boolForKey:@"FocusSelectionOnMessageCommandExecution"];
}

+ (BOOL)memberListSortFavorsServerStaff
{
	return [RZUserDefaults() boolForKey:@"MemberListSortFavorsServerStaff"];
}

+ (BOOL)postNotificationsWhileInFocus
{
	return [RZUserDefaults() boolForKey:@"PostNotificationsWhileInFocus"];
}

+ (BOOL)automaticallyFilterUnicodeTextSpam
{
	return [RZUserDefaults() boolForKey:@"AutomaticallyFilterUnicodeTextSpam"];
}

+ (BOOL)nickAllConnections
{
	return [RZUserDefaults() boolForKey:@"ApplyCommandToAllConnections -> nick"];
}

+ (BOOL)confirmQuit
{
	return [RZUserDefaults() boolForKey:@"ConfirmApplicationQuit"];
}

+ (BOOL)rememberServerListQueryStates
{
	return [RZUserDefaults() boolForKey:@"ServerListRetainsQueriesBetweenRestarts"];
}

+ (BOOL)rejoinOnKick
{
	return [RZUserDefaults() boolForKey:@"RejoinChannelOnLocalKick"];
}

+ (BOOL)reloadScrollbackOnLaunch
{
	return [RZUserDefaults() boolForKey:@"ReloadScrollbackOnLaunch"];
}

+ (BOOL)autoJoinOnInvite
{
	return [RZUserDefaults() boolForKey:@"AutojoinChannelOnInvite"];
}

+ (BOOL)connectOnDoubleclick
{
	return [RZUserDefaults() boolForKey:@"ServerListDoubleClickConnectServer"];
}

+ (BOOL)disconnectOnDoubleclick
{
	return [RZUserDefaults() boolForKey:@"ServerListDoubleClickDisconnectServer"];
}

+ (BOOL)joinOnDoubleclick
{
	return [RZUserDefaults() boolForKey:@"ServerListDoubleClickJoinChannel"];
}

+ (BOOL)leaveOnDoubleclick
{
	return [RZUserDefaults() boolForKey:@"ServerListDoubleClickLeaveChannel"];
}

+ (BOOL)logTranscript
{
	return [RZUserDefaults() boolForKey:@"LogTranscript"];
}

+ (BOOL)openBrowserInBackground
{
	return [RZUserDefaults() boolForKey:@"OpenClickedLinksInBackgroundBrowser"];
}

+ (BOOL)showInlineImages
{
	return [RZUserDefaults() boolForKey:@"DisplayEventInLogView -> Inline Media"];
}

+ (BOOL)showJoinLeave
{
	return [RZUserDefaults() boolForKey:@"DisplayEventInLogView -> Join, Part, Quit"];
}

+ (BOOL)commandReturnSendsMessageAsAction
{
	return [RZUserDefaults() boolForKey:@"CommandReturnSendsMessageAsAction"];
}

+ (BOOL)controlEnterSnedsMessage;
{
	return [RZUserDefaults() boolForKey:@"ControlEnterSendsMessage"];
}

+ (BOOL)displayPublicMessageCountOnDockBadge
{
	return [RZUserDefaults() boolForKey:@"DisplayPublicMessageCountInDockBadge"];
}

+ (BOOL)highlightCurrentNickname
{
	return [RZUserDefaults() boolForKey:@"TrackNicknameHighlightsOfLocalUser"];
}

+ (CGFloat)swipeMinimumLength
{
	return [RZUserDefaults() doubleForKey:@"SwipeMinimumLength"];
}

+ (NSInteger)trackUserAwayStatusMaximumChannelSize
{
    return [RZUserDefaults() integerForKey:@"TrackUserAwayStatusMaximumChannelSize"];
}

+ (TXTabKeyAction)tabKeyAction
{
	return (TXTabKeyAction)[RZUserDefaults() integerForKey:@"Keyboard -> Tab Key Action"];
}

+ (TXNicknameHighlightMatchType)highlightMatchingMethod
{
	return (TXNicknameHighlightMatchType)[RZUserDefaults() integerForKey:@"NicknameHighlightMatchingType"];
}

+ (TXUserDoubleClickAction)userDoubleClickOption
{
	return (TXUserDoubleClickAction)[RZUserDefaults() integerForKey:@"UserListDoubleClickAction"];
}

+ (TXNoticeSendLocationType)locationToSendNotices
{
	return (TXNoticeSendLocationType)[RZUserDefaults() integerForKey:@"DestinationOfNonserverNotices"];
}

+ (TXCommandWKeyAction)commandWKeyAction
{
	return (TXCommandWKeyAction)[RZUserDefaults() integerForKey:@"Keyboard -> Command+W Action"];
}

+ (TXHostmaskBanFormat)banFormat
{
	return (TXHostmaskBanFormat)[RZUserDefaults() integerForKey:@"DefaultBanCommandHostmaskFormat"];
}

+ (TXMainTextBoxFontSize)mainTextBoxFontSize
{
	return (TXMainTextBoxFontSize)[RZUserDefaults() integerForKey:@"Main Input Text Field -> Font Size"];
}

#pragma mark -
#pragma mark Theme

+ (NSString *)themeName
{
	return [RZUserDefaults() objectForKey:TPCPreferencesThemeNameDefaultsKey];
}

+ (void)setThemeName:(NSString *)value
{
	[RZUserDefaults() setObject:value forKey:TPCPreferencesThemeNameDefaultsKey];
	
	[RZUserDefaults() removeObjectForKey:TPCPreferencesThemeNameMissingLocallyDefaultsKey];
}

+ (void)setThemeNameWithExistenceCheck:(NSString *)value
{
	/* Did it exist anywhere at all? */
	if ([TPCThemeController themeExists:value] == NO) {
		[RZUserDefaults() setBool:YES forKey:TPCPreferencesThemeNameMissingLocallyDefaultsKey];
	} else {
		[TPCPreferences setThemeName:value];
	}
}

+ (NSString *)themeChannelViewFontName
{
	return [RZUserDefaults() objectForKey:TPCPreferencesThemeFontNameDefaultsKey];
}

+ (void)setThemeChannelViewFontName:(NSString *)value
{
	[RZUserDefaults() setObject:value forKey:TPCPreferencesThemeFontNameDefaultsKey];
	
	[RZUserDefaults() removeObjectForKey:TPCPreferencesThemeFontNameMissingLocallyDefaultsKey];
}

+ (void)setThemeChannelViewFontNameWithExistenceCheck:(NSString *)value
{
	if ([NSFont fontIsAvailable:value] == NO) {
		[RZUserDefaults() setBool:YES forKey:TPCPreferencesThemeFontNameMissingLocallyDefaultsKey];
	} else {
		[TPCPreferences setThemeChannelViewFontName:value];
	}
}

+ (double)themeChannelViewFontSize
{
	return [RZUserDefaults() doubleForKey:@"Theme -> Font Size"];
}

+ (void)setThemeChannelViewFontSize:(double)value
{
	[RZUserDefaults() setDouble:value forKey:@"Theme -> Font Size"];
}

+ (NSFont *)themeChannelViewFont
{
	return [NSFont fontWithName:[TPCPreferences themeChannelViewFontName]
						   size:[TPCPreferences themeChannelViewFontSize]];
}

+ (NSString *)themeNicknameFormat
{
	return [RZUserDefaults() objectForKey:@"Theme -> Nickname Format"];
}

+ (BOOL)inputHistoryIsChannelSpecific
{
	return [RZUserDefaults() boolForKey:@"SaveInputHistoryPerSelection"];
}

+ (NSString *)themeTimestampFormat
{
	return [RZUserDefaults() objectForKey:@"Theme -> Timestamp Format"];
}

+ (double)themeTransparency
{
	return [RZUserDefaults() doubleForKey:@"MainWindowTransparencyLevel"];
}

#pragma mark -
#pragma mark Completion Suffix

+ (void)setTabCompletionSuffix:(NSString *)value
{
	[RZUserDefaults() setObject:value forKey:@"Keyboard -> Tab Key Completion Suffix"];
}

#pragma mark -
#pragma mark Inline Image Size

+ (TXFSLongInt)inlineImagesMaxFilesize
{
	NSInteger filesizeTag = [RZUserDefaults() integerForKey:@"inlineImageMaxFilesize"];

	switch (filesizeTag) {
		case 1: return			(TXFSLongInt)1048576;			// 1 MB
		case 2: return			(TXFSLongInt)2097152;			// 2 MB
		case 3: return			(TXFSLongInt)3145728;			// 3 MB
		case 4: return			(TXFSLongInt)4194304;			// 4 MB
		case 5: return			(TXFSLongInt)5242880;			// 5 MB
		case 6: return			(TXFSLongInt)10485760;			// 10 MB
		case 7: return			(TXFSLongInt)15728640;			// 15 MB
		case 8: return			(TXFSLongInt)20971520;			// 20 MB
		case 9: return			(TXFSLongInt)52428800;			// 50 MB
		case 10: return			(TXFSLongInt)104857600;			// 100 MB
		case 11: return			(TXFSLongInt)1073741824;		// 1 GB
		case 12: return			(TXFSLongInt)1099511627776;		// 1 TB
		default: return			(TXFSLongInt)5242880;			// 5 MB
	}
}

+ (NSInteger)inlineImagesMaxWidth
{
	return [RZUserDefaults() integerForKey:@"InlineMediaScalingWidth"];
}

+ (NSInteger)inlineImagesMaxHeight
{
	return [RZUserDefaults() integerForKey:@"InlineMediaMaximumHeight"];
}

+ (void)setInlineImagesMaxWidth:(NSInteger)value
{
	[RZUserDefaults() setInteger:value forKey:@"InlineMediaScalingWidth"];
}

+ (void)setInlineImagesMaxHeight:(NSInteger)value
{
	[RZUserDefaults() setInteger:value forKey:@"InlineMediaMaximumHeight"];
}

#pragma mark -
#pragma mark File Transfers

+ (TXFileTransferRequestReplyAction)fileTransferRequestReplyAction
{
	return [RZUserDefaults() integerForKey:@"File Transfers -> File Transfer Request Reply Action"];
}

+ (TXFileTransferIPAddressDetectionMethod)fileTransferIPAddressDetectionMethod
{
	return [RZUserDefaults() integerForKey:@"File Transfers -> File Transfer IP Address Detection Method"];
}

+ (NSInteger)fileTransferPortRangeStart
{
	return [RZUserDefaults() integerForKey:@"File Transfers -> File Transfer Port Range Start"];
}

+ (void)setFileTransferPortRangeStart:(NSInteger)value
{
	[RZUserDefaults() setInteger:value forKey:@"File Transfers -> File Transfer Port Range Start"];
}

+ (NSInteger)fileTransferPortRangeEnd
{
	return [RZUserDefaults() integerForKey:@"File Transfers -> File Transfer Port Range End"];
}

+ (void)setFileTransferPortRangeEnd:(NSInteger)value
{
	[RZUserDefaults() setInteger:value forKey:@"File Transfers -> File Transfer Port Range End"];
}

+ (NSString *)fileTransferManuallyEnteredIPAddress
{
	return [RZUserDefaults() objectForKey:@"File Transfers -> File Transfer Manually Entered IP Address"];
}

#pragma mark -
#pragma mark Max Log Lines

+ (NSInteger)maxLogLines
{
	return [RZUserDefaults() integerForKey:@"ScrollbackMaximumLineCount"];
}

+ (void)setMaxLogLines:(NSInteger)value
{
	[RZUserDefaults() setInteger:value forKey:@"ScrollbackMaximumLineCount"];
}

#pragma mark -
#pragma mark Growl

+ (NSString *)titleForEvent:(TXNotificationType)event
{
	switch (event) {
		case TXNotificationAddressBookMatchType:	{ return TXTLS(@"TXNotificationAddressBookMatchType");			}
		case TXNotificationChannelMessageType:		{ return TXTLS(@"TXNotificationChannelMessageType");			}
		case TXNotificationChannelNoticeType:		{ return TXTLS(@"TXNotificationChannelNoticeType");				}
		case TXNotificationConnectType:				{ return TXTLS(@"TXNotificationConnectType");					}
		case TXNotificationDisconnectType:			{ return TXTLS(@"TXNotificationDisconnectType");				}
		case TXNotificationInviteType:				{ return TXTLS(@"TXNotificationInviteType");					}
		case TXNotificationKickType:				{ return TXTLS(@"TXNotificationKickType");						}
		case TXNotificationNewPrivateMessageType:	{ return TXTLS(@"TXNotificationNewPrivateMessageType");			}
		case TXNotificationPrivateMessageType:		{ return TXTLS(@"TXNotificationPrivateMessageType");			}
		case TXNotificationPrivateNoticeType:		{ return TXTLS(@"TXNotificationPrivateNoticeType");				}
		case TXNotificationHighlightType:			{ return TXTLS(@"TXNotificationHighlightType");					}
			
		case TXNotificationFileTransferSendSuccessfulType:		{ return TXTLS(@"TXNotificationFileTransferSendSuccessfulType");		}
		case TXNotificationFileTransferReceiveSuccessfulType:	{ return TXTLS(@"TXNotificationFileTransferReceiveSuccessfulType");		}
		case TXNotificationFileTransferSendFailedType:			{ return TXTLS(@"TXNotificationFileTransferSendFailedType");			}
		case TXNotificationFileTransferReceiveFailedType:		{ return TXTLS(@"TXNotificationFileTransferReceiveFailedType");			}
		case TXNotificationFileTransferReceiveRequestedType:	{ return TXTLS(@"TXNotificationFileTransferReceiveRequestedType");		}

		default: { return nil; }
	}

	return nil;
}

+ (NSString *)keyForEvent:(TXNotificationType)event
{
	switch (event) {
		case TXNotificationAddressBookMatchType:	{ return @"NotificationType -> Address Book Match";				}
		case TXNotificationChannelMessageType:		{ return @"NotificationType -> Public Message";					}
		case TXNotificationChannelNoticeType:		{ return @"NotificationType -> Public Notice";					}
		case TXNotificationConnectType:				{ return @"NotificationType -> Connected";						}
		case TXNotificationDisconnectType:			{ return @"NotificationType -> Disconnected";					}
		case TXNotificationHighlightType:			{ return @"NotificationType -> Highlight";						}
		case TXNotificationInviteType:				{ return @"NotificationType -> Channel Invitation";				}
		case TXNotificationKickType:				{ return @"NotificationType -> Kicked from Channel";			}
		case TXNotificationNewPrivateMessageType:	{ return @"NotificationType -> Private Message (New)";			}
		case TXNotificationPrivateMessageType:		{ return @"NotificationType -> Private Message";				}
		case TXNotificationPrivateNoticeType:		{ return @"NotificationType -> Private Notice";					}
			
		case TXNotificationFileTransferSendSuccessfulType:		{ return @"NotificationType -> Successful File Transfer (Sending)";			}
		case TXNotificationFileTransferReceiveSuccessfulType:	{ return @"NotificationType -> Successful File Transfer (Receiving)";		}
		case TXNotificationFileTransferSendFailedType:			{ return @"NotificationType -> Failed File Transfer (Sending)";				}
		case TXNotificationFileTransferReceiveFailedType:		{ return @"NotificationType -> Failed File Transfer (Receiving)";			}
		case TXNotificationFileTransferReceiveRequestedType:	{ return @"NotificationType -> File Transfer Request";						}
			
		default: { return nil; }
	}

	return nil;
}

+ (NSString *)soundForEvent:(TXNotificationType)event
{
	NSString *okey = [TPCPreferences keyForEvent:event];

	NSObjectIsEmptyAssertReturn(okey, nil);

	NSString *key = [okey stringByAppendingString:@" -> Sound"];

	return [RZUserDefaults() objectForKey:key];
}

+ (void)setSound:(NSString *)value forEvent:(TXNotificationType)event
{
	NSString *okey = [TPCPreferences keyForEvent:event];

	NSObjectIsEmptyAssert(okey);

	NSString *key = [okey stringByAppendingString:@" -> Sound"];

	[RZUserDefaults() setObject:value forKey:key];
}

+ (BOOL)growlEnabledForEvent:(TXNotificationType)event
{
	NSString *okey = [TPCPreferences keyForEvent:event];

	NSObjectIsEmptyAssertReturn(okey, NO);

	NSString *key = [okey stringByAppendingString:@" -> Enabled"];

	return [RZUserDefaults() boolForKey:key];
}

+ (void)setGrowlEnabled:(BOOL)value forEvent:(TXNotificationType)event
{
	NSString *okey = [TPCPreferences keyForEvent:event];

	NSObjectIsEmptyAssert(okey);

	NSString *key = [okey stringByAppendingString:@" -> Enabled"];

	[RZUserDefaults() setBool:value forKey:key];
}

+ (BOOL)disabledWhileAwayForEvent:(TXNotificationType)event
{
	NSString *okey = [TPCPreferences keyForEvent:event];

	NSObjectIsEmptyAssertReturn(okey, NO);

	NSString *key = [okey stringByAppendingString:@" -> Disable While Away"];

	return [RZUserDefaults() boolForKey:key];
}

+ (void)setDisabledWhileAway:(BOOL)value forEvent:(TXNotificationType)event
{
	NSString *okey = [TPCPreferences keyForEvent:event];

	NSObjectIsEmptyAssert(okey);

	NSString *key = [okey stringByAppendingString:@" -> Disable While Away"];

	[RZUserDefaults() setBool:value forKey:key];
}

+ (BOOL)bounceDockIconForEvent:(TXNotificationType)event
{
    NSString *okey = [TPCPreferences keyForEvent:event];
    
    NSObjectIsEmptyAssertReturn(okey, NO);
    
    NSString *key = [okey stringByAppendingString:@" -> Bounce Dock Icon"];
    
    return [RZUserDefaults() boolForKey:key];
}

+ (void)setBounceDockIcon:(BOOL)value forEvent:(TXNotificationType)event
{
    NSString *okey = [TPCPreferences keyForEvent:event];
    
	NSObjectIsEmptyAssert(okey);
    
	NSString *key = [okey stringByAppendingString:@" -> Bounce Dock Icon"];
    
	[RZUserDefaults() setBool:value forKey:key];
}

+ (BOOL)speakEvent:(TXNotificationType)event
{
	NSString *okey = [TPCPreferences keyForEvent:event];

	NSObjectIsEmptyAssertReturn(okey, NO);

	NSString *key = [okey stringByAppendingString:@" -> Speak"];

	return [RZUserDefaults() boolForKey:key];
}

+ (void)setEventIsSpoken:(BOOL)value forEvent:(TXNotificationType)event
{
	NSString *okey = [TPCPreferences keyForEvent:event];

	NSObjectIsEmptyAssert(okey);

	NSString *key = [okey stringByAppendingString:@" -> Speak"];

	[RZUserDefaults() setBool:value forKey:key];
}

#pragma mark -
#pragma mark World

+ (NSDictionary *)loadWorld
{
	return [RZUserDefaults() objectForKey:IRCWorldControllerDefaultsStorageKey];
}

+ (void)saveWorld:(NSDictionary *)value
{
	[RZUserDefaults() setObject:value forKey:IRCWorldControllerDefaultsStorageKey];
}

#pragma mark -
#pragma mark Window

+ (NSDictionary *)loadWindowStateWithName:(NSString *)name
{
	return [RZUserDefaults() objectForKey:name];
}

+ (void)saveWindowState:(NSDictionary *)value name:(NSString *)name
{
	[RZUserDefaults() setObject:value forKey:name];
}

#pragma mark -
#pragma mark Keywords

static NSMutableArray *matchKeywords = nil;
static NSMutableArray *excludeKeywords = nil;

+ (void)loadMatchKeywords
{
	if (matchKeywords) {
		[matchKeywords removeAllObjects];
	} else {
		matchKeywords = [NSMutableArray new];
	}

	NSArray *ary = [RZUserDefaults() objectForKey:@"Highlight List -> Primary Matches"];

	for (NSDictionary *e in ary) {
		NSString *s = e[@"string"];

		NSObjectIsEmptyAssertLoopContinue(s);

		[matchKeywords safeAddObject:s];
	}
}

+ (void)loadExcludeKeywords
{
	if (excludeKeywords) {
		[excludeKeywords removeAllObjects];
	} else {
		excludeKeywords = [NSMutableArray new];
	}

	NSArray *ary = [RZUserDefaults() objectForKey:@"Highlight List -> Excluded Matches"];

	for (NSDictionary *e in ary) {
		NSString *s = e[@"string"];

		NSObjectIsEmptyAssertLoopContinue(s);

		[excludeKeywords safeAddObject:s];
	}
}

+ (void)cleanUpKeywords:(NSString *)key
{
	NSArray *src = [RZUserDefaults() objectForKey:key];

	NSMutableArray *ary = [NSMutableArray array];

	for (NSDictionary *e in src) {
		NSString *s = e[@"string"];

		NSObjectIsEmptyAssertLoopContinue(s);

		[ary safeAddObject:s];
	}

	[ary sortUsingSelector:@selector(caseInsensitiveCompare:)];

	NSMutableArray *saveAry = [NSMutableArray array];

	for (NSString *s in ary) {
		[saveAry safeAddObject:[@{@"string" : s} mutableCopy]];
	}

	[RZUserDefaults() setObject:saveAry forKey:key];
	[RZUserDefaults() synchronize];
}

+ (void)cleanUpHighlightKeywords
{
	[TPCPreferences cleanUpKeywords:@"Highlight List -> Primary Matches"];
	[TPCPreferences cleanUpKeywords:@"Highlight List -> Excluded Matches"];
}

+ (NSArray *)highlightMatchKeywords
{
	return matchKeywords;
}

+ (NSArray *)highlightExcludeKeywords
{
	return excludeKeywords;
}

#pragma mark -
#pragma mark Start/Run Time Monitoring

+ (NSTimeInterval)timeIntervalSinceApplicationLaunch
{
	NSRunningApplication *runningApp = [NSRunningApplication currentApplication];

	/* This can be nil when launched from something not launchd. i.e. Xcode */
	NSDate *launchDate = runningApp.launchDate;

	PointerIsEmptyAssertReturn(launchDate, 0);

	return [NSDate secondsSinceUnixTimestamp:launchDate.timeIntervalSince1970];
}

+ (NSTimeInterval)timeIntervalSinceApplicationInstall
{
	NSTimeInterval appStartTime = [TPCPreferences timeIntervalSinceApplicationLaunch];

	return ([RZUserDefaults() integerForKey:@"TXRunTime"] + appStartTime);
}

+ (void)saveTimeIntervalSinceApplicationInstall
{
	[RZUserDefaults() setInteger:[TPCPreferences timeIntervalSinceApplicationInstall] forKey:@"TXRunTime"];
}

+ (NSInteger)applicationRunCount
{
	return [RZUserDefaults() integerForKey:@"TXRunCount"];
}

+ (void)updateApplicationRunCount
{
	[RZUserDefaults() setInteger:([TPCPreferences applicationRunCount] + 1) forKey:@"TXRunCount"];
}

+ (NSSize)minimumWindowSize
{
	/* Fine, it is not an actual zero requirement for window size, but who would
	 possibly go below this size? You cannot even see the chat view or anything 
	 in that area at this size. It is being forced at this size to fix a bug 
	 with the input field breaking when it hits a negative draw rect. This can
	 just be considered a lazy man fix. */

	if ([RZUserDefaults() boolForKey:@"MinimumWindowSizeIsNotForced"]) {
		return NSMakeSize(200, 50);
	} else {
		return NSMakeSize(600, 250);
	}
}

+ (NSRect)defaultWindowFrame
{
	NSRect usable = [RZMainWindowScreen() visibleFrame];

	CGFloat w = 800;
	CGFloat h = 474;

	CGFloat x = (usable.origin.x + (usable.size.width / 2)) - (w / 2);
	CGFloat y = (usable.origin.y + (usable.size.height / 2)) - (h / 2);

	return NSMakeRect(x, y, w, h);
}

#pragma mark -
#pragma mark Key-Value Observing

+ (void)observeValueForKeyPath:(NSString *)key ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if ([key isEqualToString:@"Highlight List -> Primary Matches"]) {
		[TPCPreferences loadMatchKeywords];
	} else if ([key isEqualToString:@"Highlight List -> Excluded Matches"]) {
		[TPCPreferences loadExcludeKeywords];
	}
}

#pragma mark -
#pragma mark Initialization

+ (void)defaultIRCClientSheetCallback:(TLOPopupPromptReturnType)returnCode withOriginalAlert:(NSAlert *)originalAlert
{
	if (returnCode == TLOPopupPromptReturnPrimaryType) {
		NSString *bundleID = [TPCPreferences applicationBundleIdentifier];

		OSStatus changeResult;

		changeResult = LSSetDefaultHandlerForURLScheme((__bridge CFStringRef)@"irc",
													   (__bridge CFStringRef)(bundleID));

		changeResult = LSSetDefaultHandlerForURLScheme((__bridge CFStringRef)@"ircs",
													   (__bridge CFStringRef)(bundleID));

		changeResult = LSSetDefaultHandlerForURLScheme((__bridge CFStringRef)@"textual",
													   (__bridge CFStringRef)(bundleID));

#pragma unused(changeResult)
	}
}

+ (BOOL)isDefaultIRCClient
{
	NSURL *baseURL = [NSURL URLWithString:@"irc:"];

    CFURLRef appURL = NULL;
	
    OSStatus status = LSGetApplicationForURL((__bridge CFURLRef)baseURL, kLSRolesAll, NULL, &appURL);

	if (status == noErr) {
		NSBundle *baseBundle = [NSBundle bundleWithURL:CFBridgingRelease(appURL)];

		return [baseBundle.bundleIdentifier isEqualTo:[TPCPreferences applicationBundleIdentifier]];
	}

	return NO;
}

+ (void)defaultIRCClientPrompt:(BOOL)forced
{
	if ([TPCPreferences isDefaultIRCClient] == NO || forced) {
		TLOPopupPrompts *prompt = [TLOPopupPrompts new];

        NSString *supkey = @"default_irc_client";

        if (forced) {
            supkey = nil;
        }
        
		[prompt sheetWindowWithQuestion:[NSApp keyWindow]
								 target:self
								 action:@selector(defaultIRCClientSheetCallback:withOriginalAlert:)
								   body:TXTLS(@"SetAsDefaultIRCClientPromptMessage")
								  title:TXTLS(@"SetAsDefaultIRCClientPromptTitle")
						  defaultButton:TXTLS(@"YesButton")
						alternateButton:TXTLS(@"NoButton")
							otherButton:nil
						 suppressionKey:supkey
						suppressionText:nil];
	}
}

+ (NSDictionary *)defaultPreferences
{
	NSMutableDictionary *d = [NSMutableDictionary dictionary];
	
#ifdef TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT
	d[TPCPreferencesCloudSyncKeyValueStoreServicesDefaultsKey]					= @(NO);
	d[TPCPreferencesCloudSyncKeyValueStoreServicesLimitedToServersDefaultsKey]	= @(NO);
#endif
	
	d[@"AutomaticallyAddScrollbackMarker"]				= @(YES);
	d[@"AutomaticallyDetectHighlightSpam"]				= @(YES);
	d[@"ChannelNavigationIsServerSpecific"]				= @(YES);
	d[@"CommandReturnSendsMessageAsAction"]				= @(YES);
	d[@"ConversationTrackingIncludesUserModeSymbol"]	= @(YES);
	d[@"ConfirmApplicationQuit"]						= @(YES);
	d[@"DisplayDockBadges"]								= @(YES);
	d[@"DisplayEventInLogView -> Join, Part, Quit"]		= @(YES);
	d[@"DisplayServerMessageOfTheDayOnConnect"]			= @(YES);
	d[@"DisplayUserListNoModeSymbol"]					= @(YES);
	d[@"FocusSelectionOnMessageCommandExecution"]		= @(YES);
	d[@"LogHighlights"]									= @(YES);
	d[@"PostNotificationsWhileInFocus"]					= @(YES);
	d[@"ReloadScrollbackOnLaunch"]						= @(YES);
	d[@"ReplyUnignoredExternalCTCPRequests"]			= @(YES);
	d[@"TrackNicknameHighlightsOfLocalUser"]			= @(YES);
	d[@"WebKitDeveloperExtras"]							= @(YES);
	
	/* Settings for the NSTextView context menu. */
	d[@"TextFieldAutomaticSpellCheck"]					= @(YES);
	d[@"TextFieldAutomaticGrammarCheck"]				= @(YES);
	d[@"TextFieldAutomaticSpellCorrection"]				= @(NO);
	d[@"TextFieldSmartCopyPaste"]						= @(YES);
	d[@"TextFieldTextReplacement"]						= @(YES);
	
	/* This controls the two-finger swipe sensitivity. The lower it is, the more
	 sensitive the swipe left/right detection is. The higher it is, the less
	 sensitive the swipe detection is. <= 0 means off. */
	d[@"SwipeMinimumLength"]							= @(30);
	
	d[@"NotificationType -> Highlight -> Enabled"]				= @(YES);
	d[@"NotificationType -> Highlight -> Sound"]				= @"Glass";
	d[@"NotificationType -> Highlight -> Bounce Dock Icon"]		= @(YES);
	
	d[@"NotificationType -> Private Message (New) -> Enabled"]			= @(YES);
	d[@"NotificationType -> Private Message (New) -> Sound"]			= @"Submarine";
	d[@"NotificationType -> Private Message (New) -> Bounce Dock Icon"] = @(YES);
	
	d[@"NotificationType -> Private Message -> Enabled"]			= @(YES);
	d[@"NotificationType -> Private Message -> Sound"]				= @"Submarine";
	d[@"NotificationType -> Private Message -> Bounce Dock Icon"]	= @(YES);
	
	d[@"NotificationType -> Address Book Match -> Enabled"]		= @(YES);
	d[@"NotificationType -> Private Message (New) -> Enabled"]	= @(YES);
	
	d[@"NotificationType -> Successful File Transfer (Sending) -> Enabled"]		= @(YES);
	d[@"NotificationType -> Successful File Transfer (Receiving) -> Enabled"]	= @(YES);
	d[@"NotificationType -> Failed File Transfer (Sending) -> Enabled"]			= @(YES);
	d[@"NotificationType -> Failed File Transfer (Receiving) -> Enabled"]		= @(YES);
	d[@"NotificationType -> File Transfer Request -> Enabled"]					= @(YES);
	
	d[@"NotificationType -> Successful File Transfer (Sending) -> Bounce Dock Icon"]	= @(YES);
	d[@"NotificationType -> Successful File Transfer (Receiving) -> Bounce Dock Icon"]	= @(YES);
	d[@"NotificationType -> Failed File Transfer (Sending) -> Bounce Dock Icon"]		= @(YES);
	d[@"NotificationType -> Failed File Transfer (Receiving) -> Bounce Dock Icon"]		= @(YES);
	d[@"NotificationType -> File Transfer Request -> Bounce Dock Icon"]					= @(YES);
	
	d[@"NotificationType -> File Transfer Request -> Sound"] = @"Blow"; // u wut m8
	
	d[@"DefaultIdentity -> Nickname"] = @"Guest";
	d[@"DefaultIdentity -> AwayNickname"] = NSStringEmptyPlaceholder;
	d[@"DefaultIdentity -> Username"] = @"textual";
	d[@"DefaultIdentity -> Realname"] = @"Textual User";
	
	d[@"IRCopDefaultLocalizaiton -> Shun Reason"]	= TXTLS(@"ShunReason");
	d[@"IRCopDefaultLocalizaiton -> Kill Reason"]	= TXTLS(@"KillReason");
	d[@"IRCopDefaultLocalizaiton -> G:Line Reason"] = TXTLS(@"GlineReason");
	
	TVCMemberList *memberList = self.masterController.memberList;
	
	d[@"User List Mode Badge Colors —> +y"] = [NSArchiver archivedDataWithRootObject:memberList.userMarkBadgeBackgroundColor_YDefault];
	d[@"User List Mode Badge Colors —> +q"] = [NSArchiver archivedDataWithRootObject:memberList.userMarkBadgeBackgroundColor_QDefault];
	d[@"User List Mode Badge Colors —> +a"] = [NSArchiver archivedDataWithRootObject:memberList.userMarkBadgeBackgroundColor_ADefault];
	d[@"User List Mode Badge Colors —> +o"] = [NSArchiver archivedDataWithRootObject:memberList.userMarkBadgeBackgroundColor_ODefault];
	d[@"User List Mode Badge Colors —> +h"] = [NSArchiver archivedDataWithRootObject:memberList.userMarkBadgeBackgroundColor_HDefault];
	d[@"User List Mode Badge Colors —> +v"] = [NSArchiver archivedDataWithRootObject:memberList.userMarkBadgeBackgroundColor_VDefault];
	
	d[@"ChannelOperatorDefaultLocalization -> Kick Reason"] = TXTLS(@"KickReason");
	
	d[TPCPreferencesThemeNameDefaultsKey]				= TXDefaultTextualLogStyle;
	d[TPCPreferencesThemeFontNameDefaultsKey]			= TXDefaultTextualLogFont;

	d[@"Theme -> Nickname Format"]						= TXLogLineUndefinedNicknameFormat;
	d[@"Theme -> Timestamp Format"]						= TXDefaultTextualTimestampFormat;
	
	d[@"inlineImageMaxFilesize"]				= @(2);
    d[@"TrackUserAwayStatusMaximumChannelSize"] = @(0);
	d[@"AutojoinMaximumChannelJoinCount"]		= @(2);
	d[@"ScrollbackMaximumLineCount"]			= @(300);
	d[@"InlineMediaScalingWidth"]				= @(300);
	d[@"InlineMediaMaximumHeight"]				= @(0);
	d[@"Keyboard -> Tab Key Action"]			= @(TXTabKeyNickCompleteAction);
	d[@"Keyboard -> Command+W Action"]			= @(TXCommandWKeyCloseWindowAction);
	d[@"Main Input Text Field -> Font Size"]	= @(TXMainTextBoxFontNormalSize);
	d[@"NicknameHighlightMatchingType"]			= @(TXNicknameHighlightExactMatchType);
	d[@"DefaultBanCommandHostmaskFormat"]		= @(TXHostmaskBanWHAINNFormat);
	d[@"DestinationOfNonserverNotices"]			= @(TXNoticeSendServerConsoleType);
	d[@"UserListDoubleClickAction"]				= @(TXUserDoubleClickPrivateMessageAction);
	
	d[@"File Transfers -> File Transfer Request Reply Action"] = @(TXFileTransferRequestReplyOpenDialogAction);
	d[@"File Transfers -> File Transfer IP Address Detection Method"] = @(TXFileTransferIPAddressAutomaticDetectionMethod);
	d[@"File Transfers -> File Transfer Port Range Start"] = @(TXDefaultFileTransferPortRangeStart);
	d[@"File Transfers -> File Transfer Port Range End"] = @(TXDefaultFileTransferPortRangeEnd);
	
	d[@"MainWindowTransparencyLevel"]		= @(1.0);
	d[@"Theme -> Font Size"]				= @(12.0);
	
	return d;
}

+ (void)initPreferences
{
	[TPCPreferences updateApplicationRunCount];

#ifndef TEXTUAL_TRIAL_BINARY
	NSInteger numberOfRuns = [TPCPreferences applicationRunCount];

	if (numberOfRuns >= 2) {
		[self.invokeInBackgroundThread defaultIRCClientPrompt:NO];
	}
#endif

	[TPCPreferences startUsingTranscriptFolderSecurityScopedBookmark];

	// ====================================================== //

	NSDictionary *d = [TPCPreferences defaultPreferences];

	// ====================================================== //

	[RZUserDefaults() registerDefaults:d];

	[RZUserDefaults() addObserver:(id)self forKeyPath:@"Highlight List -> Primary Matches"  options:NSKeyValueObservingOptionNew context:NULL];
	[RZUserDefaults() addObserver:(id)self forKeyPath:@"Highlight List -> Excluded Matches" options:NSKeyValueObservingOptionNew context:NULL];

	[TPCPreferences loadMatchKeywords];
	[TPCPreferences loadExcludeKeywords];
	[TPCPreferences populateCommandIndex];

	/* Sandbox Check */

	[RZUserDefaults() setBool:[TPCPreferences sandboxEnabled]						forKey:@"Security -> Sandbox Enabled"];

	[RZUserDefaults() setBool:[TPCPreferences featureAvailableToOSXLion]			forKey:@"System —> Running Mac OS Lion Or Newer"];
	[RZUserDefaults() setBool:[TPCPreferences featureAvailableToOSXMountainLion]	forKey:@"System —> Running Mac OS Mountain Lion Or Newer"];
	[RZUserDefaults() setBool:[TPCPreferences featureAvailableToOSXMavericks]		forKey:@"System —> Running Mac OS Mavericks Or Newer"];
	
#ifndef TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT
	[RZUserDefaults() setBool:NO forKey:@"System —> Built with iCloud Support"];
#else
	if ([TPCPreferences featureAvailableToOSXMountainLion]) {
		[RZUserDefaults() setBool:YES forKey:@"System —> Built with iCloud Support"];
	} else {
		[RZUserDefaults() setBool:NO forKey:@"System —> Built with iCloud Support"];
	}
#endif
	
	/* Validate some stuff. */
	(void)[TPCPreferences performValidationForKeyValues:YES];

	/* Setup loggin. */
	[TPCPreferences startUsingTranscriptFolderSecurityScopedBookmark];
}

#pragma mark -
#pragma mark NSTextView Preferences

+ (BOOL)textFieldAutomaticSpellCheck
{
	return [RZUserDefaults() boolForKey:@"TextFieldAutomaticSpellCheck"];
}

+ (void)setTextFieldAutomaticSpellCheck:(BOOL)value
{
	if (NSDissimilarObjects(value, [TPCPreferences textFieldAutomaticSpellCheck])) {
		[RZUserDefaults() setBool:value forKey:@"TextFieldAutomaticSpellCheck"];
	}
}

+ (BOOL)textFieldAutomaticGrammarCheck
{
	return [RZUserDefaults() boolForKey:@"TextFieldAutomaticGrammarCheck"];
}

+ (void)setTextFieldAutomaticGrammarCheck:(BOOL)value
{
	if (NSDissimilarObjects(value, [TPCPreferences textFieldAutomaticGrammarCheck])) {
		[RZUserDefaults() setBool:value forKey:@"TextFieldAutomaticGrammarCheck"];
	}
}

+ (BOOL)textFieldAutomaticSpellCorrection
{
	return [RZUserDefaults() boolForKey:@"TextFieldAutomaticSpellCorrection"];
}

+ (void)setTextFieldAutomaticSpellCorrection:(BOOL)value
{
	if (NSDissimilarObjects(value, [TPCPreferences textFieldAutomaticSpellCorrection])) {
		[RZUserDefaults() setBool:value forKey:@"TextFieldAutomaticSpellCorrection"];
	}
}

+ (BOOL)textFieldSmartCopyPaste
{
	return [RZUserDefaults() boolForKey:@"TextFieldSmartCopyPaste"];
}

+ (void)setTextFieldSmartCopyPaste:(BOOL)value
{
	if (NSDissimilarObjects(value, [TPCPreferences textFieldSmartCopyPaste])) {
		[RZUserDefaults() setBool:value forKey:@"TextFieldSmartCopyPaste"];
	}
}

+ (BOOL)textFieldSmartQuotes
{
	return [RZUserDefaults() boolForKey:@"TextFieldSmartQuotes"];
}

+ (void)setTextFieldSmartQuotes:(BOOL)value
{
	if (NSDissimilarObjects(value, [TPCPreferences textFieldSmartQuotes])) {
		[RZUserDefaults() setBool:value forKey:@"TextFieldSmartQuotes"];
	}
}

+ (BOOL)textFieldSmartDashes
{
	return [RZUserDefaults() boolForKey:@"TextFieldSmartDashes"];
}

+ (void)setTextFieldSmartDashes:(BOOL)value
{
	if (NSDissimilarObjects(value, [TPCPreferences textFieldSmartDashes])) {
		[RZUserDefaults() setBool:value forKey:@"TextFieldSmartDashes"];
	}
}

+ (BOOL)textFieldSmartLinks
{
	return [RZUserDefaults() boolForKey:@"TextFieldSmartLinks"];
}

+ (void)setTextFieldSmartLinks:(BOOL)value
{
	if (NSDissimilarObjects(value, [TPCPreferences textFieldSmartLinks])) {
		[RZUserDefaults() setBool:value forKey:@"TextFieldSmartLinks"];
	}
}

+ (BOOL)textFieldDataDetectors
{
	return [RZUserDefaults() boolForKey:@"TextFieldDataDetectors"];
}

+ (void)setTextFieldDataDetectors:(BOOL)value
{
	if (NSDissimilarObjects(value, [TPCPreferences textFieldDataDetectors])) {
		[RZUserDefaults() setBool:value forKey:@"TextFieldDataDetectors"];
	}
}

+ (BOOL)textFieldTextReplacement
{
	return [RZUserDefaults() boolForKey:@"TextFieldTextReplacement"];
}

+ (void)setTextFieldTextReplacement:(BOOL)value
{
	if (NSDissimilarObjects(value, [TPCPreferences textFieldTextReplacement])) {
		[RZUserDefaults() setBool:value forKey:@"TextFieldTextReplacement"];
	}
}

@end
