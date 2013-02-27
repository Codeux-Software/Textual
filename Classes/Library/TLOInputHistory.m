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

#define _inputHistoryMax			50

@implementation TLOInputHistory

- (id)init
{
	if ((self = [super init])) {
		self.historyBuffer = [NSMutableArray new];
	}
	
	return self;
}

- (void)add:(NSAttributedString *)s
{
	NSAttributedString *lo = self.historyBuffer.lastObject;
	
	self.historyBufferPosition = self.historyBuffer.count;

	NSObjectIsEmptyAssert(s);
	
	if ([lo.string isEqualToString:s.string] == NO) {
		[self.historyBuffer safeAddObject:s];
	
		if (self.historyBuffer.count > _inputHistoryMax) {
			[self.historyBuffer safeRemoveObjectAtIndex:0];
		}
	
		self.historyBufferPosition = self.historyBuffer.count;
	}
}

- (NSAttributedString *)up:(NSAttributedString *)s
{
	if (NSObjectIsNotEmpty(s)) {
		NSAttributedString *cur = nil;
		
		if (0 <= self.historyBufferPosition && self.historyBufferPosition < self.historyBuffer.count) {
			cur = [self.historyBuffer safeObjectAtIndex:self.historyBufferPosition];
		}
		
		if (NSObjectIsEmpty(cur) || [cur.string isEqualToString:s.string] == NO) {
			[self.historyBuffer safeAddObject:s];
			
			if (self.historyBuffer.count > _inputHistoryMax) {
				[self.historyBuffer safeRemoveObjectAtIndex:0];
				
				self.historyBufferPosition += 1;
			}
		}
	}	

	self.historyBufferPosition -= 1;
	
	if (self.historyBufferPosition < 0) {
		self.historyBufferPosition = 0;
		
		return nil;
	} else if (0 <= self.historyBufferPosition && self.historyBufferPosition < self.historyBuffer.count) {
		return [self.historyBuffer safeObjectAtIndex:self.historyBufferPosition];
	} else {
		return [NSAttributedString emptyString];
	}
}

- (NSAttributedString *)down:(NSAttributedString *)s
{
	if (NSObjectIsEmpty(s)) {
		self.historyBufferPosition = self.historyBuffer.count;
		
		return nil;
	}
	
	NSAttributedString *cur = nil;
	
	if (0 <= self.historyBufferPosition && self.historyBufferPosition < self.historyBuffer.count) {
		cur = [self.historyBuffer safeObjectAtIndex:self.historyBufferPosition];
	}

	if (NSObjectIsEmpty(cur) || [cur.string isEqualToString:s.string] == NO) {
		[self add:s];
		
		return [NSAttributedString emptyString];
	} else {
		self.historyBufferPosition += 1;
		
		if (0 <= self.historyBufferPosition && self.historyBufferPosition < self.historyBuffer.count) {
			return [self.historyBuffer safeObjectAtIndex:self.historyBufferPosition];
		}

		return [NSAttributedString emptyString];
	}
}

@end
