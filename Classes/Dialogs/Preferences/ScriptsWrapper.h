#import <Cocoa/Cocoa.h>

@interface ScriptsWrapper : NSTableView
{
	NSMutableArray *scripts;
}

@property (retain) NSMutableArray *scripts;
@end