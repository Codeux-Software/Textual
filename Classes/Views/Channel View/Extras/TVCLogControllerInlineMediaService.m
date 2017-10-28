/* ********************************************************************* 
                  _____         _               _
                 |_   _|____  _| |_ _   _  __ _| |
                   | |/ _ \ \/ / __| | | |/ _` | |
                   | |  __/>  <| |_| |_| | (_| | |
                   |_|\___/_/\_\\__|\__,_|\__,_|_|

 Copyright (c) 2010 - 2017 Codeux Software, LLC & respective contributors.
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

#import "ICLInlineContentProtocol.h"
#import "ICLPayload.h"
#import "TXMasterController.h"
#import "IRCTreeItem.h"
#import "IRCWorld.h"
#import "TPCPathInfoPrivate.h"
#import "TPCPreferencesUserDefaults.h"
#import "TVCLogControllerPrivate.h"
#import "TVCLogControllerInlineMediaServicePrivate.h"

NS_ASSUME_NONNULL_BEGIN

@interface TVCLogControllerInlineMediaService ()
@property (nonatomic, strong) NSXPCConnection *serviceConnection;
@end

@implementation TVCLogControllerInlineMediaService

+ (TVCLogControllerInlineMediaService *)sharedInstance
{
	static id sharedSelf = nil;

	static dispatch_once_t onceToken;

	dispatch_once(&onceToken, ^{
		sharedSelf = [[self alloc] init];
	});

	return sharedSelf;
}

#pragma mark -
#pragma mark Construction

- (void)warmProcessIfNeeded
{
	if (self.serviceConnection != nil) {
		return;
	}

	LogToConsoleDebug("Warming process...");

	[self connectToService];
}

- (void)invalidateProcess
{
	if (self.serviceConnection == nil) {
		return;
	}

	LogToConsoleDebug("Invaliating process...");

	[self.serviceConnection invalidate];
}

- (void)connectToService
{
	NSXPCConnection *serviceConnection = [[NSXPCConnection alloc] initWithServiceName:@"com.codeux.app-utilities.Textual-InlineContentLoader"];

	NSXPCInterface *remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(ICLInlineContentServerProtocol)];

	serviceConnection.remoteObjectInterface = remoteObjectInterface;

	NSXPCInterface *exportedInterface = [NSXPCInterface interfaceWithProtocol:@protocol(ICLInlineContentClientProtocol)];

	serviceConnection.exportedInterface = exportedInterface;

	serviceConnection.exportedObject = self;

	serviceConnection.interruptionHandler = ^{
		[self interuptionHandler];

		LogToConsole("Interuption handler called");
	};

	serviceConnection.invalidationHandler = ^{
		[self invalidationHandler];

		LogToConsole("Invalidation handler called");
	};

	[serviceConnection resume];

	self.serviceConnection = serviceConnection;

	[self registerDefaults];
	[self registerPlugins];
}

- (void)interuptionHandler
{
	[self invalidateProcess];
}

- (void)invalidationHandler
{
	self.serviceConnection = nil;
}

- (void)prepareForApplicationTermination
{
	[self invalidateProcess];
}

- (void)registerDefaults
{
	/* We pass the registered defaults for the app to the XPC
	 service because it accesses preferences within that domain. */
	/* The registered defaults aren't changed after launch which
	 means this is a one off deal, but we should use notifications
	 if that ever changes in the future. */

	NSDictionary *defaults = [RZUserDefaults() registeredDefaults];

	[[self remoteObjectProxy] warmServiceByRegisteringDefaults:defaults];
}

- (void)registerPlugins
{
	NSArray *pluginLocations = @[
		 [self _applicationSupportInlineMediaPluginsURL]
	];

	[[self remoteObjectProxy] warmServiceByLoadingPluginsAtLocations:pluginLocations];
}

- (NSURL *)_applicationSupportInlineMediaPluginsURL
{
	NSURL *sourceURL = [TPCPathInfo groupContainerApplicationSupportURL];

	NSURL *baseuRL = [sourceURL URLByAppendingPathComponent:@"/Inline Media Modules/"];

	[TPCPathInfo _createDirectoryAtURL:baseuRL];

	return baseuRL;
}

#pragma mark -
#pragma mark Private API

- (id <ICLInlineContentServerProtocol>)remoteObjectProxy
{
	return [self remoteObjectProxyWithErrorHandler:nil];
}

- (id <ICLInlineContentServerProtocol>)remoteObjectProxyWithErrorHandler:(void (^ _Nullable)(NSError *error))handler
{
	return [self.serviceConnection remoteObjectProxyWithErrorHandler:^(NSError *error) {
		LogToConsoleError("Error occurred while communicating with service: %@",
			error.localizedDescription);

		if (handler) {
			handler(error);
		}
	}];
}

#pragma mark -
#pragma mark Public API

- (void)processAddress:(NSString *)address withUniqueIdentifier:(NSString *)uniqueIdentifier atLineNumber:(NSString *)lineNumber index:(NSUInteger)index forItem:(IRCTreeItem *)item
{
	NSParameterAssert(address != nil);
	NSParameterAssert(uniqueIdentifier != nil);
	NSParameterAssert(lineNumber != nil);
	NSParameterAssert(item != nil);

	/* WebKit is able to translate an address to punycode
	 for us by giving it a pasteboard with the URL. */
	NSURL *url = address.URLUsingWebKitPasteboard;

	if (url == nil) {
		LogToConsoleError("Address could not be normalized");

		return;
	}

	[self processURL:url withUniqueIdentifier:uniqueIdentifier atLineNumber:lineNumber index:index forItem:item];
}

- (void)processURL:(NSURL *)url withUniqueIdentifier:(NSString *)uniqueIdentifier atLineNumber:(NSString *)lineNumber index:(NSUInteger)index forItem:(IRCTreeItem *)item
{
	NSParameterAssert(url != nil);
	NSParameterAssert(uniqueIdentifier != nil);
	NSParameterAssert(lineNumber != nil);
	NSParameterAssert(item != nil);

	[self warmProcessIfNeeded];

	[[self remoteObjectProxy] processURL:url withUniqueIdentifier:uniqueIdentifier atLineNumber:lineNumber index:index inView:item.uniqueIdentifier];
}

#pragma mark -
#pragma mark Private API (Client)

- (void)processingPayloadSucceeded:(ICLPayload *)payload
{
	IRCTreeItem *item = [worldController() findItemWithId:payload.viewIdentifier];

	if (item == nil) {
		return;
	}

	[self _processingPayloadSucceeded:payload forItem:item];
}

- (void)processingPayload:(ICLPayload *)payload failedWithError:(NSError *)error
{
	IRCTreeItem *item = [worldController() findItemWithId:payload.viewIdentifier];

	if (item == nil) {
		return;
	}

	[self _processingPayload:payload forItem:item failedWithError:error];
}

- (void)_processingPayloadSucceeded:(ICLPayload *)payload forItem:(IRCTreeItem *)item
{
	[item.viewController processingInlineMediaPayloadSucceeded:payload];
}

- (void)_processingPayload:(ICLPayload *)payload forItem:(IRCTreeItem *)item failedWithError:(NSError *)error
{
	[item.viewController processingInlineMediaPayload:payload failedWithError:error];
}

@end

NS_ASSUME_NONNULL_END
