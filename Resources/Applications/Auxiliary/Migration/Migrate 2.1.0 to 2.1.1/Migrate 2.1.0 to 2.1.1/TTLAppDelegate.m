//
//  TTLAppDelegate.m
//  Migrate 2.1.0 to 2.1.1
//
//  Created by Michael Morris on 8/13/12.
//  Copyright (c) 2012 Codeux Software. All rights reserved.
//

#import "TTLAppDelegate.h"

@implementation TTLAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	self.label.stringValue = @"Complete.";

	// ---- //

	NSFileManager *fileManager = [NSFileManager defaultManager];

	// ---- //

	if (fileManager) {
		NSString *oldPath = [@"~/Library/Containers/com.codeux.irc.textual/"	stringByExpandingTildeInPath];
		NSString *newPath = [@"~/Library/Containers/com.codeux.textual/"		stringByExpandingTildeInPath];

		NSString *oldPathBackup = [@"~/Library/Containers/com.codeux.irc.textual.backup/"	stringByExpandingTildeInPath];
		NSString *newPathBackup = [@"~/Library/Containers/com.codeux.textual.backup/"		stringByExpandingTildeInPath];

		BOOL isDirectory = NO;

		// ---- //

		if ([fileManager fileExistsAtPath:oldPath isDirectory:&isDirectory]) {
			if (isDirectory) {
				NSError *operationError = nil;

				// ---- //

				if ([fileManager fileExistsAtPath:newPath]) {
					[fileManager copyItemAtPath:newPath
										 toPath:newPathBackup
										  error:&operationError];

					if (operationError) {
						self.label.stringValue = @"Migration failed. Error #1.";
						
						return;
					}

					// ---- //

					operationError = nil;

					[fileManager removeItemAtPath:newPath
											error:&operationError];

					if (operationError) {
						self.label.stringValue = @"Migration failed. Error #2.";
						
						return;
					}
				}

				// ---- //

				operationError = nil;

				[fileManager copyItemAtPath:oldPath
									 toPath:oldPathBackup
									  error:&operationError];

				if (operationError) {
					self.label.stringValue = @"Migration failed. Error #3.";

					return;
				}

				// ---- //

				operationError = nil;

				[fileManager removeItemAtPath:oldPath
										error:&operationError];

				if (operationError) {
					self.label.stringValue = @"Migration failed. Error #4.";

					return;
				}

				// ---- //

				operationError = nil;

				[fileManager copyItemAtPath:oldPathBackup
									 toPath:newPath
									  error:&operationError];

				if (operationError) {
					self.label.stringValue = @"Migration failed. Error #5.";

					return;
				}
			}
		}
	}
}
	
@end
