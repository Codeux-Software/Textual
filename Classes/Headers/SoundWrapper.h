// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// You can redistribute it and/or modify it under the new BSD license.
// Converted to ARC Support on Thursday, June 09, 2012

#define EMPTY_SOUND		TXTLS(@"EMPTY_SOUND")

@interface SoundWrapper : NSObject
@property (nonatomic, assign) NotificationType eventType;
@property (nonatomic, weak) NSString *displayName;
@property (nonatomic, weak) NSString *sound;
@property (nonatomic, assign) BOOL growl;
@property (nonatomic, assign) BOOL growlSticky;
@property (nonatomic, assign) BOOL disableWhileAway;

+ (SoundWrapper *)soundWrapperWithEventType:(NotificationType)eventType;
- (NotificationType)eventType;
@end
