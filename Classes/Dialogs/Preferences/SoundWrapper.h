// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// You can redistribute it and/or modify it under the new BSD license.

#import <Cocoa/Cocoa.h>
#import "GrowlController.h"

#define EMPTY_SOUND		@"-"

@interface SoundWrapper : NSObject
{
	GrowlNotificationType eventType;
}

@property (readonly) NSString* displayName;
@property (assign) NSString* sound;
@property (assign) BOOL growl;
@property (assign) BOOL growlSticky;

+ (SoundWrapper*)soundWrapperWithEventType:(GrowlNotificationType)eventType;

@end