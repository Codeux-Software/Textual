#import <Cocoa/Cocoa.h>

@interface IRCWorldConfig : NSObject <NSMutableCopying>
{
	NSMutableArray* clients;
}

@property (readonly) NSMutableArray* clients;

- (id)initWithDictionary:(NSDictionary*)dic;
- (NSMutableDictionary*)dictionaryValue;

@end