// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// You can redistribute it and/or modify it under the new BSD license.
// Converted to ARC Support on Thursday, June 08, 2012

@implementation TLOSoundPlayer

+ (void)play:(NSString *)name isMuted:(BOOL)muted
{
	if (NSObjectIsEmpty(name) || muted) return;
	
	if ([name isEqualToString:@"Beep"]) {
		NSBeep();
	} else {
		NSSound *sound = [NSSound soundNamed:name];
		
		if (sound) {
			[sound play];
		}
	}
}

@end