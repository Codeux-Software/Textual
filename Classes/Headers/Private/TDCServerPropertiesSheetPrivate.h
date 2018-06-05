/* *********************************************************************
 *                  _____         _               _
 *                 |_   _|____  _| |_ _   _  __ _| |
 *                   | |/ _ \ \/ / __| | | |/ _` | |
 *                   | |  __/>  <| |_| |_| | (_| | |
 *                   |_|\___/_/\_\\__|\__,_|\__,_|_|
 *
 * Copyright (c) 2008 - 2010 Satoshi Nakagawa <psychs AT limechat DOT net>
 * Copyright (c) 2010 - 2015 Codeux Software, LLC & respective contributors.
 *       Please see Acknowledgements.pdf for additional information.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 *  * Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 *  * Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *  * Neither the name of Textual, "Codeux Software, LLC", nor the
 *    names of its contributors may be used to endorse or promote products
 *    derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 *
 *********************************************************************** */

#import "TDCSharedProtocolDefinitionsPrivate.h"
#import "TDCSheetBase.h"

NS_ASSUME_NONNULL_BEGIN

@class IRCClient, IRCClientConfig;

typedef NS_ENUM(NSUInteger, TDCServerPropertiesSheetNavigationSelection) {
	TDCServerPropertiesSheetDefaultSelection = 0,

	TDCServerPropertiesSheetAddressBookSelection = 1,
	TDCServerPropertiesSheetAutojoinSelection = 2,
	TDCServerPropertiesSheetConnectCommandsSelection = 3,
	TDCServerPropertiesSheetEncodingSelection = 4,
	TDCServerPropertiesSheetGeneralSelection = 5,
	TDCServerPropertiesSheetIdentitySelection = 6,
	TDCServerPropertiesSheetHighlightsSelection = 7,
	TDCServerPropertiesSheetDisconnectMessagesSelection = 8,
	TDCServerPropertiesSheetZncBouncerSelection = 10,
	TDCServerPropertiesSheetClientCertificateSelection = 12,
	TDCServerPropertiesSheetFloodControlSelection = 13,
	TDCServerPropertiesSheetNetworkSocketSelection = 14,
	TDCServerPropertiesSheetProxyServerSelection = 15,
	TDCServerPropertiesSheetRedundancySelection = 16,

	TDCServerPropertiesSheetNewIgnoreEntrySelection = 200
};

@protocol TDCServerPropertiesSheetDelegate;

@interface TDCServerPropertiesSheet : TDCSheetBase <TDCClientPrototype>
- (instancetype)initWithClient:(nullable IRCClient *)client NS_DESIGNATED_INITIALIZER;

- (void)startWithSelection:(TDCServerPropertiesSheetNavigationSelection)selection context:(nullable id)context;
@end

@protocol TDCServerPropertiesSheetDelegate <NSObject>
@required

- (void)serverPropertiesSheet:(TDCServerPropertiesSheet *)sender onOk:(IRCClientConfig *)config;
- (void)serverPropertiesSheetWillClose:(TDCServerPropertiesSheet *)sender;

#if TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT == 1
- (void)serverPropertiesSheet:(TDCServerPropertiesSheet *)sender removeClientFromCloud:(NSString *)clientId;
#endif
@end

NS_ASSUME_NONNULL_END
