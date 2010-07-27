// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// You can redistribute it and/or modify it under the new BSD license.

#import <Foundation/Foundation.h>

@interface TinyGrowlClient : NSObject
{
	id delegate;
	NSString* appName;
	NSArray* allNotifications;
	NSArray* defaultNotifications;
	NSImage* appIcon;
	
	NSString* clickedNotificationName;
	NSString* timedOutNotificationName;
}

@property (assign) id delegate;
@property (copy) NSString* appName;
@property (retain) NSArray* allNotifications;
@property (retain) NSArray* defaultNotifications;
@property (retain) NSImage* appIcon;
@property (retain) NSString* clickedNotificationName;
@property (retain) NSString* timedOutNotificationName;

- (void)registerApplication;

- (void)notifyWithType:(NSString*)type
				 title:(NSString*)title
		   description:(NSString*)desc;

- (void)notifyWithType:(NSString*)type
				 title:(NSString*)title
		   description:(NSString*)desc
		  clickContext:(id)context;

- (void)notifyWithType:(NSString*)type
				 title:(NSString*)title
		   description:(NSString*)desc
		  clickContext:(id)context
				sticky:(BOOL)sticky;

- (void)notifyWithType:(NSString*)type
				 title:(NSString*)title
		   description:(NSString*)desc
		  clickContext:(id)context
				sticky:(BOOL)sticky
			  priority:(NSInteger)priority
				  icon:(NSImage*)icon;
@end

@interface NSObject (TinyGrowlClientDelegate)
- (void)tinyGrowlClient:(TinyGrowlClient*)sender didClick:(id)context;
- (void)tinyGrowlClient:(TinyGrowlClient*)sender didTimeOut:(id)context;
@end