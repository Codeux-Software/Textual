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

@implementation TVCLogLine

+ (NSString *)lineTypeString:(TVCLogLineType)type
{
	switch (type) {
		case TVCLogLineActionType:							{ return @"action";		}
		case TVCLogLineActionNoHighlightType:				{ return @"action";		}
		case TVCLogLineCTCPType:							{ return @"ctcp";		}
		case TVCLogLineDebugType:							{ return @"debug";		}
		case TVCLogLineInviteType:							{ return @"invite";		}
		case TVCLogLineJoinType:							{ return @"join";		}
		case TVCLogLineKickType:							{ return @"kick";		}
		case TVCLogLineKillType:							{ return @"kill";		}
		case TVCLogLineModeType:							{ return @"mode";		}
		case TVCLogLineNickType:							{ return @"nick";		}
		case TVCLogLineNoticeType:							{ return @"notice";		}
		case TVCLogLinePartType:							{ return @"part";		}
		case TVCLogLinePrivateMessageType:					{ return @"privmsg";	}
		case TVCLogLinePrivateMessageNoHighlightType:		{ return @"privmsg";	}
		case TVCLogLineQuitType:							{ return @"quit";		}
		case TVCLogLineTopicType:							{ return @"topic";		}
		case TVCLogLineWebsiteType:							{ return @"website";	}
	}
	
	return NSStringEmptyPlaceholder;
}

+ (NSString *)memberTypeString:(TVCLogMemberType)type
{
	if (type == TVCLogMemberLocalUserType) {
		return @"myself";
	}

	return @"normal";
}

- (NSString *)formattedTimestamp
{
	TPCThemeSettings *customSettings = self.masterController.themeController.customSettings;

	NSObjectIsEmptyAssertReturn(self.receivedAt, nil);
	
	NSString *time = TXFormattedTimestampWithOverride(self.receivedAt, [TPCPreferences themeTimestampFormat], customSettings.timestampFormat);

	NSObjectIsEmptyAssertReturn(time, nil);

	return [time stringByAppendingString:NSStringWhitespacePlaceholder];
}

- (NSString *)formattedNickname:(IRCChannel *)owner
{
	NSObjectIsEmptyAssertReturn(self.nickname, nil);
	
	if (self.lineType == TVCLogLineActionType) {
		return [NSString stringWithFormat:TXLogLineActionNicknameFormat, self.nickname];
	} else if (self.lineType == TVCLogLineNoticeType) {
		return [NSString stringWithFormat:TXLogLineNoticeNicknameFormat, self.nickname];
	}

	PointerIsEmptyAssertReturn(owner, nil);

	return [owner.client formatNick:self.nickname channel:owner];
}

- (id)initWithDictionary:(NSDictionary *)dic
{
	if ((self = [self init])) {
		NSInteger receivedAt = NSDictionaryIntegerKeyValueCompare(dic, @"receivedAt", [NSDate epochTime]);

		self.nickname				= NSDictionaryObjectKeyValueCompare(dic, @"nickname", NSStringEmptyPlaceholder);
		self.nicknameColorNumber	= NSDictionaryIntegerKeyValueCompare(dic, @"nicknameColorNumber", 0);
		
		self.messageBody		= NSDictionaryObjectKeyValueCompare(dic, @"messageBody", NSStringEmptyPlaceholder);

		self.rawCommand			= NSDictionaryObjectKeyValueCompare(dic, @"rawCommand", TXLogLineDefaultRawCommandValue);
		
		self.highlightKeywords	= NSDictionaryObjectKeyValueCompare(dic, @"highlightKeywords", @[]);
		self.excludeKeywords	= NSDictionaryObjectKeyValueCompare(dic, @"excludeKeywords", @[]);

		self.lineType			= NSDictionaryIntegerKeyValueCompare(dic, @"lineType", TVCLogLinePrivateMessageType);
		self.memberType			= NSDictionaryIntegerKeyValueCompare(dic, @"memberType", TVCLogMemberNormalType);

		self.isHistoric		= NSDictionaryBOOLKeyValueCompare(dic, @"isHistoric", self.isHistoric);
		self.isEncrypted	= NSDictionaryBOOLKeyValueCompare(dic, @"isEncrypted", self.isHistoric);

		self.receivedAt		= [NSDate dateWithTimeIntervalSince1970:receivedAt];

		return self;
	}

	return nil;
}

- (NSDictionary *)dictionaryValue
{
	NSMutableDictionary *dict = [NSMutableDictionary dictionary];

	[dict safeSetObject:@([self.receivedAt timeIntervalSince1970])		forKey:@"receivedAt"];

	[dict safeSetObject:self.excludeKeywords		forKey:@"excludeKeywords"];
	[dict safeSetObject:self.highlightKeywords		forKey:@"highlightKeywords"];
	[dict safeSetObject:self.messageBody			forKey:@"messageBody"];
	[dict safeSetObject:self.nickname				forKey:@"nickname"];
	[dict safeSetObject:self.rawCommand				forKey:@"rawCommand"];
	
	[dict safeSetObject:@(self.lineType)				forKey:@"lineType"];
	[dict safeSetObject:@(self.memberType)				forKey:@"memberType"];
	[dict safeSetObject:@(self.nicknameColorNumber)		forKey:@"nicknameColorNumber"];

	[dict setBool:self.isEncrypted		forKey:@"isEncrypted"];
	[dict setBool:self.isHistoric		forKey:@"isHistoric"];

	return dict;
}

@end
