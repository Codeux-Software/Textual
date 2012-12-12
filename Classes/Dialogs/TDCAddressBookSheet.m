/* ********************************************************************* 
       _____        _               _    ___ ____   ____
      |_   _|___  _| |_ _   _  __ _| |  |_ _|  _ \ / ___|
       | |/ _ \ \/ / __| | | |/ _` | |   | || |_) | |
       | |  __/>  <| |_| |_| | (_| | |   | ||  _ <| |___
       |_|\___/_/\_\\__|\__,_|\__,_|_|  |___|_| \_\\____|

 Copyright (c) 2010 — 2013 Codeux Software & respective contributors.
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

@implementation TDCAddressBookSheet

- (id)init
{
	if ((self = [super init])) {
		[NSBundle loadNibNamed:@"TDCAddressBookSheet" owner:self];
	}

	return self;
}

- (void)start
{
	if (self.ignore.entryType == IRCAddressBookIgnoreEntryType) {
		self.sheet = self.ignoreWindow;
		
		if (NSObjectIsNotEmpty(self.ignore.hostmask)) {
			[self.hostmask setStringValue:self.ignore.hostmask];
		} 
	} else {
		self.sheet = self.notifyWindow;
		
		if (NSObjectIsNotEmpty(self.ignore.hostmask)) {
			[self.nickname setStringValue:self.ignore.hostmask];
		} 
	}
	
	[self.ignorePublicMsg		setState:self.ignore.ignorePublicMsg];
	[self.ignorePrivateMsg		setState:self.ignore.ignorePrivateMsg];
	[self.ignoreHighlights		setState:self.ignore.ignoreHighlights];
	[self.ignoreNotices			setState:self.ignore.ignoreNotices];
	[self.ignoreCTCP			setState:self.ignore.ignoreCTCP];
	[self.ignoreJPQE			setState:self.ignore.ignoreJPQE];
	[self.notifyJoins			setState:self.ignore.notifyJoins];
	[self.ignorePMHighlights	setState:self.ignore.ignorePMHighlights];
	
	[self startSheet];
}

- (void)ok:(id)sender
{
	if (self.ignore.entryType == IRCAddressBookIgnoreEntryType) {
		self.ignore.hostmask = [self.hostmask stringValue];
	} else {
		self.ignore.hostmask = [self.nickname stringValue];
	}
	
	self.ignore.ignorePublicMsg		= [self.ignorePublicMsg state];
	self.ignore.ignorePrivateMsg	= [self.ignorePrivateMsg state];
	self.ignore.ignoreHighlights	= [self.ignoreHighlights state];
	self.ignore.ignoreNotices		= [self.ignoreNotices state];
	self.ignore.ignoreCTCP			= [self.ignoreCTCP state];
	self.ignore.ignoreJPQE			= [self.ignoreJPQE state];
	self.ignore.notifyJoins			= [self.notifyJoins state];
	self.ignore.ignorePMHighlights	= [self.ignorePMHighlights state];
	
	[self.ignore processHostMaskRegex];
	
	if ([self.delegate respondsToSelector:@selector(ignoreItemSheetOnOK:)]) {
		[self.delegate ignoreItemSheetOnOK:self];
	}
	
	[super ok:sender];
}

#pragma mark -
#pragma mark NSWindow Delegate

- (void)windowWillClose:(NSNotification *)note
{
	if ([self.delegate respondsToSelector:@selector(ignoreItemSheetWillClose:)]) {
		[self.delegate ignoreItemSheetWillClose:self];
	}
}

@end