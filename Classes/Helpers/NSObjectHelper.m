// Created by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

@implementation NSObject (NSOjectHelper)

- (oneway void)drain
{
	if (self) {
		NSUInteger retainTotal = [self retainCount];
		
		if (retainTotal >= 1) {
			[self release];
		} 
	}
}

- (oneway void)forcedrain
{
	if (self) {
		while (self && [self retainCount] >= 0) {
			[self drain];
		}
	}
}

@end