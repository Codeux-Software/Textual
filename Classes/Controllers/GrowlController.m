// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Michael Morris <mikey AT codeux DOT com> <http://github.com/mikemac11/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#import "GrowlController.h"
#import "IRCWorld.h"
#import "Preferences.h"

#define CLICK_INTERVAL						2

@interface GrowlController (Private)
@end

@implementation GrowlController

@synthesize owner;

- (id)init
{
	if (self = [super init]) {
		registered = [Preferences registeredToGrowl];
	}
	return self;
}

- (void)dealloc
{
	[growl release];
	[lastClickedContext release];
	[super dealloc];
}

- (void)registerToGrowl
{
	if (growl) return;
	
	growl = [TinyGrowlClient new];
	growl.delegate = self;
	
	if (!registered) {
		// reset growl settings
		growl.allNotifications = [NSArray array];
		growl.defaultNotifications = growl.allNotifications;
		[growl registerApplication];
	}
	
	growl.allNotifications = [NSArray arrayWithObjects:
							  TXTLS(@"GROWL_MSG_LOGIN"), TXTLS(@"GROWL_MSG_KICKED"), 
							  TXTLS(@"GROWL_MSG_INVITED"), TXTLS(@"GROWL_MSG_NEW_TALK"), 
							  TXTLS(@"GROWL_MSG_TALK_MSG"), TXTLS(@"GROWL_MSG_HIGHLIGHT"), 
							  TXTLS(@"GROWL_MSG_DISCONNECT"), TXTLS(@"GROWL_MSG_TALK_NOTICE"), 
							  TXTLS(@"GROWL_MSG_CHANNEL_MSG"), TXTLS(@"GROWL_MSG_CHANNEL_NOTICE"), 
							  TXTLS(@"GROWL_NSG_FILE_SEND_FAILED"), TXTLS(@"GROWL_MSG_FILE_RECEIVE_FAILED"), 
							  TXTLS(@"GROWL_MSG_FILE_SEND_SUCCEEDED"), TXTLS(@"GROWL_MSG_FILE_RECEIVE_REQUEST"), 
							  TXTLS(@"GROWL_MSG_FILE_RECEIVE_SUCCEEDED"), TXTLS(@"GROWL_ADDRESS_BOOK_MATCH"),
								nil];
	growl.defaultNotifications = growl.allNotifications;
	[growl registerApplication];
}

- (void)notify:(GrowlNotificationType)type title:(NSString*)title desc:(NSString*)desc context:(id)context
{
	if (![Preferences growlEnabledForEvent:type]) return;
	
	NSInteger priority = 0;
	BOOL sticky = [Preferences growlStickyForEvent:type];
	NSString* kind = nil;
	
	switch (type) {
		case GROWL_ADDRESS_BOOK_MATCH:
			kind = TXTLS(@"GROWL_ADDRESS_BOOK_MATCH");
			priority = 1;
			title = TXTLS(@"GROWL_MSG_ADDRESS_BOOK_MATCH_TITLE");
			desc = [NSString stringWithFormat:TXTLS(@"GROWL_MSG_ADDRESS_BOOK_MATCH"), desc];
			break;
		case GROWL_HIGHLIGHT:
			kind =  TXTLS(@"GROWL_MSG_HIGHLIGHT");
			priority = 1;
			title = [NSString stringWithFormat:TXTLS(@"GROWL_MSG_HIGHLIGHT_TITLE"), title];
			break;
		case GROWL_NEW_TALK:
			kind =  TXTLS(@"GROWL_MSG_NEW_TALK");
			priority = 1;
			title = TXTLS(@"GROWL_MSG_NEW_TALK_TITLE");
			break;
		case GROWL_CHANNEL_MSG:
			kind =  TXTLS(@"GROWL_MSG_CHANNEL_MSG");
			break;
		case GROWL_CHANNEL_NOTICE:
			kind =  TXTLS(@"GROWL_MSG_CHANNEL_NOTICE");
			title = [NSString stringWithFormat:TXTLS(@"GROWL_MSG_CHANNEL_NOTICE_TITLE"), title];
			break;
		case GROWL_TALK_MSG:
			kind =  TXTLS(@"GROWL_MSG_TALK_MSG");
			title = TXTLS(@"GROWL_MSG_TALK_MSG_TITLE");
			break;
		case GROWL_TALK_NOTICE:
			kind =  TXTLS(@"GROWL_MSG_TALK_NOTICE");
			title = TXTLS(@"GROWL_MSG_TALK_NOTICE_TITLE");
			break;
		case GROWL_KICKED:
			kind =  TXTLS(@"GROWL_MSG_KICKED");
			title = [NSString stringWithFormat:TXTLS(@"GROWL_MSG_KICKED_TITLE"), title];
			break;
		case GROWL_INVITED:
			kind =  TXTLS(@"GROWL_MSG_INVITED");
			title = [NSString stringWithFormat:TXTLS(@"GROWL_MSG_INVITED_TITLE"), title];
			break;
		case GROWL_LOGIN:
			kind =  TXTLS(@"GROWL_MSG_LOGIN");
			title = [NSString stringWithFormat:TXTLS(@"GROWL_MSG_LOGIN_TITLE"), title];
			break;
		case GROWL_DISCONNECT:
			kind =  TXTLS(@"GROWL_MSG_DISCONNECT");
			title = [NSString stringWithFormat:TXTLS(@"GROWL_MSG_DISCONNECT_TITLE"), title];
			break;
		case GROWL_FILE_RECEIVE_REQUEST:
			kind =  TXTLS(@"GROWL_MSG_FILE_RECEIVE_REQUEST");
			desc = [NSString stringWithFormat:TXTLS(@"GROWL_MSG_FILE_RECIEVE_REQUEST_DESC"), title, desc];
			title = TXTLS(@"GROWL_MSG_FILE_RECIEVE_REQUEST_TITLE");
			context = @"dcc";
			break;
		case GROWL_FILE_RECEIVE_SUCCESS:
			kind =  TXTLS(@"GROWL_MSG_FILE_RECEIVE_SUCCEEDED");
			desc = [NSString stringWithFormat:TXTLS(@"GROWL_MSG_FILE_RECIEVE_SUCCEEDED_DESC"), title, desc];
			title = TXTLS(@"GROWL_MSG_FILE_RECIEVE_SUCCEEDED_TITLE");
			context = @"dcc";
			break;
		case GROWL_FILE_RECEIVE_ERROR:
			kind =  TXTLS(@"GROWL_MSG_FILE_RECEIVE_FAILED");
			desc = [NSString stringWithFormat:TXTLS(@"GROWL_MSG_FILE_RECIEVE_FAILED_DESC"), title, desc];
			title = TXTLS(@"GROWL_MSG_FILE_RECIEVE_FAILED_TITLE");
			context = @"dcc";
			break;
		case GROWL_FILE_SEND_SUCCESS:
			kind =  TXTLS(@"GROWL_MSG_FILE_SEND_SUCCEEDED");
			desc = [NSString stringWithFormat:TXTLS(@"GROWL_MSG_FILE_SEND_SUCCEEDED_DESC"), title, desc];
			title = TXTLS(@"GROWL_MSG_FILE_SEND_SUCCEEDED_TITLE");
			context = @"dcc";
			break;
		case GROWL_FILE_SEND_ERROR:
			kind =  TXTLS(@"GROWL_NSG_FILE_SEND_FAILED");
			desc = [NSString stringWithFormat:TXTLS(@"GROWL_MSG_FILE_SEND_FAILED_DESC"), title, desc];
			title = TXTLS(@"GROWL_MSG_FILE_SEND_FAILED_TITLE");
			context = @"dcc";
			break;
		default:
			break;
	}
	
	[growl notifyWithType:kind title:title description:desc clickContext:context sticky:sticky priority:priority icon:nil];
}

- (void)tinyGrowlClient:(TinyGrowlClient*)sender didClick:(id)context
{
	CFAbsoluteTime now = CFAbsoluteTimeGetCurrent();
	
	if (now - lastClickedTime < CLICK_INTERVAL) {
		if (lastClickedContext && [lastClickedContext isEqual:context]) {
			return;
		}
	}
	
	lastClickedTime = now;
	[lastClickedContext release];
	lastClickedContext = [context retain];
	
	if (!registered) {
		registered = YES;
		[Preferences setRegisteredToGrowl:YES];
	}
	
	[owner.window makeKeyAndOrderFront:nil];
	[NSApp activateIgnoringOtherApps:YES];
	
	if ([context isEqualToString:@"dcc"]) {
		[owner.dcc show:YES];
	} else if ([context isKindOfClass:[NSString class]]) {
		NSString* s = context;
		NSArray* ary = [s componentsSeparatedByString:@" "];
		if (ary.count >= 2) {
			NSInteger uid = [[ary safeObjectAtIndex:0] integerValue];
			NSInteger cid = [[ary safeObjectAtIndex:1] integerValue];
			
			IRCClient* u = [owner findClientById:uid];
			IRCChannel* c = [owner findChannelByClientId:uid channelId:cid];
			if (c) {
				[owner select:c];
			}
			else if (u) {
				[owner select:u];
			}
		} else if (ary.count == 1) {
			NSInteger uid = [[ary safeObjectAtIndex:0] integerValue];
			
			IRCClient* u = [owner findClientById:uid];
			if (u) {
				[owner select:u];
			}
		}
	}
}

- (void)tinyGrowlClient:(TinyGrowlClient*)sender didTimeOut:(id)context
{
	if (!registered) {
		registered = YES;
		[Preferences setRegisteredToGrowl:YES];
	}
}

@synthesize growl;
@synthesize lastClickedContext;
@synthesize lastClickedTime;
@synthesize registered;
@end