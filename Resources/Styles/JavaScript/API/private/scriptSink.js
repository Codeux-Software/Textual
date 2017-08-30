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

/* ************************************************** */
/*                                                    */
/* DO NOT OVERRIDE ANYTHING BELOW THIS LINE           */
/*                                                    */
/* ************************************************** */

var app = {};
var appInternal = {};

appInternal.promiseIndex = 1;
appInternal.promisedCallbacks = {}

appInternal.promiseKept = function(promiseIndex, returnValue)
{
	/* Check to see if an array entry exists for given index. */
	var callbackFunction = appInternal.promisedCallbacks[promiseIndex];

	/* If an array entry did exist, then perform it as a function. */
	if (typeof callbackFunction !== "undefined") {
		callbackFunction(returnValue);

		delete appInternal.promisedCallbacks[promiseIndex];
	}
};

appInternal.makePromise = function(callbackFunction)
{
	/* Best to be safe about the data we take in. */
	if (appInternal.isValidCallbackFunction(callbackFunction) === false) {
		throw "Invalid callback function";
	}

	/* Insert the promise then return its index (count minus one) */
	var promiseIndex = appInternal.promiseIndex;

	appInternal.promiseIndex += 1;
	appInternal.promisedCallbacks[promiseIndex] = callbackFunction;

	return promiseIndex;
};

appInternal.isValidCallbackFunction = function(callbackFunction)
{
	if (callbackFunction && typeof callbackFunction === "function") {
		return true;
	} else {
		return false;
	}
};

appInternal.isWebKit2 = function()
{
	if (window.webkit && typeof window.webkit.messageHandlers !== "undefined") {
		return true;
	} else {
		return false;
	}
};

app.finishedLayingOutView = function()
{
	if (appInternal.isWebKit2()) {
		window.webkit.messageHandlers.finishedLayingOutView.postMessage(null);
	} else {
		TextualScriptSink.finishedLayingOutView();
	}
};

app.setURLAddress = function(object)
{
	if (appInternal.isWebKit2()) {
		window.webkit.messageHandlers.setURLAddress.postMessage(object);
	} else {
		TextualScriptSink.setURLAddress(object);
	}
};

app.setSelection = function(object)
{
	if (appInternal.isWebKit2()) {
		window.webkit.messageHandlers.setSelection.postMessage(object);
	} else {
		TextualScriptSink.setSelection(object);
	}
};

app.setChannelName = function(object)
{
	if (appInternal.isWebKit2()) {
		window.webkit.messageHandlers.setChannelName.postMessage(object);
	} else {
		TextualScriptSink.setChannelName(object);
	}
};

app.setNickname = function(object)
{
	if (appInternal.isWebKit2()) {
		window.webkit.messageHandlers.setNickname.postMessage(object);
	} else {
		TextualScriptSink.setNickname(object);
	}
};

app.channelNameDoubleClicked = function()
{
	if (appInternal.isWebKit2()) {
		window.webkit.messageHandlers.channelNameDoubleClicked.postMessage(null);
	} else {
		TextualScriptSink.channelNameDoubleClicked();
	}
};

app.nicknameDoubleClicked = function()
{
	if (appInternal.isWebKit2()) {
		window.webkit.messageHandlers.nicknameDoubleClicked.postMessage(null);
	} else {
		TextualScriptSink.nicknameDoubleClicked();
	}
};

app.topicBarDoubleClicked = function()
{
	if (appInternal.isWebKit2()) {
		window.webkit.messageHandlers.topicBarDoubleClicked.postMessage(null);
	} else {
		TextualScriptSink.topicBarDoubleClicked();
	}
};

app.channelMemberCount = function(callbackFunction)
{
	var promiseIndex = appInternal.makePromise(callbackFunction);

	var dataValue = {"promiseIndex" : promiseIndex};

	if (appInternal.isWebKit2()) {
		window.webkit.messageHandlers.channelMemberCount.postMessage(dataValue);
	} else {
		TextualScriptSink.channelMemberCount(dataValue);
	}
};

app.serverChannelCount = function(callbackFunction)
{
	var promiseIndex = appInternal.makePromise(callbackFunction);

	var dataValue = {"promiseIndex" : promiseIndex};

	if (appInternal.isWebKit2()) {
		window.webkit.messageHandlers.serverChannelCount.postMessage(dataValue);
	} else {
		TextualScriptSink.serverChannelCount(dataValue);
	}
};

app.serverIsConnected = function(callbackFunction)
{
	var promiseIndex = appInternal.makePromise(callbackFunction);

	var dataValue = {"promiseIndex" : promiseIndex};

	if (appInternal.isWebKit2()) {
		window.webkit.messageHandlers.serverIsConnected.postMessage(dataValue);
	} else {
		TextualScriptSink.serverIsConnected(dataValue);
	}
};

app.channelIsJoined = function(callbackFunction)
{
	var promiseIndex = appInternal.makePromise(callbackFunction);

	var dataValue = {"promiseIndex" : promiseIndex};

	if (appInternal.isWebKit2()) {
		window.webkit.messageHandlers.channelIsJoined.postMessage(dataValue);
	} else {
		TextualScriptSink.channelIsJoined(dataValue);
	}
};

app.channelName = function(callbackFunction)
{
	var promiseIndex = appInternal.makePromise(callbackFunction);

	var dataValue = {"promiseIndex" : promiseIndex};

	if (appInternal.isWebKit2()) {
		window.webkit.messageHandlers.channelName.postMessage(dataValue);
	} else {
		TextualScriptSink.channelName(dataValue);
	}
};

app.serverAddress = function(callbackFunction)
{
	var promiseIndex = appInternal.makePromise(callbackFunction);

	var dataValue = {"promiseIndex" : promiseIndex};

	if (appInternal.isWebKit2()) {
		window.webkit.messageHandlers.serverAddress.postMessage(dataValue);
	} else {
		TextualScriptSink.serverAddress(dataValue);
	}
};

app.networkName = function(callbackFunction)
{
	var promiseIndex = appInternal.makePromise(callbackFunction);

	var dataValue = {"promiseIndex" : promiseIndex};

	if (appInternal.isWebKit2()) {
		window.webkit.messageHandlers.networkName.postMessage(dataValue);
	} else {
		TextualScriptSink.networkName(dataValue);
	}
};

app.localUserNickname = function(callbackFunction)
{
	var promiseIndex = appInternal.makePromise(callbackFunction);

	var dataValue = {"promiseIndex" : promiseIndex};

	if (appInternal.isWebKit2()) {
		window.webkit.messageHandlers.localUserNickname.postMessage(dataValue);
	} else {
		TextualScriptSink.localUserNickname(dataValue);
	}
};

app.localUserHostmask = function(callbackFunction)
{
	var promiseIndex = appInternal.makePromise(callbackFunction);

	var dataValue = {"promiseIndex" : promiseIndex};

	if (appInternal.isWebKit2()) {
		window.webkit.messageHandlers.localUserHostmask.postMessage(dataValue);
	} else {
		TextualScriptSink.localUserHostmask(dataValue);
	}
};

app.logToConsole = function(message)
{
	if (appInternal.isWebKit2()) {
		window.webkit.messageHandlers.logToConsole.postMessage(message);
	} else {
		TextualScriptSink.logToConsole(message);
	}
};

app.printDebugInformationToConsole = function(message)
{
	if (appInternal.isWebKit2()) {
		window.webkit.messageHandlers.printDebugInformationToConsole.postMessage(message);
	} else {
		TextualScriptSink.printDebugInformationToConsole(message);
	}
};

app.printDebugInformation = function(message)
{
	if (appInternal.isWebKit2()) {
		window.webkit.messageHandlers.printDebugInformation.postMessage(message);
	} else {
		TextualScriptSink.printDebugInformation(message);
	}
};

app.sidebarInversionIsEnabled = function()
{
	var promiseIndex = appInternal.makePromise(callbackFunction);

	var dataValue = {"promiseIndex" : promiseIndex};

	if (appInternal.isWebKit2()) {
		window.webkit.messageHandlers.sidebarInversionIsEnabled.postMessage(dataValue);
	} else {
		TextualScriptSink.sidebarInversionIsEnabled(dataValue);
	}
};

app.inlineMediaEnabledForView = function(callbackFunction)
{
	var promiseIndex = appInternal.makePromise(callbackFunction);

	var dataValue = {"promiseIndex" : promiseIndex};

	if (appInternal.isWebKit2()) {
		window.webkit.messageHandlers.inlineMediaEnabledForView.postMessage(dataValue);
	} else {
		TextualScriptSink.inlineMediaEnabledForView(dataValue);
	}
};

app.nicknameColorStyleHash = function(nickname, nicknameColorStyle, callbackFunction)
{
	var promiseIndex = appInternal.makePromise(callbackFunction);

	var dataValue = {"promiseIndex" : promiseIndex, "values" : [nickname, nicknameColorStyle]};

	if (appInternal.isWebKit2()) {
		window.webkit.messageHandlers.nicknameColorStyleHash.postMessage(dataValue);
	} else {
		TextualScriptSink.nicknameColorStyleHash(dataValue);
	}
};

app.styleSettingsRetrieveValue = function(key, callbackFunction)
{
	var promiseIndex = appInternal.makePromise(callbackFunction);

	var dataValue = {"promiseIndex" : promiseIndex, "values" : [key]};

	if (appInternal.isWebKit2()) {
		window.webkit.messageHandlers.styleSettingsRetrieveValue.postMessage(dataValue);
	} else {
		TextualScriptSink.styleSettingsRetrieveValue(dataValue);
	}
};

app.styleSettingsSetValue = function(key, value, callbackFunction)
{
	var promiseIndex = appInternal.makePromise(callbackFunction);

	var dataValue = {"promiseIndex" : promiseIndex, "values" : [key, value]};

	if (appInternal.isWebKit2()) {
		window.webkit.messageHandlers.styleSettingsSetValue.postMessage(dataValue);
	} else {
		TextualScriptSink.styleSettingsSetValue(dataValue);
	}
};

app.retrievePreferencesWithMethodName = function(name, callbackFunction)
{
	var promiseIndex = appInternal.makePromise(callbackFunction);

	var dataValue = {"promiseIndex" : promiseIndex, "values" : [name]};

	if (appInternal.isWebKit2()) {
		window.webkit.messageHandlers.retrievePreferencesWithMethodName.postMessage(dataValue);
	} else {
		TextualScriptSink.retrievePreferencesWithMethodName(dataValue);
	}
};

app.copySelectionWhenPermitted = function(callbackFunction)
{
	var promiseIndex = appInternal.makePromise(callbackFunction);

	var dataValue = {"promiseIndex" : promiseIndex};

	if (appInternal.isWebKit2()) {
		window.webkit.messageHandlers.copySelectionWhenPermitted.postMessage(dataValue);
	} else {
		TextualScriptSink.copySelectionWhenPermitted(dataValue);
	}
};

app.displayContextMenu = function()
{
	window.webkit.messageHandlers.displayContextMenu.postMessage(null);
};

app.sendPluginPayload = function(payloadLabel, payloadContent)
{
	var dataValue = {"values" : [payloadLabel, payloadContent]};

	if (appInternal.isWebKit2()) {
		window.webkit.messageHandlers.sendPluginPayload.postMessage(dataValue);
	} else {
		TextualScriptSink.sendPluginPayload(dataValue);
	}
};

app.showInAppPurchaseWindow = function()
{
	if (appInternal.isWebKit2()) {
		window.webkit.messageHandlers.showInAppPurchaseWindow.postMessage(null);
	} else {
		TextualScriptSink.showInAppPurchaseWindow();
	}
};

app.renderMessagesBefore = function(lineNumber, maximumNumberOfLines, callbackFunction)
{
	var promiseIndex = appInternal.makePromise(callbackFunction);

	var dataValue = {"promiseIndex" : promiseIndex, "values" : [lineNumber, maximumNumberOfLines]};

	if (appInternal.isWebKit2()) {
		window.webkit.messageHandlers.renderMessagesBefore.postMessage(dataValue);
	} else {
		TextualScriptSink.renderMessagesBefore(dataValue);
	}
};

app.renderMessagesAfter = function(lineNumber, maximumNumberOfLines, callbackFunction)
{
	var promiseIndex = appInternal.makePromise(callbackFunction);

	var dataValue = {"promiseIndex" : promiseIndex, "values" : [lineNumber, maximumNumberOfLines]};

	if (appInternal.isWebKit2()) {
		window.webkit.messageHandlers.renderMessagesAfter.postMessage(dataValue);
	} else {
		TextualScriptSink.renderMessagesAfter(dataValue);
	}
};

app.renderMessagesInRange = function(lineNumberAfter, lineNumberBefore, callbackFunction)
{
	var promiseIndex = appInternal.makePromise(callbackFunction);

	var dataValue = {"promiseIndex" : promiseIndex, "values" : [lineNumberAfter, lineNumberBefore]};

	if (appInternal.isWebKit2()) {
		window.webkit.messageHandlers.renderMessagesInRange.postMessage(dataValue);
	} else {
		TextualScriptSink.renderMessagesInRange(dataValue);
	}
};

app.renderTemplate = function(templateName, templateAttributes, callbackFunction)
{
	var promiseIndex = appInternal.makePromise(callbackFunction);

	var dataValue = {"promiseIndex" : promiseIndex, "values" : [templateName, templateAttributes]};

	if (appInternal.isWebKit2()) {
		window.webkit.messageHandlers.renderTemplate.postMessage(dataValue);
	} else {
		TextualScriptSink.renderTemplate(dataValue);
	}
};

