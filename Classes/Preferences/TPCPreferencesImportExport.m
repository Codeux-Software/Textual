/* ********************************************************************* 
                  _____         _               _
                 |_   _|____  _| |_ _   _  __ _| |
                   | |/ _ \ \/ / __| | | |/ _` | |
                   | |  __/>  <| |_| |_| | (_| | |
                   |_|\___/_/\_\\__|\__,_|\__,_|_|

 Copyright (c) 2010 - 2015 Codeux Software, LLC & respective contributors.
        Please see Acknowledgements.pdf for additional information.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of Textual and/or "Codeux Software, LLC", nor the 
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

/*
	Everything related to import/export is handled within this class.

	Sheets are used to lock focus to the task at hand.
 */

@implementation TPCPreferencesImportExport

/* -import handles the actual import menu item. */
+ (void)import
{
	TLOPopupPrompts *prompt = [TLOPopupPrompts new];

	[prompt sheetWindowWithQuestion:mainWindow()
							 target:self
							 action:@selector(importPreflight:withOriginalAlert:)
							   body:TXTLS(@"BasicLanguage[1181][2]")
							  title:TXTLS(@"BasicLanguage[1181][1]")
					  defaultButton:TXTLS(@"BasicLanguage[1181][3]")
					alternateButton:BLS(1009)
						otherButton:nil
					 suppressionKey:nil
					suppressionText:nil];
}

/* Master controller internal handles for import. */
+ (void)importPreflight:(TLOPopupPromptReturnType)buttonPressed withOriginalAlert:(NSAlert *)originalAlert
{
	/* What button? */
	if (buttonPressed == TLOPopupPromptReturnPrimaryType) {
		NSOpenPanel *d = [NSOpenPanel openPanel];

		[d setCanChooseFiles:YES];
		[d setResolvesAliases:YES];
		[d setCanChooseDirectories:NO];
		[d setCanCreateDirectories:NO];
		[d setAllowsMultipleSelection:NO];

		[d beginWithCompletionHandler:^(NSInteger returnCode) {
			if (returnCode == NSModalResponseOK) {
				NSURL *pathURL = [d URLs][0];

				[self importPostflight:pathURL];
			}
		}];
	}
}

+ (void)importPostflight:(NSURL *)pathURL
{
	TXPerformBlockAsynchronouslyOnMainQueue(^{
		/* The loading screen is a generic way to show something during import. */
		[mainWindowLoadingScreen() hideAll:NO];
		[mainWindowLoadingScreen() popLoadingConfigurationView];
		
		/* isPopulatingSeeds tells the world to not close the loading screen on state
		 changes when creating new connections. */
		[worldController() setIsPopulatingSeeds:YES];
		
		/* Before we do anything at all, we create a backup of the old configuration. */
		/* We refuse to continue unless that wrote successfully. */
		/* These are stored in the home directory of our container. */
		NSString *basePath = [NSString stringWithFormat:@"/importBackup-%@.plist", [NSString stringWithUUID]];
		
		NSString *backupPath = [NSHomeDirectory() stringByAppendingPathComponent:basePath];
		
		BOOL backupWrite = [self exportPostflightForURL:[NSURL fileURLWithPath:backupPath] filterJunk:NO];
		
		if (backupWrite == NO) {
			LogToConsole(@"Import cancelled. Creation of backup file failed.");
			
			return;
		}
		
		/* Begin import. */
		NSData *rawData = [NSData dataWithContentsOfURL:pathURL];

		NSDictionary *plist = [NSPropertyListSerialization propertyListWithData:rawData
																		options:NSPropertyListImmutable
																		 format:NULL
																		  error:NULL];
		
		/* Perform actual import if we have the dictionary. */
		if (plist) {
			/* Import data. */
			[self importContentsOfDictionary:plist withAutomaticReload:NO];
			
			/* Do not push the loading screen right away. Add a little delay to give everything
			 a chance to settle down before presenting the changes to the user. */
			[self performSelector:@selector(importPostflightCleanup:) withObject:[plist allKeys] afterDelay:2.0];
		} else {
			LogToConsole(@"Import failed. Could not read property list.");
		}
	});
}

/* Conditional for keys that require special processing during the import process. */
+ (BOOL)isKeyNameExcludedFromNormalImportProcess:(NSString *)key
{
	return ([key isEqualToString:IRCWorldControllerDefaultsStorageKey] ||
			
#ifdef TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT
			[key hasPrefix:IRCWorldControllerCloudClientEntryKeyPrefix] ||
			
			[key isEqualToString:IRCWorldControllerCloudDeletedClientsStorageKey] ||
#endif
			
			[key isEqualToString:TPCPreferencesThemeNameDefaultsKey] ||
			[key isEqualToString:TPCPreferencesThemeFontNameDefaultsKey]);
}

+ (void)importContentsOfDictionary:(NSDictionary *)aDict
{
	[self importContentsOfDictionary:aDict withAutomaticReload:YES];
}

+ (void)importContentsOfDictionary:(NSDictionary *)aDict withAutomaticReload:(BOOL)reloadPreferences
{
	/* The expected format of this dictionary should NOT have hashed keys. */
	 //LogToConsole(@"Dictionary to Import: %@", aDict);

	/* Normal import process. */
	[aDict enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
		[self import:obj withKey:key];
	}];

	/* Perform reload for changed keys. */
	if (reloadPreferences) {
		[TPCPreferences performReloadActionForKeyValues:[aDict allKeys]];
	}
}

+ (void)import:(id)obj withKey:(id)key
{
	/* Is it a normal key? */
	if ([self isKeyNameExcludedFromNormalImportProcess:key] == NO) {
		[RZUserDefaults() setObject:obj forKey:key];
	} else {
		if ([key isEqual:TPCPreferencesThemeNameDefaultsKey])
		{
			NSObjectIsKindOfClassAssert(obj, NSString);
			
			[TPCPreferences setThemeNameWithExistenceCheck:obj];
		}
		else if ([key isEqual:TPCPreferencesThemeFontNameDefaultsKey])
		{
			NSObjectIsKindOfClassAssert(obj, NSString);
			
			[TPCPreferences setThemeChannelViewFontNameWithExistenceCheck:obj];
		}
		else if ([key isEqual:IRCWorldControllerDefaultsStorageKey])
		{
			/* It is the world controller! */
			NSObjectIsKindOfClassAssert(obj, NSDictionary);
			
			/* Start import. */
			NSArray *clientList = obj[@"clients"];
			
			NSObjectIsEmptyAssert(clientList);
			
			/* Bleh, let's get this over with. */
			[clientList enumerateObjectsUsingBlock:^(id objd, NSUInteger idx, BOOL *stop) {
				[self importWorldControllerClientConfiguration:objd isCloudBasedImport:NO];
			}];
		}
	}
}

+ (void)importWorldControllerClientConfiguration:(NSDictionary *)client isCloudBasedImport:(BOOL)isCloudImport
{
	/* Validate that shiznet. */
	NSObjectIsEmptyAssert(client);
	
	/* Create a configuration rep. */
	IRCClientConfig *config = [[IRCClientConfig alloc] initWithDictionary:client];
	
	/* Were we able to create new configuration? */
	if (config) {
		/* Try to find any clients matching this value. */
		IRCClient *u = [worldController() findClientById:[config itemUUID]];
		
		/* Handle cloud sync logic. */
#ifdef TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT
		if (isCloudImport) {
			if (u && u.config.excludedFromCloudSyncing) {
				return;
			}
		}
#endif
		
		if (u) {
			if (isCloudImport) {
				[u updateConfigFromTheCloud:config];
			} else {
				[u updateConfig:config];
			}
		} else {
			[worldController() createClient:config reload:YES];
		}
	}
}

+ (void)importPostflightCleanup:(NSArray *)changedKeys
{
	/* Update selection. */
	[mainWindow() setupTree];

	/* Reload preferences. */
	[TPCPreferences performReloadActionForKeyValues:changedKeys];

	/* Finish seeding. */
	[worldController() setIsPopulatingSeeds:NO];

	/* Pop loading screen. */
	[mainWindow() reloadLoadingScreen];
}

#pragma mark -
#pragma mark Export

/* Conditional for matching whether we want a key in the exported dictionary. */
+ (BOOL)isKeyNameSupposedToBeIgnored:(NSString *)key
{
	if ([TPCPreferencesUserDefaults keyIsExcludedFromGroupContainer:key] ||
		
		[key hasPrefix:@"File Transfers -> File Transfer Download Folder Bookmark"]		||		/* Textual owned prefix. */

		[key hasPrefix:@"LogTranscriptDestinationSecurityBookmark"] ||				/* Textual owned prefix. */

		[key hasPrefix:TPCPreferencesThemeNameMissingLocallyDefaultsKey] ||			/* Textual owned prefix. */
		[key hasPrefix:TPCPreferencesThemeFontNameMissingLocallyDefaultsKey])		/* Textual owned prefix. */
	{
		return YES; // Key has an ignored prefix.
	}
	else
	{
		return NO;
	}
}

+ (NSDictionary *)exportedPreferencesDictionaryRepresentation
{
	return [self exportedPreferencesDictionaryRepresentation:YES];
}

+ (NSDictionary *)exportedPreferencesDictionaryRepresentation:(BOOL)removeJunk
{
	/* Gather everything into one big dictionary. */
	NSDictionary *settings = [RZUserDefaults() dictionaryRepresentation];

	if (removeJunk) {
		/* Now, it is time for the hashing process. */
		NSMutableDictionary *fnlsettings = [NSMutableDictionary dictionary];

		[settings enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
			if ([self isKeyNameSupposedToBeIgnored:key] == NO) {
				fnlsettings[key] = obj;
			}
		}];

		return fnlsettings; // Return modified dictionary.
	}

	return settings;
}

/* +exportPostflightForURL: handles the actual export. */
/* This method is also called internally to backup the old configuration file. */
+ (BOOL)exportPostflightForURL:(NSURL *)pathURL filterJunk:(BOOL)removeJunk
{
	/* Gather everything into one big dictionary. */
	NSDictionary *mutsettings = [self exportedPreferencesDictionaryRepresentation:removeJunk];

	/* The export will be saved as binary. Two reasons: 1) Discourages user from
	 trying to tamper with stuff. 2) Smaller, faster. Mostly #1. */
	NSError *parseError;

	/* Create the new property list. */
	NSData *plist = [NSPropertyListSerialization dataWithPropertyList:mutsettings
															   format:NSPropertyListBinaryFormat_v1_0
															  options:0
																error:&parseError];

	/* Do the actual write. */
	if (NSObjectIsEmpty(plist) || parseError) {
		LogToConsole(@"Error Creating Property List: %@", [parseError localizedDescription]);
		
		return NO;
	} else {
		BOOL writeResult = [plist writeToURL:pathURL atomically:YES];

		if (writeResult == NO) {
			LogToConsole(@"Write failed.");

			return NO;
		}
	}

	return YES;
}

/* Open sheet. */
+ (void)export
{
	/* Pop open panel. An open panel is used instead of save panel because we only
	 want the user selecting a folder, nothing else. */
	NSSavePanel *d = [NSSavePanel savePanel];

	[d setCanCreateDirectories:YES];
	[d setNameFieldStringValue:@"TextualPrefrences.plist"];

	[d setMessage:BLS(1180)];

	[d beginWithCompletionHandler:^(NSInteger returnCode) {
		if (returnCode == NSModalResponseOK) {
			(void)[self exportPostflightForURL:[d URL] filterJunk:YES];
		}
	}];
}

@end
