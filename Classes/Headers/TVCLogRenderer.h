// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.
// Converted to ARC Support on June 07, 2012

#import "TextualApplication.h"

typedef enum TVCLogRendererType : NSInteger {
	TVCLogRendererHTMLType,
	TVCLogRendererAttributedStringType,
} TVCLogRendererType;

TEXTUAL_EXTERN NSString *logEscape(NSString *s);
TEXTUAL_EXTERN NSString *logEscapeWithNil(NSString *s);

TEXTUAL_EXTERN NSInteger mapColorValue(NSColor *color);
TEXTUAL_EXTERN NSColor *mapColorCode(NSInteger colorChar);

@interface LVCLogRenderer : NSObject
+ (NSString *)renderBody:(NSString *)body 
			  controller:(TVCLogController *)log
			  renderType:(TVCLogRendererType)drawingType
			  properties:(NSDictionary *)inputDictionary
			  resultInfo:(NSDictionary **)outputDictionary;
@end