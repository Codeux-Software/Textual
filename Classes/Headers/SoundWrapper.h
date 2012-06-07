// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// You can redistribute it and/or modify it under the new BSD license.

#define EMPTY_SOUND		@"None"

@interface SoundWrapper : NSObject
{
	NotificationType eventType;
}

@property (weak, nonatomic, readonly) NSString *displayName;
@property (nonatomic, weak) NSString *sound;
@property (nonatomic, assign) BOOL growl;
@property (nonatomic, assign) BOOL growlSticky;
@property (nonatomic, assign) BOOL disableWhileAway;

+ (SoundWrapper *)soundWrapperWithEventType:(NotificationType)eventType;
- (NotificationType)eventType;

@end
