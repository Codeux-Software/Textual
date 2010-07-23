#import <Cocoa/Cocoa.h>


NSString* logEscape(NSString* s);

@interface LogRenderer : NSObject

+ (void)setUp;
+ (NSString*)renderBody:(NSString*)body 
		    nolinks:(BOOL)showLinks 
		   keywords:(NSArray*)keywords 
	     excludeWords:(NSArray*)excludeWords 
	   exactWordMatch:(BOOL)exactWordMatch 
		highlighted:(BOOL*)highlighted 
		  URLRanges:(NSArray**)urlRanges;

@end