#import <Foundation/Foundation.h>

@interface CustomJSFile : NSObject
{
	NSString* fileName;
	NSString* content;
}

@property (retain, getter=fileName, setter=setFileName:) NSString* fileName;
@property (readonly) NSString* content;

- (void)reload;

@end