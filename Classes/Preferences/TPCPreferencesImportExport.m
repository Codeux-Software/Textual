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

	/* Disconnect and clear all. */
	IRCWorld *theWorld = self.worldController;

	for (IRCClient *u in theWorld.clients) {
		[u quit];
	}

	/* Begin import. */
	NSData *rawData = [NSData dataWithContentsOfURL:pathURL];

	NSDictionary *plist = [NSPropertyListSerialization propertyListFromData:rawData
														   mutabilityOption:NSPropertyListImmutable
																	 format:NULL
														   errorDescription:NULL];

	if (plist) {
		/* The only thing that we should actually be processing from the plist is the
		 world controller which defines all the clients. After that, shove everything
		 in NSUserDefaults and call it a day. */

		for (NSString *key in plist) {
			if ([key isEqualToString:@"World Controller"]) {
				/* How we handle the world controller is very sensitive because of the sheer
				 amount of data contained within it. Most of all the hard work will be done
				 by createClient:reload: in IRCWorld. However, there are some internal things
				 we have to update first. Mostly, our UUIDs. Each client, channel, and address
				 book entry has a unique identifier associated with it. We have to give each
				 newly imported item a new UUID before doing anything with it. This step cannot
				 be skipped. */

				NSDictionary *config = [plist dictionaryForKey:key];

				for (NSDictionary *e in config[@"clients"]) {
					NSMutableDictionary *mut_e = [e mutableCopy];

					/* Reset the client UUID. */
					[mut_e setObject:[NSString stringWithUUID] forKey:@"uniqueIdentifier"];

					/* Do the channels next. */
					NSMutableArray *newChannelList = [NSMutableArray array];
					
					for (NSDictionary *ce in e[@"channelList"]) {
						NSMutableDictionary *mut_ce = [ce mutableCopy];

						/* Reset the channel UUID. */
						[mut_ce setObject:[NSString stringWithUUID] forKey:@"uniqueIdentifier"];

						/* Set new entry. */
						[newChannelList addObject:mut_ce];
					}

					[mut_e setObject:newChannelList forKey:@"channelList"];

					/* Do the highlight list. */
					NSMutableArray *newHighlightList = [NSMutableArray array];

					for (NSDictionary *ce in e[@"highlightList"]) {
						NSMutableDictionary *mut_ce = [ce mutableCopy];

						/* Reset the channel UUID. */
						[mut_ce setObject:[NSString stringWithUUID] forKey:@"uniqueIdentifier"];

						/* Set new entry. */
						[newHighlightList addObject:mut_ce];
					}

					[mut_e setObject:newHighlightList forKey:@"highlightList"];

					/* Do the ignore list. */
					NSMutableArray *newIgnoreList = [NSMutableArray array];

					for (NSDictionary *ce in e[@"ignoreList"]) {
						NSMutableDictionary *mut_ce = [ce mutableCopy];

						/* Reset the ignore UUID. */
						[mut_ce setObject:[NSString stringWithUUID] forKey:@"uniqueIdentifier"];

						/* Set new entry. */
						[newIgnoreList addObject:mut_ce];
					}

					[mut_e setObject:newIgnoreList forKey:@"ignoreList"];

					/* Now that we reset everything… it is safe to create the new client. */					
					[theWorld createClient:mut_e reload:YES];
				}
			} else {
				[RZUserDefaults() setObject:[plist objectForKey:key] forKey:key];
			}
		}
	}

	/* Finish up. */
	[theWorld destroyAllEvidence];
	
	[theWorld save];
	[theWorld reloadTheme];

	[self.masterController loadWindowState:YES];

	[TPCPreferences cleanUpHighlightKeywords];

	/* Do not push the loading screen right away. Add a little delay to give everything 
	 a chance to settle down before presenting the changes to the user. */
	[self performSelector:@selector(importPostflightCleanup) withObject:nil afterDelay:1.0];
}

+ (void)importPostflightCleanup
{
	[self.masterController.mainWindowLoadingScreen hideLoadingConfigurationView];

	self.worldController.isPopulatingSeeds = NO;
}

#pragma mark -
#pragma mark Export

/* +exportPostflightForURL: handles the actual export. */
/* This method is also called internally to backup the old configuration file. */
+ (BOOL)exportPostflightForURL:(NSURL *)pathURL filterJunk:(BOOL)removeJunk
{
	/* Save the world. Just like superman! */
	IRCWorld *theWorld = self.worldController;

	[theWorld save];

	/* Gather everything into one big dictionary. */
	NSDictionary *settings = [RZUserDefaults() dictionaryRepresentation];

	NSMutableDictionary *mutsettings = [settings mutableCopy];

	if (removeJunk) {
		/* Cocoa filter. */
		/* There are some Apple defined keys we do not want in our property list. 
		 We remove those here. */
		for (NSString *key in settings) {
			if ([key hasPrefix:@"NS"] ||
				[key hasPrefix:@"Apple"] ||
				[key hasPrefix:@"WebKit"] ||
				[key hasPrefix:@"com.apple."])
			{
				[mutsettings removeObjectForKey:key];
			} else if ([key hasPrefix:@"Saved Window State —> Internal —> "]) {
				/* While we are going through the list, also remove window frames. */
				
				[mutsettings removeObjectForKey:key];
			}
		}

		/* Custom filter. */
		/* Some settings such as log folder scoped bookmark cannot be exported/imported so we will
		 drop that from our exported dictionary. Other things that cannot be handled is the main 
		 window frame. Also, any custom styles. */
		[mutsettings removeObjectForKey:@"LogTranscriptDestinationSecurityBookmark"];

		/* Is it custom style? */
		NSString *themeName = [settings objectForKey:@"Theme -> Name"];

		if ([themeName hasPrefix:TPCThemeControllerBundledStyleNameCompletePrefix] == NO) { // It is custom.
			[mutsettings removeObjectForKey:@"Theme -> Name"];
		}
	}

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
