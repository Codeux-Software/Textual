/* *********************************************************************
 *                  _____         _               _
 *                 |_   _|____  _| |_ _   _  __ _| |
 *                   | |/ _ \ \/ / __| | | |/ _` | |
 *                   | |  __/>  <| |_| |_| | (_| | |
 *                   |_|\___/_/\_\\__|\__,_|\__,_|_|
 *
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

#import "TPCThemeController.h"
#import "TPCPreferencesCloudSyncPrivate.h"
#import "TPCPreferencesLocalPrivate.h"
#import "TPCPreferencesReload.h"
#import "TPCPreferencesUserDefaults.h"
#import "TPCPreferencesCloudSyncExtensionPrivate.h"

NS_ASSUME_NONNULL_BEGIN

#if TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT == 1
#pragma mark -
#pragma mark Public

@implementation TPCPreferences (TPCPreferencesCloudSync)

NSString * const TPCPreferencesCloudSyncServicesEnabledDefaultsKey = @"SyncPreferencesToTheCloud";
NSString * const TPCPreferencesCloudSyncServicesLimitedToServersDefaultsKey = @"SyncPreferencesToTheCloudLimitedToServers";

NSString * const TPCPreferencesCloudSyncDidChangeThemeFontNotification = @"TPCPreferencesCloudSyncDidChangeThemeFontNotification";
NSString * const TPCPreferencesCloudSyncDidChangeThemeNameNotification = @"TPCPreferencesCloudSyncDidChangeThemeNameNotification";

+ (BOOL)syncPreferencesToTheCloud
{
	return [RZUserDefaults() boolForKey:TPCPreferencesCloudSyncServicesEnabledDefaultsKey];
}

+ (BOOL)syncPreferencesToTheCloudLimitedToServers
{
	return [RZUserDefaults() boolForKey:TPCPreferencesCloudSyncServicesLimitedToServersDefaultsKey];
}

@end

#pragma mark -
#pragma mark Private

@implementation TPCPreferences (TPCPreferencesCloudSyncPrivate)

+ (void)setSyncPreferencesToTheCloud:(BOOL)syncPreferencesToTheCloud
{
	return [RZUserDefaults() setBool:syncPreferencesToTheCloud forKey:TPCPreferencesCloudSyncServicesEnabledDefaultsKey];
}

+ (void)fixThemeNameMissingDuringSync
{
	BOOL missingTheme = [RZUserDefaults() boolForKey:TPCPreferencesThemeNameMissingLocallyDefaultsKey];

	if (missingTheme == NO) {
		return;
	}

	NSString *remoteValue = [sharedCloudManager() valueForKey:TPCPreferencesThemeNameDefaultsKey];

	NSString *localValue = [TPCPreferences themeName];

	if (remoteValue == nil || [localValue isEqualToString:remoteValue]) {
		return;
	}

	if ([TPCThemeController themeExists:remoteValue] == NO) {
		return;
	}

	[TPCPreferences setThemeName:remoteValue]; // Will reset the BOOL

	[TPCPreferences performReloadAction:TPCPreferencesReloadActionStyle];

	[RZNotificationCenter() postNotificationName:TPCPreferencesCloudSyncDidChangeThemeNameNotification object:nil];
}

+ (void)fixThemeFontNameMissingDuringSync
{
	BOOL fontMissing = [RZUserDefaults() boolForKey:TPCPreferencesThemeFontNameMissingLocallyDefaultsKey];

	if (fontMissing == NO) {
		return;
	}

	NSString *remoteValue = [sharedCloudManager() valueForKey:TPCPreferencesThemeFontNameDefaultsKey];

	NSString *localValue = [TPCPreferences themeChannelViewFontName];

	if (remoteValue == nil || [localValue isEqualToString:remoteValue]) {
		return;
	}

	if ([NSFont fontIsAvailable:remoteValue] == NO) {
		return;
	}

	[TPCPreferences setThemeChannelViewFontName:remoteValue]; // Will remove the BOOL

	[TPCPreferences performReloadAction:TPCPreferencesReloadActionStyle];

	[RZNotificationCenter() postNotificationName:TPCPreferencesCloudSyncDidChangeThemeFontNotification object:nil];
}

@end
#endif

NS_ASSUME_NONNULL_END
