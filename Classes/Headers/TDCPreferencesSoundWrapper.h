// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// You can redistribute it and/or modify it under the new BSD license.

#import "TextualApplication.h"

#define TXEmptySoundAlertLabel		TXTLS(@"TXEmptySoundAlertLabel")

@interface TDCPreferencesSoundWrapper : NSObject
@property (nonatomic, assign) TXNotificationType eventType;
@property (nonatomic, weak) NSString *displayName;
@property (nonatomic, weak) NSString *sound;
@property (nonatomic, assign) BOOL growl;
@property (nonatomic, assign) BOOL growlSticky;
@property (nonatomic, assign) BOOL disableWhileAway;

+ (TDCPreferencesSoundWrapper *)soundWrapperWithEventType:(TXNotificationType)eventType;
@end