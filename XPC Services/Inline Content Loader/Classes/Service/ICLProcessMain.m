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

#import <objc/runtime.h>

#import "NSObjectHelperPrivate.h"
#import "TPCPreferences.h"
#import "TPCPreferencesUserDefaults.h"
#import "ICLInlineContentModulePrivate.h"
#import "ICLPayloadPrivate.h"
#import "ICLPluginManagerPrivate.h"
#import "CoreModulesImportsPrivate.h"
#import "ICLProcessMainPrivate.h"

NS_ASSUME_NONNULL_BEGIN

NSString * const ICLInlineContentErrorDomain = @"ICLInlineContentErrorDomain";

@interface ICLProcessMain ()
@property (nonatomic, strong) NSXPCConnection *serviceConnection;
@property (readonly, copy) NSArray<Class> *moduleClasses;
@property (readonly, copy) NSArray<Class> *moduleClassesInCore;
@property (readonly, copy) NSDictionary<NSString *, NSArray<Class> *> *modules;
@property (readonly) NSCache *moduleReferences;
@end

@implementation ICLProcessMain

ClassWithDesignatedInitializerInitMethod

- (instancetype)initWithXPCConnection:(NSXPCConnection *)connection
{
	NSParameterAssert(connection != nil);

	if ((self = [super init])) {
		self.serviceConnection = connection;

		return self;
	}

	return nil;
}

#pragma mark -
#pragma mark XPC Interface

/* List of module classes that are automatically mapped */
- (NSArray<Class> *)moduleClassesInCore
{
	return
	@[
		[ICMDailymotion class],
		[ICMGfycat class],
		[ICMGyazo class],
		[ICMImgurGifv class],
		[ICMLiveleak class],
		[ICMPornhub class],
		[ICMStreamable class],
		[ICMTweet class],
		[ICMTwitchClips class],
		[ICMTwitchLive class],
		[ICMVimeo class],
		[ICMXkcd class],
		[ICMYouTube class],
		[ICMCommonInlineVideos class],
		[ICMCommonInlineImages class],

		/* This module should ALWAYS be the last
		 in line because it matches any URL. */
		[ICMAssessedMedia class]
	  ];
}

- (NSArray<Class> *)moduleClasses
{
	NSArray *modules = [[ICLPluginManager sharedPluginManager] modules];

	modules = [modules arrayByAddingObjectsFromArray:self.moduleClassesInCore];

	return modules;
}

/* Returns a dictionary with the key equal to the domain a module
 maps to and the value a list of modules that map to that domain. */
/* If a module does not map to a specific domain, then those can be
 accessed by the wildcard key "*" */
- (NSDictionary<NSString *, NSArray<Class> *> *)modules
{
	static NSDictionary<NSString *, NSArray<Class> *> *modules = nil;

	static dispatch_once_t onceToken;

	dispatch_once(&onceToken, ^{
		/* Add new modules to this array */
		NSArray *moduleClasses = self.moduleClasses;

		/* Mapping logic */
		NSMutableDictionary<NSString *, NSMutableArray<Class> *> *modulesOut = [NSMutableDictionary dictionary];

		void (^mapModuleDomain)(Class, NSString *) = ^(Class moduleClass, NSString *moduleDomain) {
			NSMutableArray *mappedDomains = modulesOut[moduleDomain];

			if (mappedDomains == nil) {
				mappedDomains = [NSMutableArray array];

				[modulesOut setObject:mappedDomains forKey:moduleDomain];
			}

			[mappedDomains addObject:moduleClass];
		};

		void (^mapModuleDomains)(Class, NSArray *) = ^(Class moduleClass, NSArray<NSString *> * _Nullable moduleDomains) {
			/* If the module does not map to a specific domain,
			 then map it to a wildcard for all other classes. */
			if (moduleDomains == nil || moduleDomains.count == 0) {
				mapModuleDomain(moduleClass, @"*");

				return;
			}

			/* Map domains */
			for (NSString *moduleDomain in moduleDomains) {
				mapModuleDomain(moduleClass, moduleDomain);
			}
		};

		for (Class moduleClass in moduleClasses) {
			NSArray *moduleDomains = [moduleClass domains];

			mapModuleDomains(moduleClass, moduleDomains);
		}

		/* Replace mutable arrays with immutable copies */
		[modulesOut performSelectorOnObjectValueAndReplace:@selector(copy)];

		modules = [modulesOut copy];
	});

	return modules;
}

- (void)processURL:(NSURL *)url withUniqueIdentifier:(NSString *)uniqueIdentifier atLineNumber:(NSString *)lineNumber index:(NSUInteger)index inView:(NSString *)viewIdentifier
{
	NSParameterAssert(url != nil);
	NSParameterAssert(url.isFileURL == NO);
	NSParameterAssert(uniqueIdentifier != nil);
	NSParameterAssert(lineNumber != nil);
	NSParameterAssert(viewIdentifier != nil);

	  ICLPayloadMutable *payload =
	[[ICLPayloadMutable alloc] initWithURL:url
					  withUniqueIdentifier:uniqueIdentifier
							  atLineNumber:lineNumber
									 index:index
									inView:viewIdentifier];

	[self processPayload:payload];
}

- (void)processPayload:(ICLPayload *)payload
{
	NSParameterAssert(payload != nil);

	NSString *urlScheme = payload.url.scheme;

	if ([urlScheme isEqualToString:@"http"] == NO &&
		[urlScheme isEqualToString:@"https"] == NO)
	{
		return;
	}

	ICLPayloadMutable *payloadIn = nil;

	if ([payloadIn isKindOfClass:[ICLPayloadMutable class]] == NO) {
		payloadIn = [payload mutableCopy];
	} else {
		payloadIn = (id)payload;
	}

	BOOL (^processModulesWithDomain)(NSString *) = ^BOOL (NSString *domain) {
		NSParameterAssert(domain != nil);

		NSArray *modules = [self.modules objectForKey:domain];

		for (Class module in modules) {
			if ([self _processPayload:payloadIn usingModule:module]) {
				return YES;
			}
		}

		return NO;
	};

	NSString *urlHost = payloadIn.url.host;

	if (processModulesWithDomain(urlHost)) {
		return;
	}

	/* If no module accepted responsiblity for the urlHost,
	 then we try modules that do not map to a specific domain. */
	(void)processModulesWithDomain(@"*");
}

- (BOOL)_processPayload:(ICLPayloadMutable *)payloadIn usingModule:(Class)moduleClass
{
	NSParameterAssert(payloadIn != nil);
	NSParameterAssert(moduleClass != NULL);

	/* Do not allow unsafe content */
	if ([moduleClass contentImageOrVideo] == NO && [TPCPreferences inlineMediaLimitToBasics]) {
		return NO;
	} else if ([moduleClass contentNotSafeForWork] && [TPCPreferences inlineMediaLimitNaughtyContent]) {
		return NO;
	} else if ([moduleClass contentUntrusted] && [TPCPreferences inlineMediaLimitUnsafeContent]) {
		return NO;
	}

	/* Determine whether this module has an action for this URL. */
	NSURL *url = payloadIn.url;

	ICLInlineContentModuleActionBlock actionBlock = [moduleClass actionBlockForURL:url];

	SEL action = NULL;

	if (actionBlock == nil) {
		action = [moduleClass actionForURL:url];
	}

	if (actionBlock == nil && (action == NULL /* || [moduleClass instancesRespondToSelector:action] == NO */)) {
		return NO;
	}

	/* Create module and call it */
	ICLInlineContentModule *module = [[moduleClass alloc] initWithPayload:payloadIn inProcess:self];

	[self _addReferenceForModule:module];

	if (actionBlock) {
		actionBlock(module);
	} else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
		[module performSelector:action];
#pragma clang diagnostic pop
	}

	return YES;
}

#pragma mark -
#pragma mark State

- (void)_finalizeModule:(ICLInlineContentModule *)module withError:(nullable NSError *)error
{
	NSParameterAssert(module != nil);

	ICLPayload *payload = [module.payload copy];

	/* Remove reference to module */
	[self _removeReferenceForModule:module];

	/* If you are wondering why so much care has been put into these errors
	 when we control the code, it's because there are plans to support plugins
	 for modules in the future so future proofing it is best. */
	if (payload.html.length == 0 &&
		payload.scriptResources.count == 0)
	{
		error =
		[NSError errorWithDomain:ICLInlineContentErrorDomain
							code:1001
						userInfo:@{
			NSLocalizedDescriptionKey : @"-[ICLPayload scriptResources] must contain at least one path if -[ICLPayload html] is empty"
		}];
	}
	else if (payload.html.length == 0 &&
			 payload.entrypoint.length == 0)
	{
		error =
		[NSError errorWithDomain:ICLInlineContentErrorDomain
							code:1002
						userInfo:@{
			NSLocalizedDescriptionKey : @"-[ICLPayload html] and -[ICLPayload entrypoint] cannot both be empty"
		}];
	}

	if (error) {
		[[self remoteObjectProxy] processingPayload:payload failedWithError:error];
	} else {
		[[self remoteObjectProxy] processingPayloadSucceeded:payload];
	}
}

- (void)_cancelModule:(ICLInlineContentModule *)module
{
	NSParameterAssert(module != nil);

	[self _removeReferenceForModule:module];
}

- (void)_deferModule:(ICLInlineContentModule *)module asType:(ICLMediaType)type performCheck:(BOOL)performCheck
{
	NSParameterAssert(module != nil);
	NSParameterAssert(type == ICLMediaTypeImage ||
					  type == ICLMediaTypeVideo ||
					  type == ICLMediaTypeVideoGif);

	switch (type) {
		case ICLMediaTypeImage:
		{
			ICMInlineImage *imageModule = [[ICMInlineImage alloc] initWithDeferredModule:module];

			[self _addReferenceForModule:imageModule];

			[imageModule performActionWithImageCheck:performCheck];

			break;
		}
		case ICLMediaTypeVideo:
		{
			ICMInlineVideo *videoModule = [[ICMInlineVideo alloc] initWithDeferredModule:module];

			[self _addReferenceForModule:videoModule];

			[videoModule performActionWithVideoCheck:performCheck];

			break;
		}
		case ICLMediaTypeVideoGif:
		{
			ICMInlineGifVideo *videoModule = [[ICMInlineGifVideo alloc] initWithDeferredModule:module];

			[self _addReferenceForModule:videoModule];

			[videoModule performActionWithVideoCheck:performCheck];

			break;
		}
		default:
		{
			LogToConsoleError("Unexpected media type: %ld", type);

			break;
		} // case
	} // switch
}

#pragma mark -
#pragma mark Memory

- (NSCache *)moduleReferences
{
	static NSCache *modules = nil;

	static dispatch_once_t onceToken;

	dispatch_once(&onceToken, ^{
		modules = [NSCache new];
	});

	return modules;
}

- (void)_addReferenceForModule:(ICLInlineContentModule *)module
{
	NSParameterAssert(module != nil);

	[self.moduleReferences setObject:module forKey:module.description];
}

- (void)_removeReferenceForModule:(ICLInlineContentModule *)module
{
	NSParameterAssert(module != nil);

	[self.moduleReferences removeObjectForKey:module.description];
}

#pragma mark -
#pragma mark Process Management

- (void)warmServiceByLoadingPluginsAtLocations:(NSArray<NSURL *> *)pluginLocations
{
	NSParameterAssert(pluginLocations != nil);

	[[ICLPluginManager sharedPluginManager] loadPluginsAtLocations:pluginLocations];
}

- (void)warmServiceByRegisteringDefaults:(NSDictionary<NSString *, id> *)defaults
{
	NSParameterAssert(defaults != nil);

	[RZUserDefaults() registerDefaults:defaults];
}

#pragma mark -
#pragma mark XPC Connection

- (id <ICLInlineContentClientProtocol>)remoteObjectProxy
{
	return self.serviceConnection.remoteObjectProxy;
}

@end

NS_ASSUME_NONNULL_END
