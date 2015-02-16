/* *********************************************************************
                  _____         _               _
                 |_   _|____  _| |_ _   _  __ _| |
                   | |/ _ \ \/ / __| | | |/ _` | |
                   | |  __/>  <| |_| |_| | (_| | |
                   |_|\___/_/\_\\__|\__,_|\__,_|_|

 Copyright (c) 2010 - 2015 Codeux Software, LLC & respective contributors.
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

var Textual = {};

/* *********************************************************************** */
/*						View Callbacks									   */
/* *********************************************************************** */

/* Callbacks for each WebView in Textual. — Self explanatory. */

/* These callbacks are limited to the context of this view. The view can represent either
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

Textual.newMessagePostedToView 			= function(lineNumber) {};

Textual.historyIndicatorAddedToView			= function() {};
Textual.historyIndicatorRemovedFromView 	= function() {};

Textual.topicBarValueChanged 				= function(newTopic) {};

Textual.viewContentsBeingCleared 				= function() {};
Textual.viewFinishedLoading 					= function() {};
Textual.viewFinishedReload 						= function() {};
Textual.viewFontSizeChanged						= function(bigger) {};
Textual.viewPositionMovedToBottom				= function() {};
Textual.viewPositionMovedToHistoryIndicator 	= function() {};
Textual.viewPositionMovedToLine 				= function(lineNumber) {};
Textual.viewPositionMovedToTop 					= function() {};

/* This function is not called by Textual itself, but by WebKit. It is appended
   to <body> as the function to call during onload phase. It is used by the newer
   templates to replace viewDidFinishLoading as the function responsible for
   fading out the loading screen. It is defined here so style's that do not
   implement it do not error out. */
Textual.viewBodyDidLoad						= function() {};

/* *********************************************************************** */
/*						Textual Specific Preferences					   */
/* *********************************************************************** */

/* A style can retrieve the value of preferences using the retrievePreferencesWithMethodName() function.
   The key supplied to this function corresponds to the Objective-C method name defined in the TPCPreferences.h
   header file located at the path "Textual 5.app/Contents/Headers" — calling a particular method name instead of
   the raw key name was picked because it was a more uniform approach. */
// app.retrievePreferencesWithMethodName(name)		— Retrieve particular value from preferences

/* No key is supplied to preferencesDidChange() because it is preferred that the style maintain a cached state
   of any values that they wish to monitor and update accordingly. */
/* This callback is called very frequently. Up to a dozen times a second. Make sure your code is efficient. */
Textual.preferencesDidChange						= function() {};

/* Checks whether inline images are enabled for this particular view. Inline images can be enabled and disabled
   on a per-view basis so querying preferences alone for the value will only give the global value. */
// app.inlineImagesEnabledForView()					— Returns true when inline images are enabled for view.

/* Allows a style to respond to the user switching between light and dark mode. */
Textual.sidebarInversionPreferenceChanged			= function() {};

/* When switching styles, the sidebarInversionPreferenceChanged() function is not called, but a style may force the
   sidebar color to dark (a.k.a inverted). Therefore, it is important to use the app.sidebarInversionIsEnabled()
   function call at some point to update your style logic if it depends on the value. */
// app.sidebarInversionIsEnabled()					- Returns true if the sidebar colors are inverted (dark mode).

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

	THESE EVENTS ARE PUSHED WHEN THEY OCCUR. When a style is reloaded by Textual or
    the end user, these events are not sent again. It is recommended to use a feature
    of WebKit known as sessionStorage if these events are required to be known between
    reloads. When a reload occurs to a style, the entire HTML and JavaScript is replaced
    so the previous style will actually have no knowledge of the new one unless it is
    stored in a local database.
*/
Textual.handleEvent                            = function(eventToken) {};

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

	When setting a value of undefined or null, the specified key is removed from the store.
	Any other value is automatically converted by WebKit to match the following data types:

	    JavaScript              ObjC
	    ----------              ----------
	    number          =>      NSNumber
	    boolean         =>      CFBoolean
	    string          =>      NSString
	    object          =>      id

	    ObjC                    JavaScript
	    ----                    ----------
	    CFBoolean       =>      boolean
	    NSNumber        =>      number
	    NSString        =>      string
	    NSArray         =>      array object
	    WebScriptObject =>      object

	 When the value of a setting is retrieved, undefined will be returned if key is not found.
*/

// app.styleSettingsRetrieveValue(key)				— Retrieve value of /key/ from the key-value store.
// app.styleSettingsSetValue(key, value)			— Set /value/ to /key/ in the key-value store.

/* This function is invoked when a style setting has changed. It is invoked on all WebViews
   including the one that was responsible for changing the original value. */
Textual.styleSettingDidChange                       = function(changedKey) {};

/* *********************************************************************** */
/*						Owning Channel/Server Status					   */
/* *********************************************************************** */

// app.serverIsConnected()          - true if associated server is connected.
// app.channelIsJoined()            — true if associated channel is joined.
// app.channelMemberCount()         — Number of members on the channel associated with this view.

// app.serverChannelCount()         — Number of channels part of the server associated with this view.
//                                    This number does not count against the status of the channels.
//                                    They can be joined or all parted. It is only a raw count.

// app.channelName()				— Channel name of associated channel. Can be an actual channel name,
//									  a nickname for a private message, or blank for the console.

// app.networkName()				— Returns the name of the client related to this view. If the actual network
//									  name of the connected server is known (e.g. "freenode IRC network"), then
//									  that is returned. Otherwise, the user configured name is returned.

// app.serverAddress()				— Actual server address (e.g. verne.freenode.net) of the associated
//									  server. This value is not available until raw numeric 005 is posted.

// app.localUserNickname()			— Nickname of the local user.
// app.localUserHostmask()			— Hostmask of the local user obtained during join.

/* *********************************************************************** */
/*						Print Debug Messages							   */
/* *********************************************************************** */

// app.logToConsole(<input>)						- Log a message to the OS X system-wide console.

/* The app.printDebugInformation* calls documented below also call newMessagePostedToView() which means calling
   them from within newMessagePostedToView() will create an infinite loop. If needed inside newMessagePostedToView(),
   then check the line type of the new message and do not respond to line types with the value "debug" */

// app.printDebugInformationToConsole(message)		— Show a debug message to the user in the server console.
//													  This is the equivalent of a script using the /debug command.

// app.printDebugInformation(message)				— Show a debug message to the user in the associated channel.
