// Created by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.
// Converted to ARC Support on June 09, 2012

#import "TextualApplication.h"

typedef enum IRCAddressBookEntryType : NSInteger {
	IRCAddressBookIgnoreEntryType,
	IRCAddressBookUserTrackingEntryType
} IRCAddressBookEntryType;

@interface IRCAddressBook : NSObject
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
@property (nonatomic, assign) IRCAddressBookEntryType entryType;

- (id)initWithDictionary:(NSDictionary *)dic;
- (NSDictionary *)dictionaryValue;

- (NSString *)trackingNickname;
- (BOOL)checkIgnore:(NSString *)thehost;

- (void)processHostMaskRegex;
@end