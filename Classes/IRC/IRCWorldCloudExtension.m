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

#import "IRCWorldPrivate.h"

#if TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT == 1
NSString * const IRCWorldControllerCloudDeletedClientsStorageKey	= @"World Controller -> Cloud Deleted Clients";
NSString * const IRCWorldControllerCloudClientEntryKeyPrefix		= @"World Controller -> Cloud Synced Client -> ";

@implementation IRCWorld (IRCWorldCloudExtension)

- (NSMutableDictionary *)cloudDictionaryValue
{
	NSMutableDictionary *dict = [NSMutableDictionary dictionary];
	
	@synchronized(self.clients) {
		for (IRCClient *u in self.clients) {
			if (u.config.excludedFromCloudSyncing == NO) {
				NSDictionary *prefs = [u dictionaryValue:YES];
				
				NSString *prefKey = [IRCWorldControllerCloudClientEntryKeyPrefix stringByAppendingString:[u uniqueIdentifier]];
				
				[dict setObject:prefs forKey:prefKey];
			}
		}
	}
	
	return dict;
}

- (void)destroyClientInCloud:(IRCClient *)client
{
	if (client) {
		if (client.config.excludedFromCloudSyncing == NO) {
			/* Add client to list of clients to delete. */
			[self addClientToListOfDeletedClients:[client uniqueIdentifier]];
			
			/* Remove any copy of the client configuration from cloud. */
			[self removeClientConfigurationCloudEntry:[client uniqueIdentifier]];
		}
	}
}

- (void)addClientToListOfDeletedClients:(NSString *)clientID
{
	if ([TPCPreferences syncPreferencesToTheCloud]) {
		/* Begin work. */
		NSArray *deletedClients = [sharedCloudManager() valueForKey:IRCWorldControllerCloudDeletedClientsStorageKey];
		
		/* Does the array even exist? */
		if (deletedClients == nil) {
			deletedClients = @[clientID];
		} else {
			/* Duplicate? */
			if ([deletedClients containsObject:clientID]) {
				return;
			}
			
			/* Append to existing list. */
			deletedClients = [deletedClients arrayByAddingObject:clientID];
		}
		
		/* Set new array. */
		[sharedCloudManager() setValue:deletedClients forKey:IRCWorldControllerCloudDeletedClientsStorageKey];
	}
}

/* If a client set locally was set to not be synced from the cloud, but its UUID appears as a
 deleted item from another client, then remove that UUID from the deleted clients list if that
 client is again set to sync to the cloud. */
- (void)removeClientFromListOfDeletedClients:(NSString *)clientID
{
	if ([TPCPreferences syncPreferencesToTheCloud]) {
		/* Begin work. */
		NSArray *deletedClients = [sharedCloudManager() valueForKey:IRCWorldControllerCloudDeletedClientsStorageKey];
		
		if (deletedClients) {
			NSInteger clientIndex = [deletedClients indexOfObject:clientID];
			
			if (NSDissimilarObjects(clientIndex, NSNotFound)) {
				deletedClients = [deletedClients arrayByRemovingObjectAtIndex:clientIndex];
				
				[sharedCloudManager() setValue:deletedClients forKey:IRCWorldControllerCloudDeletedClientsStorageKey];
			}
		}
	}
}

- (void)removeClientConfigurationCloudEntry:(NSString *)clientID
{
	if ([TPCPreferences syncPreferencesToTheCloud]) {
		NSString *prefKey = [IRCWorldControllerCloudClientEntryKeyPrefix stringByAppendingString:clientID];
	
		[sharedCloudManager() removeObjectForKey:prefKey];
	}
}

- (void)processCloudCientDeletionList:(NSArray *)deletedClients
{
	if ([TPCPreferences syncPreferencesToTheCloud]) {
		NSObjectIsEmptyAssert(deletedClients);
		
		[deletedClients enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
			/* Try to find a client from the imported list. */
			IRCClient *u = [self findClientById:obj];
			
			/* We only delete clients that are set to be synced. */
			if (u) {
				if (u.config.excludedFromCloudSyncing == NO) {
					[self destroyClient:u bySkippingCloud:YES];
				}
			}
		}];
	}
}

@end
#endif
