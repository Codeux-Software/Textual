// Created by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

@implementation NSFont (NSFontHelper)

const CGFloat kRotationForItalicText = -14.0;   

- (NSFont *)convertToItalics
{ 
	// The following code to make a font have italics with an extra fallback is from:
	// <http://www.answerspice.com/c119/1619181/how-do-i-get-lucida-grande-italic-into-my-application>
	
	NSFont *theFont = [[NSFontManager sharedFontManager] convertFont:self toHaveTrait:NSItalicFontMask];  
	
	if ([self fontTraitSet:NSItalicFontMask] == NO) {       
		NSAffineTransform *fontTransform = [NSAffineTransform transform];    
		NSAffineTransform *italicTransform = [NSAffineTransform transform];  
		
		[fontTransform scaleBy:[NSFont systemFontSizeForControlSize:NSRegularControlSize]];           
		
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

- (BOOL)fontTraitSet:(NSFontTraitMask)trait
{
	NSFontTraitMask fontTraits = [[NSFontManager sharedFontManager] traitsOfFont:self];    
	
	return ((fontTraits & trait) == trait);
}

@end