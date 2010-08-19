// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Michael Morris <mikey AT codeux DOT com> <http://github.com/mikemac11/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#import <Foundation/Foundation.h>
#import "TinyGrowlClient.h"

@class IRCWorld;

typedef enum {
	GROWL_HIGHLIGHT,
	GROWL_NEW_TALK,
	GROWL_CHANNEL_MSG,
	GROWL_CHANNEL_NOTICE,
	GROWL_TALK_MSG,
	GROWL_TALK_NOTICE,
	GROWL_KICKED,
	GROWL_INVITED,
	GROWL_LOGIN,
	GROWL_DISCONNECT,
	GROWL_FILE_RECEIVE_REQUEST,
	GROWL_FILE_RECEIVE_SUCCESS,
	GROWL_FILE_RECEIVE_ERROR,
	GROWL_FILE_SEND_SUCCESS,
	GROWL_FILE_SEND_ERROR,
	GROWL_ADDRESS_BOOK_MATCH,
} GrowlNotificationType;

@interface GrowlController : NSObject
{
	IRCWorld* owner;
	TinyGrowlClient* growl;
	id lastClickedContext;
	CFAbsoluteTime lastClickedTime;
	BOOL registered;
}

@property (nonatomic, assign) IRCWorld* owner;
@property (nonatomic, retain) TinyGrowlClient* growl;
@property (nonatomic, retain) id lastClickedContext;
@property CFAbsoluteTime lastClickedTime;
@property (nonatomic) BOOL registered;

- (void)registerToGrowl;
- (void)notify:(GrowlNotificationType)type title:(NSString*)title desc:(NSString*)desc context:(id)context;
@end