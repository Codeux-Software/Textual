#define MARK_LEFT_MARGIN	2
#define MARK_RIGHT_MARGIN	2

static NSInteger markWidth;

@implementation MemberListViewCell

@synthesize member;
@synthesize theme;
@synthesize nickStyle;
@synthesize markStyle;

- (id)init
{
	if ((self = [super init])) {
		markStyle = [NSMutableParagraphStyle new];
		[markStyle setAlignment:NSCenterTextAlignment];
		
		nickStyle = [NSMutableParagraphStyle new];
		[nickStyle setAlignment:NSLeftTextAlignment];
		[nickStyle setLineBreakMode:NSLineBreakByTruncatingTail];
	}
	return self;
}

- (void)dealloc
{
	[nickStyle release];
	[markStyle release];
	[member release];
	[super dealloc];
}

- (id)copyWithZone:(NSZone *)zone
{
	MemberListViewCell *c = [[MemberListViewCell allocWithZone:zone] init];
	c.font = self.font;
	c.member = member;
	return c;
}

- (void)calculateMarkWidth
{
	markWidth = 0;
	
	NSDictionary *style = [NSDictionary dictionaryWithObject:self.font forKey:NSFontAttributeName];
	NSArray *marks = [NSArray arrayWithObjects:@"~", @"&", @"@", @"%", @"+", @"!", nil];
	
	for (NSString *s in marks) {
		NSSize size = [s sizeWithAttributes:style];
		NSInteger width = ceil(size.width);
		if (markWidth < width) {
			markWidth = width;
		}
	}
}

+ (MemberListViewCell *)initWithTheme:(id)aTheme
{
	MemberListViewCell *cell = [[MemberListViewCell alloc] init];
	cell.theme = aTheme;
	return [cell autorelease];
}

- (void)themeChanged
{
	[self calculateMarkWidth];
}
/*
- (NSAttributedString *)tooltipValue
{
	if (member.address && member.username) {
		NSString *permission = @"USER_HOSTMASK_HOVER_TOOLTIP_MODE_NA";
		
		if (member.v) permission = @"USER_HOSTMASK_HOVER_TOOLTIP_MODE_V";
		if (member.h) permission = @"USER_HOSTMASK_HOVER_TOOLTIP_MODE_H";
		if (member.o) permission = @"USER_HOSTMASK_HOVER_TOOLTIP_MODE_O";
		if (member.a) permission = @"USER_HOSTMASK_HOVER_TOOLTIP_MODE_A";
		if (member.q) permission = @"USER_HOSTMASK_HOVER_TOOLTIP_MODE_Q";
		
		NSString *fullhost = [NSString stringWithFormat:@"%@%@\n%@%@\n%@%@\n%@%@", TXTLS(@"USER_HOSTMASK_HOVER_TOOLTIP_NICKNAME"), member.nick, 
																					TXTLS(@"USER_HOSTMASK_HOVER_TOOLTIP_USERNAME"), member.username, 
																					TXTLS(@"USER_HOSTMASK_HOVER_TOOLTIP_HOSTMASK"), member.address,
																					TXTLS(@"USER_HOSTMASK_HOVER_TOOLTIP_PRIVILEGES"), TXTLS(permission)];
		
		NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:[NSFont fontWithName:@"Lucida Grande" size:13], NSFontAttributeName, 
							   [NSColor whiteColor], NSForegroundColorAttributeName, nil];
		
		NSFont *boldFont = [[NSFontManager sharedFontManager] fontWithFamily:@"Lucida Grande" traits:NSBoldFontMask weight:1.0 size:13];
		
		NSMutableAttributedString *atrsTooltip = [[NSMutableAttributedString alloc] initWithString:fullhost attributes:attrs];
		
		[atrsTooltip addAttribute:NSFontAttributeName value:boldFont range:[fullhost rangeOfString:TXTLS(@"USER_HOSTMASK_HOVER_TOOLTIP_NICKNAME")]];
		[atrsTooltip addAttribute:NSFontAttributeName value:boldFont range:[fullhost rangeOfString:TXTLS(@"USER_HOSTMASK_HOVER_TOOLTIP_USERNAME")]];
		[atrsTooltip addAttribute:NSFontAttributeName value:boldFont range:[fullhost rangeOfString:TXTLS(@"USER_HOSTMASK_HOVER_TOOLTIP_HOSTMASK")]];
		[atrsTooltip addAttribute:NSFontAttributeName value:boldFont range:[fullhost rangeOfString:TXTLS(@"USER_HOSTMASK_HOVER_TOOLTIP_PRIVILEGES")]];
		
		return [atrsTooltip autorelease];
	}
	
	return nil;
}

- (NSRect)expansionFrameWithFrame:(NSRect)cellFrame inView:(NSView *)view
{
	NSAttributedString *tooltip = [self tooltipValue];
	
	if (tooltip) {
		NSSize hostTextSize = [tooltip size];
		
		if (hostTextSize.width < cellFrame.size.width){
			return NSZeroRect;
		}
		
		return NSMakeRect((cellFrame.origin.x + 5), 
						  (cellFrame.origin.y + 5), 
						  (hostTextSize.width + 31), 
						  (hostTextSize.height + 18));	
	} else {
		return NSZeroRect;
	}
}

- (void)drawWithExpansionFrame:(NSRect)cellFrame inView:(NSView *)view
{
	NSAttributedString *tooltip = [self tooltipValue];
	
	if (tooltip) {   
		[[NSColor clearColor] set];
		NSRectFill([view frame]);
		
		NSSize hostTextSize = [tooltip size];
		
		[[NSColor colorWithCalibratedWhite:0.7 alpha:0.8] setStroke];
		[[NSColor colorWithCalibratedWhite:0.1 alpha:0.8] setFill];
		
		NSRect rect = NSMakeRect((cellFrame.origin.x + 1), 
								 (cellFrame.origin.y + 1), 
								 (hostTextSize.width + 30), 
								 (hostTextSize.height + 16));
		
		NSBezierPath *path = [NSBezierPath bezierPath];
		[path appendBezierPathWithRoundedRect:rect xRadius:10 yRadius:10];
		[path setLineWidth:2];
		[path stroke];
		[path fill];
		
		[view setAlphaValue:0.5];
		
		[tooltip drawAtPoint:NSMakePoint((cellFrame.origin.x + 11), 
											 (cellFrame.origin.y + 7))];
	} else {
		[super drawWithExpansionFrame:cellFrame inView:view];
	}
}*/

- (void)drawWithFrame:(NSRect)frame inView:(NSView *)view
{
	NSWindow *window = view.window;
	NSColor *color = nil;
	
	if ([self isHighlighted]) {
		if (window && [window isMainWindow] && [window firstResponder] == view) {
			color = [theme memberListSelColor] ?: [NSColor alternateSelectedControlTextColor];
		} else {
			color = [theme memberListSelColor] ?: [NSColor selectedControlTextColor];
		}
	} else if ([member isOp]) {
		color = [theme memberListOpColor];
	} else {
		color = [theme memberListColor];
	}
	
	NSMutableDictionary *style = [NSMutableDictionary dictionary];
	[style setObject:markStyle forKey:NSParagraphStyleAttributeName];
	[style setObject:self.font forKey:NSFontAttributeName];
	
	if (color) {
		[style setObject:color forKey:NSForegroundColorAttributeName];
	}
	
	NSRect rect = frame;
	rect.origin.x += MARK_LEFT_MARGIN;
	rect.origin.y -= 1;
	rect.size.width = markWidth;
	
	char mark = [member mark];
	if (mark != ' ') {
		NSString *markStr = [NSString stringWithChar:mark];
		
		if (mark == '+' || mark == '%') {
			rect.origin.y += 1;
		}
		
		[markStr drawInRect:rect withAttributes:style];
	}
	
	[style setObject:nickStyle forKey:NSParagraphStyleAttributeName];
	
	NSInteger offset = MARK_LEFT_MARGIN + markWidth + MARK_RIGHT_MARGIN;
	
	rect = frame;
	rect.origin.x += offset;
	rect.size.width -= offset;
	
	NSString *nick = [member nick];
	[nick drawInRect:rect withAttributes:style];
}

@end