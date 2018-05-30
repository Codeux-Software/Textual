/* *********************************************************************
 *                  _____         _               _
 *                 |_   _|____  _| |_ _   _  __ _| |
 *                   | |/ _ \ \/ / __| | | |/ _` | |
 *                   | |  __/>  <| |_| |_| | (_| | |
 *                   |_|\___/_/\_\\__|\__,_|\__,_|_|
 *
 * Copyright (c) 2016 - 2018 Codeux Software, LLC & respective contributors.
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

NS_ASSUME_NONNULL_BEGIN

@implementation HSLHistoricLogProcessDelegate

- (BOOL)listener:(NSXPCListener *)listener shouldAcceptNewConnection:(NSXPCConnection *)newConnection
{
	NSXPCInterface *exportedInterface = [NSXPCInterface interfaceWithProtocol:@protocol(HLSHistoricLogServerProtocol)];

	[exportedInterface setClasses:[NSSet setWithObjects:[NSArray class], [TVCLogLineXPC class], nil]
					  forSelector:@selector(fetchEntriesForView:ascending:fetchLimit:limitToDate:withCompletionBlock:)
					argumentIndex:0
						  ofReply:YES];

	[exportedInterface setClasses:[NSSet setWithObjects:[NSArray class], [TVCLogLineXPC class], nil]
					  forSelector:@selector(fetchEntriesForView:withUniqueIdentifier:beforeFetchLimit:afterFetchLimit:limitToDate:withCompletionBlock:)
					argumentIndex:0
						  ofReply:YES];

	[exportedInterface setClasses:[NSSet setWithObjects:[NSArray class], [TVCLogLineXPC class], nil]
					  forSelector:@selector(fetchEntriesForView:beforeUniqueIdentifier:fetchLimit:limitToDate:withCompletionBlock:)
					argumentIndex:0
						  ofReply:YES];

	[exportedInterface setClasses:[NSSet setWithObjects:[NSArray class], [TVCLogLineXPC class], nil]
					  forSelector:@selector(fetchEntriesForView:afterUniqueIdentifier:fetchLimit:limitToDate:withCompletionBlock:)
					argumentIndex:0
						  ofReply:YES];

	[exportedInterface setClasses:[NSSet setWithObjects:[NSArray class], [TVCLogLineXPC class], nil]
					  forSelector:@selector(fetchEntriesForView:afterUniqueIdentifier:beforeUniqueIdentifier:fetchLimit:withCompletionBlock:)
					argumentIndex:0
						  ofReply:YES];

	newConnection.exportedInterface = exportedInterface;

	NSXPCInterface *remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(HLSHistoricLogClientProtocol)];

	newConnection.remoteObjectInterface = remoteObjectInterface;

	HLSHistoricLogProcessMain *exportedObject = [[HLSHistoricLogProcessMain alloc] initWithConnection:newConnection];

	newConnection.exportedObject = exportedObject;

	[newConnection resume];

	return YES;
}

@end

NS_ASSUME_NONNULL_END
