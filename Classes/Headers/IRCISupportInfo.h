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

#define IRCISupportRawSuffix				@"are supported by this server"

@interface IRCISupportInfo : NSObject
/* Technically speaking, all these properties should be readonly, but
 Textual does not enforce that too much since almost no plugins will
 be trying to override these. That is the way it is in most of the
 headers. We put trust in the idea that plugins will be basic bundles
 that do fine with our plugin API. */

@property (nonatomic, strong) NSDictionary *channelModes;
@property (nonatomic, assign) NSInteger nicknameLength;
@property (nonatomic, assign) NSInteger modesCount;
@property (nonatomic, strong) NSString *channelNamePrefixes;
@property (nonatomic, strong) NSString *networkAddress;
@property (nonatomic, strong) NSString *networkName;
@property (nonatomic, strong) NSString *networkNameActual;
@property (nonatomic, strong) NSDictionary *userModePrefixes;
@property (nonatomic, readonly, strong) NSArray *cachedConfiguration;

- (void)reset;

- (void)update:(NSString *)configData client:(IRCClient *)client;

- (NSArray *)buildConfigurationRepresentation;

- (NSString *)userModePrefixSymbol:(NSString *)mode;
- (BOOL)modeIsSupportedUserPrefix:(NSString *)mode;

- (NSArray *)parseMode:(NSString *)modeString;
- (IRCModeInfo *)createMode:(NSString *)mode;
@end
