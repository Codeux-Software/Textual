@interface MemberListView : ListView
{
	id dropDelegate;
	
	OtherTheme *theme;
	
	NSColor *bgColor;
	NSColor *topLineColor;
	NSColor *bottomLineColor;
	
	NSGradient *gradient;
}

@property (assign) id dropDelegate;
@property (retain) OtherTheme *theme;
@property (retain) NSColor *bgColor;
@property (retain) NSColor *topLineColor;
@property (retain) NSColor *bottomLineColor;
@property (retain) NSGradient *gradient;

- (void)themeChanged;
@end

@interface NSObject (MemberListView)
- (void)memberListViewKeyDown:(NSEvent *)e;
- (void)memberListViewDropFiles:(NSArray *)files row:(NSNumber *)row;
@end