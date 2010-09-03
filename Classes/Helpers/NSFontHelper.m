#import "NSFontHelper.h"

@implementation NSFont (NSFontHelper)

- (NSFont*)convertToItalics
{ 
	// The following code to make a font have italics with an extra fallback is from:
	// <http://www.answerspice.com/c119/1619181/how-do-i-get-lucida-grande-italic-into-my-application>
	
	NSFont *theFont = self;
	NSFontManager *sharedFontManager = [NSFontManager sharedFontManager];  
	
	theFont = [sharedFontManager convertFont:theFont toHaveTrait:NSItalicFontMask];     
	NSFontTraitMask fontTraits = [sharedFontManager traitsOfFont:theFont];    
	
	if (!((fontTraits & NSItalicFontMask) == NSItalicFontMask)) {        
		const CGFloat kRotationForItalicText = -14.0;     
		
		NSAffineTransform *fontTransform = [NSAffineTransform transform];                
		[fontTransform scaleBy:[NSFont systemFontSizeForControlSize:NSRegularControlSize]];         
		NSAffineTransformStruct italicTransformData;   
		
		italicTransformData.m11 = 1;       
		italicTransformData.m12 = 0;       
		italicTransformData.m21 = -tanf(kRotationForItalicText * acosf(0) / 90);        
		italicTransformData.m22 = 1;         
		italicTransformData.tX  = 0;       
		italicTransformData.tY  = 0;      
		
		NSAffineTransform *italicTransform = [NSAffineTransform transform];       
		[italicTransform setTransformStruct:italicTransformData];      
		[fontTransform appendTransform:italicTransform]; 
		
		theFont = [NSFont fontWithDescriptor:[theFont fontDescriptor] textTransform:fontTransform];  
		
		if (theFont) {
			return theFont;
		}
	}
	
	return self;
}

@end