/* *********************************************************************
 *                  _____         _               _
 *                 |_   _|____  _| |_ _   _  __ _| |
 *                   | |/ _ \ \/ / __| | | |/ _` | |
 *                   | |  __/>  <| |_| |_| | (_| | |
 *                   |_|\___/_/\_\\__|\__,_|\__,_|_|
 *
 * Copyright (c) 2015 - 2018 Codeux Software, LLC & respective contributors.
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

#import "TPI_Caffeine.h"

NS_ASSUME_NONNULL_BEGIN

@interface TPI_Caffeine ()
@property (nonatomic, strong) NSMutableArray<IRCClient *> *observedClients;
@property (nonatomic, strong) NSProgress *progressObject;
@property (nonatomic, strong) IBOutlet NSView *preferencesPaneView;
@end

@implementation TPI_Caffeine

#pragma mark -
#pragma mark Progress Management

- (BOOL)disableSleepModeWhenConnected
{
	return [RZUserDefaults() boolForKey:@"Private Extension Store -> Caffeine Extension -> Prevent Sleep"];
}

- (void)disableSleepMode
{
	self.progressObject = [RZProcessInfo() beginActivityWithOptions:NSActivityUserInitiated reason:@"Disable sleep mode"];

	LogToConsole("Disabled sleep mode");
}

- (void)enableSleepMode
{
	if (self.progressObject == nil) {
		return;
	}

	[RZProcessInfo() endActivity:self.progressObject];

	self.progressObject = nil;

	LogToConsole("Enabled sleep mode");
}

- (void)toggleSleepMode
{
	BOOL oneClientLoggedIn = NO;

	@synchronized(self.observedClients) {
		for (IRCClient *client in self.observedClients) {
			if (client.isLoggedIn == NO) {
				continue;
			}

			oneClientLoggedIn = YES;

			break;
		}
	}

	if (oneClientLoggedIn) {
		[self disableSleepMode];
	} else {
		[self enableSleepMode];
	}
}

#pragma mark -
#pragma mark Key-value Observation

- (void)rebuildObservedClients
{
	/* This method is called anytime the client list changes
	 which means we only begin observing clients here if they
	 are not already observed. */
	/* This method will remove observed clients if the user 
	 has disabled the option to disable sleep mode. If the
	 option is enabled, then this method observes clients 
	 and toggles sleep mode once completed. */
	@synchronized(self.observedClients) {
		BOOL observeClients = [self disableSleepModeWhenConnected];

		NSArray *clientList = worldController().clientList;

		for (IRCClient *client in self.observedClients) {
			/* Only stop observing client if they are still in -clientList */
			/* If they are not, then we are only dangling a reference to a
			 client that no longer exists and can free it below. */

			if ([clientList containsObject:client] || observeClients == NO) {
				@try {
					[client removeObserver:self forKeyPath:@"isLoggedIn"];
				} @catch (NSException *exception) {
					LogToConsole("Caught exception: %@", [exception reason]);
					LogStackTrace();
				}
			}
		}

		if (observeClients == NO) {
			self.observedClients = nil;
		}
		else
		{
			if (self.observedClients == nil) {
				self.observedClients = [NSMutableArray array];
			}

			for (IRCClient *client in clientList) {
				if ([self.observedClients containsObject:client] == NO) {
					[self.observedClients addObject:client];

					[client addObserver:self
							 forKeyPath:@"isLoggedIn"
								options:NSKeyValueObservingOptionNew
								context:NULL];
				}
			}
		}

		[self toggleSleepMode];
	}
}

#ifdef TXSystemIsOSXSierraOrLater
- (void)observeValueForKeyPath:(nullable NSString *)keyPath ofObject:(nullable id)object change:(nullable NSDictionary<NSKeyValueChangeKey, id> *)change context:(nullable void *)context
#else
- (void)observeValueForKeyPath:(nullable NSString *)keyPath ofObject:(nullable id)object change:(nullable NSDictionary<NSString*, id> *)change context:(nullable void *)context
#endif
{
	[self toggleSleepMode];
}

- (IBAction)toggledDisableSleepModeWhileConnected:(id)sender
{
	[self rebuildObservedClients];
}

#pragma mark -
#pragma mark Plugin API

- (void)pluginLoadedIntoMemory
{
	/* This plugin uses NSProgress which is not available on Mountain Lion */
	/* The Textual Extras installer can detect operating system and will not
	 allow it to be installed on Mountain Lion, but still good to have some
	 type of sanity type. */
	if (TEXTUAL_RUNNING_ON(10.9, Mavericks) == NO) {
		return;
	}

	/* Load interface and begin observing client list changes */
	(void)[TPIBundleFromClass() loadNibNamed:@"TPI_Caffeine" owner:self topLevelObjects:nil];

	[RZNotificationCenter() addObserverForName:IRCWorldClientListWasModifiedNotification
										object:nil
										 queue:nil
									usingBlock:^(NSNotification *note) {
										[self rebuildObservedClients];
									}];

	/* Plugins are loaded after clients have been setup which
	 means we have to manually build observes in addition to
	 observing the client list change notification. */
	[self rebuildObservedClients];
}

- (void)pluginWillBeUnloadedFromMemory
{
	[RZNotificationCenter() removeObserver:self];

	[self enableSleepMode];
}

- (NSString *)pluginPreferencesPaneMenuItemName
{
	return TPILocalizedString(@"BasicLanguage[xqp-6g]");
}

- (NSView *)pluginPreferencesPaneView
{
	return self.preferencesPaneView;
}

@end

NS_ASSUME_NONNULL_END
