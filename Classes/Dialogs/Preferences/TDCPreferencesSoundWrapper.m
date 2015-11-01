/* ********************************************************************* 
                  _____         _               _
                 |_   _|____  _| |_ _   _  __ _| |
                   | |/ _ \ \/ / __| | | |/ _` | |
                   | |  __/>  <| |_| |_| | (_| | |
                   |_|\___/_/\_\\__|\__,_|\__,_|_|

 Copyright (c) 2008 - 2010 Satoshi Nakagawa <psychs AT limechat DOT net>
 Copyright (c) 2010 - 2015 Codeux Software, LLC & respective contributors.
        Please see Acknowledgements.pdf for additional information.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of Textual and/or "Codeux Software, LLC", nor the 
      names of its contributors may be used to endorse or promote products 
      derived from this software without specific prior written permission.

 THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
 ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 SUCH DAMAGE.

 *********************************************************************** */

#import "TextualApplication.h"

NSString * const TXEmptySoundAlertPreferenceValue = @"None";

@implementation TDCPreferencesSoundWrapper

- (instancetype)initWithEventType:(TXNotificationType)aEventType
{
	if ((self = [super init])) {
		self.eventType = aEventType;
		
		return self;
	}

	return nil;
}

+ (NSString *)localizedEmptySoundSelectionLabel
{
	return BLS(1234);
}

+ (TDCPreferencesSoundWrapper *)soundWrapperWithEventType:(TXNotificationType)eventType
{
	return [[TDCPreferencesSoundWrapper alloc] initWithEventType:eventType];
}

- (NSString *)displayName
{
	return [sharedGrowlController() titleForEvent:self.eventType];
}

- (NSString *)alertSound
{
	NSString *soundd = [TPCPreferences soundForEvent:self.eventType];

	if (NSObjectIsEmpty(soundd)) {
		return [TDCPreferencesSoundWrapper localizedEmptySoundSelectionLabel];
	}

	return soundd;
}

- (void)setAlertSound:(NSString *)value
{
	if ([value isEqualToString:[TDCPreferencesSoundWrapper localizedEmptySoundSelectionLabel]]) { // Do not set the default, none label
		value = TXEmptySoundAlertPreferenceValue;
	}
	
	if (NSObjectIsNotEmpty(value)) {
		[TLOSoundPlayer playAlertSound:value];
	}
	
	[TPCPreferences setSound:value forEvent:self.eventType];
}

- (BOOL)pushNotification
{
	return [TPCPreferences growlEnabledForEvent:self.eventType];
}

- (void)setPushNotification:(BOOL)value
{
	[TPCPreferences setGrowlEnabled:value forEvent:self.eventType];
}

- (BOOL)speakEvent
{
	return [TPCPreferences speakEvent:self.eventType];
}

- (void)setSpeakEvent:(BOOL)value
{
	[TPCPreferences setEventIsSpoken:value forEvent:self.eventType];
}

- (BOOL)disabledWhileAway
{
	return [TPCPreferences disabledWhileAwayForEvent:self.eventType];
}

- (void)setDisabledWhileAway:(BOOL)value
{
	[TPCPreferences setDisabledWhileAway:value forEvent:self.eventType];
}

- (BOOL)bounceDockIcon
{
    return [TPCPreferences bounceDockIconForEvent:self.eventType];
}

- (void)setBounceDockIcon:(BOOL)value
{
    [TPCPreferences setBounceDockIcon:value forEvent:self.eventType];
}

- (BOOL)bounceDockIconRepeatedly
{
    return [TPCPreferences bounceDockIconRepeatedlyForEvent:self.eventType];
}

- (void)setBounceDockIconRepeatedly:(BOOL)value
{
    [TPCPreferences setBounceDockIconRepeatedly:value forEvent:self.eventType];
}

@end
