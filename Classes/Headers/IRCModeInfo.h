// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.
// Converted to ARC Support on June 09, 2012

@interface IRCModeInfo : NSObject
@property (nonatomic, assign) BOOL op;
@property (nonatomic, assign) BOOL plus;
@property (nonatomic, assign) BOOL simpleMode;
@property (nonatomic, strong) NSString *param;
@property (nonatomic, assign) unsigned char mode;

+ (IRCModeInfo *)modeInfo;
@end