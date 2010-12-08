#import "MemberListViewCell.h"

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
	MemberListViewCell* c = [[MemberListViewCell allocWithZone:zone] init];
	c.font = self.font;
	c.member = member;
	return c;
}

- (void)calculateMarkWidth
{
	markWidth = 0;
	
	NSDictionary* style = [NSDictionary dictionaryWithObject:self.font forKey:NSFontAttributeName];
	NSArray* marks = [NSArray arrayWithObjects:@"~", @"&", @"@", @"%", @"+", @"!", nil];
	
	for (NSString* s in marks) {
		NSSize size = [s sizeWithAttributes:style];
		NSInteger width = ceil(size.width);
		if (markWidth < width) {
			markWidth = width;
		}
	}
}

+ (MemberListViewCell*)initWithTheme:(id)aTheme
{
	MemberListViewCell* cell = [[MemberListViewCell alloc] init];
	cell.theme = aTheme;
	return [cell autorelease];
}

- (void)themeChanged
{
	[self calculateMarkWidth];
}

- (NSString *)tooltipValue
{
	if (member.address && member.username) {
		return [NSString stringWithFormat:@"!%@@%@", member.username, member.address];
	}
	
	return nil;
}

- (NSRect)expansionFrameWithFrame:(NSRect)cellFrame inView:(NSView *)view
{
	NSString *tooltip = [self tooltipValue];
	
	if (tooltip) {
		NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:self.font, NSFontAttributeName, nil];
		
		NSSize hostTextSize = [tooltip sizeWithAttributes:attrs];
		NSSize nickTextSize = [[NSString stringWithFormat:@"%C%@", [member mark], [member nick]] sizeWithAttributes:attrs];
		
		float width = 25.0;
		
		width += nickTextSize.width;
		width += hostTextSize.width;
		
		if (width < cellFrame.size.width){
			return NSZeroRect;
		}
		
		return NSMakeRect((cellFrame.origin.x + 5), 
						  (cellFrame.origin.y + 5), 
						  width, cellFrame.size.height);	
	} else {
		return NSZeroRect;
	}
}

- (void)drawWithExpansionFrame:(NSRect)cellFrame inView:(NSView *)view
{
	NSString *tooltip = [self tooltipValue];
	
	if (tooltip) {
		NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:self.font, NSFontAttributeName, nil];
		NSSize nickTextSize = [[NSString stringWithFormat:@"%C%@", [member mark], [member nick]] sizeWithAttributes:attrs];
		
		float rightJustify = 6.0;
		
		if ([member mark] == ' ') {
			rightJustify = 11.0;
		}
		
		[tooltip drawAtPoint:NSMakePoint(((cellFrame.origin.x + nickTextSize.width) + rightJustify), 
										 cellFrame.origin.y) withAttributes:attrs];
		
		[self drawWithFrame:cellFrame inView:view];
	} else {
		[super drawWithExpansionFrame:cellFrame inView:view];
	}
}

- (void)drawInteriorWithFrame:(NSRect)frame inView:(NSView*)view
{
	NSWindow* window = view.window;
	NSColor* color = nil;
	
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
	
	NSMutableDictionary* style = [NSMutableDictionary dictionary];
	[style setObject:markStyle forKey:NSParagraphStyleAttributeName];
	[style setObject:self.font forKey:NSFontAttributeName];
	
	if (color) {
		[style setObject:color forKey:NSForegroundColorAttributeName];
	}
	
	NSRect rect = frame;
	rect.origin.x += MARK_LEFT_MARGIN;
	rect.size.width = markWidth;
	
	char mark = [member mark];
	if (mark != ' ') {
		NSString* markStr = [NSString stringWithFormat:@"%C", mark];
		[markStr drawInRect:rect withAttributes:style];
	}
	
	[style setObject:nickStyle forKey:NSParagraphStyleAttributeName];
	
	NSInteger offset = MARK_LEFT_MARGIN + markWidth + MARK_RIGHT_MARGIN;
	
	rect = frame;
	rect.origin.x += offset;
	rect.size.width -= offset;
	
	NSString* nick = [member nick];
	[nick drawInRect:rect withAttributes:style];
}

@end