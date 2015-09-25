/* ********************************************************************* 
                  _____         _               _
                 |_   _|____  _| |_ _   _  __ _| |
                   | |/ _ \ \/ / __| | | |/ _` | |
                   | |  __/>  <| |_| |_| | (_| | |
                   |_|\___/_/\_\\__|\__,_|\__,_|_|

 Copyright (c) 2008 - 2010 Satoshi Nakagawa <psychs AT limechat DOT net>
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

TEXTUAL_EXTERN NSStringEncoding const TXDefaultPrimaryStringEncoding;
TEXTUAL_EXTERN NSStringEncoding const TXDefaultFallbackStringEncoding;

@interface NSString (TXStringHelper)
@property (readonly, copy) NSString *stringByAppendingIRCFormattingStop;

@property (readonly, copy) NSString *channelNameToken;
- (NSString *)channelNameTokenByTrimmingAllPrefixes:(IRCClient *)client;

@property (readonly, copy) NSString *nicknameFromHostmask;
@property (readonly, copy) NSString *usernameFromHostmask;
@property (readonly, copy) NSString *addressFromHostmask;

- (id)attributedStringWithIRCFormatting:(NSFont *)preferredFont preferredFontColor:(NSColor *)preferredFontColor;
- (id)attributedStringWithIRCFormatting:(NSFont *)preferredFont preferredFontColor:(NSColor *)preferredFontColor honorFormattingPreference:(BOOL)formattingPreference;

@property (readonly, copy) NSString *stripIRCEffects;

@property (getter=isValidInternetAddress, readonly) BOOL validInternetAddress;

@property (getter=isHostmask, readonly) BOOL hostmask;

@property (getter=isIPv4Address, readonly) BOOL IPv4Address;
@property (getter=isIPv6Address, readonly) BOOL IPv6Address;
@property (getter=isIPAddress, readonly) BOOL IPAddress;

@property (getter=isModeChannelName, readonly) BOOL modeChannelName;

- (BOOL)hostmaskComponents:(NSString **)nickname username:(NSString **)username address:(NSString **)address;

@property (getter=isNickname, readonly) BOOL nickname TEXTUAL_DEPRECATED("Use -isHostmaskNickname instead");

@property (getter=isHostmaskNickname, readonly) BOOL hostmaskNickname;
@property (getter=isHostmaskAddress, readonly) BOOL hostmaskAddress;
@property (getter=isHostmaskUsername, readonly) BOOL hostmaskUsername;

@property (getter=isChannelName, readonly) BOOL channelName;
- (BOOL)isChannelName:(IRCClient *)client; // Client to parse CHANTYPES from.

@property (readonly, copy) NSString *stringWithValidURIScheme;

- (NSString *)base64EncodingWithLineLength:(NSUInteger)lineLength;
@end
