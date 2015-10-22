/* ********************************************************************* 
                  _____         _               _
                 |_   _|____  _| |_ _   _  __ _| |
                   | |/ _ \ \/ / __| | | |/ _` | |
                   | |  __/>  <| |_| |_| | (_| | |
                   |_|\___/_/\_\\__|\__,_|\__,_|_|

 Copyright (c) 2008 - 2010 Satoshi Nakagawa <psychs AT limechat DOT net>
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

#import "TVCLogView.h" // @protocol

TEXTUAL_EXTERN NSString * const TVCLogControllerViewFinishedLoadingNotification;

#ifdef TXSystemIsOSXElCapitanOrLater
@interface TVCLogController : NSObject <TVCLogViewDelegate, TVCImageURLoaderDelegate, WebFrameLoadDelegate, WebResourceLoadDelegate>
#else
@interface TVCLogController : NSObject <TVCLogViewDelegate, TVCImageURLoaderDelegate>
#endif

@property (nonatomic, weak) IRCClient *associatedClient;
@property (nonatomic, weak) IRCChannel *associatedChannel;
@property (nonatomic, strong) TVCLogView *webView;
@property (nonatomic, strong) TVCLogPolicy *webViewPolicy;
@property (nonatomic, assign) BOOL isLoaded;
@property (nonatomic, assign) BOOL viewIsEncrypted;
@property (nonatomic, assign) NSInteger maximumLineCount;

@property (assign) BOOL reloadingBacklog;
@property (assign) BOOL reloadingHistory;

- (void)setUp;

- (void)notifyDidBecomeVisible;
- (void)notifyDidBecomeHidden;

- (void)preferencesChanged;

- (void)prepareForApplicationTermination;
- (void)prepareForPermanentDestruction;

- (void)nextHighlight;
- (void)previousHighlight;

- (BOOL)highlightAvailable:(BOOL)previous;

@property (readonly, copy) NSString *uniqueIdentifier;

@property (readonly, copy) DOMDocument *mainFrameDocument;

- (void)moveToTop;
- (void)moveToBottom;

@property (readonly) BOOL viewingBottom;

@property (readonly, copy) NSString *topicValue;
- (void)setTopic:(NSString *)topic;

@property (readonly) BOOL inlineImagesEnabledForView;

- (void)mark;
- (void)unmark;
- (void)goToMark;

- (void)clear;

- (void)reloadTheme;

- (void)changeTextSize:(BOOL)bigger;

- (void)print:(TVCLogLine *)logLine;
- (void)print:(TVCLogLine *)logLine completionBlock:(void(^)(BOOL highlighted))completionBlock;

- (void)executeScriptCommand:(NSString *)command withArguments:(NSArray *)args; // Defaults to onQueue YES
- (void)executeScriptCommand:(NSString *)command withArguments:(NSArray *)args onQueue:(BOOL)onQueue;
@end
