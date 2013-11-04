/* ********************************************************************* 
       _____        _               _    ___ ____   ____
      |_   _|___  _| |_ _   _  __ _| |  |_ _|  _ \ / ___|
       | |/ _ \ \/ / __| | | |/ _` | |   | || |_) | |
       | |  __/>  <| |_| |_| | (_| | |   | ||  _ <| |___
       |_|\___/_/\_\\__|\__,_|\__,_|_|  |___|_| \_\\____|

 Copyright (c) 2010 — 2013 Codeux Software & respective contributors.
        Please see Contributors.rtfd and Acknowledgements.rtfd

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

/*
	Everything related to import/export is handled within this class.

	Sheets are used to lock focus to the task at hand.
 */

@implementation TPCPreferencesImportExport

/* -import handles the actual import menu item. */
+ (void)import
{
	TLOPopupPrompts *prompt = [TLOPopupPrompts new];

	[prompt sheetWindowWithQuestion:self.masterController.mainWindow
							 target:self
							 action:@selector(importPreflight:)
							   body:TXTLS(@"PreferencesImportPreflightDialogMessage")
							  title:TXTLS(@"PreferencesImportPreflightDialogTitle")
					  defaultButton:TXTLS(@"PreferencesImportPreflightDialogSelectFileButton")
					alternateButton:TXTLS(@"CancelButton")
						otherButton:nil
					 suppressionKey:nil
					suppressionText:nil];
}

/* Master controller internal handles for import. */
+ (void)importPreflight:(TLOPopupPromptReturnType)buttonPressed
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
			if (returnCode == NSOKButton) {
				NSURL *pathURL = [d.URLs safeObjectAtIndex:0];

				[self importPostflight:pathURL];
			}
		}];
	}
}

+ (void)importPostflight:(NSURL *)pathURL
{
	/* The loading screen is a generic way to show something during import. */
	[self.masterController.mainWindowLoadingScreen popLoadingConfigurationView];

	/* isPopulatingSeeds tells the world to not close the loading screen on state
	 changes when creating new connections. */
	self.worldController.isPopulatingSeeds = YES;

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

	NSDictionary *plist = [NSPropertyListSerialization propertyListFromData:rawData
														   mutabilityOption:NSPropertyListImmutable
																	 format:NULL
														   errorDescription:NULL];

	/* Perform actual import if we have the dictionary. */
	if (plist) {
		[self importContentsOfDictionary:plist];

		/* Do not push the loading screen right away. Add a little delay to give everything
		 a chance to settle down before presenting the changes to the user. */
		[self performSelector:@selector(importPostflightCleanup) withObject:nil afterDelay:1.0];
	} else {
		LogToConsole(@"Import failed. Could not read property list.");
	}
}

/* Conditional for keys that require special processing during the import process. */
+ (BOOL)isKeyNameExcludedFromNormalImportProcess:(NSString *)key
{
	return ([key isEqualToString:IRCWorldControllerDefaultsStorageKey] ||
			[key isEqualToString:IRCWorldControllerDeletedClientsStorageKey]);
}

+ (void)importContentsOfDictionary:(NSDictionary *)aDict
{
	/* The expected format of this dictionary should NOT have hashed keys. */
	 LogToConsole(@"Dictionary to Import: %@", aDict);

	/* Normal import process. */
	[aDict enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
		[self import:obj withKey:key];
	}];

	/* Perform reload for changed keys. */
	[TPCPreferences performReloadActionForKeyValues:aDict.allKeys];
}

+ (void)import:(id)obj withKey:(id)key
{
	[self import:obj withKey:key isCloudBasedImport:NO];
}

+ (void)import:(id)obj withKey:(id)key isCloudBasedImport:(BOOL)isCloudImport
{
	/* Is it a normal key? */
	if ([self isKeyNameExcludedFromNormalImportProcess:key] == NO) {
		[RZUserDefaults() setObject:obj forKey:key];
	} else {
		/* It's not, so what special action is needed? */
		if ([key isEqual:IRCWorldControllerDefaultsStorageKey]) {
			/* It is the world controller! */
			NSObjectIsKindOfClassAssert(obj, NSDictionary);

			/* Start import. */
			id clientList = [obj objectForKey:@"clients"];

			[self importWorldControllerObject:clientList isCloudBasedImport:isCloudImport];
		} else if ([key isEqualToString:IRCWorldControllerDeletedClientsStorageKey]) {
			/* NEVER access this list unless it is from the cloud. Not regular import. */
			
			if (isCloudImport) {
				/* It is the deleted clients list. */
				NSObjectIsKindOfClassAssert(obj, NSArray);
				
				/* Start import. */
				[self importWorldControllerDeletedClientsObject:obj];
			}
		}
	}
}

+ (void)importWorldControllerObject:(NSArray *)clientList isCloudBasedImport:(BOOL)isCloudImport
{
	
}

+ (void)importWorldControllerDeletedClientsObject:(NSArray *)deletedClients
{
	NSObjectIsEmptyAssert(deletedClients);
	
	[deletedClients enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		/* Try to find a client from the imported list. */
		IRCClient *u = [self.worldController findClientById:obj];
		
		/* Did we find one? */
		if (u) {
			/* We did find one… is it set to sync to cloud? */
			/* We only delete clients that are set to be synced. */
			if (u.config.excludedFromCloudSyncing == NO) {
				[self.worldController destroyClient:u];
			}
		}
	}];
}

+ (void)importPostflightCleanup
{
	/* Pop loading screen. */
	[self.masterController.mainWindowLoadingScreen hideLoadingConfigurationView];

	/* Finish seeding. */
	self.worldController.isPopulatingSeeds = NO;
}

#pragma mark -
#pragma mark Export

/* Conditional for matching whether we want a key in the exported dictionary. */
+ (BOOL)isKeyNameSupposedToBeIgnored:(NSString *)key
{
	if ([key hasPrefix:@"NS"] ||											/* Apple owned prefix. */
		[key hasPrefix:@"SGT"] ||											/* Apple owned prefix. */
		[key hasPrefix:@"Apple"] ||											/* Apple owned prefix. */
		[key hasPrefix:@"WebKit"] ||										/* Apple owned prefix. */
		[key hasPrefix:@"com.apple."] ||									/* Apple owned prefix. */
		[key hasPrefix:@"DataDetectorsSettings"] ||							/* Apple owned prefix. */

		[key hasPrefix:@"TXRunCount"] ||									/* Textual owned prefix. */
		[key hasPrefix:@"TXRunTime"] ||										/* Textual owned prefix. */

		[key hasPrefix:@"System —>"] ||										/* Textual owned prefix. */
		[key hasPrefix:@"Security ->"] ||									/* Textual owned prefix. */
		[key hasPrefix:@"Window -> Main Window"] ||							/* Textual owned prefix. */
		[key hasPrefix:@"Saved Window State —> Internal —> "] ||			/* Textual owned prefix. */
		[key hasPrefix:@"Text Input Prompt Suppression -> "] ||				/* Textual owned prefix. */

		[key hasPrefix:@"LogTranscriptDestinationSecurityBookmark"])		/* Textual owned prefix. */
	{
		return YES; // Key has an ignored prefix.
	}

	return NO;
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
		NSMutableDictionary *mutsettings = [settings mutableCopy];

		/* Is it custom style? */
		NSString *themeName = [settings objectForKey:@"Theme -> Name"];

		if ([themeName hasPrefix:TPCThemeControllerBundledStyleNameCompletePrefix] == NO) { // It is custom.
			[mutsettings removeObjectForKey:@"Theme -> Name"];
		}

		/* Now, it is time for the hashing process. */
		NSMutableDictionary *fnlsettings = [NSMutableDictionary dictionary];

		[mutsettings enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
			if ([self isKeyNameSupposedToBeIgnored:key] == NO) {
				[fnlsettings setObject:obj forKey:key];
			}
		}];

		/* Insert the dictionary version information. */
		/* This has no use right now… but it might in the future. */
		[fnlsettings setObject:TPCPreferencesImportExportVersionKeyValue
						forKey:TPCPreferencesImportExportVersionKeyName];

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
	NSString *parseError;

	/* Create the new property list. */
	NSData *plist = [NSPropertyListSerialization dataFromPropertyList:mutsettings
															   format:NSPropertyListBinaryFormat_v1_0
													 errorDescription:&parseError];

	/* Do the actual write. */
	if (NSObjectIsEmpty(plist) || parseError) {
		LogToConsole(@"Error Creating Property List: %@", parseError);
		
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

	[d setMessage:TXTLS(@"PreferencesExportSaveLocationDialogMessage")];

	[d beginWithCompletionHandler:^(NSInteger returnCode) {
		if (returnCode == NSOKButton) {
			(void)[self exportPostflightForURL:d.URL filterJunk:YES];
		}
	}];
}

@end
