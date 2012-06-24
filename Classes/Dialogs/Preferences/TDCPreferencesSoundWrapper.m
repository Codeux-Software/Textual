// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// You can redistribute it and/or modify it under the new BSD license.
// Converted to ARC Support on June 09, 2012

#import "TextualApplication.h"

@implementation TDCPreferencesSoundWrapper


- (id)initWithEventType:(TXNotificationType)aEventType
{
	if ((self = [super init])) {
		self.eventType = aEventType;
		
		return self;
	}

	return nil;
}

+ (TDCPreferencesSoundWrapper *)soundWrapperWithEventType:(TXNotificationType)eventType
{
	return [[TDCPreferencesSoundWrapper alloc] initWithEventType:eventType];
}

- (NSString *)displayName
{
	return [TPCPreferences titleForEvent:self.eventType];
}

- (NSString *)sound
{
	NSString *soundd = [TPCPreferences soundForEvent:self.eventType];
	
	if (NSObjectIsEmpty(soundd)) {
		return TXEmptySoundAlertLabel;
	} else {
		return soundd;
	}
}

- (void)setSound:(NSString *)value
{
	if ([value isEqualToString:TXEmptySoundAlertLabel]) {
		value = NSStringEmptyPlaceholder;
	}
	
	if (NSObjectIsNotEmpty(value)) {
		[TLOSoundPlayer play:value isMuted:NO];
	}
	
	[TPCPreferences setSound:value forEvent:self.eventType];
}

- (BOOL)growl
{
	return [TPCPreferences growlEnabledForEvent:self.eventType];
}

- (void)setGrowl:(BOOL)value
{
	[TPCPreferences setGrowlEnabled:value forEvent:self.eventType];
}

- (BOOL)growlSticky
{
	return [TPCPreferences growlStickyForEvent:self.eventType];
}

- (void)setGrowlSticky:(BOOL)value
{
	[TPCPreferences setGrowlSticky:value forEvent:self.eventType];
}

- (BOOL)disableWhileAway
{
	return [TPCPreferences disableWhileAwayForEvent:self.eventType];
}

- (void)setDisableWhileAway:(BOOL)value
{
	[TPCPreferences setDisableWhileAway:value forEvent:self.eventType];
}

@end
