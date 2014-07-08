/* ********************************************************************* 
       _____        _               _    ___ ____   ____
      |_   _|___  _| |_ _   _  __ _| |  |_ _|  _ \ / ___|
       | |/ _ \ \/ / __| | | |/ _` | |   | || |_) | |
       | |  __/>  <| |_| |_| | (_| | |   | ||  _ <| |___
       |_|\___/_/\_\\__|\__,_|\__,_|_|  |___|_| \_\\____|

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

#define _checkInterval			86400 // 1 day
#define _checkTimeout			30.0

#define _userDefaults			[NSUserDefaults standardUserDefaults]

@interface TPCPreferencesTextualFiveMigrationTool ()
@property (nonatomic, uweak) IBOutlet NSWindow *dialogWindow;
@property (nonatomic, strong) NSURLConnection *requestConnection;
@property (nonatomic, strong) NSHTTPURLResponse *requestResponse;

- (IBAction)openAppStorePage:(id)sender;
- (IBAction)openSupportPage:(id)sender;
- (IBAction)openDownloadTrialPage:(id)sender;
- (IBAction)openListOfChangesPage:(id)sender;

- (IBAction)hideDialogTemporarly:(id)sender;
- (IBAction)hideDialogPermanently:(id)sender;
@end

@implementation TPCPreferencesTextualFiveMigrationTool

#pragma mark -
#pragma mark Public API

- (void)performMigration
{
	if ([TPCPreferences featureAvailableToOSXMountainLion]) {
		[[self invokeInBackgroundThread] _performMigration];
	}
}

- (void)_performMigration
{
	[self migrateUserDefaults];
	[self migrateUserFiles];
	
	[self maybeOpenDialog];
}

#pragma mark -
#pragma mark Style Files

- (void)migrateUserFiles
{
	/* Style files are pretty much the only files we can migrate from within the app
	 ourselves. Extensions will crash instantly if we copy those because of the large
	 codebase refactoring that went underway for Textual 5. Scripts are stored in a 
	 folder which we do not have write access… so… yeah. */
	if ([RZFileManager() respondsToSelector:@selector(containerURLForSecurityApplicationGroupIdentifier:)]) {
		/* Get container URL. */
		NSURL *containerURL = [RZFileManager() containerURLForSecurityApplicationGroupIdentifier:TXBundleGroupIdentifier];
		
		if (containerURL) {
			/* Convert URL to workable path. */
			NSString *destinationPath = [containerURL relativePath];
			
			/* Append direct path. */
			destinationPath = [destinationPath stringByAppendingPathComponent:@"/Library/Application Support/Textual/"];
			
			/* Maybe create folder. */
			if ([RZFileManager() fileExistsAtPath:destinationPath] == NO) {
				[RZFileManager() createDirectoryAtPath:destinationPath withIntermediateDirectories:YES attributes:nil error:NULL];
			}
			
			/* Perform migration. */
			NSArray *arguments;
			
			/* Perform migration of user styles. */
			arguments = @[[TPCPreferences customThemeFolderPath], destinationPath];
		
			[self performRsyncTaskWithArguments:arguments];
			
			/* Perform migration. */
			/* Copy from extensions folder but exclude actual extensions to allow extension
			 created user data databases to be migrated. */
			arguments = @[@"--exclude", @"*.bundle/", [TPCPreferences customExtensionFolderPath], destinationPath];
			
			[self performRsyncTaskWithArguments:arguments];
		}
	}
}

- (void)performRsyncTaskWithArguments:(NSArray *)arguments
{
	/* This is probably not the most elegant solution for this but for right now all
	 we are going to do is call rsync on the folders and allow it to do its magic. */
	NSTask *copyTask = [NSTask new];
	
	arguments = [@[@"-a"] arrayByAddingObjectsFromArray:arguments];
	
	[copyTask setLaunchPath:@"/usr/bin/rsync"];
	[copyTask setArguments:arguments];
	
	[copyTask launch];
}

#pragma mark -
#pragma mark User Defaults 

- (void)migrateUserDefaults
{
	if ([TPCPreferences featureAvailableToOSXMavericks]) {
		/* On Mavericks or later, we can use a group container for NSUserDefaults. */
		/* Each time migration runs, we scan the NSUserDefaults dictionary for the
		 application container and migrate the value of those keys to the group 
		 container if the key from the dictionary does not already exist there. */
		/* We only do this during launch events. RZUserDefaults() automatically 
		 handles writing to the appropriate container afterwards. */
		
		/* Perform migration. */
		[RZUserDefaults() migrateValuesToGroupContainer];
	}
}

#pragma mark -
#pragma mark Dialog Window

- (void)maybeOpenDialog
{
	/* Maybe the user doesn't even want to ever see this again. */
	BOOL neverShowDialog = [_userDefaults boolForKey:@"Textual Five Migration Tool -> Never Show Dialog"];
	
	if (neverShowDialog == NO) {
		/* The check method is invoked in the background so the read to codeux.com does
		 not block the main loop while we wait for a response. */
		[self _maybeOpenDialog];
	}
}

- (void)_maybeOpenDialog
{
	/* Check the last time we checked for a dialog. */
	double lastTimeRan = [_userDefaults doubleForKey:@"Textual Five Migration Tool -> Last Check Time"];
	
	double lastCheckDiff = ([NSDate epochTime] - lastTimeRan);
	
	/* If it is above that time, we request the URL. */
	if (lastCheckDiff > _checkInterval) {
		dispatch_async(dispatch_get_main_queue(), ^{
			NSURL *requestURL = [NSURL URLWithString:@"http://www.codeux.com/textual/private/appcast/textual_5_update_live3.txt"];
			
			NSMutableURLRequest *baseRequest = [NSMutableURLRequest requestWithURL:requestURL
																	   cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
																   timeoutInterval:_checkTimeout];
			
			[baseRequest setHTTPMethod:@"HEAD"];
			
			self.requestConnection = [[NSURLConnection alloc] initWithRequest:baseRequest delegate:self];
			
			[self.requestConnection start];
		});
	}
}

- (void)openDialogWindow
{
	[self.dialogWindow setLevel:NSMainMenuWindowLevel];
	[self.dialogWindow makeKeyAndOrderFront:nil];
}

- (void)closeDialogWindow
{
	[self.dialogWindow close];
}

#pragma mark -
#pragma mark Data Request Delegate

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	if (self.requestResponse.statusCode == 200) {
		[self openDialogWindow];
	}
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	; // We don't care.
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
	self.requestResponse = (id)response;
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse
{
	return nil; /* Do not return any cache. */
}

#pragma mark -
#pragma mark Dialog Actions

- (IBAction)openAppStorePage:(id)sender
{
	[RZWorkspace() openURL:[NSURL URLWithString:@"http://www.textualapp.com/"]];
}

- (IBAction)openSupportPage:(id)sender
{
	[RZWorkspace() openURL:[NSURL URLWithString:@"http://www.codeux.com/textual/wiki/Support.wiki"]];
}

- (IBAction)openDownloadTrialPage:(id)sender
{
	[RZWorkspace() openURL:[NSURL URLWithString:@"http://www.codeux.com/textual/trial.download"]];
}

- (IBAction)openListOfChangesPage:(id)sender
{
	[RZWorkspace() openURL:[NSURL URLWithString:@"http://www.codeux.com/textual/textual5migration/list_of_changes"]];
}

- (IBAction)hideDialogTemporarly:(id)sender
{
	[self closeDialogWindow];
	
	/* Update time. */
	[_userDefaults setDouble:[NSDate epochTime] forKey:@"Textual Five Migration Tool -> Last Check Time"];
}

- (IBAction)hideDialogPermanently:(id)sender
{
	[self closeDialogWindow];
	
	[_userDefaults setBool:YES forKey:@"Textual Five Migration Tool -> Never Show Dialog"];
}

@end
