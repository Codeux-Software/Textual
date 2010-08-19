// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// You can redistribute it and/or modify it under the new BSD license.

#import <Cocoa/Cocoa.h>
#import "GrowlController.h"

#define EMPTY_SOUND		@"-"

@interface SoundWrapper : NSObject
{
	GrowlNotificationType eventType;
}

@property (nonatomic, readonly) NSString* displayName;
@property (nonatomic, assign) NSString* sound;
@property (nonatomic, assign) BOOL growl;
@property (nonatomic, assign) BOOL growlSticky;

+ (SoundWrapper*)soundWrapperWithEventType:(GrowlNotificationType)eventType;

@end