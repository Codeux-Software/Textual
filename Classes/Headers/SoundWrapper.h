// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// You can redistribute it and/or modify it under the new BSD license.

#define EMPTY_SOUND		@"None"

@interface SoundWrapper : NSObject
{
	NotificationType eventType;
}

@property (weak, readonly) NSString *displayName;
@property (weak) NSString *sound;
@property (assign) BOOL growl;
@property (assign) BOOL growlSticky;
@property (assign) BOOL disableWhileAway;

+ (SoundWrapper *)soundWrapperWithEventType:(NotificationType)eventType;
- (NotificationType)eventType;

@end
