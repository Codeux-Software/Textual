/* *********************************************************************
 *                  _____         _               _
 *                 |_   _|____  _| |_ _   _  __ _| |
 *                   | |/ _ \ \/ / __| | | |/ _` | |
 *                   | |  __/>  <| |_| |_| | (_| | |
 *                   |_|\___/_/\_\\__|\__,_|\__,_|_|
 *
 * Copyright (c) 2008 - 2010 Satoshi Nakagawa <psychs AT limechat DOT net>
 * Copyright (c) 2010 - 2015 Codeux Software, LLC & respective contributors.
 *       Please see Acknowledgements.pdf for additional information.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 *  * Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 *  * Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *  * Neither the name of Textual, "Codeux Software, LLC", nor the
 *    names of its contributors may be used to endorse or promote products
 *    derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 *
 *********************************************************************** */

#import "TLOGrowlController.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, IRCChannelType) {
	IRCChannelTypeChannel = 0,
	IRCChannelTypePrivateMessage,
	IRCChannelTypeUtility,
};

#pragma mark -
#pragma mark Immutable Object

@interface IRCChannelConfig : NSObject <NSCopying, NSMutableCopying>
@property (readonly) BOOL autoJoin;
@property (readonly) BOOL ignoreGeneralEventMessages;
@property (readonly) BOOL ignoreHighlights;
@property (readonly) BOOL inlineMediaDisabled;
@property (readonly) BOOL inlineMediaEnabled;
@property (readonly) BOOL pushNotifications;
@property (readonly) BOOL showTreeBadgeCount;
@property (readonly) IRCChannelType type;
@property (readonly, copy) NSString *channelName;
@property (readonly, copy) NSString *uniqueIdentifier;
@property (readonly, copy, nullable) NSString *label;
@property (readonly, copy, nullable) NSString *defaultModes;
@property (readonly, copy, nullable) NSString *defaultTopic;
@property (readonly, copy, nullable) NSString *secretKey;
@property (readonly, copy, nullable) NSString *secretKeyFromKeychain;

+ (IRCChannelConfig *)seedWithName:(NSString *)channelName;

- (instancetype)initWithDictionary:(NSDictionary<NSString *, id> *)dic NS_DESIGNATED_INITIALIZER;
- (NSDictionary<NSString *, id> *)dictionaryValue;

- (id)uniqueCopy;
- (id)uniqueCopyMutable;

/* Notifications */
- (nullable NSString *)soundForEvent:(TXNotificationType)event;

// These methods return an integer because there are more than
// two possible values. When there is no channel defined value
// for the given event, NSMixedState is returned which indicates
// that the global value should be used. NSOnState and NSOffState
// are returned when a channel defined value is available.
- (NSUInteger)growlEnabledForEvent:(TXNotificationType)event;
- (NSUInteger)disabledWhileAwayForEvent:(TXNotificationType)event;
- (NSUInteger)bounceDockIconForEvent:(TXNotificationType)event;
- (NSUInteger)bounceDockIconRepeatedlyForEvent:(TXNotificationType)event;
- (NSUInteger)speakEvent:(TXNotificationType)event;

/* Deprecated */
/* This property will always return NO */
@property (readonly) BOOL ignoreInlineMedia;
@end

#pragma mark -
#pragma mark Mutable Object

@interface IRCChannelConfigMutable : IRCChannelConfig
@property (nonatomic, assign, readwrite) IRCChannelType type;
@property (nonatomic, assign, readwrite) BOOL autoJoin;
@property (nonatomic, assign, readwrite) BOOL ignoreGeneralEventMessages;
@property (nonatomic, assign, readwrite) BOOL ignoreHighlights;
@property (nonatomic, assign, readwrite) BOOL inlineMediaDisabled;
@property (nonatomic, assign, readwrite) BOOL inlineMediaEnabled;
@property (nonatomic, assign, readwrite) BOOL pushNotifications;
@property (nonatomic, assign, readwrite) BOOL showTreeBadgeCount;
@property (nonatomic, copy, readwrite) NSString *channelName;
@property (nonatomic, copy, readwrite, nullable) NSString *label;
@property (nonatomic, copy, readwrite, nullable) NSString *defaultModes;
@property (nonatomic, copy, readwrite, nullable) NSString *defaultTopic;
@property (nonatomic, copy, readwrite, nullable) NSString *secretKey;

- (void)setSound:(nullable NSString *)value forEvent:(TXNotificationType)event;

// NSOnState = YES
// NSOffState = NO
// NSMixedState = Reset, use default
- (void)setGrowlEnabled:(NSUInteger)value forEvent:(TXNotificationType)event;
- (void)setDisabledWhileAway:(NSUInteger)value forEvent:(TXNotificationType)event;
- (void)setBounceDockIcon:(NSUInteger)value forEvent:(TXNotificationType)event;
- (void)setBounceDockIconRepeatedly:(NSUInteger)value forEvent:(TXNotificationType)event;
- (void)setEventIsSpoken:(NSUInteger)value forEvent:(TXNotificationType)event;

/* Deprecated */
/* Trying to set one of the following properties will throw an exception. */
@property (nonatomic, assign, readwrite) BOOL ignoreInlineMedia TEXTUAL_DEPRECATED("Use -disableInlineMedia and -enableInlineMedia instead");
@end

NS_ASSUME_NONNULL_END
