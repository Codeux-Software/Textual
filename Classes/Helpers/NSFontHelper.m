// Created by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

@implementation NSFont (NSFontHelper)

const CGFloat kRotationForItalicText = -14.0;   

- (NSFont *)convertToItalics
{ 
	// The following code to make a font have italics with an extra fallback is from:
	// <http://www.answerspice.com/c119/1619181/how-do-i-get-lucida-grande-italic-into-my-application>
	
	NSFont *theFont = [_NSFontManager() convertFont:self toHaveTrait:NSItalicFontMask];  
	
	if ([self fontTraitSet:NSItalicFontMask] == NO) {       
		NSAffineTransform *fontTransform	= [NSAffineTransform transform];    
		NSAffineTransform *italicTransform	= [NSAffineTransform transform];  
		
		[fontTransform scaleBy:[self pointSize]];           
		
		NSAffineTransformStruct italicTransformData;   
		
		italicTransformData.m11 = 1;       
		italicTransformData.m12 = 0;       
		italicTransformData.m21 = (-tanf(kRotationForItalicText * (acosf(0) / 90)));        
		italicTransformData.m22 = 1;         
		italicTransformData.tX  = 0;       
		italicTransformData.tY  = 0;      
		     
		[italicTransform setTransformStruct:italicTransformData];      
		[fontTransform appendTransform:italicTransform]; 
		
		theFont = [NSFont fontWithDescriptor:[theFont fontDescriptor] textTransform:fontTransform];  
		
		if (theFont) {
			return theFont;
		}
	}
	
	return self;
}

- (BOOL)fontMatchesFont:(NSFont *)otherFont
{
	NSString *oldName = [self fontName];
	NSString *newName = [otherFont fontName];
	
	NSInteger oldSize = [self pointSize];
	NSInteger newSize = [otherFont pointSize];
	
	return ([oldName isEqualToString:newName] && oldSize == newSize);
}

- (BOOL)fontTraitSet:(NSFontTraitMask)trait
{
	NSFontTraitMask fontTraits = [_NSFontManager() traitsOfFont:self];    
	
	return ((fontTraits & trait) == trait);
}

+ (BOOL)fontIsAvailable:(NSString *)fontName
{
	NSArray *systemFonts = [_NSFontManager() availableFonts];
	NSFont  *createdFont = [NSFont fontWithName:fontName size:9.0];
	
	return (createdFont || [systemFonts containsObjectIgnoringCase:fontName]);
}

- (BOOL)fontMatchesName:(NSString *)fontName
{
	return ([[self fontName] isEqualNoCase:fontName]);
}

@end