// Created by Michael Morris <mikey AT codeux DOT com> <http://github.com/mikemac11/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#import <Foundation/Foundation.h>

@interface AddressBook : NSObject
{
	NSInteger cid;
	 
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

@property (nonatomic) NSInteger cid;
@property (nonatomic, retain) NSString* hostmask;
@property (nonatomic, assign) BOOL ignorePublicMsg;
@property (nonatomic, assign) BOOL ignorePrivateMsg;
@property (nonatomic, assign) BOOL ignoreHighlights;
@property (nonatomic, assign) BOOL ignoreNotices;
@property (nonatomic, assign) BOOL ignoreCTCP;
@property (nonatomic, assign) BOOL ignoreDCC;
@property (nonatomic, assign) BOOL ignoreJPQE;
@property (nonatomic, assign) BOOL notifyJoins;
@property (nonatomic, retain) NSString* hostmaskRegex;
@property (nonatomic) BOOL notifyWhoisJoins;

- (id)initWithDictionary:(NSDictionary*)dic;
- (NSDictionary*)dictionaryValue;
- (BOOL)checkIgnore:(NSString*)thehost;
@end