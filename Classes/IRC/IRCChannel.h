#import <Cocoa/Cocoa.h>
#import "IRCTreeItem.h"
#import "IRCChannelConfig.h"
#import "LogController.h"
#import "IRCUser.h"
#import "IRCChannelMode.h"
#import "ChannelSheet.h"
#import "FileLogger.h"

@class IRCClient;

@interface IRCChannel : IRCTreeItem
{
	IRCClient* client;
	IRCChannelConfig* config;
	
	IRCChannelMode* mode;
	NSMutableArray* members;
	NSString* topic;
	NSString* storedTopic;
	BOOL isActive;
	BOOL isOp;
	BOOL isHalfOp;
	BOOL isModeInit;
	BOOL isNamesInit;
	BOOL isWhoInit;
	
	FileLogger* logFile;
	NSString* logDate;
	
	ChannelSheet* propertyDialog;
}

@property (assign) IRCClient* client;
@property (readonly) IRCChannelConfig* config;
@property (assign) NSString* name;
@property (readonly) NSString* password;
@property (readonly) IRCChannelMode* mode;
@property (readonly) NSMutableArray* members;
@property (readonly) NSString* channelTypeString;
@property (retain) NSString* topic;
@property (retain) NSString* storedTopic;
@property (assign) BOOL isActive;
@property (assign) BOOL isOp;
@property (assign) BOOL isHalfOp;
@property (assign) BOOL isModeInit;
@property (assign) BOOL isNamesInit;
@property (assign) BOOL isWhoInit;
@property (readonly) BOOL isChannel;
@property (readonly) BOOL isTalk;
@property (retain) ChannelSheet* propertyDialog;
@property (retain) FileLogger* logFile;
@property (retain) NSString* logDate;

- (void)setup:(IRCChannelConfig*)seed;
- (void)updateConfig:(IRCChannelConfig*)seed;
- (NSMutableDictionary*)dictionaryValue;

- (void)terminate;
- (void)closeDialogs;
- (void)preferencesChanged;

- (void)activate;
- (void)deactivate;

- (BOOL)print:(LogLine*)line;

- (void)addMember:(IRCUser*)user;
- (void)addMember:(IRCUser*)user reload:(BOOL)reload;
- (void)removeMember:(NSString*)nick;
- (void)removeMember:(NSString*)nick reload:(BOOL)reload;
- (void)renameMember:(NSString*)fromNick to:(NSString*)toNick;
- (void)updateOrAddMember:(IRCUser*)user;
- (void)changeMember:(NSString*)nick mode:(char)mode value:(BOOL)value;
- (void)clearMembers;
- (NSInteger)indexOfMember:(NSString*)nick;
- (IRCUser*)memberAtIndex:(NSInteger)index;
- (IRCUser*)findMember:(NSString*)nick;
- (NSInteger)numberOfMembers;
- (void)reloadMemberList;
@end