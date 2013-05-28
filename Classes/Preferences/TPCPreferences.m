/* ********************************************************************* 
       _____        _               _    ___ ____   ____
      |_   _|___  _| |_ _   _  __ _| |  |_ _|  _ \ / ___|
       | |/ _ \ \/ / __| | | |/ _` | |   | || |_) | |
       | |  __/>  <| |_| |_| | (_| | |   | ||  _ <| |___
       |_|\___/_/\_\\__|\__,_|\__,_|_|  |___|_| \_\\____|

 Copyright (c) 2010 — 2013 Codeux Software & respective contributors.
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
#import "BuildConfig.h"

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

	IRCUserAccessibleCommandIndexMap = @[ // Open Key: 5098
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
		@[@"unload_plugins",			@"UNLOAD_PLUGINS",		@(5074),		@(YES)],
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
	NSArray *searchPath = [self IRCCommandIndex:isPublic];

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
	return [self indexOfIRCommand:command publicSearch:YES];
}

+ (NSInteger)indexOfIRCommand:(NSString *)command publicSearch:(BOOL)isPublic
{
	NSArray *searchPath = [self IRCCommandIndex:isPublic];

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
	return [RZMainScreen() runningInHighResolutionMode];
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

+ (NSString *)customScriptFolderPath
{
	NSString *dest = [[self applicationSupportFolderPath] stringByAppendingPathComponent:@"/Scripts/"];

	if ([RZFileManager() fileExistsAtPath:dest] == NO) {
        /* Starting with Mountain Lion Apple has created a folder that users can place scripts within 
         that will allow them to run outside of the Mac OS sandbox. Starting with version of 3.0.0 of
         Textual, we will default our Scripts folder path to this location and only create a symbolic
         link to the real folder in our custom location so that users can follow it there. 
         
         The new folder only works on Mountain Lion so we still have to check which OS we are on before
         deciding whether to create an actual folder or symbolic link. */
        
        if ([self featureAvailableToOSXMountainLion]) {
            [RZFileManager() createSymbolicLinkAtPath:dest withDestinationPath:[self systemUnsupervisedScriptFolderPath] error:NULL];
        } else {
            [RZFileManager() createDirectoryAtPath:dest withIntermediateDirectories:YES attributes:nil error:NULL];
        }
	}

	return dest;
}

+ (NSString *)customThemeFolderPath
{
	NSString *dest = [[self applicationSupportFolderPath] stringByAppendingPathComponent:@"/Styles/"];

	if ([RZFileManager() fileExistsAtPath:dest] == NO) {
		[RZFileManager() createDirectoryAtPath:dest withIntermediateDirectories:YES attributes:nil error:NULL];
	}

	return dest;
}

+ (NSString *)customExtensionFolderPath
{
	NSString *dest = [[self applicationSupportFolderPath] stringByAppendingPathComponent:@"/Extensions/"];

	if ([RZFileManager() fileExistsAtPath:dest] == NO) {
		[RZFileManager() createDirectoryAtPath:dest withIntermediateDirectories:YES attributes:nil error:NULL];
	}

	return dest;
}

+ (NSString *)bundledScriptFolderPath
{
	return [[self applicationResourcesFolderPath] stringByAppendingPathComponent:@"/Scripts/"];
}

+ (NSString *)bundledThemeFolderPath
{
	return [[self applicationResourcesFolderPath] stringByAppendingPathComponent:@"/Styles/"];
}

+ (NSString *)bundledExtensionFolderPath
{
	return [[self applicationResourcesFolderPath] stringByAppendingPathComponent:@"/Extensions/"];
}

+ (NSString *)applicationResourcesFolderPath
{
	return [RZMainBundle() resourcePath];
}

+ (NSString *)applicationBundlePath
{
	return [RZMainBundle() bundlePath];
}

+ (NSString *)systemUnsupervisedScriptFolderPath
{
	if ([self featureAvailableToOSXMountainLion]) {
		static NSString *path = NSStringEmptyPlaceholder;
		
		static dispatch_once_t onceToken;

		dispatch_once(&onceToken, ^{
			@autoreleasepool {
				NSArray *searchArray = NSSearchPathForDirectoriesInDomains(NSApplicationScriptsDirectory, NSUserDomainMask, YES);

				if (NSObjectIsNotEmpty(searchArray)) {
					path = [searchArray[0] copy];
				}
			}

			DebugLogToConsole(@"NSApplicationScriptsDirectory = \"%@\"", path);
		});

		return path;
	}

	/* We return an empty string instead of nil because
	 the result of this method may be inserted into an 
	 array and a nil value would throw an exception. */
	
	return NSStringEmptyPlaceholder;
}

#pragma mark -
#pragma mark Logging

static NSURL *transcriptFolderResolvedBookmark;

+ (void)startUsingTranscriptFolderSecurityScopedBookmark
{
	// URLByResolvingBookmarkData throws some weird shit during shutdown.
	// We're just going to loose whatever long we were wanting to save.
	// Probably the disconnect message. Oh well.
	if (self.masterController.terminating) {
		return;
	}
	
	NSData *bookmark = [RZUserDefaults() dataForKey:@"LogTranscriptDestinationSecurityBookmark"];

	NSObjectIsEmptyAssert(bookmark);

	NSError *resolveError;

	NSURL *resolvedBookmark = [NSURL URLByResolvingBookmarkData:bookmark
														options:NSURLBookmarkResolutionWithSecurityScope
												  relativeToURL:nil
											bookmarkDataIsStale:NO
														  error:&resolveError];

	if (resolveError) {
		LogToConsole(@"Error creating bookmark for URL: %@", [resolveError localizedDescription]);
	} else {
		if (transcriptFolderResolvedBookmark) {
			[self stopUsingTranscriptFolderSecurityScopedBookmark];
		}

		 transcriptFolderResolvedBookmark = resolvedBookmark;
		[transcriptFolderResolvedBookmark startAccessingSecurityScopedResource];  
	}
}

+ (void)stopUsingTranscriptFolderSecurityScopedBookmark
{
	NSObjectIsEmptyAssert(transcriptFolderResolvedBookmark);

	[transcriptFolderResolvedBookmark stopAccessingSecurityScopedResource];

	transcriptFolderResolvedBookmark = nil;
}

#pragma mark -

+ (NSString *)transcriptFolder
{
	if (NSObjectIsEmpty(transcriptFolderResolvedBookmark)) {
		[self startUsingTranscriptFolderSecurityScopedBookmark];
	} 

	return [transcriptFolderResolvedBookmark path];
}

+ (void)setTranscriptFolder:(id)value
{
	[self stopUsingTranscriptFolderSecurityScopedBookmark];

	[RZUserDefaults() setObject:value forKey:@"LogTranscriptDestinationSecurityBookmark"];
}

#pragma mark -
#pragma mark Sandbox Check

+ (BOOL)sandboxEnabled
{
	NSString *suffix = [NSString stringWithFormat:@"Containers/%@/Data", [self applicationBundleIdentifier]];

	return [NSHomeDirectory() hasSuffix:suffix];
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

+ (NSString *)IRCopAlertMatch
{
	return [RZUserDefaults() objectForKey:@"ScanForIRCopAlertInServerNoticesMatch"];
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
	TXMasterController *master = [self masterController];
	
	if (master.themeController.customSettings.forceInvertSidebarColors) {
		return YES;
	}

	return [RZUserDefaults() boolForKey:@"InvertSidebarColors"];
}

+ (BOOL)hideMainWindowSegmentedController
{
	return [RZUserDefaults() boolForKey:@"DisableMainWindowSegmentedController"];
}

+ (BOOL)trackConversations
{
	return [RZUserDefaults() boolForKey:@"TrackConversationsWithColorHashing"];
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

+ (BOOL)disableNicknameColorHashing
{
	return [RZUserDefaults() boolForKey:@"DisableRemoteNicknameColorHashing"];
}

+ (BOOL)useLargeFontForSidebars
{
	return [RZUserDefaults() boolForKey:@"UseLargeFontForSidebars"];
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

+ (BOOL)handleIRCopAlerts
{
	return [RZUserDefaults() boolForKey:@"ScanForIRCopAlertInServerNotices"];
}

+ (BOOL)handleServerNotices
{
	return [RZUserDefaults() boolForKey:@"ProcessServerNoticesForIRCop"];
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

+ (BOOL)nickAllConnections
{
	return [RZUserDefaults() boolForKey:@"ApplyCommandToAllConnections -> nick"];
}

+ (BOOL)confirmQuit
{
	return [RZUserDefaults() boolForKey:@"ConfirmApplicationQuit"];
}

+ (BOOL)processChannelModes
{
	return [RZUserDefaults() boolForKey:@"ProcessChannelModesOnJoin"];
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

+ (BOOL)stopGrowlOnActive
{
	return [RZUserDefaults() boolForKey:@"DisableNotificationsForActiveWindow"];
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

#pragma mark -
#pragma mark Theme

+ (NSString *)themeName
{
	return [RZUserDefaults() objectForKey:@"Theme -> Name"];
}

+ (void)setThemeName:(NSString *)value
{
	[RZUserDefaults() setObject:value forKey:@"Theme -> Name"];
}

+ (NSString *)themeChannelViewFontName
{
	return [RZUserDefaults() objectForKey:@"Theme -> Font Name"];
}

+ (void)setThemeChannelViewFontName:(NSString *)value
{
	[RZUserDefaults() setObject:value forKey:@"Theme -> Font Name"];
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
	return [NSFont fontWithName:[self themeChannelViewFontName]
						   size:[self themeChannelViewFontSize]];
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

+ (NSInteger)inlineImagesMaxWidth
{
	return [RZUserDefaults() integerForKey:@"InlineMediaScalingWidth"];
}

+ (void)setInlineImagesMaxWidth:(NSInteger)value
{
	[RZUserDefaults() setInteger:value forKey:@"InlineMediaScalingWidth"];
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
		default: { return nil; }
	}

	return nil;
}

+ (NSString *)keyForEvent:(TXNotificationType)event
{
	switch (event) {
		case TXNotificationAddressBookMatchType:	{ return @"NotificationType -> Address Bok Match";				}
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
		default: { return nil; }
	}

	return nil;
}

+ (NSString *)soundForEvent:(TXNotificationType)event
{
	NSString *okey = [self keyForEvent:event];

	NSObjectIsEmptyAssertReturn(okey, nil);

	NSString *key = [okey stringByAppendingString:@" -> Sound"];

	return [RZUserDefaults() objectForKey:key];
}

+ (void)setSound:(NSString *)value forEvent:(TXNotificationType)event
{
	NSString *okey = [self keyForEvent:event];

	NSObjectIsEmptyAssert(okey);

	NSString *key = [okey stringByAppendingString:@" -> Sound"];

	[RZUserDefaults() setObject:value forKey:key];
}

+ (BOOL)growlEnabledForEvent:(TXNotificationType)event
{
	NSString *okey = [self keyForEvent:event];

	NSObjectIsEmptyAssertReturn(okey, NO);

	NSString *key = [okey stringByAppendingString:@" -> Enabled"];

	return [RZUserDefaults() boolForKey:key];
}

+ (void)setGrowlEnabled:(BOOL)value forEvent:(TXNotificationType)event
{
	NSString *okey = [self keyForEvent:event];

	NSObjectIsEmptyAssert(okey);

	NSString *key = [okey stringByAppendingString:@" -> Enabled"];

	[RZUserDefaults() setBool:value forKey:key];
}

+ (BOOL)disabledWhileAwayForEvent:(TXNotificationType)event
{
	NSString *okey = [self keyForEvent:event];

	NSObjectIsEmptyAssertReturn(okey, NO);

	NSString *key = [okey stringByAppendingString:@" -> Disable While Away"];

	return [RZUserDefaults() boolForKey:key];
}

+ (void)setDisabledWhileAway:(BOOL)value forEvent:(TXNotificationType)event
{
	NSString *okey = [self keyForEvent:event];

	NSObjectIsEmptyAssert(okey);

	NSString *key = [okey stringByAppendingString:@" -> Disable While Away"];

	[RZUserDefaults() setBool:value forKey:key];
}

+ (BOOL)speakEvent:(TXNotificationType)event
{
	NSString *okey = [self keyForEvent:event];

	NSObjectIsEmptyAssertReturn(okey, NO);

	NSString *key = [okey stringByAppendingString:@" -> Speak"];

	return [RZUserDefaults() boolForKey:key];
}

+ (void)setEventIsSpoken:(BOOL)value forEvent:(TXNotificationType)event
{
	NSString *okey = [self keyForEvent:event];

	NSObjectIsEmptyAssert(okey);

	NSString *key = [okey stringByAppendingString:@" -> Speak"];

	[RZUserDefaults() setBool:value forKey:key];
}

#pragma mark -
#pragma mark World

+ (NSDictionary *)loadWorld
{
	return [RZUserDefaults() objectForKey:@"World Controller"];
}

+ (void)saveWorld:(NSDictionary *)value
{
	[RZUserDefaults() setObject:value forKey:@"World Controller"];
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
	[self cleanUpKeywords:@"Highlight List -> Primary Matches"];
	[self cleanUpKeywords:@"Highlight List -> Excluded Matches"];
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
	NSTimeInterval appStartTime = [self timeIntervalSinceApplicationLaunch];

	return ([RZUserDefaults() integerForKey:@"TXRunTime"] + appStartTime);
}

+ (void)saveTimeIntervalSinceApplicationInstall
{
	[RZUserDefaults() setInteger:[self timeIntervalSinceApplicationInstall] forKey:@"TXRunTime"];
}

+ (NSInteger)applicationRunCount
{
	return [RZUserDefaults() integerForKey:@"TXRunCount"];
}

+ (void)updateApplicationRunCount
{
	[RZUserDefaults() setInteger:([self applicationRunCount] + 1) forKey:@"TXRunCount"];
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
	NSRect usable = RZMainScreen().visibleFrame;

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
		[self loadMatchKeywords];
	} else if ([key isEqualToString:@"Highlight List -> Excluded Matches"]) {
		[self loadExcludeKeywords];
	}
}

#pragma mark -
#pragma mark Initialization

+ (void)defaultIRCClientSheetCallback:(TLOPopupPromptReturnType)returnCode
{
	if (returnCode == TLOPopupPromptReturnPrimaryType) {
		NSString *bundleID = [self applicationBundleIdentifier];

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

		return [baseBundle.bundleIdentifier isEqualTo:[self applicationBundleIdentifier]];
	}

	return NO;
}

+ (void)defaultIRCClientPrompt:(BOOL)forced
{
	if ([self isDefaultIRCClient] == NO || forced) {
		TLOPopupPrompts *prompt = [TLOPopupPrompts new];

        NSString *supkey = @"default_irc_client";

        if (forced) {
            supkey = nil;
        }
        
		[prompt sheetWindowWithQuestion:[NSApp keyWindow]
								 target:self
								 action:@selector(defaultIRCClientSheetCallback:)
								   body:TXTLS(@"SetAsDefaultIRCClientPromptMessage")
								  title:TXTLS(@"SetAsDefaultIRCClientPromptTitle")
						  defaultButton:TXTLS(@"YesButton")
						alternateButton:TXTLS(@"NoButton")
							otherButton:nil
						 suppressionKey:supkey
						suppressionText:nil];
	}
}

+ (void)initPreferences
{
	[self updateApplicationRunCount];

#ifndef TEXTUAL_TRIAL_BINARY
	NSInteger numberOfRuns = [self applicationRunCount];

	if (numberOfRuns >= 2) {
		[self.invokeInBackgroundThread defaultIRCClientPrompt:NO];
	}
#endif

	// ====================================================== //

	NSMutableDictionary *d = [NSMutableDictionary dictionary];

	d[@"AutomaticallyAddScrollbackMarker"]				= @(YES);
	d[@"ConfirmApplicationQuit"]						= @(YES);
	d[@"ChannelNavigationIsServerSpecific"]				= @(YES);
	d[@"DisableNotificationsForActiveWindow"]			= @(YES);
	d[@"DisplayDockBadges"]								= @(YES);
	d[@"DisplayEventInLogView -> Join, Part, Quit"]		= @(YES);
	d[@"DisplayMainWindowWithAntialiasing"]				= @(YES);
	d[@"DisplayServerMessageOfTheDayOnConnect"]			= @(YES);
	d[@"DisplayUserListNoModeSymbol"]					= @(YES);
	d[@"FocusSelectionOnMessageCommandExecution"]		= @(YES);
	d[@"LogHighlights"]									= @(YES);
	d[@"ProcessChannelModesOnJoin"]						= @(YES);
	d[@"ReplyUnignoredExternalCTCPRequests"]			= @(YES);
	d[@"TrackConversationsWithColorHashing"]			= @(YES);
	d[@"TrackNicknameHighlightsOfLocalUser"]			= @(YES);
	d[@"WebKitDeveloperExtras"]							= @(YES);

	/* Settings for the NSTextView context menu. */
	d[@"TextFieldAutomaticSpellCheck"]					= @(YES);
	d[@"TextFieldAutomaticGrammarCheck"]				= @(YES);
    d[@"TextFieldAutomaticSpellCorrection"]             = @(NO);
	d[@"TextFieldSmartCopyPaste"]						= @(YES);
	d[@"TextFieldTextReplacement"]						= @(YES);

	/* This controls the two-finger swipe sensitivity. The lower it is, the more
		sensitive the swipe left/right detection is. The higher it is, the less 
		sensitive the swipe detection is. <= 0 means off. */
	d[@"SwipeMinimumLength"]							= @(30);

	d[@"NotificationType -> Highlight -> Enabled"]				= @(YES);
	d[@"NotificationType -> Highlight -> Sound"]				= @"Glass";

	d[@"NotificationType -> Private Message (New) -> Enabled"]	= @(YES);
	d[@"NotificationType -> Private Message (New) -> Sound"]	= @"Submarine";
	
	d[@"NotificationType -> Private Message -> Enabled"]		= @(YES);
	d[@"NotificationType -> Private Message -> Sound"]			= @"Submarine";

	d[@"NotificationType -> Address Bok Match -> Enabled"]		= @(YES);
	d[@"NotificationType -> Private Message (New) -> Enabled"]	= @(YES);
	
	d[@"ScanForIRCopAlertInServerNoticesMatch"]	= @"ircop alert";

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

	d[@"Theme -> Name"]					= TXDefaultTextualLogStyle;
	d[@"Theme -> Font Name"]			= TXDefaultTextualLogFont;
	d[@"Theme -> Nickname Format"]		= TXLogLineUndefinedNicknameFormat;
	d[@"Theme -> Timestamp Format"]		= TXDefaultTextualTimestampFormat;

    d[@"TrackUserAwayStatusMaximumChannelSize"] = @(0);
	d[@"AutojoinMaximumChannelJoinCount"]		= @(2);
	d[@"ScrollbackMaximumLineCount"]			= @(300);
	d[@"InlineMediaScalingWidth"]				= @(300);
	d[@"Keyboard -> Tab Key Action"]			= @(TXTabKeyNickCompleteAction);
	d[@"Keyboard -> Command+W Action"]			= @(TXCommandWKeyCloseWindowAction);
	d[@"NicknameHighlightMatchingType"]			= @(TXNicknameHighlightExactMatchType);
	d[@"DefaultBanCommandHostmaskFormat"]		= @(TXHostmaskBanWHAINNFormat);
	d[@"DestinationOfNonserverNotices"]			= @(TXNoticeSendServerConsoleType);
	d[@"UserListDoubleClickAction"]				= @(TXUserDoubleClickPrivateMessageAction);
	
	d[@"MainWindowTransparencyLevel"]		= @(1.0);
	d[@"Theme -> Font Size"]				= @(12.0);

	// ====================================================== //

	/* The following defaults are defined in here even though they 
	 are part of the System Profiler extension for one reason: crashes.
	 
	 For some reason, which I have yet to understand, calling NSUserDefault
	 registerDefaults: within a plugin works great the first time, but it
	 will crash if the plugin is unloaded and reloaded. The crash only 
	 occurs when a nib is involved. I am assuming there is an issue with
	 the objects part the shared user defaults controller being accessed
	 from within the nib resulting in a crash. Just haven't figured out 
	 the exact details yet. Until then… these go here. */

	d[@"System Profiler Extension -> Feature Disabled -> GPU Model"] = @(YES);
	d[@"System Profiler Extension -> Feature Disabled -> Disk Information"] = @(YES);
	d[@"System Profiler Extension -> Feature Disabled -> Screen Resolution"] = @(YES);

	// ====================================================== //

	[TPCPreferencesMigrationAssistant convertExistingGlobalPreferences];

	[RZUserDefaults() registerDefaults:d];

	[RZUserDefaults() addObserver:(id)self forKeyPath:@"Highlight List -> Primary Matches"  options:NSKeyValueObservingOptionNew context:NULL];
	[RZUserDefaults() addObserver:(id)self forKeyPath:@"Highlight List -> Excluded Matches" options:NSKeyValueObservingOptionNew context:NULL];

	[self loadMatchKeywords];
	[self loadExcludeKeywords];
	[self populateCommandIndex];

	/* Sandbox Check */

	[RZUserDefaults() setBool:[self sandboxEnabled]						forKey:@"Security -> Sandbox Enabled"];

	[RZUserDefaults() setBool:[self featureAvailableToOSXLion]			forKey:@"System —> Running Mac OS Lion Or Newer"];
	[RZUserDefaults() setBool:[self featureAvailableToOSXMountainLion]  forKey:@"System —> Running Mac OS Mountain Lion Or Newer"];

	/* Font Check */

	if ([NSFont fontIsAvailable:[self themeChannelViewFontName]] == NO) {
		[RZUserDefaults() setObject:TXDefaultTextualLogFont forKey:@"Theme -> Font Name"];
	}

	/* Theme Check */

	NSString *themeName = [TPCThemeController extractThemeName:[self themeName]];
	NSString *themeType = [TPCThemeController extractThemeSource:[self themeName]];

    NSString *customPath = [[self customThemeFolderPath] stringByAppendingPathComponent:themeName];
    NSString *bundlePath = [[self bundledThemeFolderPath] stringByAppendingPathComponent:themeName];

    if ([RZFileManager() fileExistsAtPath:customPath] == NO) {
        if ([RZFileManager() fileExistsAtPath:bundlePath] == NO) {
            [self setThemeName:TXDefaultTextualLogStyle];
        } else {
            if ([themeType isEqualToString:TPCThemeControllerBundledStyleNameBasicPrefix] == NO) {
                NSString *newName = [TPCThemeController buildResourceFilename:themeName];

                [self setThemeName:newName];
            }
        }
    }
}

#pragma mark -
#pragma mark NSTextView Preferences

+ (BOOL)textFieldAutomaticSpellCheck
{
	return [RZUserDefaults() boolForKey:@"TextFieldAutomaticSpellCheck"];
}

+ (void)setTextFieldAutomaticSpellCheck:(BOOL)value
{
	if (NSDissimilarObjects(value, [self textFieldAutomaticSpellCheck])) {
		[RZUserDefaults() setBool:value forKey:@"TextFieldAutomaticSpellCheck"];
	}
}

+ (BOOL)textFieldAutomaticGrammarCheck
{
	return [RZUserDefaults() boolForKey:@"TextFieldAutomaticGrammarCheck"];
}

+ (void)setTextFieldAutomaticGrammarCheck:(BOOL)value
{
	if (NSDissimilarObjects(value, [self textFieldAutomaticGrammarCheck])) {
		[RZUserDefaults() setBool:value forKey:@"TextFieldAutomaticGrammarCheck"];
	}
}

+ (BOOL)textFieldAutomaticSpellCorrection
{
	return [RZUserDefaults() boolForKey:@"TextFieldAutomaticSpellCorrection"];
}

+ (void)setTextFieldAutomaticSpellCorrection:(BOOL)value
{
	if (NSDissimilarObjects(value, [self textFieldAutomaticSpellCorrection])) {
		[RZUserDefaults() setBool:value forKey:@"TextFieldAutomaticSpellCorrection"];
	}
}

+ (BOOL)textFieldSmartCopyPaste
{
	return [RZUserDefaults() boolForKey:@"TextFieldSmartCopyPaste"];
}

+ (void)setTextFieldSmartCopyPaste:(BOOL)value
{
	if (NSDissimilarObjects(value, [self textFieldSmartCopyPaste])) {
		[RZUserDefaults() setBool:value forKey:@"TextFieldSmartCopyPaste"];
	}
}

+ (BOOL)textFieldSmartQuotes
{
	return [RZUserDefaults() boolForKey:@"TextFieldSmartQuotes"];
}

+ (void)setTextFieldSmartQuotes:(BOOL)value
{
	if (NSDissimilarObjects(value, [self textFieldSmartQuotes])) {
		[RZUserDefaults() setBool:value forKey:@"TextFieldSmartQuotes"];
	}
}

+ (BOOL)textFieldSmartDashes
{
	return [RZUserDefaults() boolForKey:@"TextFieldSmartDashes"];
}

+ (void)setTextFieldSmartDashes:(BOOL)value
{
	if (NSDissimilarObjects(value, [self textFieldSmartDashes])) {
		[RZUserDefaults() setBool:value forKey:@"TextFieldSmartDashes"];
	}
}

+ (BOOL)textFieldSmartLinks
{
	return [RZUserDefaults() boolForKey:@"TextFieldSmartLinks"];
}

+ (void)setTextFieldSmartLinks:(BOOL)value
{
	if (NSDissimilarObjects(value, [self textFieldSmartLinks])) {
		[RZUserDefaults() setBool:value forKey:@"TextFieldSmartLinks"];
	}
}

+ (BOOL)textFieldDataDetectors
{
	return [RZUserDefaults() boolForKey:@"TextFieldDataDetectors"];
}

+ (void)setTextFieldDataDetectors:(BOOL)value
{
	if (NSDissimilarObjects(value, [self textFieldDataDetectors])) {
		[RZUserDefaults() setBool:value forKey:@"TextFieldDataDetectors"];
	}
}

+ (BOOL)textFieldTextReplacement
{
	return [RZUserDefaults() boolForKey:@"TextFieldTextReplacement"];
}

+ (void)setTextFieldTextReplacement:(BOOL)value
{
	if (NSDissimilarObjects(value, [self textFieldTextReplacement])) {
		[RZUserDefaults() setBool:value forKey:@"TextFieldTextReplacement"];
	}
}

@end
