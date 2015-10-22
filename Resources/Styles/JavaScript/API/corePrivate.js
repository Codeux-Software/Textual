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

/* *********************************************************************** */
/*																		   */
/* DO NOT EDIT ANYTHING BELOW THIS LINE FROM WITHIN A STYLE. 			   */
/* THE FUNCTIONS DELCARED WITHIN THIS FILE ARE USED FOR INTERNAL		   */
/* PURPOSES AND THE RESULT OF OVERRIDING A FUNCTION IS UNDEFINED.		   */
/*																		   */
/* *********************************************************************** */

/* Internal state. */
Textual.nicknameDoubleClickTimer = null;

/* Loading screen. */
Textual.fadeInLoadingScreen = function(bodyOp, topicOp)
{
	/* fadeInLoadingScreen is the old API name and makes no sense since we are
	not bringing the loading screen into view, we are removing it. So it is
	being faded "out" not "in" */

	Textual.fadeOutLoadingScreen(bodyOp, topicOp);
};

Textual.fadeOutLoadingScreen = function(bodyOp, topicOp)
{
	/* Reserved element IDs. */
	var bhe = document.getElementById("body_home");
	var tbe = document.getElementById("topic_bar");
	var lbe = document.getElementById("loading_screen");

	lbe.style.opacity = 0.00;
	bhe.style.opacity = bodyOp;

	if (tbe !== null) {
		tbe.style.opacity = topicOp;
	}

	/* The fade time for the loading screen depends on the CSS of the actual
	style, but there is no reason it should take more than five (5) seconds.
	We will wait that amount of time before setting the overlay to hidden.
	Setting it to hidden makes it not copiable after it is not visible. */

	setTimeout(function() {
		var lbef = document.getElementById("loading_screen");

		lbef.style.display = "none";
	}, 5000);
};

/* Scrolling. */
Textual.scrollToBottomOfView = function(fireNotification)
{
	document.body.scrollTop = document.body.scrollHeight;

	if (fireNotification === undefined || fireNotification === true) {
		Textual.viewPositionMovedToBottom();
	}
};

Textual.notifyDidBecomeVisible = function(wasViewingBottom)
{
	window.getSelection().empty();

	if (wasViewingBottom) {
		Textual.scrollToBottomOfView();
	}
};
};

/* Resource management. */
Textual.includeStyleResourceFile = function(file)
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
};

Textual.includeScriptResourceFile = function(file)
{
	if (/loaded|complete/.test(document.readyState)) {
		var js = document.createElement("script");

		js.src  = file;
		js.type = "text/javascript";

		document.getElementsByTagName("HEAD")[0].appendChild(js);
	} else {
		document.write('<script type="text/javascript" src="' + file + '"></scr' + 'ipt>');
	}
};

/* Contextual menu management and other resources.
We do not recommend anyone try to override these. */
Textual.openChannelNameContextualMenu = function()
{
	app.setChannelName(event.target.textContent);
};

Textual.openURLManagementContextualMenu = function()
{
	app.setURLAddress(event.target.textContent);
};

Textual.openInlineNicknameContextualMenu = function()
{
	var userNickname = event.target.textContent;

	var userMode = event.target.getAttribute("mode");

	if (userMode && userMode.length > 0 && userNickname.indexOf(userMode) === 0) {
		app.setNickname(userNickname.substring(1));
	} else {
		app.setNickname(userNickname);
	}
}; // Conversation Tracking

Textual.openStandardNicknameContextualMenu = function()
{
	var userNickname = event.target.getAttribute("nickname");

	app.setNickname(userNickname);
};

Textual.nicknameMaybeWasDoubleClicked = function(e)
{
	if (Textual.nicknameDoubleClickTimer) {
		clearTimeout(Textual.nicknameDoubleClickTimer);

		Textual.nicknameDoubleClickTimer = null;

		Textual.nicknameDoubleClicked(e);
	} else {
		Textual.nicknameDoubleClickTimer = setTimeout(function() {
			Textual.nicknameDoubleClickTimer = null;

			Textual.nicknameSingleClicked(e);
		}, 250);
	}
};

Textual.nicknameSingleClicked = function(e)
{
	// API does not handle this action by default...
};

Textual.nicknameDoubleClicked = function(e)
{
	Textual.openStandardNicknameContextualMenu();

	app.nicknameDoubleClicked();
};

Textual.channelNameDoubleClicked = function()
{
	Textual.openChannelNameContextualMenu();

	app.channelNameDoubleClicked();
};

Textual.inlineNicknameDoubleClicked = function()
{
	Textual.openInlineNicknameContextualMenu();

	app.nicknameDoubleClicked();
};

Textual.topicDoubleClicked = function()
{
	app.topicDoubleClicked();
};

Textual.hasLiveResize = function()
{
	if (typeof InlineImageLiveResize !== 'undefined') {
		return true;
	} else {
		return false;
	}
};

Textual.toggleInlineImage = function(object, onlyPerformForShiftKey)
{
	/* We only want certain actions to happen for shift key. */
	if (onlyPerformForShiftKey) {
		if (window.event.shiftKey === false) {
			return true;
		}
	}

	/* toggleInlineImage() is called when an onclick event is thrown on the associated
	link anchor of an inline image. If the last mouse down event was related to a resize,
	then we return false to stop link from opening. Else, we pass the event information
	to the internals of Textual itself to determine whether to cancel the request. */

	if (Textual.hasLiveResize()) {
		if (InlineImageLiveResize.previousMouseActionWasForResizing === false) {
			app.toggleInlineImage(object);
		}
	} else {
		app.toggleInlineImage(object);
	}

	return false;
};

Textual.didToggleInlineImageToHidden = function(imageElement)
{
	/* Do something here? */
};

Textual.didToggleInlineImageToVisible = function(imageElement)
{
	/* Start monitoring events for this image. */
	if (Textual.hasLiveResize()) {
		var realImageElement = imageElement.querySelector("a .image");

		realImageElement.addEventListener("mousedown", InlineImageLiveResize.onMouseDown, false);
	}
};
