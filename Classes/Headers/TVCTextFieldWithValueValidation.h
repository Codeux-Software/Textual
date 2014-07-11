/* ********************************************************************* 
       _____        _               _    ___ ____   ____
      |_   _|___  _| |_ _   _  __ _| |  |_ _|  _ \ / ___|
       | |/ _ \ \/ / __| | | |/ _` | |   | || |_) | |
       | |  __/>  <| |_| |_| | (_| | |   | ||  _ <| |___
       |_|\___/_/\_\\__|\__,_|\__,_|_|  |___|_| \_\\____|

 Copyright (c) 2010 — 2014 Codeux Software & respective contributors.
     Please see Acknowledgements.pdf for additional information.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of the Textual IRC Client & Codeux Software nor the
      names of its contributors may be used to endorse or promote products
      derived from this software without specific prior written permission.

 THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
 ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 SUCH DAMAGE.

 *********************************************************************** */

#import "TextualApplication.h"

/* Keep the validation block as fast as possible as it is called every time 
 that the value of the text field is changed. */
typedef BOOL (^TVCTextFieldWithValueValidationBlock)(NSString *currentValue);

@interface TVCTextFieldWithValueValidation : NSTextField
@property (nonatomic, copy) TVCTextFieldWithValueValidationBlock validationBlock;
@property (nonatomic, assign) BOOL onlyShowStatusIfErrorOccurs; // Only show color or symbol if value is erroneous.
@property (nonatomic, assign) BOOL stringValueUsesOnlyFirstToken; // Only use everything before first space (" ") as value.
@property (nonatomic, assign) BOOL stringValueIsTrimmed; // Returned value is trimmed of whitespaces and newlines when returned. The value is returned trimmed by -value. It is also sent to the validation block as trimmed.
@property (nonatomic, assign) BOOL stringValueIsInvalidOnEmpty; // Is an empty string considered invalid?
@property (nonatomic, uweak) id textDidChangeCallback; // Calls method "-(void)validatedTextFieldTextDidChange:(id)sender" whereas "sender" is the text field.

- (NSString *)value; /* The current value. */
- (NSString *)lowercaseValue;
- (NSString *)uppercaseValue;

- (NSInteger)integerValue;

- (BOOL)valueIsEmpty;
- (BOOL)valueIsValid;

- (void)performValidation; /* Force the text field to clear cache and validate value. */
@end

/* NSComboBox is actually a subclass of NSTextField, but because there is 
 no way to have TVCTextFieldWithValueValidation as our superclass without
 reimplementing all the dynamics of NSComboBox, we have to redeclare the 
 entire API of TVCTextFieldWithValueValidation. */
@interface TVCTextFieldComboBoxWithValueValidation : NSComboBox
@property (nonatomic, copy) TVCTextFieldWithValueValidationBlock validationBlock;
@property (nonatomic, assign) BOOL onlyShowStatusIfErrorOccurs; // Only show color or symbol if value is erroneous.
@property (nonatomic, assign) BOOL stringValueUsesOnlyFirstToken; // Only use everything before first space (" ") as value.
@property (nonatomic, assign) BOOL stringValueIsTrimmed; // -stringValueUsesOnlyFirstToken returns a trimmed value of newlines and spaces. However, if you want mroe than first token, then specify this.
@property (nonatomic, assign) BOOL stringValueIsInvalidOnEmpty; // Is an empty string considered invalid?
@property (nonatomic, uweak) id textDidChangeCallback; // Calls method "-(void)validatedTextFieldTextDidChange:(id)sender" whereas "sender" is the text field.

- (NSString *)value; /* The current value. */
- (NSString *)lowercaseValue;
- (NSString *)uppercaseValue;

- (NSInteger)integerValue;

- (BOOL)valueIsEmpty;
- (BOOL)valueIsValid;

- (void)performValidation; /* Force the text field to clear cache and validate value. */
@end

/* The cell is shared by both normal text field and combo box. */
/* It will adjust the underlying frames depending on which. */
@interface TVCTextFieldWithValueValidationCell : NSTextFieldCell
@property (nonatomic, nweak) IBOutlet TVCTextFieldWithValueValidation *parentField;
@end
