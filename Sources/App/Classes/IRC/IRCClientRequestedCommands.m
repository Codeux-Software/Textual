/* *********************************************************************
 *                  _____         _               _
 *                 |_   _|____  _| |_ _   _  __ _| |
 *                   | |/ _ \ \/ / __| | | |/ _` | |
 *                   | |  __/>  <| |_| |_| | (_| | |
 *                   |_|\___/_/\_\\__|\__,_|\__,_|_|
 *
 *    Copyright (c) 2018 Codeux Software, LLC & respective contributors.
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

#import "IRCClientRequestedCommandsPrivate.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, IRCClientRequestedCommandsHiddenState)
{
	IRCClientRequestedCommandsUnknownHiddenState = 0,
	IRCClientRequestedCommandsIsHiddenState,
	IRCClientRequestedCommandsIsNotHiddenState
};

@interface IRCClientRequestedCommand : NSObject
@property (nonatomic, assign) IRCRemoteCommand command;
@property (nonatomic, assign) BOOL hiddenResponse;
@property (nonatomic, assign) BOOL enforceCount;
@property (nonatomic, assign) NSUInteger count;
@end

@interface IRCClientRequestedCommands ()
/* We could use a dictionary or cache with command as key
 and an array of objects for the assigned object but that
 is much more complex than just scanning a one level array. */
@property (nonatomic, strong) NSMutableArray<IRCClientRequestedCommand *> *invokedCommandsInt;
@end

@implementation IRCClientRequestedCommands

- (instancetype)init
{
	if ((self = [super init])) {
		[self prepareInitialState];

		return self;
	}

	return nil;
}

- (void)prepareInitialState
{
	self.invokedCommandsInt = [NSMutableArray array];
}

- (nullable IRCClientRequestedCommand *)findCommand:(IRCRemoteCommand)command
{
	@synchronized (self.invokedCommandsInt) {
		return [self.invokedCommandsInt objectPassingTest:^BOOL(IRCClientRequestedCommand *object, NSUInteger index, BOOL *stop) {
			return (object.command == command);
		}];
	}
}

- (void)addCommand:(IRCRemoteCommand)command hiddenResponse:(BOOL)hiddenResponse
{
	[self addCommand:command withCount:0 hiddenResponse:hiddenResponse];
}

- (void)addCommand:(IRCRemoteCommand)command withCount:(NSUInteger)count hiddenResponse:(BOOL)hiddenResponse
{
	IRCClientRequestedCommand *commandObject = [IRCClientRequestedCommand new];

	commandObject.command = command;
	commandObject.hiddenResponse = hiddenResponse;
	commandObject.enforceCount = (count > 0);
	commandObject.count = count;

	@synchronized (self.invokedCommandsInt) {
		[self.invokedCommandsInt addObject:commandObject];
	}
}

- (void)removeCommands
{
	@synchronized (self.invokedCommandsInt) {
		[self.invokedCommandsInt removeAllObjects];
	}
}

- (void)removeCommand:(IRCRemoteCommand)command
{
	/* There can be multiple commands with same context.
	 When we remove, we remove the first that is matched and let next
	 pass of responses remove the others. */
	IRCClientRequestedCommand *commandObject = [self findCommand:command];

	if (commandObject == nil) {
		return;
	}

	[self removeCommandObject:commandObject];
}

- (void)removeCommandObject:(IRCClientRequestedCommand *)commandObject
{
	NSParameterAssert(commandObject != nil);

	@synchronized (self.invokedCommandsInt) {
		[self.invokedCommandsInt removeObject:commandObject];
	}
}

- (void)decrementCommandCount:(IRCRemoteCommand)command
{
	IRCClientRequestedCommand *commandObject = [self findCommand:command];

	if (commandObject == nil) {
		return;
	}

	if (commandObject.enforceCount == NO) {
		return;
	}

	commandObject.count -= 1;

	if (commandObject.count == 0) {
		[self removeCommandObject:commandObject];
	}
}

- (IRCClientRequestedCommandsHiddenState)commandHiddenState:(IRCRemoteCommand)command
{
	IRCClientRequestedCommand *commandObject = [self findCommand:command];

	if (commandObject == nil) {
		return IRCClientRequestedCommandsUnknownHiddenState;
	}

	if (commandObject.hiddenResponse == NO) {
		return IRCClientRequestedCommandsIsNotHiddenState;
	} else {
		return IRCClientRequestedCommandsIsHiddenState;
	}
}

@end

#pragma mark -

@implementation IRCClientRequestedCommands (Helpers)

- (BOOL)inVisibleIsonRequest
{
	return ([self commandHiddenState:IRCRemoteCommandIsonIndex] == IRCClientRequestedCommandsIsNotHiddenState);
}

- (void)recordIsonRequestOpened
{
	[self addCommand:IRCRemoteCommandIsonIndex hiddenResponse:YES];
}

- (void)recordIsonRequestOpenedAsVisible
{
	[self addCommand:IRCRemoteCommandIsonIndex hiddenResponse:NO];
}

- (void)recordIsonRequestClosed
{
	[self removeCommand:IRCRemoteCommandIsonIndex];
}

#if 0
- (BOOL)inVisibleMonitorRequest
{
	return ([self commandHiddenState:IRCRemoteCommandMonitorIndex] == IRCClientRequestedCommandsIsNotHiddenState);
}

- (void)recordMonitorRequestOpened
{
	[self addCommand:IRCRemoteCommandMonitorIndex hiddenResponse:YES];
}

- (void)recordMonitorRequestOpenedWithCount:(NSUInteger)count
{
	NSParameterAssert(count > 0);

	[self addCommand:IRCRemoteCommandMonitorIndex withCount:count hiddenResponse:YES];
}

- (void)recordMonitorRequestOpenedAsVisibleWithCount:(NSUInteger)count
{
	NSParameterAssert(count > 0);

	[self addCommand:IRCRemoteCommandMonitorIndex withCount:count hiddenResponse:NO];
}

- (void)recordMonitorRequestOpenedAsVisible
{
	[self addCommand:IRCRemoteCommandMonitorIndex hiddenResponse:NO];
}

- (void)recordMonitorRequestClosedOne
{
	[self decrementCommandCount:IRCRemoteCommandMonitorIndex];
}

- (void)recordMonitorRequestClosed
{
	[self removeCommand:IRCRemoteCommandMonitorIndex];
}

- (BOOL)inVisibleNamesRequest
{
	return ([self commandHiddenState:IRCRemoteCommandNamesIndex] == IRCClientRequestedCommandsIsNotHiddenState);
}

- (void)recordNamesRequestOpened
{
	[self addCommand:IRCRemoteCommandNamesIndex hiddenResponse:YES];
}

- (void)recordNamesRequestOpenedAsVisible
{
	[self addCommand:IRCRemoteCommandNamesIndex hiddenResponse:NO];
}

- (void)recordNamesRequestClosed
{
	[self removeCommand:IRCRemoteCommandNamesIndex];
}

- (BOOL)inVisibleWatchRequest
{
	return ([self commandHiddenState:IRCRemoteCommandWatchIndex] == IRCClientRequestedCommandsIsNotHiddenState);
}

- (void)recordWatchRequestOpened
{
	[self addCommand:IRCRemoteCommandWatchIndex hiddenResponse:YES];
}

- (void)recordWatchRequestOpenedWithCount:(NSUInteger)count
{
	NSParameterAssert(count > 0);

	[self addCommand:IRCRemoteCommandWatchIndex withCount:count hiddenResponse:YES];
}

- (void)recordWatchRequestOpenedAsVisibleWithCount:(NSUInteger)count
{
	NSParameterAssert(count > 0);

	[self addCommand:IRCRemoteCommandWatchIndex withCount:count hiddenResponse:NO];
}

- (void)recordWatchRequestOpenedAsVisible
{
	[self addCommand:IRCRemoteCommandWatchIndex hiddenResponse:NO];
}

- (void)recordWatchRequestClosedOne
{
	[self decrementCommandCount:IRCRemoteCommandWatchIndex];
}

- (void)recordWatchRequestClosed
{
	[self removeCommand:IRCRemoteCommandWatchIndex];
}
#endif

- (BOOL)inVisibleWhoRequest
{
	return ([self commandHiddenState:IRCRemoteCommandWhoIndex] == IRCClientRequestedCommandsIsNotHiddenState);
}

- (void)recordWhoRequestOpened
{
	[self addCommand:IRCRemoteCommandWhoIndex hiddenResponse:YES];
}

- (void)recordWhoRequestOpenedAsVisible
{
	[self addCommand:IRCRemoteCommandWhoIndex hiddenResponse:NO];
}

- (void)recordWhoRequestClosed
{
	[self removeCommand:IRCRemoteCommandWhoIndex];
}

@end

#pragma mark -

@implementation IRCClientRequestedCommand
@end

NS_ASSUME_NONNULL_END
