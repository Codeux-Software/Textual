// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// You can redistribute it and/or modify it under the new BSD license.

@interface LogView : WebView
{
	id keyDelegate;
	id resizeDelegate;
}

@property (nonatomic, assign) id keyDelegate;
@property (nonatomic, assign) id resizeDelegate;

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