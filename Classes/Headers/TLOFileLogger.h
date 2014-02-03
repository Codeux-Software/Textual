/* ********************************************************************* 
       _____        _               _    ___ ____   ____
      |_   _|___  _| |_ _   _  __ _| |  |_ _|  _ \ / ___|
       | |/ _ \ \/ / __| | | |/ _` | |   | || |_) | |
       | |  __/>  <| |_| |_| | (_| | |   | ||  _ <| |___
       |_|\___/_/\_\\__|\__,_|\__,_|_|  |___|_| \_\\____|

 Copyright (c) 2008 - 2010 Satoshi Nakagawa <psychs AT limechat DOT net>
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

/* This is the class used for logging to text in Textual… */
#define TLOFileLoggerConsoleDirectoryName				@"Console"
#define TLOFileLoggerChannelDirectoryName				@"Channels"
#define TLOFileLoggerPrivateMessageDirectoryName		@"Queries"

#define TLOFileLoggerUndefinedNicknameFormat	@"<%@%n>"
#define TLOFileLoggerActionNicknameFormat		@"• %n:"
#define TLOFileLoggerNoticeNicknameFormat		@"-%n-"

#define TLOFileLoggerISOStandardClockFormat			@"[%Y-%m-%dT%H:%M:%S%z]" // 2008-07-09T16:13:30+12:00
#define TLOFileLoggerTwentyFourHourClockFormat		@"[%H:%M:%S]"

@interface TLOFileLogger : NSObject
@property (nonatomic, nweak) IRCClient *client;
@property (nonatomic, nweak) IRCChannel *channel;
@property (nonatomic, strong) NSURL *filename;
@property (nonatomic, strong) NSURL *fileWritePath;
@property (nonatomic, strong) NSFileHandle *file;

- (void)open;
- (void)close;
- (void)reset;
- (void)reopenIfNeeded;

- (NSURL *)buildPath;

- (void)writeLine:(TVCLogLine *)logLine;
- (void)writePlainTextLine:(NSString *)s;
@end
