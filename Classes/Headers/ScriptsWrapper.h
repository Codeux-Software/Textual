// Created by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.
// Converted to ARC Support on Thursday, June 09, 2012

@interface ScriptsWrapper : NSObject <NSTableViewDelegate, NSTableViewDataSource>
@property (nonatomic, weak) IRCWorld *world;
@property (nonatomic, strong) NSMutableArray *scripts;

- (void)populateData;
@end