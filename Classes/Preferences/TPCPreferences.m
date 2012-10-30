/* ********************************************************************* 
       _____        _               _    ___ ____   ____
      |_   _|___  _| |_ _   _  __ _| |  |_ _|  _ \ / ___|
       | |/ _ \ \/ / __| | | |/ _` | |   | || |_) | |
       | |  __/>  <| |_| |_| | (_| | |   | ||  _ <| |___
       |_|\___/_/\_\\__|\__,_|\__,_|_|  |___|_| \_\\____|

 Copyright (c) 2010 — 2012 Codeux Software & respective contributors.
        Please see Contributors.pdf and Acknowledgements.pdf

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

#include <unistd.h>         // -------
#include <sys/types.h>      // --- | For +userHomeDirectoryPathOutsideSandbox
#include <pwd.h>            // -------

@implementation TPCPreferences

#pragma mark -
#pragma mark Master Controller

__weak static TXMasterController *internalMasterController;

/* masterController was only added to use with -invertSidebarColors, but
 having a reference in this class can make some calls much simplier. Instead
 of digging down through delegates to find something… we can just call this.

 The master control has pointers to everything. */

+ (TXMasterController *)masterController
{
	return internalMasterController;
}

+ (void)setMasterController:(TXMasterController *)master
{
	if ([master isKindOfClass:[TXMasterController class]] && PointerIsEmpty(internalMasterController)) {
		internalMasterController = master;
	}
}

#pragma mark -
#pragma mark Version Dictonaries

static NSDictionary *systemVersionPlist = nil;

+ (NSDictionary *)textualInfoPlist
{
	return [[NSBundle mainBundle] infoDictionary];
}

+ (NSDictionary *)systemInfoPlist
{
	return systemVersionPlist;
}

#pragma mark -
#pragma mark Command Index

static NSArray *IRCUserAccessibleCommandIndexMap;
static NSArray *IRCInternalUseCommandIndexMap;

+ (void)populateCommandIndex
{
	IRCInternalUseCommandIndexMap = @[ // Open Key: 1051
	@[@"action",			@"ACTION",				@(1002),		@(NO)],
	@[@"adchat",			@"ADCHAT",				@(1003),		@(YES)],
	@[@"away",				@"AWAY",				@(1050),		@(YES)],
	@[@"cap",				@"CAP",					@(1004),		@(YES)],
	@[@"cap_authenticate",	@"AUTHENTICATE",		@(1005),		@(YES)],
	@[@"chatops",			@"CHATOPS",				@(1006),		@(YES)],
	@[@"ctcp",				@"CTCP",				@(1007),		@(NO)],
	@[@"ctcp_clientinfo",	@"CLIENTINFO",			@(1008),		@(NO)],
	@[@"ctcp_ctcpreply",	@"CTCPREPLY",			@(1009),		@(NO)],
	@[@"ctcp_lagcheck", 	@"LAGCHECK",			@(1010),		@(NO)],
	@[@"ctcp_ping", 		@"PING",				@(1011),		@(NO)],
	@[@"ctcp_time", 		@"TIME",				@(1012),		@(NO)],
	@[@"ctcp_userinfo", 	@"USERINFO",			@(1013),		@(NO)],
	@[@"ctcp_version", 		@"VERSION",				@(1014),		@(NO)],
	@[@"dcc",				@"DCC",					@(1015),		@(NO)],
	@[@"error",				@"ERROR",				@(1016),		@(YES)],
	@[@"gline", 			@"GLINE",				@(1047),		@(YES)],
	@[@"globops",			@"GLOBOPS",				@(1017),		@(YES)],
	@[@"gzline", 			@"GZLINE",				@(1048),		@(YES)],
	@[@"invite",			@"INVITE",				@(1018),		@(YES)],
	@[@"ison",				@"ISON",				@(1019),		@(YES)],
	@[@"ison",				@"ISON",				@(1043),		@(YES)],
	@[@"join",				@"JOIN",				@(1020),		@(YES)],
	@[@"kick",				@"KICK",				@(1021),		@(YES)],
	@[@"kill",				@"KILL",				@(1022),		@(YES)],
	@[@"list",				@"LIST",				@(1023),		@(YES)],
	@[@"locops",			@"LOCOPS",				@(1024),		@(YES)],
	@[@"mode",				@"MODE",				@(1026),		@(YES)],
	@[@"nachat", 			@"NACHAT",				@(1027),		@(YES)],
	@[@"names", 			@"NAMES",				@(1028),		@(YES)],
	@[@"nick",				@"NICK",				@(1029),		@(YES)],
	@[@"notice",			@"NOTICE",				@(1030),		@(YES)],
	@[@"part",				@"PART",				@(1031),		@(YES)],
	@[@"pass",				@"PASS",				@(1032),		@(YES)],
	@[@"ping",				@"PING",				@(1033),		@(YES)],
	@[@"pong",				@"PONG",				@(1034),		@(YES)],
	@[@"privmsg", 			@"PRIVMSG",				@(1035),		@(YES)],
	@[@"quit",				@"QUIT",				@(1036),		@(YES)],
	@[@"shun",				@"SHUN",				@(1045),		@(YES)],
	@[@"tempshun", 			@"TEMPSHUN",			@(1046),		@(YES)],
	@[@"topic", 			@"TOPIC",				@(1039),		@(YES)],
	@[@"user", 				@"USER",				@(1037),		@(YES)],
	@[@"wallops", 			@"WALLOPS",				@(1038),		@(YES)],
	@[@"who",				@"WHO",					@(1040),		@(YES)],
	@[@"whois", 			@"WHOIS",				@(1042),		@(YES)],
	@[@"whowas", 			@"WHOWAS",				@(1041),		@(YES)],
	@[@"zline", 			@"ZLINE",				@(1049),		@(YES)],
	];

	IRCUserAccessibleCommandIndexMap = @[ // Open Key: 5085
	@[@"adchat",					@"ADCHAT",				@(5001),		@(NO)],
	@[@"ame",						@"AME",					@(5002),		@(NO)],
	@[@"amsg",						@"AMSG",				@(5003),		@(NO)],
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
	@[@"echo",						@"ECHO",				@(5022),		@(NO)],
	@[@"gline",						@"GLINE",				@(5023),		@(NO)],
	@[@"globops",					@"GLOBOPS",				@(5024),		@(NO)],
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
	@[@"load_plugins",				@"LOAD_PLUGINS",		@(5038),		@(YES)],
	@[@"locops",					@"LOCOPS",				@(5039),		@(NO)],
	@[@"m",							@"M",					@(5040),		@(NO)],
	@[@"me",						@"ME",					@(5041),		@(NO)],
	@[@"mode",						@"MODE",				@(5042),		@(NO)],
	@[@"msg",						@"MSG",					@(5043),		@(NO)],
	@[@"mute",						@"MUTE",				@(5044),		@(NO)],
	@[@"mylag",						@"MYLAG",				@(5045),		@(NO)],
	@[@"myversion",					@"MYVERSION",			@(5046),		@(NO)],
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
	@[@"tempshun",					@"TEMPSHUN",			@(5068),		@(NO)],
	@[@"timer",						@"TIMER",				@(5069),		@(NO)],
	@[@"topic",						@"TOPIC",				@(5070),		@(NO)],
	@[@"umode",						@"UMODE",				@(5071),		@(NO)],
	@[@"unban",						@"UNBAN",				@(5072),		@(NO)],
	@[@"unignore",					@"UNIGNORE",			@(5073),		@(NO)],
	@[@"unload_plugins",			@"UNLOAD_PLUGINS",		@(5074),		@(YES)],
	@[@"unmute",					@"UNMUTE",				@(5075),		@(NO)],
	@[@"voice",						@"VOICE",				@(5076),		@(NO)],
	@[@"wallops",					@"WALLOPS",				@(5077),		@(NO)],
	@[@"weights",					@"WEIGHTS",				@(5078),		@(NO)],
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

	BOOL inDevMode = [_NSUserDefaults() boolForKey:TXDeveloperEnvironmentToken];

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
	NSArray *searchPath = [self.class IRCCommandIndex:isPublic];

	for (NSArray *indexInfo in searchPath) {
		NSString *matchKey = indexInfo[0];

		if ([matchKey isEqualNoCase:key]) {
			return indexInfo[1];
		}
 	}

	return nil;
}

#pragma mark -

NSString *IRCCommandIndex(const char *key)
{
	return IRCPublicCommandIndex(key);
}

NSString *IRCPrivateCommandIndex(const char *key)
{
	NSString *ckey = [NSString stringWithUTF8String:key];

	NSString *rkey = [TPCPreferences IRCCommandFromIndexKey:ckey publicSearch:NO];

	DebugLogToConsole(@"%@; %@", ckey, rkey);

	return rkey;
}

NSString *IRCPublicCommandIndex(const char *key)
{
	NSString *ckey = [NSString stringWithUTF8String:key];

	NSString *rkey = [TPCPreferences IRCCommandFromIndexKey:ckey publicSearch:YES];

	DebugLogToConsole(@"%@; %@", ckey, rkey);

	return rkey;
}

#pragma mark -

+ (NSInteger)indexOfIRCommand:(NSString *)command
{
	return [self.class indexOfIRCommand:command publicSearch:YES];
}

+ (NSInteger)indexOfIRCommand:(NSString *)command publicSearch:(BOOL)isPublic
{
	NSArray *searchPath = [self.class IRCCommandIndex:isPublic];

	BOOL inDevMode = [_NSUserDefaults() boolForKey:TXDeveloperEnvironmentToken];

	for (NSArray *indexInfo in searchPath) {
		NSString *matValue = indexInfo[1];

		if (isPublic) {
			BOOL developerOnly = [indexInfo boolAtIndex:3];

			if (inDevMode == NO && developerOnly) {
				continue;
			}
		} else {
			BOOL isNotSpecial = [indexInfo boolAtIndex:3];

			if (isNotSpecial == NO) {
				continue;
			}
		}

		if ([matValue isEqualNoCase:command]) {
			return [indexInfo integerAtIndex:2];
		}
 	}

	return -1;
}

#pragma mark -
#pragma mark Application Information

+ (BOOL)featureAvailableToOSXLion
{
	return (floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_6);
}

+ (BOOL)featureAvailableToOSXMountainLion
{
	return (floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_7);
}

+ (NSData *)applicationIcon
{
	return [[NSApp applicationIconImage] TIFFRepresentation];
}

+ (NSString *)applicationName
{
	return [TPCPreferences textualInfoPlist][@"CFBundleName"];
}

+ (NSInteger)applicationProcessID
{
	return [[NSProcessInfo processInfo] processIdentifier];
}

+ (NSString *)gitBuildReference
{
	return [TPCPreferences textualInfoPlist][@"TXBundleBuildReference"];
}

+ (NSString *)applicationBundleIdentifier
{
	return [[NSBundle mainBundle] bundleIdentifier];
}

+ (BOOL)runningInHighResolutionMode
{
	return ([_NSMainScreen() runningInHighResolutionMode]);
}

#pragma mark -
#pragma mark Path Index

+ (NSString *)_whereApplicationSupportPath
{
	return [_NSFileManager() URLForDirectory:NSApplicationSupportDirectory
									inDomain:NSUserDomainMask
						   appropriateForURL:nil
									  create:YES
									   error:NULL].relativePath;
}

+ (NSString *)applicationTemporaryFolderPath
{
	return NSTemporaryDirectory();
}

+ (NSString *)applicationSupportFolderPath
{
	NSString *dest = [[self _whereApplicationSupportPath] stringByAppendingPathComponent:@"/Textual IRC/"];

	if ([_NSFileManager() fileExistsAtPath:dest] == NO) {
		[_NSFileManager() createDirectoryAtPath:dest withIntermediateDirectories:YES attributes:nil error:NULL];
	}

	return dest;
}

+ (NSString *)customScriptFolderPath
{
	NSString *dest = [[self _whereApplicationSupportPath] stringByAppendingPathComponent:@"/Textual IRC/Scripts/"];

	if ([_NSFileManager() fileExistsAtPath:dest] == NO) {
		[_NSFileManager() createDirectoryAtPath:dest withIntermediateDirectories:YES attributes:nil error:NULL];
	}

	return dest;
}

+ (NSString *)customThemeFolderPath
{
	NSString *dest = [[self _whereApplicationSupportPath] stringByAppendingPathComponent:@"/Textual IRC/Styles/"];

	if ([_NSFileManager() fileExistsAtPath:dest] == NO) {
		[_NSFileManager() createDirectoryAtPath:dest withIntermediateDirectories:YES attributes:nil error:NULL];
	}

	return dest;
}

+ (NSString *)customExtensionFolderPath
{
	NSString *dest = [[self _whereApplicationSupportPath] stringByAppendingPathComponent:@"/Textual IRC/Extensions/"];

	if ([_NSFileManager() fileExistsAtPath:dest] == NO) {
		[_NSFileManager() createDirectoryAtPath:dest withIntermediateDirectories:YES attributes:nil error:NULL];
	}

	return dest;
}

+ (NSString *)bundledScriptFolderPath
{
	return [[self applicationResourcesFolderPath] stringByAppendingPathComponent:@"Scripts"];
}

#ifdef TXUserScriptsFolderAvailable
+ (NSString *)systemUnsupervisedScriptFolderPath
{
	if ([TPCPreferences featureAvailableToOSXMountainLion]) {
		NSString *pathHead = [NSString stringWithFormat:@"/Library/Application Scripts/%@/", [TPCPreferences applicationBundleIdentifier]];

		return [NSHomeDirectory() stringByAppendingPathComponent:pathHead];

		 // This was creating a lot of leaks in Mountain Lion Preview 4.
		 // Commenting out for now…

		/*
		return [_NSFileManager() URLForDirectory:NSApplicationScriptsDirectory
										inDomain:NSUserDomainMask
							   appropriateForURL:nil
										  create:YES
										   error:NULL].relativePath;
		*/
		 
	}

	return NSStringEmptyPlaceholder;
}
#endif

+ (NSString *)bundledThemeFolderPath
{
	return [[self applicationResourcesFolderPath] stringByAppendingPathComponent:@"Styles"];
}

+ (NSString *)bundledExtensionFolderPath
{
	return [[self applicationResourcesFolderPath] stringByAppendingPathComponent:@"Extensions"];
}

+ (NSString *)appleStoreReceiptFilePath
{
	return [[self applicationBundlePath] stringByAppendingPathComponent:@"/Contents/_MASReceipt/receipt"];
}

+ (NSString *)applicationResourcesFolderPath
{
	return [[NSBundle mainBundle] resourcePath];
}

+ (NSString *)applicationBundlePath
{
	return [[NSBundle mainBundle] bundlePath];
}

+ (NSString *)userHomeDirectoryPathOutsideSandbox
{
	struct passwd *pw = getpwuid(getuid());

	return [NSString stringWithUTF8String:pw->pw_dir];
}

#pragma mark -
#pragma mark Logging

static NSURL *transcriptFolderResolvedBookmark;

+ (void)stopUsingTranscriptFolderBookmarkResources
{
	if (NSObjectIsNotEmpty(transcriptFolderResolvedBookmark)) {
		[transcriptFolderResolvedBookmark stopAccessingSecurityScopedResource];

		transcriptFolderResolvedBookmark = nil;
	}
}

+ (NSString *)transcriptFolder
{
	if ([self sandboxEnabled] && [TPCPreferences securityScopedBookmarksAvailable]) {
		if (NSObjectIsNotEmpty(transcriptFolderResolvedBookmark)) {
			return [transcriptFolderResolvedBookmark path];
		} else {
			NSData *bookmark = [_NSUserDefaults() dataForKey:@"LogTranscriptDestinationSecurityBookmark"];

			if (NSObjectIsNotEmpty(bookmark)) {
				NSError *error;

				NSURL *resolvedBookmark = [NSURL URLByResolvingBookmarkData:bookmark
																	options:NSURLBookmarkResolutionWithSecurityScope
															  relativeToURL:nil
														bookmarkDataIsStale:NO
																	  error:&error];

				if (error) {
					LogToConsole(@"Error creating bookmark for URL: %@", error);
				} else {
					[resolvedBookmark startAccessingSecurityScopedResource];

					transcriptFolderResolvedBookmark = resolvedBookmark;

					return [transcriptFolderResolvedBookmark path];
				}
			}
		}

		return nil;
	} else {
		NSString *base = [_NSUserDefaults() objectForKey:@"LogTranscriptDestination"];

		return [base stringByExpandingTildeInPath];
	}
}

+ (void)setTranscriptFolder:(id)value
{
	// "value" can either be returned as an absolute path on non-sandboxed
	// versions of Textual or as an NSData object on sandboxed versions.

	if ([self sandboxEnabled]) {
		if ([TPCPreferences securityScopedBookmarksAvailable] == NO) {
			return;
		}

		[self stopUsingTranscriptFolderBookmarkResources];

		[_NSUserDefaults() setObject:value forKey:@"LogTranscriptDestinationSecurityBookmark"];
	} else {
		[_NSUserDefaults() setObject:value forKey:@"LogTranscriptDestination"];
	}
}

#pragma mark -
#pragma mark Sandbox Check

+ (BOOL)sandboxEnabled
{
	NSString *suffix = [NSString stringWithFormat:@"Containers/%@/Data", [TPCPreferences applicationBundleIdentifier]];

	return [NSHomeDirectory() hasSuffix:suffix];
}

+ (BOOL)securityScopedBookmarksAvailable
{
	if ([TPCPreferences featureAvailableToOSXLion] == NO) {
		return NO;
	}

	if ([TPCPreferences featureAvailableToOSXMountainLion]) {
		return YES;
	}

	NSString *osxversion = systemVersionPlist[@"ProductVersion"];

	NSArray *matches = @[@"10.7", @"10.7.0", @"10.7.1", @"10.7.2"];

	return ([matches containsObject:osxversion] == NO);
}

#pragma mark -
#pragma mark Default Identity

+ (NSString *)defaultNickname
{
	return [_NSUserDefaults() objectForKey:@"DefaultIdentity -> Nickname"];
}

+ (NSString *)defaultUsername
{
	return [_NSUserDefaults() objectForKey:@"DefaultIdentity -> Username"];
}

+ (NSString *)defaultRealname
{
	return [_NSUserDefaults() objectForKey:@"DefaultIdentity -> Realname"];
}

#pragma mark -
#pragma mark General Preferences

+ (NSInteger)autojoinMaxChannelJoins
{
	return [_NSUserDefaults() integerForKey:@"AutojoinMaximumChannelJoinCount"];
}

+ (NSString *)defaultKickMessage
{
	return [_NSUserDefaults() objectForKey:@"ChannelOperatorDefaultLocalization -> Kick Reason"];
}

+ (NSString *)IRCopDefaultKillMessage
{
	return [_NSUserDefaults() objectForKey:@"IRCopDefaultLocalizaiton -> Kill Reason"];
}

+ (NSString *)IRCopDefaultGlineMessage
{
	return [_NSUserDefaults() objectForKey:@"IRCopDefaultLocalizaiton -> G:Line Reason"];
}

+ (NSString *)IRCopDefaultShunMessage
{
	return [_NSUserDefaults() objectForKey:@"IRCopDefaultLocalizaiton -> Shun Reason"];
}

+ (NSString *)IRCopAlertMatch
{
	return [_NSUserDefaults() objectForKey:@"ScanForIRCopAlertInServerNoticesMatch"];
}

+ (NSString *)masqueradeCTCPVersion
{
	return [_NSUserDefaults() objectForKey:@"ApplicationCTCPVersionMasquerade"];
}

+ (BOOL)invertSidebarColors
{
	if (internalMasterController.viewTheme.other.forceInvertSidebarColors) {
		return YES;
	}

	return [_NSUserDefaults() boolForKey:@"InvertSidebarColors"];
}

+ (BOOL)hideMainWindowSegmentedController
{
	return [_NSUserDefaults() boolForKey:@"DisableMainWindowSegmentedController"];
}

+ (BOOL)trackConversations
{
	return [_NSUserDefaults() boolForKey:@"TrackConversationsWithColorHashing"];
}

+ (BOOL)autojoinWaitForNickServ
{
	return [_NSUserDefaults() boolForKey:@"AutojoinWaitsForNickservIdentification"];
}

+ (BOOL)logAllHighlightsToQuery
{
	return [_NSUserDefaults() boolForKey:@"LogHighlights"];
}

+ (BOOL)clearAllOnlyOnActiveServer
{
	return [_NSUserDefaults() boolForKey:@"ApplyCommandToAllConnections -> clearall"];
}

+ (BOOL)displayServerMOTD
{
	return [_NSUserDefaults() boolForKey:@"DisplayServerMessageOfTheDayOnConnect"];
}

+ (BOOL)copyOnSelect
{
	return [_NSUserDefaults() boolForKey:@"CopyTextSelectionOnMouseUp"];
}

+ (BOOL)replyToCTCPRequests
{
	return [_NSUserDefaults() boolForKey:@"ReplyUnignoredExternalCTCPRequests"];
}

+ (BOOL)autoAddScrollbackMark
{
	return [_NSUserDefaults() boolForKey:@"AutomaticallyAddScrollbackMarker"];
}

+ (BOOL)removeAllFormatting
{
	return [_NSUserDefaults() boolForKey:@"RemoveIRCTextFormatting"];
}

+ (BOOL)useLogAntialiasing
{
	return [_NSUserDefaults() boolForKey:@"DisplayMainWindowWithAntialiasing"];
}

+ (BOOL)disableNicknameColors
{
	return [_NSUserDefaults() boolForKey:@"DisableRemoteNicknameColorHashing"];
}

+ (BOOL)rightToLeftFormatting
{
	return [_NSUserDefaults() boolForKey:@"RightToLeftTextFormatting"];
}

+ (NSString *)completionSuffix
{
	return [_NSUserDefaults() objectForKey:@"Keyboard -> Tab Key Completion Suffix"];
}

+ (TXHostmaskBanFormat)banFormat
{
	return (TXHostmaskBanFormat)[_NSUserDefaults() integerForKey:@"DefaultBanCommandHostmaskFormat"];
}

+ (BOOL)displayDockBadge
{
	return [_NSUserDefaults() boolForKey:@"DisplayDockBadges"];
}

+ (BOOL)handleIRCopAlerts
{
	return [_NSUserDefaults() boolForKey:@"ScanForIRCopAlertInServerNotices"];
}

+ (BOOL)handleServerNotices
{
	return [_NSUserDefaults() boolForKey:@"ProcessServerNoticesForIRCop"];
}

+ (BOOL)amsgAllConnections
{
	return [_NSUserDefaults() boolForKey:@"ApplyCommandToAllConnections -> amsg"];
}

+ (BOOL)awayAllConnections
{
	return [_NSUserDefaults() boolForKey:@"ApplyCommandToAllConnections -> away"];
}

+ (BOOL)giveFocusOnMessage
{
	return [_NSUserDefaults() boolForKey:@"FocusSelectionOnMessageCommandExecution"];
}

+ (BOOL)nickAllConnections
{
	return [_NSUserDefaults() boolForKey:@"ApplyCommandToAllConnections -> nick"];
}

+ (BOOL)confirmQuit
{
	return [_NSUserDefaults() boolForKey:@"ConfirmApplicationQuit"];
}

+ (BOOL)processChannelModes
{
	return [_NSUserDefaults() boolForKey:@"ProcessChannelModesOnJoin"];
}

+ (BOOL)rejoinOnKick
{
	return [_NSUserDefaults() boolForKey:@"RejoinChannelOnLocalKick"];
}

+ (BOOL)reloadScrollbackOnLaunch
{
	return [_NSUserDefaults() boolForKey:@"ReloadScrollbackOnLaunch"];
}

+ (BOOL)autoJoinOnInvite
{
	return [_NSUserDefaults() boolForKey:@"AutojoinChannelOnInvite"];
}

+ (BOOL)connectOnDoubleclick
{
	return [_NSUserDefaults() boolForKey:@"ServerListDoubleClickConnectServer"];
}

+ (BOOL)disconnectOnDoubleclick
{
	return [_NSUserDefaults() boolForKey:@"ServerListDoubleClickDisconnectServer"];
}

+ (BOOL)joinOnDoubleclick
{
	return [_NSUserDefaults() boolForKey:@"ServerListDoubleClickJoinChannel"];
}

+ (BOOL)leaveOnDoubleclick
{
	return [_NSUserDefaults() boolForKey:@"ServerListDoubleClickLeaveChannel"];
}

+ (BOOL)logTranscript
{
	return [_NSUserDefaults() boolForKey:@"LogTranscript"];
}

+ (BOOL)openBrowserInBackground
{
	return [_NSUserDefaults() boolForKey:@"OpenClickedLinksInBackgroundBrowser"];
}

+ (BOOL)showInlineImages
{
	return [_NSUserDefaults() boolForKey:@"DisplayEventInLogView -> Inline Media"];
}

+ (BOOL)showJoinLeave
{
	return [_NSUserDefaults() boolForKey:@"DisplayEventInLogView -> Join, Part, Quit"];
}

+ (BOOL)stopGrowlOnActive
{
	return [_NSUserDefaults() boolForKey:@"DisableNotificationsForActiveWindow"];
}

+ (BOOL)countPublicMessagesInIconBadge
{
	return [_NSUserDefaults() boolForKey:@"DisplayPublicMessageCountInDockBadge"];
}

+ (TXTabKeyActionType)tabAction
{
	return (TXTabKeyActionType)[_NSUserDefaults() integerForKey:@"Keyboard -> Tab Key Action"];
}

+ (BOOL)keywordCurrentNick
{
	return [_NSUserDefaults() boolForKey:@"TrackNicknameHighlightsOfLocalUser"];
}

+ (TXNicknameHighlightMatchType)keywordMatchingMethod
{
	return (TXNicknameHighlightMatchType)[_NSUserDefaults() integerForKey:@"NicknameHighlightMatchingType"];
}

+ (TXUserDoubleClickAction)userDoubleClickOption
{
	return (TXUserDoubleClickAction)[_NSUserDefaults() integerForKey:@"UserListDoubleClickAction"];
}

+ (TXNoticeSendLocationType)locationToSendNotices
{
	return (TXNoticeSendLocationType)[_NSUserDefaults() integerForKey:@"DestinationOfNonserverNotices"];
}

+ (TXCmdWShortcutResponseType)cmdWResponseType
{
	return (TXCmdWShortcutResponseType)[_NSUserDefaults() integerForKey:@"Keyboard -> Command+W Action"];
}

#pragma mark -
#pragma mark Theme

+ (NSString *)themeName
{
	return [_NSUserDefaults() objectForKey:@"Theme -> Name"];
}

+ (void)setThemeName:(NSString *)value
{
	[_NSUserDefaults() setObject:value forKey:@"Theme -> Name"];
}

+ (NSString *)themeChannelViewFontName
{
	return [_NSUserDefaults() objectForKey:@"Theme -> Font Name"];
}

+ (void)setThemeChannelViewFontName:(NSString *)value
{
	[_NSUserDefaults() setObject:value forKey:@"Theme -> Font Name"];
}

+ (TXNSDouble)themeChannelViewFontSize
{
	return [_NSUserDefaults() doubleForKey:@"Theme -> Font Size"];
}

+ (void)setThemeChannelViewFontSize:(TXNSDouble)value
{
	[_NSUserDefaults() setDouble:value forKey:@"Theme -> Font Size"];
}

+ (NSFont *)themeChannelViewFont
{
	return [NSFont fontWithName:[TPCPreferences themeChannelViewFontName]
						   size:[TPCPreferences themeChannelViewFontSize]];
}

+ (NSString *)themeNicknameFormat
{
	return [_NSUserDefaults() objectForKey:@"Theme -> Nickname Format"];
}

+ (BOOL)inputHistoryIsChannelSpecific
{
	return [_NSUserDefaults() boolForKey:@"SaveInputHistoryPerSelection"];
}

+ (NSString *)themeTimestampFormat
{
	return [_NSUserDefaults() objectForKey:@"Theme -> Timestamp Format"];
}

+ (TXNSDouble)themeTransparency
{
	return [_NSUserDefaults() doubleForKey:@"MainWindowTransparencyLevel"];
}

#pragma mark -
#pragma mark Completion Suffix

+ (void)setCompletionSuffix:(NSString *)value
{
	[_NSUserDefaults() setObject:value forKey:@"Keyboard -> Tab Key Completion Suffix"];
}

#pragma mark -
#pragma mark Inline Image Size

+ (NSInteger)inlineImagesMaxWidth
{
	return [_NSUserDefaults() integerForKey:@"InlineMediaScalingWidth"];
}

+ (void)setInlineImagesMaxWidth:(NSInteger)value
{
	[_NSUserDefaults() setInteger:value forKey:@"InlineMediaScalingWidth"];
}

#pragma mark -
#pragma mark Max Log Lines

+ (NSInteger)maxLogLines
{
	return [_NSUserDefaults() integerForKey:@"ScrollbackMaximumLineCount"];
}

+ (void)setMaxLogLines:(NSInteger)value
{
	[_NSUserDefaults() setInteger:value forKey:@"ScrollbackMaximumLineCount"];
}

#pragma mark -
#pragma mark Events

+ (NSString *)titleForEvent:(TXNotificationType)event
{
	switch (event) {
		case TXNotificationHighlightType:			return TXTLS(@"TXNotificationHighlightType");
		case TXNotificationNewQueryType:		    return TXTLS(@"TXNotificationNewQueryType");
		case TXNotificationChannelMessageType:		return TXTLS(@"TXNotificationChannelMessageType");
		case TXNotificationChannelNoticeType:		return TXTLS(@"TXNotificationChannelNoticeType");
		case TXNotificationQueryMessageType:		return TXTLS(@"TXNotificationQueryMessageType");
		case TXNotificationQueryNoticeType:			return TXTLS(@"TXNotificationQueryNoticeType");
		case TXNotificationKickType:				return TXTLS(@"TXNotificationKickType");
		case TXNotificationInviteType:				return TXTLS(@"TXNotificationInviteType");
		case TXNotificationConnectType:				return TXTLS(@"TXNotificationConnectType");
		case TXNotificationDisconnectType:			return TXTLS(@"TXNotificationDisconnectType");
		case TXNotificationAddressBookMatchType:	return TXTLS(@"TXNotificationAddressBookMatchType");
		default: return nil;
	}

	return nil;
}

+ (NSString *)keyForEvent:(TXNotificationType)event
{
	switch (event) {
		case TXNotificationHighlightType:			return @"NotificationType -> Highlight";
		case TXNotificationNewQueryType:			return @"NotificationType -> Private Message (New)";
		case TXNotificationChannelMessageType:		return @"NotificationType -> Public Message";
		case TXNotificationChannelNoticeType:		return @"NotificationType -> Public Notice";
		case TXNotificationQueryMessageType:		return @"NotificationType -> Private Message";
		case TXNotificationQueryNoticeType:			return @"NotificationType -> Private Notice";
		case TXNotificationKickType:				return @"NotificationType -> Kicked from Channel";
		case TXNotificationInviteType:				return @"NotificationType -> Channel Invitation";
		case TXNotificationConnectType:				return @"NotificationType -> Connected";
		case TXNotificationDisconnectType:			return @"NotificationType -> Disconnected";
		case TXNotificationAddressBookMatchType:	return @"NotificationType -> Address Bok Match";
		default: return nil;
	}

	return nil;
}

+ (NSString *)soundForEvent:(TXNotificationType)event
{
	NSString *okey = [self keyForEvent:event];

	if (NSObjectIsEmpty(okey)) {
		return nil;
	}

	NSString *key = [okey stringByAppendingString:@" -> Sound"];

	return [_NSUserDefaults() objectForKey:key];
}

+ (void)setSound:(NSString *)value forEvent:(TXNotificationType)event
{
	NSString *okey = [self keyForEvent:event];

	if (NSObjectIsEmpty(okey)) {
		return;
	}

	NSString *key = [okey stringByAppendingString:@" -> Sound"];

	[_NSUserDefaults() setObject:value forKey:key];
}

+ (BOOL)growlEnabledForEvent:(TXNotificationType)event
{
	NSString *okey = [self keyForEvent:event];

	if (NSObjectIsEmpty(okey)) {
		return NO;
	}

	NSString *key = [okey stringByAppendingString:@" -> Enabled"];

	return [_NSUserDefaults() boolForKey:key];
}

+ (void)setGrowlEnabled:(BOOL)value forEvent:(TXNotificationType)event
{
	NSString *okey = [self keyForEvent:event];

	if (NSObjectIsEmpty(okey)) {
		return;
	}

	NSString *key = [okey stringByAppendingString:@" -> Enabled"];

	[_NSUserDefaults() setBool:value forKey:key];
}

+ (BOOL)growlStickyForEvent:(TXNotificationType)event
{
	NSString *okey = [self keyForEvent:event];

	if (NSObjectIsEmpty(okey)) {
		return NO;
	}

	NSString *key = [okey stringByAppendingString:@" -> Sticky"];

	return [_NSUserDefaults() boolForKey:key];
}

+ (void)setGrowlSticky:(BOOL)value forEvent:(TXNotificationType)event
{
	NSString *okey = [self keyForEvent:event];

	if (NSObjectIsEmpty(okey)) {
		return;
	}

	NSString *key = [okey stringByAppendingString:@" -> Sticky"];

	[_NSUserDefaults() setBool:value forKey:key];
}

+ (BOOL)disableWhileAwayForEvent:(TXNotificationType)event
{
	NSString *okey = [self keyForEvent:event];

	if (NSObjectIsEmpty(okey)) {
		return NO;
	}

	NSString *key = [okey stringByAppendingString:@" -> Disable While Away"];

	return [_NSUserDefaults() boolForKey:key];
}

+ (void)setDisableWhileAway:(BOOL)value forEvent:(TXNotificationType)event
{
	NSString *okey = [self keyForEvent:event];

	if (NSObjectIsEmpty(okey)) {
		return;
	}

	NSString *key = [okey stringByAppendingString:@" -> Disable While Away"];

	[_NSUserDefaults() setBool:value forKey:key];
}

#pragma mark -
#pragma mark World

+ (NSDictionary *)loadWorld
{
	return [_NSUserDefaults() objectForKey:@"World Controller"];
}

+ (void)saveWorld:(NSDictionary *)value
{
	[_NSUserDefaults() setObject:value forKey:@"World Controller"];
}

#pragma mark -
#pragma mark Window

+ (NSDictionary *)loadWindowStateWithName:(NSString *)name
{
	return [_NSUserDefaults() objectForKey:name];
}

+ (void)saveWindowState:(NSDictionary *)value name:(NSString *)name
{
	[_NSUserDefaults() setObject:value forKey:name];
}

#pragma mark -
#pragma mark Keywords

static NSMutableArray *keywords     = nil;
static NSMutableArray *excludeWords = nil;

+ (void)loadKeywords
{
	if (keywords) {
		[keywords removeAllObjects];
	} else {
		keywords = [NSMutableArray new];
	}

	NSArray *ary = [_NSUserDefaults() objectForKey:@"Highlight List -> Primary Matches"];

	for (NSDictionary *e in ary) {
		NSString *s = e[@"string"];

		if (NSObjectIsNotEmpty(s)) {
			[keywords safeAddObject:s];
		}
	}
}

+ (void)loadExcludeWords
{
	if (excludeWords) {
		[excludeWords removeAllObjects];
	} else {
		excludeWords = [NSMutableArray new];
	}

	NSArray *ary = [_NSUserDefaults() objectForKey:@"Highlight List -> Excluded Matches"];

	for (NSDictionary *e in ary) {
		NSString *s = e[@"string"];

		if (s) [excludeWords safeAddObject:s];
	}
}

+ (void)cleanUpWords:(NSString *)key
{
	NSArray *src = [_NSUserDefaults() objectForKey:key];

	NSMutableArray *ary = [NSMutableArray array];

	for (NSDictionary *e in src) {
		NSString *s = e[@"string"];

		if (NSObjectIsNotEmpty(s)) {
			[ary safeAddObject:s];
		}
	}

	[ary sortUsingSelector:@selector(caseInsensitiveCompare:)];

	NSMutableArray *saveAry = [NSMutableArray array];

	for (NSString *s in ary) {
		NSMutableDictionary *dic = [NSMutableDictionary dictionary];

		dic[@"string"] = s;

		[saveAry safeAddObject:dic];
	}

	[_NSUserDefaults() setObject:saveAry forKey:key];
	[_NSUserDefaults() synchronize];
}

+ (void)cleanUpWords
{
	[self cleanUpWords:@"Highlight List -> Primary Matches"];
	[self cleanUpWords:@"Highlight List -> Excluded Matches"];
}

+ (NSArray *)keywords
{
	return keywords;
}

+ (NSArray *)excludeWords
{
	return excludeWords;
}

#pragma mark -
#pragma mark Start/Run Time Monitoring

static NSInteger startUpTime = 0;
static NSInteger totalRunTime = 0;

+ (NSInteger)startTime
{
	return startUpTime;
}

+ (NSInteger)totalRunTime
{
	totalRunTime  = [_NSUserDefaults() integerForKey:@"TXRunTime"];
	totalRunTime += [NSDate secondsSinceUnixTimestamp:startUpTime];

	return totalRunTime;
}

+ (void)updateTotalRunTime
{
	[_NSUserDefaults() setInteger:[self totalRunTime] forKey:@"TXRunTime"];
}

#pragma mark -
#pragma mark Key-Value Observing

+ (void)observeValueForKeyPath:(NSString *)key ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if ([key isEqualToString:@"Highlight List -> Primary Matches"]) {
		[self loadKeywords];
	} else if ([key isEqualToString:@"Highlight List -> Excluded Matches"]) {
		[self loadExcludeWords];
	}
}

#pragma mark -
#pragma mark Initialization

+ (void)defaultIRCClientSheetCallback:(TLOPopupPromptReturnType)returnCode
{
	if (returnCode == TLOPopupPromptReturnPrimaryType) {
		NSString *bundleID = [TPCPreferences applicationBundleIdentifier];

		OSStatus changeResult;

		changeResult = LSSetDefaultHandlerForURLScheme((__bridge CFStringRef)@"irc",
													   (__bridge CFStringRef)(bundleID));

		changeResult = LSSetDefaultHandlerForURLScheme((__bridge CFStringRef)@"ircs",
													   (__bridge CFStringRef)(bundleID));

#pragma unused(changeResult)
	}
}

+ (void)defaultIRCClientPrompt:(BOOL)forced
{
	[NSThread sleepForTimeInterval:1.5];

	NSURL *baseURL = [NSURL URLWithString:@"irc:"];

    CFURLRef appURL = NULL;
    OSStatus status = LSGetApplicationForURL((__bridge CFURLRef)baseURL, kLSRolesAll, NULL, &appURL);

	if (status == noErr) {
		NSBundle *mainBundle = [NSBundle mainBundle];
		NSBundle *baseBundle = [NSBundle bundleWithURL:CFBridgingRelease(appURL)];

		if ([[baseBundle bundleIdentifier] isNotEqualTo:[mainBundle bundleIdentifier]] || forced) {
			TLOPopupPrompts *prompt = [TLOPopupPrompts new];

			[prompt sheetWindowWithQuestion:[NSApp keyWindow]
									 target:self
									 action:@selector(defaultIRCClientSheetCallback:)
									   body:TXTLS(@"SetAsDefaultIRCClientPromptMessage")
									  title:TXTLS(@"SetAsDefaultIRCClientPromptTitle")
							  defaultButton:TXTLS(@"YesButton")
							alternateButton:TXTLS(@"NoButton")
								otherButton:nil
							 suppressionKey:@"default_irc_client"
							suppressionText:nil];
		}
	}
}

+ (void)initPreferences
{
	NSInteger numberOfRuns = 0;

	numberOfRuns  = [_NSUserDefaults() integerForKey:@"TXRunCount"];
	numberOfRuns += 1;

	[_NSUserDefaults() setInteger:numberOfRuns forKey:@"TXRunCount"];

#ifndef TEXTUAL_TRIAL_BINARY
	if (numberOfRuns >= 2) {
		[self.invokeInBackgroundThread defaultIRCClientPrompt:NO];
	}
#endif

	startUpTime = [NSDate epochTime];

	// ====================================================== //

	NSMutableDictionary *d = [NSMutableDictionary dictionary];

	[d setBool:YES forKey:@"AutomaticallyAddScrollbackMarker"];
	[d setBool:YES forKey:@"ConfirmApplicationQuit"];
	[d setBool:YES forKey:@"DisableNotificationsForActiveWindow"];
	[d setBool:YES forKey:@"DisplayDockBadges"];
	[d setBool:YES forKey:@"DisplayEventInLogView -> Join, Part, Quit"];
	[d setBool:YES forKey:@"DisplayMainWindowWithAntialiasing"];
	[d setBool:YES forKey:@"DisplayServerMessageOfTheDayOnConnect"];
	[d setBool:YES forKey:@"DisplayUserListNoModeSymbol"];
	[d setBool:YES forKey:@"FocusSelectionOnMessageCommandExecution"];
	[d setBool:YES forKey:@"LogHighlights"];
	[d setBool:YES forKey:@"ProcessChannelModesOnJoin"];
	[d setBool:YES forKey:@"ReplyUnignoredExternalCTCPRequests"];
	[d setBool:YES forKey:@"TextFieldAutomaticGrammarCheck"];
	[d setBool:YES forKey:@"TextFieldAutomaticSpellCheck"];
	[d setBool:YES forKey:@"TrackConversationsWithColorHashing"];
	[d setBool:YES forKey:@"TrackNicknameHighlightsOfLocalUser"];
	[d setBool:YES forKey:@"WebKitDeveloperExtras"];
	[d setBool:YES forKey:@"NotificationType -> Highlight -> Enabled"];
	[d setBool:YES forKey:@"NotificationType -> Address Bok Match -> Enabled"];
	[d setBool:YES forKey:@"NotificationType -> Private Message (New) -> Enabled"];

	d[@"NotificationType -> Highlight -> Sound"] = @"Glass";
	d[@"ScanForIRCopAlertInServerNoticesMatch"] = @"ircop alert";

	d[@"DefaultIdentity -> Nickname"] = @"Guest";
	d[@"DefaultIdentity -> Username"] = @"textual";
	d[@"DefaultIdentity -> Realname"] = @"Textual User";

	d[@"IRCopDefaultLocalizaiton -> Shun Reason"] = TXTLS(@"ShunReason");
	d[@"IRCopDefaultLocalizaiton -> Kill Reason"] = TXTLS(@"KillReason");
	d[@"IRCopDefaultLocalizaiton -> G:Line Reason"] = TXTLS(@"GlineReason");

	d[@"Theme -> Name"] = TXDefaultTextualLogStyle;
	d[@"Theme -> Font Name"] = TXDefaultTextualLogFont;
	d[@"Theme -> Nickname Format"] = TXLogLineUndefinedNicknameFormat;
	d[@"Theme -> Timestamp Format"] = TXDefaultTextualTimestampFormat;

	d[@"LogTranscriptDestination"] = @"~/Documents/Textual Logs";

	d[@"ChannelOperatorDefaultLocalization -> Kick Reason"] = TXTLS(@"KickReason");

	[d setInteger:2										forKey:@"AutojoinMaximumChannelJoinCount"];
	[d setInteger:300									forKey:@"ScrollbackMaximumLineCount"];
	[d setInteger:300									forKey:@"InlineMediaScalingWidth"];
	[d setInteger:TXTabKeyActionNickCompleteType		forKey:@"Keyboard -> Tab Key Action"];
	[d setInteger:TXCmdWShortcutCloseWindowType			forKey:@"Keyboard -> Command+W Action"];
	[d setInteger:TXNicknameHighlightExactMatchType		forKey:@"NicknameHighlightMatchingType"];
	[d setInteger:TXHostmaskBanWHAINNFormat				forKey:@"DefaultBanCommandHostmaskFormat"];
	[d setInteger:TXNoticeSendServerConsoleType			forKey:@"DestinationOfNonserverNotices"];
	[d setInteger:TXUserDoubleClickQueryAction			forKey:@"UserListDoubleClickAction"];

	[d setDouble:12.0 forKey:@"Theme -> Font Size"];
	[d setDouble:1.0  forKey:@"MainWindowTransparencyLevel"];

	// ====================================================== //

	[TPCPreferencesMigrationAssistant convertExistingGlobalPreferences];

	[_NSUserDefaults() registerDefaults:d];

	[_NSUserDefaults() addObserver:(id)self forKeyPath:@"Highlight List -> Primary Matches"  options:NSKeyValueObservingOptionNew context:NULL];
	[_NSUserDefaults() addObserver:(id)self forKeyPath:@"Highlight List -> Excluded Matches" options:NSKeyValueObservingOptionNew context:NULL];

	systemVersionPlist = [NSDictionary dictionaryWithContentsOfFile:@"/System/Library/CoreServices/ServerVersion.plist"];

	if (NSObjectIsEmpty(systemVersionPlist)) {
		systemVersionPlist = [NSDictionary dictionaryWithContentsOfFile:@"/System/Library/CoreServices/SystemVersion.plist"];
	}

	if (NSObjectIsEmpty(systemVersionPlist)) {
		exit(10);
	}

	[self loadKeywords];
	[self loadExcludeWords];
	[self populateCommandIndex];

	/* Sandbox Check */

	[_NSUserDefaults() setBool:[TPCPreferences sandboxEnabled]						forKey:@"Security -> Sandbox Enabled"];
	[_NSUserDefaults() setBool:[TPCPreferences securityScopedBookmarksAvailable]	forKey:@"Security -> Scoped Bookmarks Available"];

	/* Font Check */

	if ([NSFont fontIsAvailable:[TPCPreferences themeChannelViewFontName]] == NO) {
		[_NSUserDefaults() setObject:TXDefaultTextualLogFont forKey:@"Theme -> Font Name"];
	}

	/* Theme Check */

	NSString *themeName = [TPCViewTheme extractThemeName:[TPCPreferences themeName]];
	NSString *themePath;

	themePath = [TPCPreferences customThemeFolderPath];
	themePath = [themePath stringByAppendingPathComponent:themeName];

	if ([_NSFileManager() fileExistsAtPath:themePath] == NO) {
		themePath = [TPCPreferences bundledThemeFolderPath];
        themePath = [themePath stringByAppendingPathComponent:themeName];

        if ([_NSFileManager() fileExistsAtPath:themePath] == NO) {
            [_NSUserDefaults() setObject:TXDefaultTextualLogStyle forKey:@"Theme -> Name"];
        } else {
            NSString *newName = [NSString stringWithFormat:@"resource:%@", themeName];
			
            [_NSUserDefaults() setObject:newName forKey:@"Theme -> Name"];
        }
	}
}

+ (void)sync
{
	[_NSUserDefaults() synchronize];
}

@end
