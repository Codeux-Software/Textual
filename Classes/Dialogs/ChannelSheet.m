#import "ChannelSheet.h"
#import "NSWindowHelper.h"
#import "NSStringHelper.h"

@interface ChannelSheet (Private)
- (void)load;
- (void)save;
- (void)update;
@end

@implementation ChannelSheet

@synthesize uid;
@synthesize cid;
@synthesize config;

- (id)init
{
	if (self = [super init]) {
		[NSBundle loadNibNamed:@"ChannelSheet" owner:self];
	}
	return self;
}

- (void)dealloc
{
	[config release];
	[super dealloc];
}

- (void)start
{
	[self load];
	[self update];
	[self startSheet];
}

- (void)show
{
	[self start];
}

- (void)close
{
	delegate = nil;
	[self endSheet];
}

- (void)load
{
	nameText.stringValue = config.name;
	passwordText.stringValue = config.password;
	modeText.stringValue = config.mode;
	topicText.stringValue = config.topic;
	
	autoJoinCheck.state = config.autoJoin;
	growlCheck.state = config.growl;
}

- (void)save
{
	config.name = nameText.stringValue;
	config.password = passwordText.stringValue;
	config.mode = modeText.stringValue;
	config.topic = topicText.stringValue;

	config.autoJoin = autoJoinCheck.state;
	config.growl = growlCheck.state;
	
	if (![config.name isChannelName]) {
		config.name = [@"#" stringByAppendingString:config.name];
	}
}

- (void)update
{
	if (cid > 0) {
		[nameText setEditable:NO];
		[nameText setSelectable:NO];
		[nameText setBezeled:NO];
		[nameText setDrawsBackground:NO];
	}
	
	NSString* s = nameText.stringValue;
	[okButton setEnabled:s.length > 0];
}

- (void)controlTextDidChange:(NSNotification*)note
{
	[self update];
}

#pragma mark -
#pragma mark Actions

- (void)ok:(id)sender
{
	[self save];
	
	if ([delegate respondsToSelector:@selector(ChannelSheetOnOK:)]) {
		[delegate ChannelSheetOnOK:self];
	}
	
	[self cancel:nil];
}

- (void)cancel:(id)sender
{
	[self endSheet];
}

#pragma mark -
#pragma mark NSWindow Delegate

- (void)windowWillClose:(NSNotification*)note
{
	if ([delegate respondsToSelector:@selector(ChannelSheetWillClose:)]) {
		[delegate ChannelSheetWillClose:self];
	}
}

@synthesize nameText;
@synthesize passwordText;
@synthesize modeText;
@synthesize topicText;
@synthesize autoJoinCheck;
@synthesize growlCheck;
@end