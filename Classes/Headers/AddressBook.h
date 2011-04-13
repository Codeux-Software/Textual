// Created by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

@interface AddressBook : NSObject
{
	NSInteger cid;
	 
	NSString *hostmask;
	
	BOOL ignorePublicMsg;
	BOOL ignorePrivateMsg;
	BOOL ignoreHighlights;
	BOOL ignoreNotices;
	BOOL ignoreCTCP;
	BOOL ignoreJPQE;
	BOOL notifyJoins;
	BOOL notifyWhoisJoins;
	BOOL ignorePMHighlights;
	
	NSString *hostmaskRegex;
}

@property (assign) NSInteger cid;
@property (retain) NSString *hostmask;
@property (assign) BOOL ignorePublicMsg;
@property (assign) BOOL ignorePrivateMsg;
@property (assign) BOOL ignoreHighlights;
@property (assign) BOOL ignoreNotices;
@property (assign) BOOL ignoreCTCP;
@property (assign) BOOL ignoreJPQE;
@property (assign) BOOL notifyJoins;
@property (retain) NSString *hostmaskRegex;
@property (assign) BOOL ignorePMHighlights;
@property (assign) BOOL notifyWhoisJoins;

- (id)initWithDictionary:(NSDictionary *)dic;
- (NSDictionary *)dictionaryValue;

- (NSString *)trackingNickname;
- (BOOL)checkIgnore:(NSString *)thehost;

- (void)processHostMaskRegex;
@end