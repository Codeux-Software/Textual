// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// You can redistribute it and/or modify it under the new BSD license.

@interface TinyGrowlClient : NSObject
{
	id delegate;
	
	NSImage *appIcon;
	NSString *appName;
	
	NSArray *allNotifications;
	NSArray *defaultNotifications;
	
	NSString *clickedNotificationName;
	NSString *timedOutNotificationName;
}

@property (nonatomic, assign) id delegate;
@property (nonatomic, copy) NSString *appName;
@property (nonatomic, retain) NSImage *appIcon;
@property (nonatomic, retain) NSArray *allNotifications;
@property (nonatomic, retain) NSArray *defaultNotifications;
@property (nonatomic, retain) NSString *clickedNotificationName;
@property (nonatomic, retain) NSString *timedOutNotificationName;

- (void)registerApplication;

- (void)notifyWithType:(NSString *)type title:(NSString *)title description:(NSString *)desc;
- (void)notifyWithType:(NSString *)type title:(NSString *)title description:(NSString *)desc clickContext:(id)context;

- (void)notifyWithType:(NSString *)type
				 title:(NSString *)title
		   description:(NSString *)desc
		  clickContext:(id)context
				sticky:(BOOL)sticky;

- (void)notifyWithType:(NSString *)type
				 title:(NSString *)title
		   description:(NSString *)desc
		  clickContext:(id)context
				sticky:(BOOL)sticky
			  priority:(NSInteger)priority
				  icon:(NSImage *)icon;
@end

@interface NSObject (TinyGrowlClientDelegate)
- (void)tinyGrowlClient:(TinyGrowlClient *)sender didClick:(id)context;
- (void)tinyGrowlClient:(TinyGrowlClient *)sender didTimeOut:(id)context;
@end