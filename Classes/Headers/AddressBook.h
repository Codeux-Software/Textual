// Created by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.
// Converted to ARC Support on Thursday, June 09, 2012

typedef enum {
	ADDRESS_BOOK_IGNORE_ENTRY,
	ADDRESS_BOOK_TRACKING_ENTRY
} AddressBookEntryType;

@interface AddressBook : NSObject
@property (nonatomic, assign) NSInteger cid;
@property (nonatomic, strong) NSString *hostmask;
@property (nonatomic, assign) BOOL ignorePublicMsg;
@property (nonatomic, assign) BOOL ignorePrivateMsg;
@property (nonatomic, assign) BOOL ignoreHighlights;
@property (nonatomic, assign) BOOL ignoreNotices;
@property (nonatomic, assign) BOOL ignoreCTCP;
@property (nonatomic, assign) BOOL ignoreJPQE;
@property (nonatomic, assign) BOOL notifyJoins;
@property (nonatomic, strong) NSString *hostmaskRegex;
@property (nonatomic, assign) BOOL ignorePMHighlights;
@property (nonatomic, assign) AddressBookEntryType entryType;

- (id)initWithDictionary:(NSDictionary *)dic;
- (NSDictionary *)dictionaryValue;

- (NSString *)trackingNickname;
- (BOOL)checkIgnore:(NSString *)thehost;

- (void)processHostMaskRegex;
@end