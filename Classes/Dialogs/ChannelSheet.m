// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#define WINDOW_TOOLBAR_HEIGHT	25

@interface ChannelSheet (Private)
- (void)load;
- (void)save;
- (void)update;

- (void)firstPane:(NSView *)view;
@end

@implementation ChannelSheet

@synthesize uid;
@synthesize cid;
@synthesize config;
@synthesize tabView;
@synthesize nameText;
@synthesize encryptKeyText;
@synthesize passwordText;
@synthesize modeText;
@synthesize topicText;
@synthesize autoJoinCheck;
@synthesize growlCheck;
@synthesize ihighlights;
@synthesize contentView;
@synthesize generalView;
@synthesize encryptView;
@synthesize defaultsView;
@synthesize inlineImagesCheck;
@synthesize JPQActivityCheck;

- (id)init
{
	if ((self = [super init])) {
		[NSBundle loadNibNamed:@"ChannelSheet" owner:self];
	}

	return self;
}

- (void)dealloc
{
	[config drain];
	[generalView drain];
	[encryptView drain];
	
	[super dealloc];
}

#pragma mark -
#pragma mark NSToolbar Delegates

- (void)onMenuBarItemChanged:(id)sender 
{
	switch ([sender indexOfSelectedItem]) {
		case 0:
			[self firstPane:generalView];
			break;
		case 1:
			[self firstPane:encryptView];
			break;
        case 2:
            [self firstPane:defaultsView];
            break;
		default:
			[self firstPane:generalView];
			break;
	}
} 

- (void)firstPane:(NSView *)view 
{
	NSRect windowFrame = [sheet frame];
	
	windowFrame.size.width = [view frame].size.width;
	windowFrame.size.height = ([view frame].size.height + WINDOW_TOOLBAR_HEIGHT);
	windowFrame.origin.y = (NSMaxY([sheet frame]) - ([view frame].size.height + WINDOW_TOOLBAR_HEIGHT));
	
	if (NSObjectIsNotEmpty([contentView subviews])) {
		[[[contentView subviews] safeObjectAtIndex:0] removeFromSuperview];
	}
	
	[sheet setFrame:windowFrame display:YES animate:YES];
	
	[contentView setFrame:[view frame]];
	[contentView addSubview:view];	
	
	[sheet recalculateKeyViewLoop];
}

#pragma mark -
#pragma mark Initalization Handler

- (void)start
{
	[self load];
	[self update];
	[self startSheet];
	[self firstPane:generalView];
	
	[tabView setSelectedSegment:0];
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
	modeText.stringValue = config.mode;
	topicText.stringValue = config.topic;
	passwordText.stringValue = config.password;
	encryptKeyText.stringValue = config.encryptionKey;
	
	growlCheck.state = config.growl;
	autoJoinCheck.state = config.autoJoin;
	ihighlights.state = config.ihighlights;
    JPQActivityCheck.state = config.iJPQActivity;
    inlineImagesCheck.state = config.inlineImages;
}

- (void)save
{
	config.name = nameText.stringValue;
	config.mode = modeText.stringValue;
	config.topic = topicText.stringValue;
	config.password = passwordText.stringValue;
	config.encryptionKey = encryptKeyText.stringValue;
    
	config.growl = growlCheck.state;
	config.autoJoin = autoJoinCheck.state;
    config.ihighlights = ihighlights.state;
    config.iJPQActivity = JPQActivityCheck.state;
    config.inlineImages = inlineImagesCheck.state;
	
	if ([config.name isChannelName] == NO) {
		config.name = [@"#" stringByAppendingString:config.name];
	}
}

- (void)update
{
	if (cid > 0) {
		[nameText setEditable:NO];
	}
	
	NSString *s = nameText.stringValue;
	
	[okButton setEnabled:NSObjectIsNotEmpty(s)];
}

- (void)controlTextDidChange:(NSNotification *)note
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

- (void)windowWillClose:(NSNotification *)note
{
	if ([delegate respondsToSelector:@selector(ChannelSheetWillClose:)]) {
		[delegate ChannelSheetWillClose:self];
	}
}

@end