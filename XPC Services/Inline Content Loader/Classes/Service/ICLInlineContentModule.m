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

#import "NSObjectHelperPrivate.h"
#import "ICLPayloadPrivate.h"
#import "ICLProcessMainPrivate.h"
#import "ICLInlineContentModuleInternal.h"

NS_ASSUME_NONNULL_BEGIN

@implementation ICLInlineContentModule

ClassWithDesignatedInitializerInitMethod

- (instancetype)initWithPayload:(ICLPayloadMutable *)payload inProcess:(ICLProcessMain *)process
{
	NSParameterAssert(payload != nil);
	NSParameterAssert(process != nil);

	if ((self = [super init])) {
		self->_payload = payload;

		self->_process = process;

		[self mergePropertiesIntoPayload];

		return self;
	}

	return nil;
}

- (instancetype)initWithDeferredModule:(ICLInlineContentModule *)module
{
	NSParameterAssert(module != nil);

	if ((self = [super init])) {
		self->_payload = [[ICLPayloadMutable alloc] initWithDeferredPayload:module.payload];

		self->_process = module->_process;

		[self mergePropertiesIntoPayload];

		return self;
	}

	return nil;
}

- (void)mergePropertiesIntoPayload
{
	NSArray *scriptResources = self.scriptResources;

	if (scriptResources) {
		self.payload.scriptResources = scriptResources;
	}

	NSArray *styleResources = self.styleResources;

	if (styleResources) {
		self.payload.styleResources = styleResources;
	}

	NSString *entrypoint = self.entrypoint;

	if (entrypoint) {
		self.payload.entrypoint = entrypoint;
	}
}

- (nullable NSURL *)templateURL
{
	return nil;
}

- (nullable GRMustacheTemplate *)template
{
	NSURL *templateURL = self.templateURL;

	if (templateURL == nil || templateURL.isFileURL == NO) {
		return nil;
	}

	NSError *templateLoadError;

	GRMustacheTemplate *template = [GRMustacheTemplate templateFromContentsOfURL:templateURL error:&templateLoadError];

	if (template == nil) {
		LogToConsoleError("Failed to load template '%@': %@",
			templateURL, templateLoadError.localizedDescription);
	}

	return template;
}

+ (nullable NSArray<NSString *> *)domains
{
	return nil;
}

+ (nullable ICLInlineContentModuleActionBlock)actionBlockForURL:(NSURL *)url
{
	return nil;
}

+ (nullable SEL)actionForURL:(NSURL *)url
{
	return NULL;
}

- (nullable NSArray<NSURL *> *)styleResources
{
	return nil;
}

- (nullable NSArray<NSURL *> *)scriptResources
{
	return nil;
}

- (nullable NSString *)entrypoint
{
	return nil;
}

+ (BOOL)contentImageOrVideo
{
	return NO;
}

+ (BOOL)contentUntrusted
{
	return NO;
}

+ (BOOL)contentNotSafeForWork
{
	return NO;
}

@end

#pragma mark -
#pragma mark Completion

@implementation ICLInlineContentModule (Completion)

- (void)_finalizeAll
{
	self->_moduleFinalized = YES;

	self->_process = nil;
}

- (void)finalize
{
	[self finalizeWithError:nil];
}

- (void)finalizeWithError:(nullable NSError *)error
{
	NSAssert((self->_moduleFinalized == NO), @"Module already finalized");

	[self finalizePreflight];

	[self->_process _finalizeModule:self withError:error];

	[self _finalizeAll];
}

- (void)cancel
{
	NSAssert((self->_moduleFinalized == NO), @"Module already cancelled");

	[self finalizePreflight];

	[self->_process _cancelModule:self];

	[self _finalizeAll];
}

- (void)deferAsType:(ICLMediaType)type
{
	[self deferAsType:type performCheck:YES];
}

- (void)deferAsType:(ICLMediaType)type performCheck:(BOOL)performCheck
{
	NSAssert((self->_moduleFinalized == NO), @"Module already deferred");

	[self finalizePreflight];

	[self->_process _deferModule:self asType:type performCheck:performCheck];

	[self _finalizeAll];
}

@end

#pragma mark -
#pragma mark Completion (Private)

@implementation ICLInlineContentModule (CompletionPrivate)

- (void)finalizePreflight
{

}

@end

NS_ASSUME_NONNULL_END
