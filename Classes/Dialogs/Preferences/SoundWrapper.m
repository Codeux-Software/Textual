// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// You can redistribute it and/or modify it under the new BSD license.

@implementation SoundWrapper

- (id)initWithEventType:(GrowlNotificationType)aEventType
{
	if ((self = [super init])) {
		eventType = aEventType;
	}

	return self;
}

+ (SoundWrapper *)soundWrapperWithEventType:(GrowlNotificationType)eventType
{
	return [[[SoundWrapper alloc] initWithEventType:eventType] autodrain];
}

- (NSString *)displayName
{
	return [Preferences titleForEvent:eventType];
}

- (NSString *)sound
{
	NSString *sound = [Preferences soundForEvent:eventType];
	
	if (NSObjectIsEmpty(sound)) {
		return EMPTY_SOUND;
	} else {
		return sound;
	}
}

- (void)setSound:(NSString *)value
{
	if ([value isEqualToString:EMPTY_SOUND]) {
		value = NSNullObject;
	}
	
	if (NSObjectIsNotEmpty(value)) {
		[SoundPlayer play:value isMuted:NO];
	}
	
	[Preferences setSound:value forEvent:eventType];
}

- (BOOL)growl
{
	return [Preferences growlEnabledForEvent:eventType];
}

- (void)setGrowl:(BOOL)value
{
	[Preferences setGrowlEnabled:value forEvent:eventType];
}

- (BOOL)growlSticky
{
	return [Preferences growlStickyForEvent:eventType];
}

- (void)setGrowlSticky:(BOOL)value
{
	[Preferences setGrowlSticky:value forEvent:eventType];
}

- (BOOL)disableWhileAway
{
	return [Preferences disableWhileAwayForEvent:eventType];
}

- (void)setDisableWhileAway:(BOOL)value
{
	[Preferences setDisableWhileAway:value forEvent:eventType];
}

@end