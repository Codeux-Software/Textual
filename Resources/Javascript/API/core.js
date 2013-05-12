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

Textual = {
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
	viewInitiated: function(viewType, serverHash, channelHash, channelName) {},

	newMessagePostedToView: 				function(lineNumber) {},
	
	historyIndicatorAddedToView:	 		function() {},
	historyIndicatorRemovedFromView: 		function() {},
	
	topicBarValueChanged: 					function(newTopic) {},
	
	viewContentsBeingCleared: 				function() {},
	viewFinishedLoading: 					function() {},
	viewFinishedReload: 					function() {},
	viewFontSizeChanged:					function(bigger) {},
	viewPositionMovedToBottom:				function() {},
	viewPositionMovedToHistoryIndicator: 	function() {},
	viewPositionMovedToLine: 				function(lineNumber) {},
	viewPositionMovedToTop: 				function() {},
	
	/* Allows a style to respond to the user switching between light and
	dark mode. */
	sidebarInversionPreferenceChanged:		function() {},
    
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
    handleEvent:                            function(eventToken) {}, 
	
    /* The following API calls can be called at any time. */
    
   // app.logToConsole(<input>)        - Log a message to the Mac OS console.
   // app.serverIsConnected()          - Boolean if associated server is connected.
   // app.channelIsJoined()            — Boolean if associated channel is joined.
   // app.channelMemberCount()         — Number of members on the channel associated with this view.
   // app.serverChannelCount()         — Number of channels part of the server associated with this view.
   //                                    This number does not count against the status of the channels.
   //                                    They can be joined or all parted. It is only a raw count.
   // app.sidebarInversionIsEnabled()  - Boolean if sidebar colors are inverted.

	/* *********************************************************************** */
	
	scrollToBottomOfView: function()
	{
		document.body.scrollTop = document.body.scrollHeight;
		
		Textual.viewPositionMovedToBottom();
	},

	/* Loading screen. */
	
	fadeInLoadingScreen: function(bodyOp, topicOp)
	{
		/* Reserved element IDs. */
		var bhe = document.getElementById("body_home");
		var tbe = document.getElementById("topic_bar");
		var lbe = document.getElementById("loading_screen");

		lbe.style.opacity = 0.00;
		bhe.style.opacity = bodyOp;

		if (tbe != null) {
			tbe.style.opacity = topicOp;
		}
		
		/* The fade time for the loading screen depends on the CSS of the actual
		style, but there is no reason it should take more than five (5) seconds.
		We will wait that amount of time before setting the overlay to hidden. 
		Setting it to hidden makes it not copiable after it is not visible. */
		
		setTimeout(function() {
			lbe.style.display = "none";
		}, 5000);
	},

	/* Resource management. */

	includeStyleResourceFile: function(file)
	{
		if (/loaded|complete/.test(document.readyState)) {
			var css = document.createElement("link");
			
			css.href = file;
			css.media = "screen";
			css.rel = "stylesheet";
			css.type = "text/css";
			
			document.getElementsByTagName("HEAD")[0].appendChild(css);
		} else {
			document.write('<link href="' + file + '" media="screen" rel="stylesheet" type="text/css" />'); 
		}
	},
	
	includeScriptResourceFile: function(file)
	{
		if (/loaded|complete/.test(document.readyState)) {
			var js = document.createElement("script");
			
			js.src  = file;
			js.type = "text/javascript";
			
			document.getElementsByTagName("HEAD")[0].appendChild(js);
		} else {
			document.write('<script type="text/javascript" src="' + file + '"></scr' + 'ipt>'); 
		}
	},
	
	/* Contextual menu management and other resources.
	 We do not recommend anyone try to override these. */
	
	openChannelNameContextualMenu: 			function() { app.setChannelName(event.target.innerHTML); },
	openURLManagementContextualMenu:		function() { app.setURLAddress(event.target.innerHTML); },
	openInlineNicknameContextualMenu:		function() { app.setNickname(event.target.innerHTML); }, // Conversation Tracking
	openStandardNicknameContextualMenu: 	function() { app.setNickname(event.target.getAttribute("nick")); },
	
	nicknameDoubleClicked: function() { 
		Textual.openStandardNicknameContextualMenu();

		app.nicknameDoubleClicked();
	},
	
	channelNameDoubleClicked: function() {
		Textual.openChannelNameContextualMenu();

		app.channelNameDoubleClicked();
	},
	
	inlineNicknameDoubleClicked: function() {
		Textual.openInlineNicknameContextualMenu();

		app.nicknameDoubleClicked();
	},
	
	toggleInlineImage: function(object) {
		if (app.toggleInlineImage(object) == "false") {
			return false;
		}
		
		return true;
	},
    
    hideInlineImage: function(object) {
        if (app.hideInlineImage(object) == "false") {
            return false;
        }
        
        return true;
    },
}
