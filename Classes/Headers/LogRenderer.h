// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

@class LogController;

extern NSString *logEscape(NSString *s);

@interface LogRenderer : NSObject

+ (NSString *)renderBody:(NSString *)body 
			  controller:(LogController *)log
				 nolinks:(BOOL)hideLinks
				keywords:(NSArray *)keywords 
			excludeWords:(NSArray *)excludeWords 
		  exactWordMatch:(BOOL)exactWordMatch 
			 highlighted:(BOOL *)highlighted 
			   URLRanges:(NSArray**)urlRanges;

+ (NSString *)renderBody:(NSString *)body 
			  controller:(LogController *)log
				 nolinks:(BOOL)hideLinks
				keywords:(NSArray *)keywords 
			excludeWords:(NSArray *)excludeWords 
		  exactWordMatch:(BOOL)exactWordMatch 
			 highlighted:(BOOL *)highlighted 
			   URLRanges:(NSArray**)urlRanges
		attributedString:(BOOL)attributed;

@end