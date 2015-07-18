/* ********************************************************************* 
                  _____         _               _
                 |_   _|____  _| |_ _   _  __ _| |
                   | |/ _ \ \/ / __| | | |/ _` | |
                   | |  __/>  <| |_| |_| | (_| | |
                   |_|\___/_/\_\\__|\__,_|\__,_|_|

 Copyright (c) 2008 - 2010 Satoshi Nakagawa <psychs AT limechat DOT net>
 Copyright (c) 2010 - 2015 Codeux Software, LLC & respective contributors.
        Please see Acknowledgements.pdf for additional information.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of Textual and/or "Codeux Software, LLC", nor the 
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

#pragma mark -
#pragma mark Private Interface

#define _inputHistoryMax						50

NSString * const _inputHistoryGlobalObjectKey	= @"TLOInputHistoryDefaultObject";

@interface TLOInputHistory ()
@property (nonatomic, strong) NSMutableDictionary *historyObjects;
@property (nonatomic, copy) NSString *currentTreeItem;
@end

@interface TLOInputHistoryObject : NSObject <NSCopying>
@property (nonatomic, assign) NSInteger historyBufferPosition;
@property (nonatomic, strong) NSMutableArray *historyBuffer;
@property (nonatomic, copy) NSAttributedString *lastHistoryItem;

- (void)add:(NSAttributedString *)s;

- (NSAttributedString *)up:(NSAttributedString *)s;
- (NSAttributedString *)down:(NSAttributedString *)s;
@end

#pragma mark -
#pragma mark Input History Manager

@implementation TLOInputHistory

- (instancetype)init
{
	if ((self = [super init])) {
		self.historyObjects = [NSMutableDictionary dictionary];
	}
	
	return self;
}

- (void)destroy:(id)treeItem
{
	PointerIsEmptyAssert(treeItem);

	if ([TPCPreferences inputHistoryIsChannelSpecific]) {
		@synchronized(self.historyObjects) {
			if ([treeItem isClient]) {
				for (id childTreeItem in [treeItem channelList]) {
					[self destroy:childTreeItem];
				}
			}

			[self.historyObjects removeObjectForKey:[treeItem uniqueIdentifier]];
		}
	}
}

- (void)moveFocusTo:(id)treeItem
{
	PointerIsEmptyAssert(treeItem);

	if ([TPCPreferences inputHistoryIsChannelSpecific]) {
		/* Set current text field value to current object. */
		TLOInputHistoryObject *oldObject = [self currentObjectForFocusedTreeView];
		
		NSAttributedString *currentTextFieldValue = [mainWindowTextField() attributedStringValue];
		
		[oldObject setLastHistoryItem:[currentTextFieldValue copy]];
		
		[mainWindowTextField() setStringValue:NSStringEmptyPlaceholder];
		
		/* Change to new view. */
		self.currentTreeItem = [treeItem uniqueIdentifier];
		
		/* Does new seleciton have a history item? */
		TLOInputHistoryObject *newObject = [self currentObjectForFocusedTreeView];
		
		NSAttributedString *lastHistoryItem = [newObject lastHistoryItem];
		
		if (NSObjectIsNotEmpty(lastHistoryItem)) {
			[mainWindowTextField() setAttributedStringValue:lastHistoryItem];
		}
	} else {
		self.currentTreeItem = nil;
	}
}

- (void)inputHistoryObjectScopeDidChange
{
	@synchronized(self.historyObjects) {
		/* If the input history was made channel specific, then we copy the current
		 value of the global input history to all tree items. */
		if ([TPCPreferences inputHistoryIsChannelSpecific]) {
			for (IRCClient *u in [worldController() clientList]) {
				[self inputHistoryObjectScopeDidChangeApplyToItem:[u uniqueIdentifier]];

				for (IRCChannel *c in [u channelList]) {
					[self inputHistoryObjectScopeDidChangeApplyToItem:[c uniqueIdentifier]];
				}
			}
			
			[self.historyObjects removeObjectForKey:_inputHistoryGlobalObjectKey];
		} else {
			/* Else, we destroy all. */
			[self.historyObjects removeAllObjects];
		}
	}
}

- (void)inputHistoryObjectScopeDidChangeApplyToItem:(NSString *)treeItem
{
	TLOInputHistoryObject *globalObject = (self.historyObjects)[_inputHistoryGlobalObjectKey];
	
	if (globalObject) {
		TLOInputHistoryObject *newObject = [globalObject copy];
		
		[newObject setLastHistoryItem:nil]; // Reset value.
		
		[self.historyObjects setValue:newObject forKey:treeItem];
	}
}

- (TLOInputHistoryObject *)currentObjectForFocusedTreeView
{
	@synchronized(self.historyObjects) {
		NSString *currentObjectKey = nil;
		
		if ([TPCPreferences inputHistoryIsChannelSpecific]) {
			currentObjectKey = self.currentTreeItem;
		} else {
			currentObjectKey = _inputHistoryGlobalObjectKey;
		}
		
		if (currentObjectKey == nil) {
			return nil;
		}
		
		TLOInputHistoryObject *currentObject = (self.historyObjects)[currentObjectKey];
		
		if (currentObject == nil) {
			currentObject = [TLOInputHistoryObject new];
			
			(self.historyObjects)[currentObjectKey] = currentObject;
		}
		
		return currentObject;
	}
}

- (void)add:(NSAttributedString *)s
{
	TLOInputHistoryObject *oldObject = [self currentObjectForFocusedTreeView];
	
	[oldObject add:s];
}

- (NSAttributedString *)up:(NSAttributedString *)s
{
	TLOInputHistoryObject *oldObject = [self currentObjectForFocusedTreeView];
	
	return [oldObject up:s];
}

- (NSAttributedString *)down:(NSAttributedString *)s
{
	TLOInputHistoryObject *oldObject = [self currentObjectForFocusedTreeView];
	
	return [oldObject down:s];
}

@end

#pragma mark -
#pragma mark Input History Objects

@implementation TLOInputHistoryObject

- (id)init
{
	if ((self = [super init])) {
		self.historyBuffer = [NSMutableArray new];
	}
	
	return self;
}

- (void)add:(NSAttributedString *)s
{
	@synchronized(self.historyBuffer) {
		NSAttributedString *lo = [self.historyBuffer lastObject];
		
		self.historyBufferPosition = [self.historyBuffer count];
		
		NSObjectIsEmptyAssert(s);
		
		if ([[lo string] isEqualToString:[s string]] == NO) {
			[self.historyBuffer addObject:s];
			
			if ([self.historyBuffer count] > _inputHistoryMax) {
				[self.historyBuffer removeObjectAtIndex:0];
			}
			
			self.historyBufferPosition = [self.historyBuffer count];
		}
	}
}

- (NSAttributedString *)up:(NSAttributedString *)s
{
	@synchronized(self.historyBuffer) {
		if (NSObjectIsNotEmpty(s)) {
			NSAttributedString *cur = nil;
			
			if (0 <= self.historyBufferPosition && self.historyBufferPosition < [self.historyBuffer count]) {
				cur = (self.historyBuffer)[self.historyBufferPosition];
			}
			
			if (NSObjectIsEmpty(cur) || [[cur string] isEqualToString:[s string]] == NO) {
				[self.historyBuffer addObject:s];
				
				if ([self.historyBuffer count] > _inputHistoryMax) {
					[self.historyBuffer removeObjectAtIndex:0];
					
					self.historyBufferPosition += 1;
				}
			}
		}
		
		self.historyBufferPosition -= 1;
		
		if (self.historyBufferPosition < 0) {
			self.historyBufferPosition = 0;
			
			return nil;
		} else if (0 <= self.historyBufferPosition && self.historyBufferPosition < [self.historyBuffer count]) {
			return (self.historyBuffer)[self.historyBufferPosition];
		} else {
			return [NSAttributedString emptyString];
		}
	}
}

- (NSAttributedString *)down:(NSAttributedString *)s
{
	@synchronized(self.historyBuffer) {
		if (NSObjectIsEmpty(s)) {
			self.historyBufferPosition = [self.historyBuffer count];
			
			return nil;
		}
		
		NSAttributedString *cur = nil;
		
		if (0 <= self.historyBufferPosition && self.historyBufferPosition < [self.historyBuffer count]) {
			cur = (self.historyBuffer)[self.historyBufferPosition];
		}
		
		if (NSObjectIsEmpty(cur) || [[cur string] isEqualToString:[s string]] == NO) {
			[self add:s];
			
			return [NSAttributedString emptyString];
		} else {
			self.historyBufferPosition += 1;
			
			if (0 <= self.historyBufferPosition &&	self.historyBufferPosition < [self.historyBuffer count]) {
				return (self.historyBuffer)[self.historyBufferPosition];
			}
			
			return [NSAttributedString emptyString];
		}
	}
}

- (id)copyWithZone:(NSZone *)zone
{
	TLOInputHistoryObject *newObject = [TLOInputHistoryObject new];
	
	[newObject setHistoryBuffer:[self.historyBuffer mutableCopy]];
	[newObject setHistoryBufferPosition:self.historyBufferPosition];
	
	[newObject setLastHistoryItem:self.lastHistoryItem];
	
	return newObject;
}

@end
