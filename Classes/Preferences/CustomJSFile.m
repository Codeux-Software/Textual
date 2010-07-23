#import "CustomJSFile.h"

@interface CustomJSFile (Private)
@end

@implementation CustomJSFile

@synthesize content;

- (id)init
{
	if (self = [super init]) {
	}
	return self;
}

- (void)dealloc
{
	[fileName release];
	[content release];
	[super dealloc];
}

- (NSString*)fileName
{
	return fileName;
}

- (void)setFileName:(NSString *)value
{
	if (fileName != value) {
		[fileName release];
		fileName = [value retain];
	}
	
	[self reload];
}

- (void)reload
{
	[content release];
	
	NSData* data = [NSData dataWithContentsOfFile:fileName];
	content = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

@end