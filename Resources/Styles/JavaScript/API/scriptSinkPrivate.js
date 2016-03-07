/* ********************************************************************* 
                  _____         _               _
                 |_   _|____  _| |_ _   _  __ _| |
                   | |/ _ \ \/ / __| | | |/ _` | |
                   | |  __/>  <| |_| |_| | (_| | |
                   |_|\___/_/\_\\__|\__,_|\__,_|_|

 Copyright (c) 2010 - 2016 Codeux Software, LLC & respective contributors.
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

/* *********************************************************************** */
/*																		   */
/* DO NOT EDIT ANYTHING BELOW THIS LINE FROM WITHIN A STYLE. 			   */
/* THE FUNCTIONS DELCARED WITHIN THIS FILE ARE USED FOR INTERNAL		   */
/* PURPOSES AND THE RESULT OF OVERRIDING A FUNCTION IS UNDEFINED.		   */
/*																		   */
/* *********************************************************************** */

var app = {};

app.supportsMessageHandlers = function()
{
	return (typeof window.webkit.messageHandlers !== "undefined");
}

app.setURLAddress = function(object)
{
	if (app.supportsMessageHandlers()) {
		window.webkit.messageHandlers.setURLAddress.postMessage(object);
	} else {
		TextualScriptSink.setURLAddress(object);
	}
};

app.setChannelName = function(object)
{
	if (app.supportsMessageHandlers()) {
		window.webkit.messageHandlers.setChannelName.postMessage(object);
	} else {
		TextualScriptSink.setChannelName(object);
	}
};

app.setNickname = function(object)
{
	if (app.supportsMessageHandlers()) {
		window.webkit.messageHandlers.setNickname.postMessage(object);
	} else {
		TextualScriptSink.setNickname(object);
	}
};

app.channelNameDoubleClicked = function()
{
	if (app.supportsMessageHandlers()) {
		window.webkit.messageHandlers.channelNameDoubleClicked.postMessage(null);
	} else {
		TextualScriptSink.channelNameDoubleClicked();
	}
};

app.nicknameDoubleClicked = function()
{
	if (app.supportsMessageHandlers()) {
		window.webkit.messageHandlers.nicknameDoubleClicked.postMessage(null);
	} else {
		TextualScriptSink.nicknameDoubleClicked();
	}
};

app.topicBarDoubleClicked = function()
{
	if (app.supportsMessageHandlers()) {
		window.webkit.messageHandlers.topicBarDoubleClicked.postMessage(null);
	} else {
		TextualScriptSink.topicBarDoubleClicked();
	}
};

app.channelMemberCount = function()
{
	if (app.supportsMessageHandlers()) {
		return window.webkit.messageHandlers.channelMemberCount.postMessage(null);
	} else {
		return TextualScriptSink.channelMemberCount();
	}
};

app.serverChannelCount = function()
{
	if (app.supportsMessageHandlers()) {
		return window.webkit.messageHandlers.serverChannelCount.postMessage(null);
	} else {
		return TextualScriptSink.serverChannelCount();
	}
};

app.serverIsConnected = function()
{
	if (app.supportsMessageHandlers()) {
		return window.webkit.messageHandlers.serverIsConnected.postMessage(null);
	} else {
		return TextualScriptSink.serverIsConnected();
	}
};

app.channelIsJoined = function()
{
	if (app.supportsMessageHandlers()) {
		return window.webkit.messageHandlers.channelIsJoined.postMessage(null);
	} else {
		return TextualScriptSink.channelIsJoined();
	}
};

app.channelName = function()
{
	if (app.supportsMessageHandlers()) {
		return window.webkit.messageHandlers.channelName.postMessage(null);
	} else {
		return TextualScriptSink.channelName();
	}
};

app.serverAddress = function()
{
	if (app.supportsMessageHandlers()) {
		return window.webkit.messageHandlers.serverAddress.postMessage(null);
	} else {
		return TextualScriptSink.serverAddress();
	}
};

app.networkName = function()
{
	if (app.supportsMessageHandlers()) {
		return window.webkit.messageHandlers.networkName.postMessage(null);
	} else {
		return TextualScriptSink.networkName();
	}
};

app.localUserNickname = function()
{
	if (app.supportsMessageHandlers()) {
		return window.webkit.messageHandlers.localUserNickname.postMessage(null);
	} else {
		return TextualScriptSink.localUserNickname();
	}
};

app.localUserHostmask = function()
{
	if (app.supportsMessageHandlers()) {
		return window.webkit.messageHandlers.localUserHostmask.postMessage(null);
	} else {
		return TextualScriptSink.localUserHostmask();
	}
};

app.inlineImagesEnabledForView = function()
{
	if (app.supportsMessageHandlers()) {
		return window.webkit.messageHandlers.inlineImagesEnabledForView.postMessage(null);
	} else {
		return TextualScriptSink.inlineImagesEnabledForView();
	}
};

app.logToConsole = function(message)
{
	if (app.supportsMessageHandlers()) {
		window.webkit.messageHandlers.logToConsole.postMessage(message);
	} else {
		TextualScriptSink.logToConsole(message);
	}
};

app.printDebugInformationToConsole = function(message)
{
	if (app.supportsMessageHandlers()) {
		window.webkit.messageHandlers.printDebugInformationToConsole.postMessage(message);
	} else {
		TextualScriptSink.printDebugInformationToConsole(message);
	}
};

app.printDebugInformation = function(message)
{
	if (app.supportsMessageHandlers()) {
		window.webkit.messageHandlers.printDebugInformation.postMessage(message);
	} else {
		TextualScriptSink.printDebugInformation(message);
	}
};

app.sidebarInversionIsEnabled = function()
{
	if (app.supportsMessageHandlers()) {
		window.webkit.messageHandlers.sidebarInversionIsEnabled.postMessage(null);
	} else {
		TextualScriptSink.sidebarInversionIsEnabled();
	}
};

app.nicknameColorStyleHash = function(nickname, nicknameColorStyle)
{
	if (app.supportsMessageHandlers()) {
		return window.webkit.messageHandlers.nicknameColorStyleHash.postMessage([nickname, nicknameColorStyle]);
	} else {
		return TextualScriptSink.nicknameColorStyleHash(nickname, nicknameColorStyle);
	}
};

app.styleSettingsRetrieveValue = function(key)
{
	if (app.supportsMessageHandlers()) {
		window.webkit.messageHandlers.styleSettingsRetrieveValue.postMessage(key);
	} else {
		TextualScriptSink.styleSettingsRetrieveValue(key);
	}
};

app.styleSettingsSetValue = function(key, value)
{
	if (app.supportsMessageHandlers()) {
		window.webkit.messageHandlers.styleSettingsSetValue.postMessage([key, value]);
	} else {
		TextualScriptSink.styleSettingsSetValue(key, value);
	}
};

app.retrievePreferencesWithMethodName = function(name)
{
	if (app.supportsMessageHandlers()) {
		window.webkit.messageHandlers.retrievePreferencesWithMethodName.postMessage(name);
	} else {
		TextualScriptSink.retrievePreferencesWithMethodName(name);
	}
};
