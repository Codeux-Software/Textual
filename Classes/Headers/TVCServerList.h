// Created by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#import "TextualApplication.h"

@interface TVCServerList : NSOutlineView
@property (nonatomic, unsafe_unretained) id keyDelegate;

@property (nonatomic, strong) NSImage *defaultDisclosureTriangle;
@property (nonatomic, strong) NSImage *alternateDisclosureTriangle;

- (NSImage *)disclosureTriangleInContext:(BOOL)up selected:(BOOL)selected;

- (void)updateBackgroundColor;
- (void)toggleAddServerButton;
@end

@interface NSObject (ServerListDelegate)
- (void)serverListKeyDown:(NSEvent *)e;
@end