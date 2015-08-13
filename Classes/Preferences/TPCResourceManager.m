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

NSString * const TPCResourceManagerBundleDocumentTypeExtension					= @".bundle";
NSString * const TPCResourceManagerBundleDocumentTypeExtensionWithoutPeriod		= @"bundle";

NSString * const TPCResourceManagerScriptDocumentTypeExtension					= @".scpt";
NSString * const TPCResourceManagerScriptDocumentTypeExtensionWithoutPeriod		= @"scpt";

@implementation TPCResourceManager

+ (void)copyResourcesToCustomAddonsFolder
{
	/* Copy specific resource files to the custom addons folder. */
	/* For now, we only are copying the text file containing information
	 about installing custom scripts. */
	
	/* Add a system link for the unsupervised scripts folder if it exists. */
	NSString *sourePath =  [TPCPathInfo systemUnsupervisedScriptFolderPath];
	NSString *destnPath = [[TPCPathInfo applicationGroupContainerApplicationSupportPath] stringByAppendingPathComponent:@"/Custom Scripts/"];
	
	if ([RZFileManager() fileExistsAtPath:sourePath] &&
		[RZFileManager() fileExistsAtPath:destnPath] == NO)
	{
		[RZFileManager() createSymbolicLinkAtPath:destnPath withDestinationPath:sourePath error:NULL];
	}
	
#if TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT == 1
	/* Add a system link for the iCloud folder if the iCloud folder exists. */
	if ([sharedCloudManager() ubiquitousContainerIsAvailable]) {
		destnPath = [[TPCPathInfo applicationGroupContainerApplicationSupportPath] stringByAppendingPathComponent:@"/iCloud Resources/"];
		
		sourePath = [sharedCloudManager() ubiquitousContainerURLPath];
		
		if ([RZFileManager() fileExistsAtPath:destnPath] == NO) {
			[RZFileManager() createSymbolicLinkAtPath:destnPath withDestinationPath:sourePath error:NULL]; // We don't care about errors.
		}
	}
#endif
}

+ (id)loadContentsOfPropertyListInResourcesFolderNamed:(NSString *)name
{
	NSString *defaultsPath = [RZMainBundle() pathForResource:name ofType:@"plist"];

	NSDictionary *localDefaults = [NSDictionary dictionaryWithContentsOfFile:defaultsPath];

	return localDefaults;
}

@end

@implementation TPCResourceManagerDocumentTypeImporter

- (BOOL)readFromURL:(NSURL *)url ofType:(NSString *)typeName error:(NSError *__autoreleasing *)outError
{
	PointerIsEmptyAssertReturn(url, NO);

	if ([[url absoluteString] hasSuffix:TPCResourceManagerScriptDocumentTypeExtension]) {
		[self performImportOfScriptFile:url];
		
		return YES;
	}

	NSString *pluginSuffix = [TPCResourceManagerBundleDocumentTypeExtension stringByAppendingString:@"/"];
	
	if ([[url absoluteString] hasSuffix:pluginSuffix]) {
		[self performImportOfPluginFile:url];
		
		return YES;
	}
	
	return NO;
}

#pragma mark -
#pragma mark Custom Plugin Files

- (void)performImportOfPluginFile:(NSURL *)url
{
	PointerIsEmptyAssert(url);

	NSString *filename = [url lastPathComponent];

	/* Ask user before installing. */
	BOOL performInstall = [TLOPopupPrompts dialogWindowWithMessage:TXTLS(@"BasicLanguage[1192][2]", filename)
															 title:TXTLS(@"BasicLanguage[1192][1]")
													 defaultButton:BLS(1182)
												   alternateButton:BLS(1219)
													suppressionKey:nil
												   suppressionText:nil];

	/* YES == No in dialog. */
	if (performInstall) {
		return; // Do not install.
	}

	NSString *newPath = [[TPCPathInfo customExtensionFolderPath] stringByAppendingPathComponent:filename];

	BOOL didImport = [self import:url into:[NSURL fileURLWithPath:newPath]];

	if (didImport) {
		[TLOPopupPrompts dialogWindowWithMessage:TXTLS(@"BasicLanguage[1189][2]", [filename stringByDeletingPathExtension])
										   title:TXTLS(@"BasicLanguage[1189][1]")
								   defaultButton:BLS(1186)
								 alternateButton:nil
								  suppressionKey:nil
								 suppressionText:nil];
	}
}

#pragma mark -
#pragma mark Custom Script Files

- (BOOL)panel:(id)sender validateURL:(NSURL *)url error:(NSError *__autoreleasing *)outError
{
	if ([[url relativePath] hasPrefix:[TPCPathInfo systemUnsupervisedScriptFolderPath]] == NO) {
		if (outError) {
			NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];

			[userInfo setObject:url forKey:NSURLErrorKey];
			[userInfo setObject:TXTLS(@"BasicLanguage[1252][1]") forKey:NSLocalizedDescriptionKey];
			[userInfo setObject:TXTLS(@"BasicLanguage[1252][2]") forKey:NSLocalizedRecoverySuggestionErrorKey];

			*outError = [NSError errorWithDomain:NSCocoaErrorDomain code:27984 userInfo:userInfo];
		}

		return NO;
	} else {
		return YES;
	}
}

- (void)performImportOfScriptFile:(NSURL *)url
{
	NSString *filename = [url lastPathComponent];

	/* Ask user before installing. */
	BOOL performInstall = [TLOPopupPrompts dialogWindowWithMessage:TXTLS(@"BasicLanguage[1192][2]", filename)
															 title:TXTLS(@"BasicLanguage[1192][1]")
													 defaultButton:BLS(1182)
												   alternateButton:BLS(1219)
													suppressionKey:nil
												   suppressionText:nil];

	/* YES == No in dialog. */
	if (performInstall) {
		return; // Do not install.
	}

#if TEXTUAL_BUILT_INSIDE_SANDBOX == 0
	NSString *newPath = [[TPCPathInfo systemUnsupervisedScriptFolderPath] stringByAppendingPathComponent:filename];

	BOOL didImport = [self import:url into:[NSURL fileURLWithPath:newPath]];

	if (didImport) {
		[self performImportOfScriptFilePostflight:filename];
	}
#else
	NSURL *folderRep = [NSURL fileURLWithPath:[TPCPathInfo systemUnsupervisedScriptFolderPath] isDirectory:YES];

	if ([RZFileManager() fileExistsAtPath:[folderRep relativePath]] == NO) {
		folderRep = [NSURL fileURLWithPath:[TPCPathInfo systemUnsupervisedScriptFolderRootPath]];
	}

	NSString *bundleID = [TPCApplicationInfo applicationBundleIdentifier];

	NSSavePanel *d = [NSSavePanel savePanel];

	[d setDelegate:self];

	[d setCanCreateDirectories:YES];
	[d setDirectoryURL:folderRep];

	[d setTitle:TXTLS(@"BasicLanguage[1187][1]")];
	[d setMessage:TXTLS(@"BasicLanguage[1187][2]", bundleID)];

	[d setNameFieldStringValue:[url lastPathComponent]];

	if ([XRSystemInformation isUsingOSXMavericksOrLater]) {
		[d setShowsTagField:NO];
	}

	[d beginWithCompletionHandler:^(NSInteger returnCode) {
		if (returnCode == NSModalResponseOK) {
			if ([self import:url into:[d URL]]) {
				NSString *filename = [[d URL] lastPathComponent];

				XRPerformBlockAsynchronouslyOnMainQueue(^{
					[self performImportOfScriptFilePostflight:filename];
				});
			}
		}
	}];
#endif
}

- (void)performImportOfScriptFilePostflight:(NSString *)filename
{
	[TLOPopupPrompts dialogWindowWithMessage:TXTLS(@"BasicLanguage[1188][2]", [filename stringByDeletingPathExtension])
									   title:TXTLS(@"BasicLanguage[1188][1]")
							   defaultButton:BLS(1186)
							 alternateButton:nil
							  suppressionKey:nil
							 suppressionText:nil];
}

#pragma mark -
#pragma mark General Import Controller

- (BOOL)import:(NSURL *)url into:(NSURL *)destination
{
	PointerIsEmptyAssertReturn(url, NO);
	PointerIsEmptyAssertReturn(destination, NO);
	
	NSError *instError = nil;

	if ([destination checkResourceIsReachableAndReturnError:NULL]) {
		BOOL trashed = [RZFileManager() trashItemAtURL:destination resultingItemURL:nil error:&instError];
		
		if (trashed == NO && instError) {
			LogToConsole(@"Install Error:\nFrom: %@\nTo: %@\nError: %@", url, destination, [instError localizedDescription]);
			
			return NO;
		}
	}

	[RZFileManager() copyItemAtURL:url toURL:destination error:&instError];
	
	if (instError) {
		LogToConsole(@"Install Error:\nFrom: %@\nTo: %@\nError: %@", url, destination, [instError localizedDescription]);
		
		return NO;
	}
	
	return YES;
}

@end

