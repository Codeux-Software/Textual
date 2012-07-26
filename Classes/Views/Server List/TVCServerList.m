/* ********************************************************************* 
       _____        _               _    ___ ____   ____
      |_   _|___  _| |_ _   _  __ _| |  |_ _|  _ \ / ___|
       | |/ _ \ \/ / __| | | |/ _` | |   | || |_) | |
       | |  __/>  <| |_| |_| | (_| | |   | ||  _ <| |___
       |_|\___/_/\_\\__|\__,_|\__,_|_|  |___|_| \_\\____|

 Copyright (c) 2010 — 2012 Codeux Software & respective contributors.
        Please see Contributors.pdf and Acknowledgements.pdf

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of the Textual IRC Client & Codeux Software nor the
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

@implementation TVCServerList

- (NSImage *)disclosureTriangleInContext:(BOOL)up selected:(BOOL)selected
{
	BOOL invertedColors = [TPCPreferences invertSidebarColors];
	
	if (invertedColors) {
		if (up) {
			if (selected) {
				return [NSImage imageNamed:@"DarkServerListViewDisclosureUpSelected"];
			} else {
				return [NSImage imageNamed:@"DarkServerListViewDisclosureUp"];
			}
		} else {
			if (selected) {
				return [NSImage imageNamed:@"DarkServerListViewDisclosureDownSelected"];
			} else {
				return [NSImage imageNamed:@"DarkServerListViewDisclosureDown"];
			}
		}
	} else {
		if (up) {
			return self.defaultDisclosureTriangle;
		} else {
			return self.alternateDisclosureTriangle;
		}
	}
}

- (void)updateBackgroundColor
{
	BOOL invertedColors = [TPCPreferences invertSidebarColors];
	
	if (invertedColors) {
		[self setBackgroundColor:[NSColor internalCalibratedRed:38.0 green:38.0 blue:38.0 alpha:1]];
	} else {
		[self setBackgroundColor:[NSColor sourceListBackgroundColor]];
	}
}

- (NSRect)frameOfCellAtColumn:(NSInteger)column row:(NSInteger)row
{ 
	NSRect nrect = [super frameOfCellAtColumn:column row:row];
	
	id childItem = [self itemAtRow:row];
	
	if ([self isGroupItem:childItem] == NO) {
		if ([TPCPreferences featureAvailableToOSXLion]) {
			nrect.origin.x   += 36;
			nrect.size.width  = (self.frame.size.width - 36);
		} else {
			nrect.origin.x   += 36;
			nrect.size.width -= 36;
		}
	} else {
		nrect.origin.x   += 16;
		nrect.size.width -= 16;
	} 
	
	return nrect;
}

- (void)toggleAddServerButton
{
	NSRect clipRect = [self frame];
	
	TXMasterController *master = [self.keyDelegate master];
	TXMenuController   *menucl = [master menu];
	
	if (NSObjectIsEmpty([self.keyDelegate clients])) {
		[master.addServerButton setHidden:NO];
		[master.addServerButton setTarget:menucl];
		[master.addServerButton setAction:@selector(addServer:)];
		
		NSRect winRect = [master.serverSplitView frame];
		NSRect oldRect = [master.addServerButton frame];
		
		oldRect.origin = NSMakePoint((NSMidX(clipRect) - (oldRect.size.width / 2.0)), 
									 (NSMidY(winRect) - (oldRect.size.height / 2.0)));
		
		[master.addServerButton setFrame:oldRect];
	} else {
		[master.addServerButton setHidden:YES];
	}
}

- (NSMenu *)menuForEvent:(NSEvent *)e
{
	NSPoint   p = [self convertPoint:[e locationInWindow] fromView:nil];
	NSInteger i = [self rowAtPoint:p];
	
	if (i >= 0) {
		[self selectItemAtIndex:i];
	} else if (i == -1) {
		return [self.keyDelegate treeMenu];
	}
	
	return [self menu];
}

- (void)keyDown:(NSEvent *)e
{
	if (self.keyDelegate) {
		switch ([e keyCode]) {
			case 123 ... 126:
			case 116:
			case 121:
				break;
			default:
				if ([self.keyDelegate respondsToSelector:@selector(serverListKeyDown:)]) {
					[self.keyDelegate serverListKeyDown:e];
				}
				
				break;
		}
	}
}

- (void)drawRect:(NSRect)dirtyRect
{
	[super drawRect:dirtyRect];
	
	[self toggleAddServerButton];
}

@end