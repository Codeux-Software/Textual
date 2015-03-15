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

NSString * const TLOEncryptionManagerWillStartGeneratingPrivateKeyNotification = @"TLOEncryptionManagerWillStartGeneratingPrivateKeyNotification";
NSString * const TLOEncryptionManagerDidFinishGeneratingPrivateKeyNotification = @"TLOEncryptionManagerDidFinishGeneratingPrivateKeyNotification";

@interface TLOEncryptionManagerEncodingDecodingObject : NSObject
@property (nonatomic, copy) TLOEncryptionManagerEncodingDecodingCallbackBlock callbackBlock;
@property (nonatomic, copy) NSString *messageFrom;
@property (nonatomic, copy) NSString *messageTo;
@property (nonatomic, copy) NSString *messageBody;
@end

@implementation TLOEncryptionManager

#pragma mark -
#pragma mark Initialization

- (instancetype)init
{
	if ((self = [super init])) {
		[self setupEncryptionManager];

		return self;
	}

	return nil;
}

- (NSString *)pathToStoreEncryptionSecrets
{
	NSString *cachesFolder = [TPCPathInfo applicationSupportFolderPath];

	NSString *dest = [cachesFolder stringByAppendingPathComponent:@"/Encryption Components/"];

	if ([RZFileManager() fileExistsAtPath:dest] == NO) {
		[RZFileManager() createDirectoryAtPath:dest withIntermediateDirectories:YES attributes:nil error:NULL];
	}

	return dest;
}

- (void)setupEncryptionManager
{
	OTRKit *otrKit = [OTRKit sharedInstance];

	[otrKit setDelegate:self];

	[otrKit setupWithDataPath:[self pathToStoreEncryptionSecrets]];

	[self prepareEncryptionComponentPath:[otrKit privateKeyPath]];
	[self prepareEncryptionComponentPath:[otrKit fingerprintsPath]];
	[self prepareEncryptionComponentPath:[otrKit instanceTagsPath]];

	NSURL *componentPathURL = [NSURL fileURLWithPath:[self pathToStoreEncryptionSecrets] isDirectory:YES];

	NSError *attributesChangeError = nil;

	if ([componentPathURL setResourceValue:@(YES) forKey:NSURLIsHiddenKey error:&attributesChangeError] == NO) {
		LogToConsole(@"Failed to hide the folder at the path '%@': %@", componentPathURL, [attributesChangeError localizedDescription]);
	}
}

- (void)prepareEncryptionComponentPath:(NSString *)path
{
	/* Create the path if it does not already exist. */
	if ([RZFileManager() fileExistsAtPath:path] == NO) {
		NSError *writeError = nil;

		if ([NSStringEmptyPlaceholder writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:&writeError] == NO) {
			LogToConsole(@"Failed to create base file for encryption component at path: %@", [writeError localizedDescription]);
		}
	}

	/* Files are stored in a location that is accessible to Time Machine
	 which means we must mark the files to not be backed up. */
	NSURL *pathURL = [NSURL fileURLWithPath:path isDirectory:NO];

	NSError *attributesChangeError = nil;

	if ([pathURL setResourceValue:@(YES) forKey:NSURLIsExcludedFromBackupKey error:&attributesChangeError] == NO) {
		LogToConsole(@"Failed to exclude the files at the path '%@' from backup: %@", pathURL, [attributesChangeError localizedDescription]);
	}
}

#pragma mark -
#pragma mark Public API

- (void)decryptMessage:(NSString *)messageBody from:(NSString *)messageFrom to:(NSString *)messageTo operationCallback:(TLOEncryptionManagerEncodingDecodingCallbackBlock)callbackBlock
{

}

- (void)encryptMessage:(NSString *)messageBody from:(NSString *)messageFrom to:(NSString *)messageTo operationCallback:(TLOEncryptionManagerEncodingDecodingCallbackBlock)callbackBlock
{

}

#pragma mark -
#pragma mark Off-the-Record Kit Delegate

- (void)otrKit:(OTRKit *)otrKit injectMessage:(NSString *)message username:(NSString *)username accountName:(NSString *)accountName protocol:(NSString *)protocol tag:(id)tag
{
	;
}

- (void)otrKit:(OTRKit *)otrKit encodedMessage:(NSString *)encodedMessage wasEncrypted:(BOOL)wasEncrypted username:(NSString *)username accountName:(NSString *)accountName protocol:(NSString *)protocol tag:(id)tag error:(NSError *)error
{
	;
}

- (void)otrKit:(OTRKit *)otrKit decodedMessage:(NSString *)decodedMessage wasEncrypted:(BOOL)wasEncrypted tlvs:(NSArray *)tlvs username:(NSString *)username accountName:(NSString *)accountName protocol:(NSString *)protocol tag:(id)tag
{
	;
}

- (void)otrKit:(OTRKit *)otrKit updateMessageState:(OTRKitMessageState)messageState username:(NSString *)username accountName:(NSString *)accountName protocol:(NSString *)protocol
{
	;
}

- (BOOL)otrKit:(OTRKit *)otrKit isUsernameLoggedIn:(NSString *)username accountName:(NSString *)accountName protocol:(NSString *)protocol
{
	return NO;
}

- (void)otrKit:(OTRKit *)otrKit showFingerprintConfirmationForTheirHash:(NSString *)theirHash ourHash:(NSString *)ourHash username:(NSString *)username accountName:(NSString *)accountName protocol:(NSString *)protocol
{
	;
}

- (void)otrKit:(OTRKit *)otrKit handleSMPEvent:(OTRKitSMPEvent)event progress:(double)progress question:(NSString *)question username:(NSString *)username accountName:(NSString *)accountName protocol:(NSString *)protocol
{
	;
}

- (void)otrKit:(OTRKit *)otrKit handleMessageEvent:(OTRKitMessageEvent)event message:(NSString *)message username:(NSString *)username accountName:(NSString *)accountName protocol:(NSString *)protocol tag:(id)tag error:(NSError *)error
{
	;
}

- (void)otrKit:(OTRKit *)otrKit receivedSymmetricKey:(NSData *)symmetricKey forUse:(NSUInteger)use useData:(NSData *)useData username:(NSString *)username accountName:(NSString *)accountName protocol:(NSString *)protocol
{
	;
}

- (void)otrKit:(OTRKit *)otrKit willStartGeneratingPrivateKeyForAccountName:(NSString *)accountName protocol:(NSString *)protocol
{

}

- (void)otrKit:(OTRKit *)otrKit didFinishGeneratingPrivateKeyForAccountName:(NSString *)accountName protocol:(NSString *)protocol error:(NSError *)error
{
	
}

@end
