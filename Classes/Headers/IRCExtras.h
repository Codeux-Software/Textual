// Created by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.
// Converted to ARC Support on Thursday, June 09, 2012

@class IRCWorld;

@interface IRCExtras : NSObject 
@property (nonatomic, weak) IRCWorld *world;

- (void)parseIRCProtocolURI:(NSString *)location;
- (void)createConnectionAndJoinChannel:(NSString *)s chan:(NSString *)channel;
@end