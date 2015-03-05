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

@interface TDCPreferencesController : NSWindowController <NSOpenSavePanelDelegate>
@property (nonatomic, weak) id delegate;

- (void)show;

- (IBAction)onAddKeyword:(id)sender;
- (IBAction)onAddExcludeKeyword:(id)sender;

- (IBAction)onChangedAlertSpoken:(id)sender;
- (IBAction)onChangedAlertSound:(id)sender;
- (IBAction)onChangedAlertDisableWhileAway:(id)sender;
- (IBAction)onChangedAlertBounceDockIcon:(id)sender;
- (IBAction)onChangedAlertNotification:(id)sender;
- (IBAction)onChangedAlertType:(id)sender;

- (IBAction)onChangedCloudSyncingServices:(id)sender;
- (IBAction)onChangedCloudSyncingServicesServersOnly:(id)sender;

- (IBAction)onOpenPathToCloudFolder:(id)sender;

- (IBAction)onChangedHighlightLogging:(id)sender;
- (IBAction)onChangedHighlightType:(id)sender;
- (IBAction)onChangedInputHistoryScheme:(id)sender;
- (IBAction)onChangedMainWindowSegmentedController:(id)sender;
- (IBAction)onChangedSidebarColorInversion:(id)sender;
- (IBAction)onChangedStyle:(id)sender;
- (IBAction)onChangedTheme:(id)sender;
- (IBAction)onChangedTranscriptFolder:(id)sender;
- (IBAction)onChangedTransparency:(id)sender;
- (IBAction)onChangedUserListModeColor:(id)sender;
- (IBAction)onChangedUserListModeSortOrder:(id)sender;
- (IBAction)onChangedServerListUnreadBadgeColor:(id)sender;

- (IBAction)onChangedMainInputTextFieldFontSize:(id)sender;

- (IBAction)onHideMountainLionDeprecationWarning:(id)sender;

- (IBAction)onFileTransferIPAddressDetectionMethodChanged:(id)sender;
- (IBAction)onFileTransferDownloadDestinationFolderChanged:(id)sender;

- (IBAction)onResetUserListModeColorsToDefaults:(id)sender;
- (IBAction)onResetServerListUnreadBadgeColorsToDefault:(id)sender;

- (IBAction)onOpenPathToScripts:(id)sender;
- (IBAction)onOpenPathToThemes:(id)sender;

- (IBAction)onManageiCloudButtonClicked:(id)sender;
- (IBAction)onPurgeOfCloudDataRequested:(id)sender;
- (IBAction)onPurgeOfCloudFilesRequested:(id)sender;

- (IBAction)onSelectNewFont:(id)sender;
@end
