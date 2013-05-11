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

#import "TextualApplication.h"

@interface IRCExtras : NSObject

/*
	Textual supports the following syntax for irc, ircs, and textual links.

	irc://irc.example.com:0000/#channel,needssl

	irc:// is a normal IRC connection.
	ircs:// is an IRC connection that defaults to SSL.
	textual:// is an alias of irc:// — forces connection through Textual.

	IPv6 addresses can be used by surrounding them by the standard square
	brackets used by the HTTP scheme.

	The port is not required nor is anything after the forward slash.

	"needssl" should appear last in URL and should be proceeded by a comma.
	It tells Textual to favor SSL when ircs:// is not used.

	The channel wanted to be joined is the first item after the forward
	slash. ONLY A SINGLE CHANNEL IS RECOMMENDED, but Textual does allow
	up to five comma seperated channels. Anything above five will be 
	ignored to prevent abuse. 

	All URLs are also considered untrusted and are set to not auto connect.

	Examples:

	irc://irc.example.com
	irc://irc.example.com:6667
	irc://irc.example.com/#channel — normal connection to #channel

	ircs://irc.example.com:6697/#channel			— SSL based connection to #channel
	irc://irc.example.com:6697/#channel,needssl		— SSL based connection to #channel

	parseIRCProtocolURI: does not actually create any connections. It only
	formats the input into a form that +createConnectionAndJoinChannel:channel:autoConnect:
	can understand. See comments below for more information.
 */

+ (void)parseIRCProtocolURI:(NSString *)location;
+ (void)parseIRCProtocolURI:(NSString *)location withDescriptor:(NSAppleEventDescriptor *)event;

/*
	+createConnectionAndJoinChannel:channel:autoConnect: is the method used to
	parse the input of the "/server" command. It also handles input from
	+parseIRCProtocolURI:

	The following syntax is supported by this method and is recommended:

	"-SSL irc.example.com:0000 serverpassword"

	Input can also vary including formats such as:

	"irc.example.com:0000 serverpassword"
	"irc.example.com 0000 serverpassword"

	"irc.example.com:+0000 serverpassword"
	"irc.example.com +0000 serverpassword"

	Of course -SSL being the front most token would favor SSL for the
	connection being created. Additionally, a server port proceeded by
	a plus sign (+) also indicates the connection will be SSL based.

	Server port can be associated with the server using a colon (:) or
	simply making it second to the server using a space.

	The server password passed using the "PASS" command is last in list.
	Nothing should follow it.
 */

+ (void)createConnectionAndJoinChannel:(NSString *)serverInfo channel:(NSString *)channelList autoConnect:(BOOL)autoConnect;
@end
