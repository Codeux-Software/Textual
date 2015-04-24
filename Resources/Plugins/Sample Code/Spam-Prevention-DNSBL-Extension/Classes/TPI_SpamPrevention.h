
#import <Foundation/Foundation.h>

#import "TextualApplication.h"

@interface TPI_SpamPreventionDNSBLController : NSObject <THOPluginProtocol>
@property (nonatomic, copy) NSDictionary *blacklist;
@end
