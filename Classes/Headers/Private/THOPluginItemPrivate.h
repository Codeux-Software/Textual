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

NS_ASSUME_NONNULL_BEGIN

@class THOPluginOutputSuppressionRule;

typedef NS_OPTIONS(NSUInteger, THOPluginItemSupportedFeatures) {
	THOPluginItemSupportsDidReceiveCommandEvent				= 1 << 1,
	THOPluginItemSupportsDidReceivePlainTextMessageEvent	= 1 << 2,
//	THOPluginItemSupportsInlineMediaManipulation			= 1 << 3,
	THOPluginItemSupportsNewMessagePostedEvent				= 1 << 4,
	THOPluginItemSupportsOutputSuppressionRules				= 1 << 5,
	THOPluginItemSupportsPreferencePane						= 1 << 6,
	THOPluginItemSupportsServerInputDataInterception		= 1 << 7,
	THOPluginItemSupportsSubscribedServerInputCommands		= 1 << 8,
	THOPluginItemSupportsSubscribedUserInputCommands		= 1 << 9,
	THOPluginItemSupportsUserInputDataInterception			= 1 << 10,
	THOPluginItemSupportsWebViewJavaScriptPayloads			= 1 << 11,
	THOPluginItemSupportsWillRenderMessageEvent				= 1 << 12,
};

@interface THOPluginItem : NSObject
@property (readonly, nullable) NSBundle *bundle;
@property (readonly, nullable) id primaryClass;
@property (readonly, assign) THOPluginItemSupportedFeatures supportedFeatures;
@property (readonly, copy, nullable) NSArray<NSString *> *supportedServerInputCommands;
@property (readonly, copy, nullable) NSArray<NSString *> *supportedUserInputCommands;
@property (readonly, copy, nullable) NSArray<THOPluginOutputSuppressionRule *> *outputSuppressionRules;
@property (readonly, copy, nullable) NSString *pluginPreferencesPaneMenuItemTitle;
@property (readonly, nullable) NSView *pluginPreferencesPaneView;

- (BOOL)loadBundle:(NSBundle *)bundle;
- (void)unloadBundle;

- (BOOL)supportsFeature:(THOPluginItemSupportedFeatures)feature;
@end

NS_ASSUME_NONNULL_END
