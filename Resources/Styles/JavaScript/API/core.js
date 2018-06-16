/* *********************************************************************
 *                  _____         _               _
 *                 |_   _|____  _| |_ _   _  __ _| |
 *                   | |/ _ \ \/ / __| | | |/ _` | |
 *                   | |  __/>  <| |_| |_| | (_| | |
 *                   |_|\___/_/\_\\__|\__,_|\__,_|_|
 *
 * Copyright (c) 2010 - 2016 Codeux Software, LLC & respective contributors.
 *       Please see Acknowledgements.pdf for additional information.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 *	* Redistributions of source code must retain the above copyright
 *	  notice, this list of conditions and the following disclaimer.
 *	* Redistributions in binary form must reproduce the above copyright
 *	  notice, this list of conditions and the following disclaimer in the
 *	  documentation and/or other materials provided with the distribution.
 *  * Neither the name of Textual and/or Codeux Software, nor the names of
 *    its contributors may be used to endorse or promote products derived
 * 	  from this software without specific prior written permission.
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

"use strict";

var Textual = {};

/* *********************************************************************** */
/*						View Callbacks									   */
/* *********************************************************************** */

/*	Callbacks for each WebView in Textual. — Self explanatory. */

/*	These callbacks are limited to the context of this view. The view can represent either
	the console, a channel, or a private message. See viewInitiated() for information about
	determining which view this view represents. */

/*
	viewInitiated():

	@viewType:		Type of view being represented. Server console, channel, query, etc.
					Possible values: server, channel, query. — query = private message.
	@serverHash:	A unique identifier to differentiate between each server a view may represent.
	@channelHash:	A unique identifier to differentiate between each channel a view may represent.
	@channelName:	Name of the view. Actual channel name, nickname for a private message, or blank for console.
*/
Textual.viewInitiated 					= function(viewType, serverHash, channelHash, channelName) {};

Textual.messageAddedToView 				= function(lineNumber, fromBuffer) {};
Textual.messageRemovedFromView 			= function(lineNumber) {};

Textual.historyIndicatorAddedToView			= function() {};
Textual.historyIndicatorRemovedFromView 	= function() {};

Textual.topicBarValueChanged 				= function(newTopic) {};

Textual.viewFinishedLoading 					= function() {};
Textual.viewFinishedLoadingHistory				= function() {};
Textual.viewFinishedReload 						= function() {};
Textual.viewFontSizeChanged						= function(bigger) {};
Textual.viewPositionMovedToBottom				= function() {};
Textual.viewPositionMovedToHistoryIndicator 	= function() {};
Textual.viewPositionMovedToLine 				= function(lineNumber) {};
Textual.viewPositionMovedToTop 					= function() {};

/*	This function is called when two conditions are met:
	1. The day has changed by reaching midnight
	2. The system clock has changed

	For the first case (#1), the timer that handles the observation of
	midnight understands Daylight Saving Time (DST) and other oddities.

	For the second case (#2), Textual does not make an effort to compare
	if the day has in-fact changed. It is merely passing the change down
	to the style to inform it that the system clock changed.  */
Textual.dateChanged								= function(dayYear, dayMonth, dayDay) {};

/*	This function is not called by Textual itself, but by WebKit. It is appended
	to <body> as the function to call during onload phase. It is used by the newer
	templates to replace viewDidFinishLoading as the function responsible for
	fading out the loading screen. It is defined here so style's that do not
	implement it do not error out. */
Textual.viewBodyDidLoad						= function() {};

/* *********************************************************************** */
/*						Textual Specific Preferences					   */
/* *********************************************************************** */

/*	No key is supplied to preferencesDidChange() because it is preferred that the style
    maintain a cached state of any values that they wish to monitor and update accordingly. */
/*	A boolean entry with key name "Post Textual.preferencesDidChange() Notifications" must
    be added to styleSettings.plist in order to enable the use of this callback. */
/*	This callback is rate-limit at one call per-second, per-view. */
Textual.preferencesDidChange						= function() {};

/* *********************************************************************** */
/*						Event Handling									   */
/* *********************************************************************** */

/*
	handleEvent allows a style to receive status information about several
	actions going on behind the scenes. The following event tokens are
	currently supported.

	serverConnected                 - Server associated with this view has connected.
	serverConnecting                - Server associated with this view is connecting.
	serverDisconnected              - Server associated with this view has disconnected.
	serverDisconnecting             - Server associated with this view is disconnecting.
	channelJoined                   - Channel associated with this view has been joined.
	channelParted                   — Channel associated with this view has been parted.
	channelMemberAdded              — Member added to the channel associated with this view.
	channelMemberRemoved            — Member removed from the channel associated with this view.
	nicknameChanged					— Nickname of local user changed

	THESE EVENTS ARE PUSHED WHEN THEY OCCUR. When a style is reloaded by Textual or
	the end user, these events are not sent again. It is recommended to use a feature
	of WebKit known as sessionStorage if these events are required to be known between
	reloads. When a reload occurs to a style, the entire HTML and JavaScript is replaced
	so the previous style will actually have no knowledge of the new one unless it is
	stored in a local database.
*/

/*	A boolean entry with key name "Post Textual.handleEvent() Notifications" must be 
	added to styleSettings.plist in order to enable the use of this callback. */
Textual.handleEvent                            = function(eventToken) {};

/* *********************************************************************** */
/*						Application Object								   */
/* *********************************************************************** */

/* 
	The "app" object provides a communication channel between the style and Textual. Functions
	defined by this object may require a callback function to receive return values. If a callback
	function is required, then the callback function should have one argument which is a variable
	defining the return value.

	For example:
		app.inlineMediaEnabledForView(
			function(returnValue) {
				console.log(returnValue);
			}
		)
*/

/* Checks whether inline media are enabled for this particular view. Inline media can be enabled on
   a per-view basis so querying preferences alone for the value will only give the global value. */
// app.inlineMediaEnabledForView(callbackFunction)

// app.serverIsConnected(callbackFunction)		- true if associated server is connected.
// app.channelIsJoined(callbackFunction)		— true if associated channel is joined.
// app.channelMemberCount(callbackFunction)		— Number of members on the channel associated with this view.

// app.serverChannelCount(callbackFunction)		— Number of channels part of the server associated with this view.
//												  This number does not count against the status of the channels.
//												  They can be joined or all parted. It is only a raw count.

// app.channelName(callbackFunction)		— Channel name of associated channel. Can be an actual channel name,
//											  a nickname for a private message, or blank for the console.

// app.networkName(callbackFunction)		— Returns the name of the client related to this view. If the actual network
//											  ame of the connected server is known (e.g. "freenode IRC network"), then
//											  that is returned. Otherwise, the user configured name is returned.

// app.serverAddress(callbackFunction)		— Actual server address (e.g. verne.freenode.net) of the associated
//											  server. This value is not available until raw numeric 005 is posted.

// app.localUserNickname(callbackFunction)		— Nickname of the local user.
// app.localUserHostmask(callbackFunction)		— Hostmask of the local user obtained during join.

/* *********************************************************************** */
/*						         Appearance								   */
/* *********************************************************************** */

/*  app.appearance() can be used to determine the current appearance of the main window.
    The return value is a string. For example: "light" or "dark" */
/*  Textual.appearanceDidChange() can be used to observe changes to the appearance. */
// app.appearance(callbackFunction);

/*	A boolean entry with key name "Post Textual.appearanceDidChange() Notifications" must be
 added to styleSettings.plist in order to enable the use of this callback. */
Textual.appearanceDidChange					= function(changedTo) {};

/* *********************************************************************** */
/*						Print Debug Messages							   */
/* *********************************************************************** */

// app.logToConsole(<input>)		- Log a message to the OS X system-wide console.

/*	The app.printDebugInformation* calls documented below also call messageAddedToView() which means calling
	them from within messageAddedToView() will create an infinite loop. If needed inside messageAddedToView(),
	then check the line type of the new message and do not respond to line types with the value "debug" */

// app.printDebugInformationToConsole(message)		— Show a debug message to the user in the server console.
// app.printDebugInformation(message)				— Show a debug message to the user in the associated channel.

/* *********************************************************************** */

/* *********************************************************************** */
/*						Style Settings									   */
/* *********************************************************************** */

/*
	Textual provides the ability to store values within a key-value store which is shared
	amongst all views. The values stored within this key-value store are maintained within
	the preferences file of Textual within its sandbox and will exist even if the style is
	renamed, removed, or replaced.

	To opt-in to using a key-value store, add a string value to the styleSettings.plist file
	of a style with the name of it being "Key-value Store Name" — the value of this key should
	be whatever the name the key-value stored should be saved under. Preferably, it would be
	named whatever the style is, but a different one can be picked so that multiple variants
	of a style can share the same values.

	When setting a value of null, the specified key is removed from the store.
	Any other value is automatically converted by WebKit to match the following data types:

		JavaScript				ObjC
		----------				----------
		array			=>		NSArray
		boolean			=>		BOOL
		number			=>		NSNumber
		object			=>		NSDictionary
		string			=>		NSString

		ObjC					JavaScript
		----					----------
		NSArray			=>		array
		BOOL			=>		boolean
		NSNumber		=>		number
		NSDictionary	=>		object
		NSString		=>		string
		NSURL           =>      string

	When the value of a setting is retrieved, null will be returned if key is not found.
 */

// app.styleSettingsRetrieveValue(key, callbackFunction)	— Retrieve value of /key/ from the key-value store.
// app.styleSettingsSetValue(key, value, callbackFunction)	— Set /value/ to /key/ in the key-value store.

/*	This function is invoked when a style setting has changed. It is invoked on all WebViews
	including the one that was responsible for changing the original value. */
Textual.styleSettingDidChange                       = function(changedKey) {};
