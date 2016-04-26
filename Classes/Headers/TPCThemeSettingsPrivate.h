/* ********************************************************************* 
                  _____         _               _
                 |_   _|____  _| |_ _   _  __ _| |
                   | |/ _ \ \/ / __| | | |/ _` | |
                   | |  __/>  <| |_| |_| | (_| | |
                   |_|\___/_/\_\\__|\__,_|\__,_|_|

 Copyright (c) 2010 - 2016 Codeux Software, LLC & respective contributors.
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

NS_ASSUME_NONNULL_BEGIN

@interface TPCThemeSettings ()
@property (nonatomic, assign, readwrite) BOOL invertSidebarColors;
@property (nonatomic, assign, readwrite) BOOL js_postHandleEventNotifications;
@property (nonatomic, assign, readwrite) BOOL js_postPreferencesDidChangesNotifications;
@property (nonatomic, assign, readwrite) BOOL usesIncompatibleTemplateEngineVersion;
@property (nonatomic, copy, readwrite, nullable) NSFont *themeChannelViewFont;
@property (nonatomic, copy, readwrite, nullable) NSString *themeNicknameFormat;
@property (nonatomic, copy, readwrite, nullable) NSString *themeTimestampFormat;
@property (nonatomic, copy, readwrite, nullable) NSString *settingsKeyValueStoreName;
@property (nonatomic, copy, readwrite, nullable) NSColor *underlyingWindowColor;
@property (nonatomic, assign, readwrite) double indentationOffset;
@property (nonatomic, assign, readwrite) TPCThemeSettingsNicknameColorStyle nicknameColorStyle;
@property (nonatomic, strong) GRMustacheTemplateRepository *styleTemplateRepository;
@property (nonatomic, strong) GRMustacheTemplateRepository *appTemplateRepository;

- (void)reloadWithPath:(NSString *)path;

- (NSString *)templateNameWithLineType:(TVCLogLineType)type;
@end

NS_ASSUME_NONNULL_END
