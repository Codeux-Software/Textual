/* ********************************************************************* 
                  _____         _               _
                 |_   _|____  _| |_ _   _  __ _| |
                   | |/ _ \ \/ / __| | | |/ _` | |
                   | |  __/>  <| |_| |_| | (_| | |
                   |_|\___/_/\_\\__|\__,_|\__,_|_|

 Copyright (c) 2008 - 2010 Satoshi Nakagawa <psychs AT limechat DOT net>
 Copyright (c) 2010 — 2014 Codeux Software, LLC & respective contributors.
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

#import <AudioToolbox/AudioToolbox.h>

@implementation TLOSoundPlayer

+ (NSDictionary *)soundFilesAtPath:(NSString *)path
{
	NSMutableDictionary *resultData = [NSMutableDictionary dictionary];

	NSArray *files = [RZFileManager() contentsOfDirectoryAtPath:path error:NULL];

	for (NSString *filename in files) {
		NSString *namewoext = [filename stringByDeletingPathExtension];
		
		NSString *namewpath = [path stringByAppendingPathComponent:filename];

		resultData[namewoext] = namewpath;
	}

	return resultData;
}

+ (NSDictionary *)systemAlertSoundFiles
{
	NSArray *folders = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSSystemDomainMask, YES);

	if ([folders count] > 0) {
		NSString *folder = [folders[0] stringByAppendingPathComponent:@"/Sounds/"];

		return [TLOSoundPlayer soundFilesAtPath:folder];
	}

	return nil;
}

+ (NSDictionary *)systemLibrarySoundFiles
{
	NSArray *folders = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSLocalDomainMask, YES);

	if ([folders count] > 0) {
		NSString *folder = [folders[0] stringByAppendingPathComponent:@"/Sounds/"];

		return [TLOSoundPlayer soundFilesAtPath:folder];
	}

	return nil;
}

+ (NSDictionary *)localLibrarySoundFiles
{
	NSArray *folders = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);

	if ([folders count] > 0) {
		NSString *folder = [folders[0] stringByAppendingPathComponent:@"/Sounds/"];

		return [TLOSoundPlayer soundFilesAtPath:folder];
	}

	return nil;
}

+ (BOOL)doesSoundFileDictionary:(NSDictionary *)fileList containName:(NSString *)name returnedPath:(NSString **)path
{
	/* Scan input and return based on name. */
	for (NSString *filename in [fileList allKeys])
	{
		if (NSObjectsAreEqual(filename, name))
		{
			NSString *exactPath = fileList[filename];

			/* Can we init a sound with this file? */
			NSSound *isSound = [[NSSound alloc] initWithContentsOfFile:exactPath byReference:YES];

			if (isSound) {
				isSound = nil;

				*path = [exactPath copy];

				return YES;
			}
		}
	}

	return NO;
}

+ (SystemSoundID)alertSoundNamed:(NSString *)name
{
	/* Check user folder first. */
	BOOL hasSoundPath = NO;

	NSString *soundPath = nil;

	NSDictionary *soundFiles;
	
	/* I know the condition will always be NO, but there are three
	 blocks of copy and pasted code. I wanted them to look the same. */
	if (hasSoundPath == NO) {
		soundFiles = [TLOSoundPlayer localLibrarySoundFiles];

		if ([TLOSoundPlayer doesSoundFileDictionary:soundFiles containName:name returnedPath:&soundPath]) {
			hasSoundPath = YES;
		}
	}

	/* Check local library? */
	if (hasSoundPath == NO) {
		soundFiles = [TLOSoundPlayer systemLibrarySoundFiles];

		if ([TLOSoundPlayer doesSoundFileDictionary:soundFiles containName:name returnedPath:&soundPath]) {
			hasSoundPath = YES;
		}
	}

	/* Check system library? */
	if (hasSoundPath == NO) {
		soundFiles = [TLOSoundPlayer systemAlertSoundFiles];

		if ([TLOSoundPlayer doesSoundFileDictionary:soundFiles containName:name returnedPath:&soundPath]) {
			hasSoundPath = YES;
		}
	}

	/* Return an object. */
	if (hasSoundPath) {
		NSURL *pathURL = [NSURL fileURLWithPath:soundPath];

		SystemSoundID soundID;

		OSStatus err = AudioServicesCreateSystemSoundID((__bridge CFURLRef)(pathURL), &soundID);

		if (err) {
			return 0; // We had an error.
		} else {
			return soundID; // Operation was succesful.
		}
	}

	return 0;
}

+ (void)playAlertSound:(NSString *)name
{
	NSObjectIsEmptyAssert(name);
	
	if ([name isEqualToString:TXEmptySoundAlertPreference]) {
		return;
	} else if ([name isEqualToString:@"Beep"]) {
		NSBeep();
	} else {
		SystemSoundID soundID = [TLOSoundPlayer alertSoundNamed:name];
		
		if (soundID) {
			AudioServicesPlayAlertSound(soundID);
		} else {
			LogToConsole(@"Error: Unable to find sound \"%@\"", name);
		}
	}
}

@end
