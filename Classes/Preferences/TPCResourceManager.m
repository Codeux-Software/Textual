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

NS_ASSUME_NONNULL_BEGIN

NSString * const TPCResourceManagerBundleDocumentTypeExtension					= @".bundle";
NSString * const TPCResourceManagerBundleDocumentTypeExtensionWithoutPeriod		= @"bundle";

NSString * const TPCResourceManagerScriptDocumentTypeExtension					= @".scpt";
NSString * const TPCResourceManagerScriptDocumentTypeExtensionWithoutPeriod		= @"scpt";

@implementation TPCResourceManager

+ (void)copyResourcesToApplicationSupportFolder
{
	/* Add a system link for the unsupervised scripts folder if it exists. */
	NSString *sourcePath = [TPCPathInfo customScriptsFolderPath];

	NSString *destinationPath = [[TPCPathInfo applicationSupportFolderPathInGroupContainer] stringByAppendingPathComponent:@"/Custom Scripts/"];
	
	if ([RZFileManager() fileExistsAtPath:sourcePath] &&
		[RZFileManager() fileExistsAtPath:destinationPath] == NO)
	{
		[RZFileManager() createSymbolicLinkAtPath:destinationPath withDestinationPath:sourcePath error:NULL];
	}
	
#if TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT == 1
	/* Add a system link for the iCloud folder if the iCloud folder exists. */
	if ([sharedCloudManager() ubiquitousContainerIsAvailable]) {
		destinationPath = [[TPCPathInfo applicationSupportFolderPathInGroupContainer] stringByAppendingPathComponent:@"/iCloud Resources/"];
		
		sourcePath = [sharedCloudManager() ubiquitousContainerPath];
		
		if ([RZFileManager() fileExistsAtPath:destinationPath] == NO) {
			[RZFileManager() createSymbolicLinkAtPath:destinationPath withDestinationPath:sourcePath error:NULL];
		}
	}
#endif
}

+ (nullable NSDictionary<NSString *, id> *)loadContentsOfPropertyListInResources:(NSString *)name
{
	NSParameterAssert(name != nil);

	NSString *defaultsPath = [RZMainBundle() pathForResource:name ofType:@"plist"];

	NSDictionary *localDefaults = [NSDictionary dictionaryWithContentsOfFile:defaultsPath];

	return localDefaults;
}

@end

#pragma mark -

@implementation TPCResourceManagerDocumentTypeImporter

- (BOOL)readFromURL:(NSURL *)url ofType:(NSString *)typeName error:(NSError **)outError
{
	NSString *filePath = url.filePathURL.absoluteString;

	if ([filePath hasSuffix:TPCResourceManagerScriptDocumentTypeExtension]) {
		[self performImportOfScriptFile:url];
		
		return YES;
	}

	NSString *pluginSuffix = [TPCResourceManagerBundleDocumentTypeExtension stringByAppendingString:@"/"];
	
	if ([filePath hasSuffix:pluginSuffix]) {
		[self performImportOfPluginFile:url];
		
		return YES;
	}
	
	return NO;
}

#pragma mark -
#pragma mark Custom Plugin Files

- (void)performImportOfPluginFile:(NSURL *)url
{
	NSParameterAssert(url != nil);

	NSString *filename = url.lastPathComponent;

	BOOL performInstall = [TLOPopupPrompts dialogWindowWithMessage:TXTLS(@"Prompts[1130][2]")
															 title:TXTLS(@"Prompts[1130][1]", filename)
													 defaultButton:TXTLS(@"Prompts[0001]")
												   alternateButton:TXTLS(@"Prompts[0002]")];

	if (performInstall == NO) {
		return;
	}

	NSString *newPath = [[TPCPathInfo customExtensionFolderPath] stringByAppendingPathComponent:filename];

	BOOL didImport = [self import:url into:[NSURL fileURLWithPath:newPath]];

	if (didImport) {
		NSString *filenameWithoutExtension = filename.stringByDeletingPathExtension;

		[TLOPopupPrompts dialogWindowWithMessage:TXTLS(@"Prompts[1128][2]")
										   title:TXTLS(@"Prompts[1128][1]", filenameWithoutExtension)
								   defaultButton:TXTLS(@"Prompts[0005]")
								 alternateButton:nil];
	}
}

#pragma mark -
#pragma mark Custom Script Files

- (BOOL)panel:(id)sender validateURL:(NSURL *)url error:(NSError **)outError
{
	NSString *scriptsPath = [TPCPathInfo customScriptsFolderPath];

	if ([url.relativePath hasPrefix:scriptsPath] == NO) {
		if (outError) {
			NSMutableDictionary<NSDictionary *, id> *userInfo = [NSMutableDictionary dictionary];

			userInfo[NSURLErrorKey] = url;

			userInfo[NSLocalizedDescriptionKey] = TXTLS(@"Prompts[1126][1]");
			userInfo[NSLocalizedRecoverySuggestionErrorKey] = TXTLS(@"Prompts[1126][2]");

			*outError = [NSError errorWithDomain:NSCocoaErrorDomain code:27984 userInfo:userInfo];
		}

		return NO;
	} else {
		return YES;
	}
}

- (void)performImportOfScriptFile:(NSURL *)url
{
	NSParameterAssert(url != nil);

	NSString *filename = url.lastPathComponent;

	/* Ask user before installing. */
	BOOL performInstall = [TLOPopupPrompts dialogWindowWithMessage:TXTLS(@"Prompts[1130][2]")
															 title:TXTLS(@"Prompts[1130][1]", filename)
													 defaultButton:TXTLS(@"Prompts[0001]")
												   alternateButton:TXTLS(@"Prompts[0002]")];

	if (performInstall == NO) {
		return; // Do not install.
	}

#if TEXTUAL_BUILT_INSIDE_SANDBOX == 0
	NSString *newPath = [[TPCPathInfo customScriptsFolderPath] stringByAppendingPathComponent:filename];

	BOOL didImport = [self import:url into:[NSURL fileURLWithPath:newPath]];

	if (didImport) {
		[self performImportOfScriptFilePostflight:filename];
	}
#else
	NSURL *folderRep = [NSURL fileURLWithPath:[TPCPathInfo customScriptsFolderPath] isDirectory:YES];

	if ([RZFileManager() fileExistsAtPath:folderRep.relativePath] == NO) {
		folderRep = [NSURL fileURLWithPath:[TPCPathInfo customScriptsFolderPathLeading] isDirectory:YES];
	}

	NSString *bundleID = [TPCApplicationInfo applicationBundleIdentifier];

	NSSavePanel *d = [NSSavePanel savePanel];

	d.delegate = (id)self;

	[d setCanCreateDirectories:YES];

	d.directoryURL = folderRep;

	d.title = TXTLS(@"Prompts[1125][1]");

	d.message = TXTLS(@"Prompts[1125][2]", bundleID);

	d.nameFieldStringValue = url.lastPathComponent;

	if ([XRSystemInformation isUsingOSXMavericksOrLater]) {
		[d setShowsTagField:NO];
	}

	[d beginWithCompletionHandler:^(NSInteger returnCode) {
		if (returnCode == NSModalResponseOK) {
			if ([self import:url into:d.URL] == NO) {
				return;
			}

			NSString *filename = d.URL.lastPathComponent;

			XRPerformBlockAsynchronouslyOnMainQueue(^{
				[self performImportOfScriptFilePostflight:filename];
			});
		}
	}];
#endif
}

- (void)performImportOfScriptFilePostflight:(NSString *)filename
{
	NSParameterAssert(filename != nil);

	NSString *filenameWithoutExtension = filename.stringByDeletingPathExtension;

	[TLOPopupPrompts dialogWindowWithMessage:TXTLS(@"Prompts[1127][2]", filenameWithoutExtension)
									   title:TXTLS(@"Prompts[1127][1]", filenameWithoutExtension)
							   defaultButton:TXTLS(@"Prompts[0005]")
							 alternateButton:nil];
}

#pragma mark -
#pragma mark General Import Controller

- (BOOL)import:(NSURL *)url into:(NSURL *)destination
{
	return [RZFileManager() replaceItemAtURL:destination
							   withItemAtURL:url
						   moveToDestination:NO
					  moveDestinationToTrash:YES];
}

@end

NS_ASSUME_NONNULL_END
