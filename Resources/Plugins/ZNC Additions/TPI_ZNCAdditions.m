/* ********************************************************************* 
       _____        _               _    ___ ____   ____
      |_   _|___  _| |_ _   _  __ _| |  |_ _|  _ \ / ___|
       | |/ _ \ \/ / __| | | |/ _` | |   | || |_) | |
       | |  __/>  <| |_| |_| | (_| | |   | ||  _ <| |___
       |_|\___/_/\_\\__|\__,_|\__,_|_|  |___|_| \_\\____|

 Copyright (c) 2010 — 2013 Codeux Software & respective contributors.
        Please see Contributors.pdf and Acknowledgements.pdf

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of the Textual IRC Client & Codeux Software nor the
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

#import "TPI_ZNCAdditions.h"

@implementation TPI_ZNCAdditions

#pragma mark -
#pragma mark Plugin API

- (void)messageReceivedByServer:(IRCClient *)client
						 sender:(NSDictionary *)senderDict
						message:(NSDictionary *)messageDict
{
	NSString *sender = [senderDict objectForKey:@"senderNickname"];
	NSString *message = [messageDict objectForKey:@"messageSequence"];

	if ([sender isEqualToString:@"*status"] && [message hasPrefix:@"Disconnected from IRC"]) {
		/* We listen for ZNC disconnects so that we can terminate channels when we
		 disconnect from the server ZNC was connected to. ZNC does not localize 
		 itself so detecting these disconnects is not very hard… */

		/* handleIRCSideDisconnect: calls -deactivate on IRCChannel. That call in 
		 IRCChannel posts a script event to the active style. Therefore, we have to
		 invoke the calls on the main thread because WebKit is not thread safe. */
		[self.iomt handleIRCSideDisconnect:client];
	}
}

- (NSArray *)pluginSupportsServerInputCommands
{
	return @[@"privmsg"];
}

#pragma mark -
#pragma mark Private API

- (void)handleIRCSideDisconnect:(IRCClient *)client
{
	for (IRCChannel *c in client.channels) {
		NSAssertReturnLoopContinue(c.isActive);
        NSAssertReturnLoopContinue([c.name hasPrefix:@"~#"] == NO);
		
        [c deactivate];
	}

	[self.worldController reloadTreeGroup:client];
}

@end
