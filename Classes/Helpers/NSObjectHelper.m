// Created by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

@implementation NSObject (NSObjectHelper)

+ (id)newad 
{
	return [[[self alloc] init] autodrain];
}

- (id)adrv
{
	return [[self retain] autodrain];
}

- (oneway void)drain
{
	if ([_NSUserDefaults() boolForKey:@"DisableMemoryDeallocation"] == NO) {
		if (self) {
			NSUInteger retainTotal = [self retainCount];
			
			if (retainTotal >= 1) {
				[self release];
			} 
		}
	}
}

- (id)autodrain
{
	if ([_NSUserDefaults() boolForKey:@"DisableMemoryDeallocation"] == NO) {
		if (self) {
			return [self autorelease];
		}
	}
	
	return self;
}

- (oneway void)forcedrain
{
	if (self) {
		while (self && [self retainCount] >= 1) {
			[self drain];
		}
	}
}

@end