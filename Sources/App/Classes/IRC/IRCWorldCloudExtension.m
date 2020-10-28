/* *********************************************************************
 *                  _____         _               _
 *                 |_   _|____  _| |_ _   _  __ _| |
 *                   | |/ _ \ \/ / __| | | |/ _` | |
 *                   | |  __/>  <| |_| |_| | (_| | |
 *                   |_|\___/_/\_\\__|\__,_|\__,_|_|
 *
 * Copyright (c) 2010 - 2018 Codeux Software, LLC & respective contributors.
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

#import "TPCPreferencesCloudSyncExtension.h"
#import "TPCPreferencesCloudSyncPrivate.h"
#import "IRCClientConfig.h"
#import "IRCClientPrivate.h"
#import "IRCWorldPrivate.h"
#import "IRCWorldPrivateCloudExtension.h"

NS_ASSUME_NONNULL_BEGIN

#if TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT == 1
NSString * const IRCWorldControllerCloudListOfDeletedClientsDefaultsKey = @"World Controller -> Cloud Deleted Clients";
NSString * const IRCWorldControllerCloudClientItemDefaultsKeyPrefix = @"World Controller -> Cloud Synced Client -> ";

@implementation IRCWorld (IRCWorldCloudExtension)

- (NSDictionary<NSString *, id> *)cloud_clientConfigurations
{
	NSMutableDictionary<NSString *, id> *dic = [NSMutableDictionary dictionary];

	for (IRCClient *u in self.clientList) {
		if (u.config.excludedFromCloudSyncing) {
			continue;
		}

		NSDictionary *dictionaryValue = [u configurationDictionaryForCloud];

		NSString *dictionaryKey = [IRCWorldControllerCloudClientItemDefaultsKeyPrefix stringByAppendingString:u.uniqueIdentifier];

		dic[dictionaryKey] = dictionaryValue;
	}

	return [dic copy];
}

- (void)cloud_destroyClient:(IRCClient *)client
{
	NSParameterAssert(client != nil);

	if (client.config.excludedFromCloudSyncing) {
		return;
	}

	[self cloud_addClientToListOfDeletedClients:client.uniqueIdentifier];

	[self cloud_removeClientConfigurationCloudEntry:client.uniqueIdentifier];
}

- (void)cloud_addClientToListOfDeletedClients:(NSString *)clientId
{
	NSParameterAssert(clientId != nil);

	if ([TPCPreferences syncPreferencesToTheCloud] == NO) {
		return;
	}

	NSArray *deletedClients = [sharedCloudManager() valueForKey:IRCWorldControllerCloudListOfDeletedClientsDefaultsKey];

	if (deletedClients == nil) {
		deletedClients = @[clientId];
	} else {
		if ([deletedClients containsObject:clientId]) {
			return;
		}

		deletedClients = [deletedClients arrayByAddingObject:clientId];
	}

	[sharedCloudManager() setValue:deletedClients forKey:IRCWorldControllerCloudListOfDeletedClientsDefaultsKey];
}

/* If a client set locally was set to not be synced from the cloud, but its UUID appears as a
 deleted item from another client, then remove that UUID from the deleted clients list if that
 client is again set to sync to the cloud. */
- (void)cloud_removeClientFromListOfDeletedClients:(NSString *)clientId
{
	NSParameterAssert(clientId != nil);

	if ([TPCPreferences syncPreferencesToTheCloud] == NO) {
		return;
	}

	NSArray *deletedClients = [sharedCloudManager() valueForKey:IRCWorldControllerCloudListOfDeletedClientsDefaultsKey];

	if (deletedClients) {
		NSUInteger clientIndex = [deletedClients indexOfObject:clientId];

		if (clientIndex == NSNotFound) {
			return;
		}

		deletedClients = [deletedClients arrayByRemovingObjectAtIndex:clientIndex];

		[sharedCloudManager() setValue:deletedClients forKey:IRCWorldControllerCloudListOfDeletedClientsDefaultsKey];
	}
}

- (void)cloud_removeClientConfigurationCloudEntry:(NSString *)clientId
{
	NSParameterAssert(clientId != nil);

	if ([TPCPreferences syncPreferencesToTheCloud] == NO) {
		return;
	}

	NSString *prefKey = [IRCWorldControllerCloudClientItemDefaultsKeyPrefix stringByAppendingString:clientId];

	[sharedCloudManager() removeObjectForKey:prefKey];
}

- (void)cloud_processDeletedClientsList:(NSArray<NSString *> *)deletedClients
{
	NSParameterAssert(deletedClients != nil);

	if ([TPCPreferences syncPreferencesToTheCloud] == NO) {
		return;
	}

	[deletedClients enumerateObjectsUsingBlock:^(id object, NSUInteger index, BOOL *stop) {
		IRCClient *u = [self findClientWithId:object];

		if (u && u.config.excludedFromCloudSyncing == NO) {
			[self destroyClient:u skipCloud:YES];
		}
	}];
}

@end
#endif

NS_ASSUME_NONNULL_END
