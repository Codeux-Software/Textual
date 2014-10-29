/* ********************************************************************* 
				  _____         _               _
				 |_   _|____  _| |_ _   _  __ _| |
				   | |/ _ \ \/ / __| | | |/ _` | |
				   | |  __/>  <| |_| |_| | (_| | |
				   |_|\___/_/\_\\__|\__,_|\__,_|_|

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
    * Neither the name of Textual and/or Codeux Software, nor the names of 
      its contributors may be used to endorse or promote products derived 
      from this software without specific prior written permission.

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

typedef enum IRCUserRank : NSInteger {
	IRCUserNoRank				= 0,	// nothing
	IRCUserIRCopRank,					// +y/+Y
	IRCUserChannelOwnerRank,			// +q
	IRCUserSuperOperatorRank,			// +a
	IRCUserNormalOperatorRank,			// +o
	IRCUserHalfOperatorRank,			// +h
	IRCUserVoicedRank,					// +v
} IRCUserRank;

@interface IRCUser : NSObject <NSCopying>
@property (nonatomic, copy) NSString *nickname;
@property (nonatomic, copy) NSString *username;
@property (nonatomic, copy) NSString *address;
@property (nonatomic, copy) NSString *realname;
@property (nonatomic, assign) NSInteger colorNumber;
@property (nonatomic, assign) BOOL q;
@property (nonatomic, assign) BOOL a;
@property (nonatomic, assign) BOOL o;
@property (nonatomic, assign) BOOL h;
@property (nonatomic, assign) BOOL v;
@property (nonatomic, assign) BOOL binircd_O; // Channel mode (+O) for channel owner on binircd.
@property (nonatomic, assign) BOOL InspIRCd_y_upper; // Channel mode (+Y) for IRCop on InspIRCd-2.0
@property (nonatomic, assign) BOOL InspIRCd_y_lower; // Channel mode (+y) for IRCop on InspIRCd-2.0
@property (nonatomic, assign) BOOL isCop;
@property (nonatomic, assign) BOOL isAway;
@property (readonly) CGFloat totalWeight;
@property (nonatomic, assign) CGFloat incomingWeight;
@property (nonatomic, assign) CGFloat outgoingWeight;
@property (nonatomic, assign) CFAbsoluteTime lastWeightFade;

+ (id)newUserOnClient:(IRCClient *)client withNickname:(NSString *)nickname;

@property (readonly, copy) NSString *mark;

@property (getter=isOp, readonly) BOOL op;
@property (getter=isHalfOp, readonly) BOOL halfOp;

@property (readonly, copy) NSString *banMask;
@property (readonly, copy) NSString *hostmask;

@property (readonly, copy) NSString *lowercaseNickname;

@property (readonly) IRCUserRank currentRank;

- (void)outgoingConversation;
- (void)incomingConversation;
- (void)conversation;

- (void)migrate:(IRCUser *)from;

- (NSComparisonResult)compare:(IRCUser *)other;

+ (NSComparator)nicknameLengthComparator;
@end
