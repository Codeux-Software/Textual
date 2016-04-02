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

@interface THOPluginDidPostNewMessageConcreteObject ()
@property (nonatomic, readwrite, assign) BOOL isProcessedInBulk;
@property (nonatomic, readwrite, copy) NSString *messageContents;
@property (nonatomic, readwrite, copy) NSString *lineNumber;
@property (nonatomic, readwrite, copy) NSString *senderNickname;
@property (nonatomic, readwrite, assign) TVCLogLineType lineType;
@property (nonatomic, readwrite, assign) TVCLogLineMemberType memberType;
@property (nonatomic, readwrite, copy) NSDate *receivedAt;
@property (nonatomic, readwrite, copy) NSArray *listOfHyperlinks;
@property (nonatomic, readwrite, copy) NSSet *listOfUsers;
@property (nonatomic, readwrite, assign) BOOL keywordMatchFound;
@end

#pragma mark -

@interface THOPluginDidReceiveServerInputConcreteObject ()
@property (nonatomic, readwrite, assign) BOOL senderIsServer;
@property (nonatomic, readwrite, copy) NSString *senderNickname;
@property (nonatomic, readwrite, copy) NSString *senderUsername;
@property (nonatomic, readwrite, copy) NSString *senderAddress;
@property (nonatomic, readwrite, copy) NSString *senderHostmask;
@property (nonatomic, readwrite, copy) NSDate *receivedAt;
@property (nonatomic, readwrite, copy) NSString *messageSequence;
@property (nonatomic, readwrite, copy) NSArray *messageParamaters;
@property (nonatomic, readwrite, copy) NSString *messageCommand;
@property (nonatomic, readwrite, assign) NSInteger messageCommandNumeric;
@property (nonatomic, readwrite, copy) NSString *networkAddress;
@property (nonatomic, readwrite, copy) NSString *networkName;
@end

#pragma mark -

@interface THOPluginWebViewJavaScriptPayloadConcreteObject ()
@property (nonatomic, readwrite, copy) NSString *payloadLabel;
@property (nonatomic, readwrite, copy) id payloadContents;
@end
