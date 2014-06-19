/* ********************************************************************* 
       _____        _               _    ___ ____   ____
      |_   _|___  _| |_ _   _  __ _| |  |_ _|  _ \ / ___|
       | |/ _ \ \/ / __| | | |/ _` | |   | || |_) | |
       | |  __/>  <| |_| |_| | (_| | |   | ||  _ <| |___
       |_|\___/_/\_\\__|\__,_|\__,_|_|  |___|_| \_\\____|

 Copyright (c) 2008 - 2010 Satoshi Nakagawa <psychs AT limechat DOT net>
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

#pragma mark -
#pragma mark Private Interface

#define _inputHistoryMax						50
#define _inputHistoryGlobalObjectKey			@"TLOInputHistoryDefaultObject"

@interface TLOInputHistory ()
@property (nonatomic, strong) NSMutableDictionary *historyObjects;
@property (nonatomic, strong) NSString *currentTreeItem;
@end

@interface TLOInputHistoryObject : NSObject <NSCopying>
@property (nonatomic, assign) NSInteger historyBufferPosition;
@property (nonatomic, strong) NSMutableArray *historyBuffer;
@property (nonatomic, strong) NSAttributedString *lastHistoryItem;

- (void)add:(NSAttributedString *)s;

- (NSAttributedString *)up:(NSAttributedString *)s;
- (NSAttributedString *)down:(NSAttributedString *)s;
@end

#warning Test new class changes.

#pragma mark -
#pragma mark Input History Manager

@implementation TLOInputHistory

- (id)init
{
	if ((self = [super init])) {
		_historyObjects = [NSMutableDictionary dictionary];
	}
	
	return self;
}

- (void)moveFocusTo:(id)treeItem
{
	if ([TPCPreferences inputHistoryIsChannelSpecific]) {
		/* Set current text field value to current object. */
		TLOInputHistoryObject *oldObject = [self currentObjectForFocusedTreeView];
		
		NSAttributedString *currentTextFieldValue = [mainWindowTextField() attributedStringValue];
		
		[oldObject setLastHistoryItem:[currentTextFieldValue copy]];
		
		[mainWindowTextField() setStringValue:NSStringEmptyPlaceholder];
		
		/* Change to new view. */
		_currentTreeItem = [treeItem uniqueIdentifier];
		
		/* Does new seleciton have a history item? */
		TLOInputHistoryObject *newObject = [self currentObjectForFocusedTreeView];
		
		NSAttributedString *lastHistoryItem = [newObject lastHistoryItem];
		
		if (NSObjectIsNotEmpty(lastHistoryItem)) {
			[mainWindowTextField() setAttributedStringValue:lastHistoryItem];
		}
	} else {
		_currentTreeItem = nil;
	}
}

- (void)inputHistoryObjectScopeDidChange
{
	/* If the input history was made channel specific, then we copy the current
	 value of the global input history to all tree items. */
	if ([TPCPreferences inputHistoryIsChannelSpecific]) {
		for (IRCClient *u in [worldController() clients]) {
			[self inputHistoryObjectScopeDidChangeApplyToItem:[u uniqueIdentifier]];

			for (IRCChannel *c in [u channels]) {
				[self inputHistoryObjectScopeDidChangeApplyToItem:[c uniqueIdentifier]];
			}
		}
		
		[_historyObjects removeObjectForKey:_inputHistoryGlobalObjectKey];
	} else {
		/* Else, we destroy all. */
		[_historyObjects removeAllObjects];
	}
}

- (void)inputHistoryObjectScopeDidChangeApplyToItem:(NSString *)treeItem
{
	TLOInputHistoryObject *globalObject = [_historyObjects objectForKey:_inputHistoryGlobalObjectKey];
	
	if (globalObject) {
		TLOInputHistoryObject *newObject = [globalObject copy];
		
		[newObject setLastHistoryItem:nil]; // Reset value.
		
		[_historyObjects setValue:newObject forKey:treeItem];
	}
}

- (TLOInputHistoryObject *)currentObjectForFocusedTreeView
{
	NSString *currentObjectKey;
	
	if ([TPCPreferences inputHistoryIsChannelSpecific]) {
		currentObjectKey = _currentTreeItem;
	} else {
		currentObjectKey = _inputHistoryGlobalObjectKey;
	}
	
	TLOInputHistoryObject *currentObject = [_historyObjects objectForKey:currentObjectKey];
	
	if (currentObject == nil) {
		currentObject = [TLOInputHistoryObject new];
		
		[_historyObjects setObject:currentObject forKey:_currentTreeItem];
	}
	
	return currentObject;
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
		_historyBuffer = [NSMutableArray new];
	}
	
	return self;
}

- (void)add:(NSAttributedString *)s
{
	NSAttributedString *lo = [_historyBuffer lastObject];
	
	_historyBufferPosition = [_historyBuffer count];

	NSObjectIsEmptyAssert(s);
	
	if ([[lo string] isEqualToString:[s string]] == NO) {
		[_historyBuffer addObject:s];
	
		if ([_historyBuffer count] > _inputHistoryMax) {
			[_historyBuffer removeObjectAtIndex:0];
		}
	
		_historyBufferPosition = [_historyBuffer count];
	}
}

- (NSAttributedString *)up:(NSAttributedString *)s
{
	if (NSObjectIsNotEmpty(s)) {
		NSAttributedString *cur = nil;
		
		if (0 <= _historyBufferPosition && _historyBufferPosition < [_historyBuffer count]) {
			cur = [_historyBuffer objectAtIndex:_historyBufferPosition];
		}
		
		if (NSObjectIsEmpty(cur) || [[cur string] isEqualToString:[s string]] == NO) {
			[_historyBuffer addObject:s];
			
			if ([_historyBuffer count] > _inputHistoryMax) {
				[_historyBuffer removeObjectAtIndex:0];
				
				_historyBufferPosition += 1;
			}
		}
	}	

	_historyBufferPosition -= 1;
	
	if (_historyBufferPosition < 0) {
		_historyBufferPosition = 0;
		
		return nil;
	} else if (0 <= _historyBufferPosition && _historyBufferPosition < [_historyBuffer count]) {
		return [_historyBuffer objectAtIndex: _historyBufferPosition];
	} else {
		return [NSAttributedString emptyString];
	}
}

- (NSAttributedString *)down:(NSAttributedString *)s
{
	if (NSObjectIsEmpty(s)) {
		_historyBufferPosition = [_historyBuffer count];
		
		return nil;
	}
	
	NSAttributedString *cur = nil;
	
	if (0 <= _historyBufferPosition && _historyBufferPosition < [_historyBuffer count]) {
		cur = [_historyBuffer objectAtIndex:_historyBufferPosition];
	}

	if (NSObjectIsEmpty(cur) || [[cur string] isEqualToString:[s string]] == NO) {
		[self add:s];
		
		return [NSAttributedString emptyString];
	} else {
		_historyBufferPosition += 1;
		
		if (0 <= _historyBufferPosition &&		 _historyBufferPosition < [_historyBuffer count]) {
			return [_historyBuffer objectAtIndex:_historyBufferPosition];
		}

		return [NSAttributedString emptyString];
	}
}

- (id)copyWithZone:(NSZone *)zone
{
	TLOInputHistoryObject *newObject = [TLOInputHistoryObject new];
	
	[newObject setHistoryBuffer:[_historyBuffer mutableCopy]];
	[newObject setHistoryBufferPosition:_historyBufferPosition];
	
	[newObject setLastHistoryItem:_lastHistoryItem];
	
	return newObject;
}

@end
