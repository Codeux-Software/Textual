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

NS_ASSUME_NONNULL_BEGIN

NSString * const ICLInlineContentErrorDomain = @"ICLInlineContentErrorDomain";

@interface ICLProcessMain ()
@property (nonatomic, strong) NSXPCConnection *serviceConnection;
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

/* -modules returns an array of classes (not objects) */
- (NSArray *)modules
{
	static NSArray *modules = nil;

	static dispatch_once_t onceToken;

	dispatch_once(&onceToken, ^{
		modules = @[[ICMInlineImage class]];
	});

	return modules;
}

- (void)processURL:(NSURL *)url withUniqueIdentifier:(NSString *)uniqueIdentifier atLineNumber:(NSString *)lineNumber inView:(NSString *)viewIdentifier
{
	NSParameterAssert(url != nil);
	NSParameterAssert(uniqueIdentifier != nil);
	NSParameterAssert(lineNumber != nil);
	NSParameterAssert(viewIdentifier != nil);

	  ICLPayloadMutable *payload =
	[[ICLPayloadMutable alloc] initWithURL:url
					  withUniqueIdentifier:uniqueIdentifier
							  atLineNumber:lineNumber
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

	for (Class module in [self modules]) {
		if ([self _processPayload:payloadIn usingModule:module]) {
			return;
		}
	}
}

- (BOOL)_processPayload:(ICLPayloadMutable *)payloadIn usingModule:(Class)moduleClass
{
	NSParameterAssert(payloadIn != nil);

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

	/* The module has an action. Call it. */
	ICLInlineContentModuleCompletionBlock completionBlock = ^(NSError * _Nullable error) {
		ICLPayload *payloadOut = [payloadIn copy];

		/* If you are wondering why so much care has been put into these errors
		 when we control the code, it's because there are plans to support plugins
		 for modules in the future so future proofing it is best. */
		if (payloadOut.scriptResources.count == 0) {
			error =
			[NSError errorWithDomain:ICLInlineContentErrorDomain
								code:1001
							userInfo:@{
				NSLocalizedDescriptionKey : @"-[ICLPayload scriptResources] must contain at least one path"
			}];
		}
		else if (payloadOut.html.length == 0 &&
				 payloadOut.entrypoint.length == 0)
		{
			error =
			[NSError errorWithDomain:ICLInlineContentErrorDomain
								code:1002
							userInfo:@{
				NSLocalizedDescriptionKey : @"-[ICLPayload html] and -[ICLPayload entrypoint] cannot both be empty"
			}];
		}

		if (error) {
			[[self remoteObjectProxy] processingPayload:payloadOut failedWithError:error];
		} else {
			[[self remoteObjectProxy] processingPayloadSucceeded:payloadOut];
		}
	};

	ICLInlineContentModule *module = [[moduleClass alloc] initWithPayload:payloadIn completionBlock:completionBlock];

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

- (void)registerDefaults:(NSDictionary<NSString *,id> *)registrationDictionary
{
	[RZUserDefaults() registerDefaults:registrationDictionary];
}

#pragma mark -
#pragma mark XPC Connection

- (id <ICLInlineContentClientProtocol>)remoteObjectProxy
{
	return self.serviceConnection.remoteObjectProxy;
}

@end

NS_ASSUME_NONNULL_END
