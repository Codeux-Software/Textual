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