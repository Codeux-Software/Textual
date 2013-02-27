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

#define TLOFileLoggerConsoleDirectoryName				@"Console"
#define TLOFileLoggerChannelDirectoryName				@"Channels"
#define TLOFileLoggerPrivateMessageDirectoryName		@"Queries"

@interface TLOFileLogger : NSObject
@property (nonatomic, nweak) IRCClient *client;
@property (nonatomic, nweak) IRCChannel *channel;
@property (nonatomic, assign) BOOL writePlainText; // Plain text or property list.
@property (nonatomic, assign) BOOL flatFileStructure; // Flat directory structure.
@property (nonatomic, assign) NSInteger maxEntryCount; // Only used if (writePlainText == NO)
@property (nonatomic, strong) NSString *filename;
@property (nonatomic, strong) NSString *filenameOverride;
@property (nonatomic, strong) NSString *fileWritePath;
@property (nonatomic, strong) NSFileHandle *file;

- (void)open;
- (void)close;
- (void)reset;
- (void)reopenIfNeeded;

- (void)updateCache; // Force update property list cache.

// Data read is pretty hit-or-miss for plain text logging.
// This class is designed to be used internally by Textual.
// It is not recommended to try using it inside a plugin.
- (id)data; // Types: (NSData			writePlainText == YES),
			//		  (NSDictionary		writePlainText == NO)
			//			or nil

- (NSString *)buildPath;

- (void)writePlainTextLine:(NSString *)s;
- (void)writePropertyListEntry:(NSDictionary *)s toKey:(NSString *)key;
@end
