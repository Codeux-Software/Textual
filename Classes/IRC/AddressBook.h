// Created by Michael Morris <mikey AT codeux DOT com> <http://github.com/mikemac11/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#import <Foundation/Foundation.h>

@interface AddressBook : NSObject
{
	NSString* hostmask;
	
	BOOL ignorePublicMsg;
	BOOL ignorePrivateMsg;
	BOOL ignoreHighlights;
	BOOL ignoreNotices;
	BOOL ignoreCTCP;
	BOOL ignoreDCC;
	BOOL ignoreJPQE;
	BOOL notifyJoins;
	BOOL notifyWhoisJoins;
	
	NSString* hostmaskRegex;
}

@property (retain) NSString* hostmask;
@property (assign) BOOL ignorePublicMsg;
@property (assign) BOOL ignorePrivateMsg;
@property (assign) BOOL ignoreHighlights;
@property (assign) BOOL ignoreNotices;
@property (assign) BOOL ignoreCTCP;
@property (assign) BOOL ignoreDCC;
@property (assign) BOOL ignoreJPQE;
@property (assign) BOOL notifyJoins;
@property (retain) NSString* hostmaskRegex;
@property BOOL notifyWhoisJoins;

- (id)initWithDictionary:(NSDictionary*)dic;
- (NSDictionary*)dictionaryValue;
- (BOOL)checkIgnore:(NSString*)thehost;
@end