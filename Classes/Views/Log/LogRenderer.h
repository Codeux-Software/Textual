// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

extern NSString *logEscape(NSString *s);

@interface LogRenderer : NSObject

+ (void)setUp;
+ (NSString *)renderBody:(NSString *)body 
				nolinks:(BOOL)showLinks 
			   keywords:(NSArray *)keywords 
		   excludeWords:(NSArray *)excludeWords 
		 exactWordMatch:(BOOL)exactWordMatch 
			highlighted:(BOOL *)highlighted 
			  URLRanges:(NSArray**)urlRanges;

+ (id)renderBody:(NSString *)body 
		 nolinks:(BOOL)showLinks 
		keywords:(NSArray *)keywords 
	excludeWords:(NSArray *)excludeWords 
  exactWordMatch:(BOOL)exactWordMatch 
	 highlighted:(BOOL *)highlighted 
	   URLRanges:(NSArray**)urlRanges
attributedString:(BOOL)attributed;

@end