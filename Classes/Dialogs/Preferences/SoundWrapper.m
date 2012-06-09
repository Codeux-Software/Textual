// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// You can redistribute it and/or modify it under the new BSD license.
// Converted to ARC Support on Thursday, June 09, 2012

@implementation SoundWrapper

@synthesize eventType;
@synthesize displayName;
@synthesize sound;
@synthesize growl;
@synthesize growlSticky;
@synthesize disableWhileAway;

- (id)initWithEventType:(NotificationType)aEventType
{
	if ((self = [super init])) {
		self.eventType = aEventType;
	}

	return self;
}

+ (SoundWrapper *)soundWrapperWithEventType:(NotificationType)eventType
{
	return [[SoundWrapper alloc] initWithEventType:eventType];
}

- (NSString *)displayName
{
	return [Preferences titleForEvent:self.eventType];
}

- (NSString *)sound
{
	NSString *soundd = [Preferences soundForEvent:self.eventType];
	
	if (NSObjectIsEmpty(soundd)) {
		return EMPTY_SOUND;
	} else {
		return soundd;
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
	
	[Preferences setSound:value forEvent:self.eventType];
}

- (BOOL)growl
{
	return [Preferences growlEnabledForEvent:self.eventType];
}

- (void)setGrowl:(BOOL)value
{
	[Preferences setGrowlEnabled:value forEvent:self.eventType];
}

- (BOOL)growlSticky
{
	return [Preferences growlStickyForEvent:self.eventType];
}

- (void)setGrowlSticky:(BOOL)value
{
	[Preferences setGrowlSticky:value forEvent:self.eventType];
}

- (BOOL)disableWhileAway
{
	return [Preferences disableWhileAwayForEvent:self.eventType];
}

- (void)setDisableWhileAway:(BOOL)value
{
	[Preferences setDisableWhileAway:value forEvent:self.eventType];
}

- (NotificationType)eventType
{
    return self.eventType;
}

@end
