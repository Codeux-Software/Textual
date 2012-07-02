// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// You can redistribute it and/or modify it under the new BSD license.

#import "TextualApplication.h"

@interface TLOSoundPlayer : NSObject
+ (void)play:(NSString *)name isMuted:(BOOL)muted;
@end