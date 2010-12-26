// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// You can redistribute it and/or modify it under the new BSD license.

#import "SoundPlayer.h"

@implementation SoundPlayer

+ (void)play:(NSString *)name isMuted:(BOOL)muted
{
	if (!name || !name.length || muted) return;
	
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