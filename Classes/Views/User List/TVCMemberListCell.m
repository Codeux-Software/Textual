/* ********************************************************************* 
       _____        _               _    ___ ____   ____
      |_   _|___  _| |_ _   _  __ _| |  |_ _|  _ \ / ___|
       | |/ _ \ \/ / __| | | |/ _` | |   | || |_) | |
       | |  __/>  <| |_| |_| | (_| | |   | ||  _ <| |___
       |_|\___/_/\_\\__|\__,_|\__,_|_|  |___|_| \_\\____|

 Copyright (c) 2010 — 2014 Codeux Software & respective contributors.
     Please see Acknowledgements.pdf for additional information.

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

@implementation TVCMemberListCell

#pragma mark -
#pragma mark Drawing

- (void)updateDrawing
{
	/* This ugly code is only temporary while refacotring is being worked on. */
	
	NSString *mark = [self.memberPointer mark];

	if (mark) {
		[self.textField setStringValue:[mark stringByAppendingString:[self.memberPointer nickname]]];
	} else {
		[self.textField setStringValue:[self.memberPointer nickname]];
	}
}

#pragma mark -
#pragma mark Expansion Frame

- (void)drawWithExpansionFrame
{
    /* Begin popover. */
	TVCMemberListUserInfoPopover *userInfoPopover = [mainWindowMemberList() memberListUserInfoPopover];

    /* What permissions does the user have? */
    NSString *permissions = @"BasicLanguage[1206]";

	if ([self.memberPointer q]) {
        permissions = @"BasicLanguage[1211]";
    } else if ([self.memberPointer a]) {
        permissions = @"BasicLanguage[1210]";
    } else if ([self.memberPointer o]) {
        permissions = @"BasicLanguage[1209]";
    } else if ([self.memberPointer h]) {
        permissions = @"BasicLanguage[1208]";
    } else if ([self.memberPointer v]) {
        permissions = @"BasicLanguage[1207]";
    }

    permissions = TXTLS(permissions);

    if ([self.memberPointer isCop]) {
        permissions = [permissions stringByAppendingString:BLS(1212)];
    }

    /* User info. */
	NSString *nickname = [self.memberPointer nickname];
	NSString *username = [self.memberPointer username];
	NSString *address = [self.memberPointer address];

    if (NSObjectIsEmpty(username)) {
        username = BLS(1215);
    }

    if (NSObjectIsEmpty(address)) {
        address = BLS(1215);
    }

    /* Where is our cell? */
	NSInteger rowIndex = [self rowIndex];

    NSRect cellFrame = [mainWindowMemberList() frameOfCellAtColumn:0 row:rowIndex];

    /* Pop our popover. */
	[[userInfoPopover nicknameField] setStringValue:nickname];
	[[userInfoPopover usernameField] setStringValue:username];
	
	[[userInfoPopover privilegesField] setStringValue:permissions];

	/* Interestingly enough, some IRC networks allow formatting characters.
	 That makes absolutely no sense, but let's support it in the pop up
	 just to say that we can. */
	NSAttributedString *addressAttr = [address attributedStringWithIRCFormatting:TXPreferredGlobalTableViewFont
													   honorFormattingPreference:NO];

	[[userInfoPopover addressField] setAttributedStringValue:addressAttr];
	
	/* Update away status. */
	if ([self.memberPointer isAway]) {
		[[userInfoPopover awayStatusField] setStringValue:BLS(1213)];
	} else {
		[[userInfoPopover awayStatusField] setStringValue:BLS(1214)];
	}

    [userInfoPopover showRelativeToRect:cellFrame
                                 ofView:mainWindowMemberList()
                          preferredEdge:NSMaxXEdge];
	
	[mainWindowTextField() focus]; // Add focus back to text field.
}

- (NSInteger)rowIndex
{
	return [mainWindowMemberList() rowForItem:self.memberPointer];
}

- (NSDictionary *)drawingContext
{
	NSInteger rowIndex = [self rowIndex];

	return @{
		@"isInverted"	: @([TPCPreferences invertSidebarColors]),
		@"isRetina"		: @([mainWindow() runningInHighResolutionMode]),
		@"isKeyWindow"	: @([mainWindow() isInactive] == NO),
		@"isSelected"	: @([mainWindowServerList() isRowSelected:rowIndex]),
		@"isGraphite"	: @([NSColor currentControlTint] == NSGraphiteControlTint)
	};
}

@end

#pragma mark -
#pragma mark Row View Cell

@implementation TVCMemberListRowCell

- (BOOL)isEmphasized
{
	return YES;
}

@end
