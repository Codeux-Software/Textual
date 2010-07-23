#import <Cocoa/Cocoa.h>

@interface LogTheme : NSObject
{
	NSString* fileName;
	NSURL* baseUrl;
	NSString* content;
}

@property (retain, getter=fileName, setter=setFileName:) NSString* fileName;
@property (readonly) NSURL* baseUrl;
@property (retain) NSString* content;

- (void)reload;

@end