@interface MemberListView : ListView
{
	id dropDelegate;
	
	OtherTheme *theme;
	
	NSColor *bgColor;
	NSColor *topLineColor;
	NSColor *bottomLineColor;
	
	NSGradient *gradient;
}

@property (nonatomic, assign) id dropDelegate;
@property (nonatomic, retain) OtherTheme *theme;
@property (nonatomic, retain) NSColor *bgColor;
@property (nonatomic, retain) NSColor *topLineColor;
@property (nonatomic, retain) NSColor *bottomLineColor;
@property (nonatomic, retain) NSGradient *gradient;

- (void)themeChanged;
@end

@interface NSObject (MemberListView)
- (void)memberListViewKeyDown:(NSEvent *)e;
- (void)memberListViewDropFiles:(NSArray *)files row:(NSNumber *)row;
@end