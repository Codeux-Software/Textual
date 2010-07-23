#import <Cocoa/Cocoa.h>

@interface OtherTheme : NSObject
{	
	NSFont* inputTextFont;
	NSColor* inputTextBgColor;
	NSColor* inputTextColor;
	
	NSFont* treeFont;
	NSColor* treeBgColor;
	NSColor* treeHighlightColor;
	NSColor* treeNewTalkColor;
	NSColor* treeUnreadColor;
	
	NSColor* treeActiveColor;
	NSColor* treeInactiveColor;
	
	NSColor* treeSelActiveColor;
	NSColor* treeSelInactiveColor;
	NSColor* treeSelTopLineColor;
	NSColor* treeSelBottomLineColor;
	NSColor* treeSelTopColor;
	NSColor* treeSelBottomColor;
	
	NSFont* memberListFont;
	NSColor* memberListBgColor;
	NSColor* memberListColor;
	NSColor* memberListOpColor;
	
	NSColor* memberListSelColor;
	NSColor* memberListSelTopLineColor;
	NSColor* memberListSelBottomLineColor;
	NSColor* memberListSelTopColor;
	NSColor* memberListSelBottomColor;
}

@property (readonly) NSFont* inputTextFont;
@property (readonly) NSColor* inputTextBgColor;
@property (readonly) NSColor* inputTextColor;
@property (readonly) NSFont* treeFont;
@property (readonly) NSColor* treeBgColor;
@property (readonly) NSColor* treeHighlightColor;
@property (readonly) NSColor* treeNewTalkColor;
@property (readonly) NSColor* treeUnreadColor;
@property (readonly) NSColor* treeActiveColor;
@property (readonly) NSColor* treeInactiveColor;
@property (readonly) NSColor* treeSelActiveColor;
@property (readonly) NSColor* treeSelInactiveColor;
@property (readonly) NSColor* treeSelTopLineColor;
@property (readonly) NSColor* treeSelBottomLineColor;
@property (readonly) NSColor* treeSelTopColor;
@property (readonly) NSColor* treeSelBottomColor;
@property (readonly) NSFont* memberListFont;
@property (readonly) NSColor* memberListBgColor;
@property (readonly) NSColor* memberListColor;
@property (readonly) NSColor* memberListOpColor;
@property (readonly) NSColor* memberListSelColor;
@property (readonly) NSColor* memberListSelTopLineColor;
@property (readonly) NSColor* memberListSelBottomLineColor;
@property (readonly) NSColor* memberListSelTopColor;
@property (readonly) NSColor* memberListSelBottomColor;

- (void)populateValues;

@end