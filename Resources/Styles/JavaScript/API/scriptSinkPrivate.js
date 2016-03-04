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

app.channelNameDoubleClicked = function()
{
	TextualScriptSink.channelNameDoubleClicked();
};

app.nicknameDoubleClicked = function()
{
	TextualScriptSink.nicknameDoubleClicked();
};

app.topicBarDoubleClicked = function()
{
	TextualScriptSink.topicBarDoubleClicked();
};

app.channelMemberCount = function()
{
	return TextualScriptSink.channelMemberCount();
};

app.serverChannelCount = function()
{
	return TextualScriptSink.serverChannelCount();
};

app.serverIsConnected = function()
{
	return TextualScriptSink.serverIsConnected();
};

app.channelIsJoined = function()
{
	return TextualScriptSink.channelIsJoined();
};

app.channelName = function()
{
	return TextualScriptSink.channelName();
};

app.serverAddress = function()
{
	return TextualScriptSink.serverAddress();
};

app.networkName = function()
{
	return TextualScriptSink.networkName();
};

app.localUserNickname = function()
{
	return TextualScriptSink.localUserNickname();
};

app.localUserHostmask = function()
{
	return TextualScriptSink.localUserHostmask();
};

app.inlineImagesEnabledForView = function()
{
	return TextualScriptSink.inlineImagesEnabledForView();
};

app.logToConsole = function(message)
{
	TextualScriptSink.logToConsole(message);
};

app.printDebugInformationToConsole = function(message)
{
	TextualScriptSink.printDebugInformationToConsole(message);
};

app.printDebugInformation = function(message)
{
	TextualScriptSink.printDebugInformation(message);
};

app.sidebarInversionIsEnabled = function()
{
	TextualScriptSink.sidebarInversionIsEnabled();
};

app.styleSettingsRetrieveValue = function(key)
{
	TextualScriptSink.styleSettingsRetrieveValue(key);
};

app.styleSettingsSetValue = function(key, value)
{
	TextualScriptSink.styleSettingsSetValue(key, value);
};

app.retrievePreferencesWithMethodName = function(name)
{
	TextualScriptSink.retrievePreferencesWithMethodName(name);
};
