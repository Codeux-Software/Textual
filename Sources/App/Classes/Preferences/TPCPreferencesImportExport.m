/* *********************************************************************
 *                  _____         _               _
 *                 |_   _|____  _| |_ _   _  __ _| |
 *                   | |/ _ \ \/ / __| | | |/ _` | |
 *                   | |  __/>  <| |_| |_| | (_| | |
 *                   |_|\___/_/\_\\__|\__,_|\__,_|_|
 *
 * Copyright (c) 2010 - 2015 Codeux Software, LLC & respective contributors.
 *       Please see Acknowledgements.pdf for additional information.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 *  * Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 *  * Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *  * Neither the name of Textual, "Codeux Software, LLC", nor the
 *    names of its contributors may be used to endorse or promote products
 *    derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 *
 *********************************************************************** */

#import "IRCClientConfig.h"
#import "IRCClientPrivate.h"
#import "IRCWorldPrivate.h"
#import "IRCWorldPrivateCloudExtension.h"
#import "TXMasterController.h"
#import "TDCAlert.h"
#import "TLOLanguagePreferences.h"
#import "TPCPreferencesLocalPrivate.h"
#import "TPCPreferencesReload.h"
#import "TPCPreferencesUserDefaultsLocal.h"
#import "TVCMainWindowPrivate.h"
#import "TVCMainWindowLoadingScreen.h"
#import "TVCServerList.h"
#import "TPCPreferencesImportExportPrivate.h"

NS_ASSUME_NONNULL_BEGIN

@implementation TPCPreferencesImportExport

+ (void)importInWindow:(NSWindow *)window
{
	NSParameterAssert(window != nil);

	[TDCAlert alertSheetWithWindow:window
							  body:TXTLS(@"Prompts[jsh-1a]")
							 title:TXTLS(@"Prompts[itb-3x]")
					 defaultButton:TXTLS(@"Prompts[502-6h]")
				   alternateButton:TXTLS(@"Prompts[qso-2g]")
					   otherButton:nil
				   completionBlock:^(TDCAlertResponse buttonClicked, BOOL suppressed, id underlyingAlert) {
					   [self importPreflight:buttonClicked];
				   }];
}

+ (void)importPreflight:(TDCAlertResponse)buttonPressed
{
	if (buttonPressed != TDCAlertResponseDefaultButton) {
		return;
	}

	NSOpenPanel *d = [NSOpenPanel openPanel];

	d.canChooseFiles = YES;
	d.canChooseDirectories = NO;
	d.canCreateDirectories = NO;
	d.resolvesAliases = YES;
	d.allowsMultipleSelection = NO;

	[d beginWithCompletionHandler:^(NSInteger returnCode) {
		if (returnCode == NSModalResponseOK) {
			NSURL *pathURL = d.URLs[0];

			[self importPostflight:pathURL];
		}
	}];
}

+ (BOOL)importPostflightBackupPreferences
{
	NSString *sourcePath = NSHomeDirectory();

	NSString *basePath = [NSString stringWithFormat:@"/Textual-importBackup-%@.plist", [NSString stringWithUUID]];

	NSString *backupPath = [sourcePath stringByAppendingPathComponent:basePath];

	return [self exportPostflightForPath:backupPath filterJunk:NO];
}

+ (void)importPostflight:(NSURL *)pathURL
{
	XRPerformBlockAsynchronouslyOnMainQueue(^{
		[self _importPostflight:pathURL];
	});
}

+ (void)_importPostflight:(NSURL *)pathURL
{
	/* Create a backup of the old configuration */
	if ([self importPostflightBackupPreferences] == NO) {
		return;
	}

	/* Begin import */
	NSData *fileContents = [NSData dataWithContentsOfURL:pathURL];

	NSError *parseError = nil;

	NSDictionary *propertyList =
	[NSPropertyListSerialization propertyListWithData:fileContents options:NSPropertyListImmutable format:NULL error:&parseError];

	/* Perform actual import if we have the dictionary. */
	if (propertyList == nil) {
		if (parseError) {
			LogToConsoleError("Import failed: %@", parseError.localizedDescription);
		}

		return;
	}

	/* The loading screen is a generic way to show something during import */
	[mainWindowLoadingScreen() showProgressViewWithReason:TXTLS(@"TVCMainWindow[5g1-i9]")];

	[worldController() setIsImportingConfiguration:YES];

	[mainWindowServerList() beginUpdates];

	/* Import data */
	[self importContentsOfDictionary:propertyList reloadPreferences:NO];

	/* Do not push the loading screen right away. Add a little delay to give everything
	 a chance to settle down before presenting the changes to the user. */
	[self performSelectorInCommonModes:@selector(importPostflightCleanup:) withObject:propertyList.allKeys afterDelay:2.0];
}

+ (void)importContentsOfDictionary:(NSDictionary<NSString *, id> *)aDict
{
	[self importContentsOfDictionary:aDict reloadPreferences:YES];
}

+ (void)importContentsOfDictionary:(NSDictionary<NSString *, id> *)aDict reloadPreferences:(BOOL)reloadPreferences
{
	NSParameterAssert(aDict != nil);

	[aDict enumerateKeysAndObjectsUsingBlock:^(NSString *key, id object, BOOL *stop) {
		[self import:object withKey:key];
	}];

	if (reloadPreferences) {
		[TPCPreferences performReloadActionForKeys:aDict.allKeys];
	}
}

+ (void)import:(id)object withKey:(NSString *)key
{
	NSParameterAssert(key != nil);

	if ([key isEqualToString:TPCPreferencesThemeNameDefaultsKey])
	{
		if ([object isKindOfClass:[NSString class]] == NO) {
			return;
		}

		[TPCPreferences setThemeNameWithExistenceCheck:object];
	}
	else if ([key isEqualToString:TPCPreferencesThemeFontNameDefaultsKey])
	{
		if ([object isKindOfClass:[NSString class]] == NO) {
			return;
		}

		[TPCPreferences setThemeChannelViewFontNameWithExistenceCheck:object];
	}
	else if ([key isEqualToString:IRCWorldClientListDefaultsKey])
	{
		if ([object isKindOfClass:[NSArray class]] == NO) {
			return;
		}

		[object enumerateObjectsUsingBlock:^(id object, NSUInteger index, BOOL *stop) {
			[self importClientConfiguration:object isImportedFromCloud:NO];
		}];
	}
	else if ([key isEqualToString:@"World Controller"])
	{
		if ([object isKindOfClass:[NSDictionary class]] == NO) {
			return;
		}

		NSArray<NSDictionary *> *clientList = [object arrayForKey:@"clients"];

		if (clientList) {
			[self import:clientList withKey:IRCWorldClientListDefaultsKey];
		}
	}

#if TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT == 1
	else if ([key hasPrefix:IRCWorldControllerCloudClientItemDefaultsKeyPrefix] ||
			 [key hasPrefix:IRCWorldControllerCloudListOfDeletedClientsDefaultsKey])
	{
		; // Ignore key...
	}
#endif

	else
	{
		[RZUserDefaults() setObject:object forKey:key];
	}
}

+ (void)importClientConfiguration:(NSDictionary<NSString *, id> *)config isImportedFromCloud:(BOOL)isImportedFromCloud
{
	NSParameterAssert(config != nil);

	IRCClientConfig *clientConfig = [[IRCClientConfig alloc] initWithDictionary:config];

	IRCClient *client = [worldController() findClientWithId:clientConfig.uniqueIdentifier];

#if TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT == 1
	if (isImportedFromCloud) {
		if (client && client.config.excludedFromCloudSyncing) {
			return;
		}
	}
#endif

	if (client) {
		if (isImportedFromCloud) {
			[client updateConfigFromTheCloud:clientConfig];
		} else {
			[client updateConfig:clientConfig];
		}
	} else {
		(void)[worldController() createClientWithConfig:clientConfig reload:YES];
	}
}

+ (void)importPostflightCleanup:(NSArray<NSString *> *)changedKeys
{
	[TPCPreferences performReloadActionForKeys:changedKeys];

	[mainWindowServerList() endUpdates];

	[worldController() setIsImportingConfiguration:NO];

	(void)[mainWindow() reloadLoadingScreen];
}

#pragma mark -
#pragma mark Export

+ (BOOL)isKeyNameSupposedToBeIgnored:(NSString *)key
{
	return ([TPCPreferencesUserDefaults keyIsExcludedFromBeingExported:key] ||
			[TPCPreferencesUserDefaults keyIsObsolete:key]);
}

+ (NSDictionary<NSString *, id> *)exportedPreferencesDictionaryForCloud
{
	return [self exportedPreferencesDictionary:YES filterDefaults:NO];
}

+ (NSDictionary<NSString *, id> *)exportedPreferencesDictionary
{
	return [self exportedPreferencesDictionary:YES filterDefaults:YES];
}

+ (NSDictionary<NSString *, id> *)exportedPreferencesDictionary:(BOOL)filterJunk
{
	return [self exportedPreferencesDictionary:filterJunk filterDefaults:filterJunk];
}

+ (NSDictionary<NSString *, id> *)exportedPreferencesDictionary:(BOOL)filterJunk filterDefaults:(BOOL)filterDefaults
{
	/* Combine list of keys to strip */
	NSMutableArray *keysToStrip = [NSMutableArray array];

	NSDictionary *argumentsDomain = [[NSUserDefaults standardUserDefaults] volatileDomainForName:NSArgumentDomain];

	[keysToStrip addObjectsFromArray:argumentsDomain.allKeys];

	if (filterDefaults) {
		NSDictionary *defaultsDomain = [TPCPreferences defaultPreferences];

		[keysToStrip addObjectsFromArray:defaultsDomain.allKeys];
	}

	if (filterJunk) {
		NSDictionary *globalsDomain = [[NSUserDefaults standardUserDefaults] persistentDomainForName:NSGlobalDomain];

		[keysToStrip addObjectsFromArray:globalsDomain.allKeys];
	}

	/* Create mutable copy of preferences and strip keys */
	NSDictionary *exportedPreferences = [RZUserDefaults() dictionaryRepresentation];

	NSMutableDictionary<NSString *, id> *finalDictionary = [exportedPreferences mutableCopy];

	[finalDictionary removeObjectsForKeys:keysToStrip];

	/* Strip keys that must be checked dynamically */
	if (filterJunk) {
		NSSet *keysToStrip2 =
		[finalDictionary keysOfEntriesPassingTest:^BOOL(NSString *key, id object, BOOL *stop) {
			return [self isKeyNameSupposedToBeIgnored:key];
		}];

		[finalDictionary removeObjectsForKeys:keysToStrip2.allObjects];
	}

	return [finalDictionary copy];
}

+ (void)exportInWindow:(NSWindow *)window
{
	NSParameterAssert(window != nil);

	[TDCAlert alertSheetWithWindow:window
							  body:TXTLS(@"Prompts[syp-al]")
							 title:TXTLS(@"Prompts[1fm-up]")
					 defaultButton:TXTLS(@"Prompts[vun-f0]")
				   alternateButton:TXTLS(@"Prompts[qso-2g]")
					   otherButton:nil
				   completionBlock:^(TDCAlertResponse buttonClicked, BOOL suppressed, id underlyingAlert) {
					   [self exportPreflight:buttonClicked];
				   }];
}

+ (void)exportPreflight:(TDCAlertResponse)buttonPressed
{
	if (buttonPressed != TDCAlertResponseDefaultButton) {
		return;
	}

	NSSavePanel *d = [NSSavePanel savePanel];

	d.canCreateDirectories = YES;

	d.nameFieldStringValue = @"TextualPreferences.plist";

	[d beginWithCompletionHandler:^(NSInteger returnCode) {
		if (returnCode == NSModalResponseOK) {
			NSURL *pathURL = d.URL;

			(void)[self exportPostflightForURL:pathURL filterJunk:YES];
		}
	}];
}

+ (BOOL)exportPostflightForPath:(NSString *)path
{
	return [self exportPostflightForPath:path filterJunk:YES];
}

+ (BOOL)exportPostflightForURL:(NSURL *)pathURL
{
	return [self exportPostflightForURL:pathURL filterJunk:YES];
}

+ (BOOL)exportPostflightForPath:(NSString *)path filterJunk:(BOOL)filterJunk
{
	NSParameterAssert(path != nil);

	NSURL *pathURL = [NSURL fileURLWithPath:path];

	return [self exportPostflightForURL:pathURL filterJunk:filterJunk];
}

+ (BOOL)exportPostflightForURL:(NSURL *)pathURL filterJunk:(BOOL)filterJunk
{
	NSParameterAssert(pathURL != nil);

	NSDictionary *exportedPreferences = [self exportedPreferencesDictionary:filterJunk];

	/* The export will be saved as binary. Two reasons: 1) Discourages user from
	 trying to tamper with stuff. 2) Smaller, faster. Mostly #1. */
	NSError *parseError = nil;

	NSData *propertyList =
	[NSPropertyListSerialization dataWithPropertyList:exportedPreferences format:NSPropertyListBinaryFormat_v1_0 options:0 error:&parseError];

	if (propertyList == nil) {
		if (parseError) {
			LogToConsoleError("Error Creating Property List: %@", parseError.localizedDescription);
		}

		return NO;
	}

	BOOL writeResult = [propertyList writeToURL:pathURL atomically:YES];

	if (writeResult == NO) {
		LogToConsoleError("Write failed");

		return NO;
	}

	return YES;
}

@end

NS_ASSUME_NONNULL_END
