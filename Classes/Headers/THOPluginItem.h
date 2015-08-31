/* ********************************************************************* 
                  _____         _               _
                 |_   _|____  _| |_ _   _  __ _| |
                   | |/ _ \ \/ / __| | | |/ _` | |
                   | |  __/>  <| |_| |_| | (_| | |
                   |_|\___/_/\_\\__|\__,_|\__,_|_|

 Copyright (c) 2010 - 2015 Codeux Software, LLC & respective contributors.
        Please see Acknowledgements.pdf for additional information.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of Textual and/or "Codeux Software, LLC", nor the 
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

/* Please DO NOT use any code declared within this header inside of a plugin.
 The code contained by this header file was designed to be used internally for
 Textual and may be dangerous to use otherwise. */

// OldStyle = deprecated class names
// NewStyle = current class names for THOPluginProtocol
typedef NS_ENUM(NSUInteger, THOPluginItemSupportedFeaturesFlags) {
	THOPluginItemSupportedFeaturePreferencePaneOldStyleFlag						= 1 << 0,
	THOPluginItemSupportedFeatureSubscribedUserInputCommandsOldStyleFlag		= 1 << 1,
	THOPluginItemSupportedFeatureSubscribedServerInputCommandsOldStyleFlag		= 1 << 2,
	THOPluginItemSupportedFeatureInlineMediaManipulationFlag					= 1 << 3,
	THOPluginItemSupportedFeatureNewMessagePostedEventFlag						= 1 << 4,
	THOPluginItemSupportedFeatureWillRenderMessageEventFlag						= 1 << 5,
	THOPluginItemSupportedFeaturePreferencePaneNewStyleFlag						= 1 << 6,
	THOPluginItemSupportedFeatureUserInputDataInterceptionFlag					= 1 << 7,
	THOPluginItemSupportedFeatureServerInputDataInterceptionFlag				= 1 << 8,
	THOPluginItemSupportedFeatureSubscribedUserInputCommandsNewStyleFlag		= 1 << 9,
	THOPluginItemSupportedFeatureSubscribedServerInputCommandsNewStyleFlag		= 1 << 10,
	THOPluginItemSupportedFeatureOutputSuppressionRulesFlag						= 1 << 11
};

@interface THOPluginItem : NSObject
@property (nonatomic, strong) id primaryClass;
@property (nonatomic, assign) THOPluginItemSupportedFeaturesFlags supportedFeatures;
@property (nonatomic, copy) NSArray *supportedUserInputCommands;
@property (nonatomic, copy) NSArray *supportedServerInputCommands;
@property (nonatomic, copy) NSDictionary *outputSuppressionRules;
@property (readonly, strong) NSView *pluginPreferenesPaneView;
@property (readonly, copy) NSString *pluginPreferencesPaneMenuItemName;

- (BOOL)loadBundle:(NSBundle *)bundle;

- (BOOL)supportsFeature:(THOPluginItemSupportedFeaturesFlags)feature;

- (void)sendDealloc;
@end
