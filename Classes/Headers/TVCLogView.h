// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// You can redistribute it and/or modify it under the new BSD license.

#import "TextualApplication.h"

@interface TVCLogView : WebView
@property (nonatomic, unsafe_unretained) id keyDelegate;
@property (nonatomic, unsafe_unretained) id resizeDelegate;

- (NSString *)contentString;
- (WebScriptObject *)js_api;

- (void)clearSelection;
- (BOOL)hasSelection;
- (NSString *)selection;
@end

@interface NSObject (LogViewDelegate)
- (void)logViewKeyDown:(NSEvent *)e;
- (void)logViewWillResize;
- (void)logViewDidResize;
@end