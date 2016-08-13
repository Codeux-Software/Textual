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

/* Internal state */
Textual.nicknameDoubleClickTimer = null;

/* Selection */
Textual.clearSelection = function()
{
	window.getSelection().empty();
};

Textual.clearSelectionAndPreventDefault = function()
{
	Textual.clearSelection();

	event.preventDefault();
};

Textual.currentSelection = function()
{
	return window.getSelection().toString();
};

Textual.recordSelection = function()
{
	var selectedText = Textual.currentSelection();

	app.setSelection(selectedText);
};

Textual.selectionChangedCallback = function()
{
	Textual.recordSelection();
};

Textual.copySelectionOnMouseUpEvent = function()
{
	if (window.event.metaKey || window.event.altKey) {
		return;
	}

	app.copySelectionWhenPermitted(
	   function(returnValue) {
			if (returnValue) {
				Textual.clearSelection();
			}
	   }
	);
};

/* Contextual menu management */
Textual.usesCustomMenuConstructor = function()
{
	if (appInternal.isWebKit2() === false) {
		return false;
	}
	
	/* macOS Sierra has an Objective-C API to modify the menus in 
	WebKit2 which isn't too difficult to use which means we only
	need a custom menu constructor on WebKit2 + OS X El Capitan. */
	if (document.documentElement.getAttribute("systemversion").indexOf("10.11.") === 0) {
		return true;
	} else {
		return false;
	}
};

Textual.openGenericContextualMenu = function()
{
	/* Do not block if target element already has a callback. */
	if (event.target.oncontextmenu !== null) {
		return;
	}

	if (Textual.usesCustomMenuConstructor()) {
		event.preventDefault();
		
		Textual.recordSelection();

		app.displayContextMenu();
	}
};

Textual.openChannelNameContextualMenu = function()
{
	Textual.setPolicyChannelName();

	if (Textual.usesCustomMenuConstructor()) {
		Textual.clearSelectionAndPreventDefault();

		app.displayContextMenu();
	}
};

Textual.openURLManagementContextualMenu = function()
{
	Textual.setPolicyURLAddress();

	if (Textual.usesCustomMenuConstructor()) {
		Textual.clearSelectionAndPreventDefault();

		app.displayContextMenu();
	}
};

Textual.openStandardNicknameContextualMenu = function()
{
	Textual.setPolicyStandardNickname();

	if (Textual.usesCustomMenuConstructor()) {
		Textual.clearSelectionAndPreventDefault();

		app.displayContextMenu();
	}
};

Textual.openInlineNicknameContextualMenu = function()
{
	Textual.setPolicyInlineNickname();

	if (Textual.usesCustomMenuConstructor()) {
		Textual.clearSelectionAndPreventDefault();

		app.displayContextMenu();
	}
};

Textual.setPolicyStandardNickname = function()
{
	var userNickname = event.target.getAttribute("nickname");

	app.setNickname(userNickname);
};

Textual.setPolicyInlineNickname = function()
{
	var userNickname = event.target.textContent;

	var userMode = event.target.getAttribute("mode");

	if (userMode && userMode.length > 0 && userNickname.indexOf(userMode) === 0) {
		app.setNickname(userNickname.substring(1));
	} else {
		app.setNickname(userNickname);
	}
};

Textual.setPolicyURLAddress = function()
{
	app.setURLAddress(event.target.getAttribute("href"));
};

Textual.setPolicyChannelName = function()
{
	app.setChannelName(event.target.textContent);
};

/* Double click actions */
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

Textual.channelNameDoubleClicked = function()
{
	Textual.clearSelectionAndPreventDefault();

	Textual.setPolicyChannelName();

	app.channelNameDoubleClicked();
};

Textual.nicknameDoubleClicked = function()
{
	Textual.clearSelectionAndPreventDefault();

	Textual.setPolicyStandardNickname();

	app.nicknameDoubleClicked();
};

Textual.inlineNicknameDoubleClicked = function()
{
	Textual.clearSelectionAndPreventDefault();

	Textual.setPolicyInlineNickname();

	app.nicknameDoubleClicked();
};

/* Bind to events */
document.addEventListener("contextmenu", Textual.openGenericContextualMenu, false);

document.addEventListener("selectionchange", Textual.selectionChangedCallback, false);
