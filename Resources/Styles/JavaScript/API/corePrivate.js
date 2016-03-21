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

/* Internal state */
Textual.nicknameDoubleClickTimer = null;

/* Loading screen */
Textual.loadingScreenElement = function()
{
	return document.getElementById("loading_screen");
};

Textual.fadeInLoadingScreen = function(bodyOp, topicOp)
{
	Textual.fadeOutLoadingScreen(bodyOp, topicOp);
};

Textual.fadeOutLoadingScreen = function(bodyOp, topicOp)
{
	var documentBody = Textual.documentBodyElement();

	var topicBar = Textual.topicBarElement();

	var loadingScreen = Textual.loadingScreenElement();

	/* Modify the opacity values of the various elements */
	loadingScreen.style.opacity = 0.00;

	documentBody.style.opacity = bodyOp;

	if (topicBar !== null) {
		topicBar.style.opacity = topicOp;
	}

	/* The fade time for the loading screen depends on the CSS of the actual
	style, but there is no reason it should take more than five (5) seconds.
	We will wait that amount of time before setting the overlay to hidden.
	Setting it to hidden makes it not copiable after it is not visible. */
	setTimeout(function() {
		var loadingScreen = Textual.loadingScreenElement();

		loadingScreen.style.display = "none";
	}, 5000);
};

/* Topic bar */
Textual.topicBarElement = function()
{
	return document.getElementById("topic_bar");
};

Textual.topicBarValue = function(asText)
{
	var topicBar = Textual.topicBarElement();

	if (topicBar) {
		if (typeof asText === 'undefined' || asText === true) {
			return topicBar.textContent;
		} else {
			return topicBar.innerHTML;
		}
	} else {
		return null;
	}
};

Textual.setTopicBarValue = function(topicValue, topicValueHTML)
{
	var topicBar = Textual.topicBarElement();

	if (topicBar) {
		topicBar.innerHTML = topicValueHTML;

		Textual.topicBarValueChanged(topicValue);

		return true;
	} else {
		return false;
	}
};

Textual.topicBarDoubleClicked = function()
{
	app.topicBarDoubleClicked();
};

/* Scrolling */
Textual.scrollToBottomOfView = function(fireNotification)
{
	var documentBody = Textual.documentBodyElement();

	if (documentBody === null) {
		return;
	}

	var lastChild = documentBody.lastChild;

	if (typeof lastChild.scrollIntoView === "function") {
		lastChild.scrollIntoView(false);

		if (typeof fireNotification === 'undefined' || fireNotification === true) {
			Textual.viewPositionMovedToBottom();
		}
	}
};

Textual.scrollToTopOfView = function(fireNotification)
{
	var documentBody = Textual.documentBodyElement();

	if (documentBody === null) {
		return;
	}

	var firstChild = documentBody.firstChild;

	if (typeof firstChild.scrollIntoView === "function") {
		firstChild.scrollIntoView(true);

		if (typeof fireNotification === 'undefined' || fireNotification === true) {
			Textual.viewPositionMovedToTop();
		}
	}
};

Textual.scrollToLine = function(lineNumber)
{
	if (Textual.scrollToElement("line-" + lineNumber)) {
		Textual.viewPositionMovedToLine(lineNumber);

		return true;
	} else {
		return false;
	}
};

Textual.scrollToElement = function(elementName)
{
	var element = document.getElementById(elementName);

	if (element) {
		element.scrollIntoViewIfNeeded(true);

		return true;
	} else {
		return false;
	}
};

/* History indicator */
Textual.scrollToHistoryIndicator = function()
{
	if (Textual.scrollToElement("mark")) {
		Textual.viewPositionModToHistoryIndicator();
	}
};

Textual.historyIndicatorAdd = function(templateHTML)
{
	Textual.historyIndicatorRemove();

	Textual.documentBodyAppend(templateHTML);

	Textual.historyIndicatorAddedToView();
};

Textual.historyIndicatorRemove = function()
{
	var e = document.getElementById("mark");

	if (e) {
		e.parentNode.removeChild(e);

		Textual.historyIndicatorRemovedFromView();
	}
};

/* Document body */
Textual.documentBodyElement = function()
{
	return document.getElementById("body_home");
};

Textual.documentBodyAppend = function(templateHTML)
{
	var documentBody = Textual.documentBodyElement();

	documentBody.insertAdjacentHTML("beforeend", templateHTML);
};

Textual.documentBodyAppendHistoric = function(templateHTML, isReload)
{
	var documentBody = Textual.documentBodyElement();

	var elementToAppendTo = null;

	if (isReload == false) {
		var historicMessagesDiv = document.getElementById("historic_messages");

		if (historicMessagesDiv) {
			elementToAppendTo = historicMessagesDiv;
		}
	}

	if (elementToAppendTo === null) {
		elementToAppendTo = documentBody;
	}

	elementToAppendTo.insertAdjacentHTML("afterbegin", templateHTML);
};

Textual.documentHTML = function()
{
	return document.documentElement.innerHTML;
};

Textual.reduceNumberOfLines = function(countOfLinesToRemove)
{
	var documentBody = Textual.documentBodyElement();

	var childNodes = documentBody.childNodes;

	if (countOfLinesToRemove > childNodes.length) {
		countOfLinesToRemove = childNodes.length;
	}

	var removedChildren = [];

	for (var i = (countOfLinesToRemove - 1); i >= 0; i--) {
		var childNode = childNodes[i];

		var childNodeID = childNode.id;

		if (childNodeID && childNodeID.indexOf("line-") === 0) {
			removedChildren.push(childNodeID);

			documentBody.removeChild(childNode);
		}

		if (removedChildren.length == countOfLinesToRemove) {
			break;
		}
	}

	return removedChildren;
};

/* State management */
Textual.notifyDidBecomeVisible = function()
{
	TextualScroller.enableScrollingTimer();

	Textual.clearSelection();
};

Textual.notifyDidBecomeHidden = function()
{
	TextualScroller.disableScrollingTimer();

	Textual.clearSelection();
};

Textual.changeTextSizeMultiplier = function(sizeMultiplier)
{
	if (sizeMultiplier === 1.0) {
		document.body.style.fontSize = "";
	} else {
		document.body.style.fontSize = ((sizeMultiplier * 100.0) + "%");
	}
}

/* Events */
Textual.mouseUpEventCallback = function()
{
	Textual.copyOnSelectMouseUpEvent();
};

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

Textual.currentSelectionCoordinates = function()
{
	var currentSelection = window.getSelection();

	if (currentSelection.toString() === "") {
		return null;
	}

	var clientHeight = document.body.offsetHeight;

	var elementRect = currentSelection.getRangeAt(0).getBoundingClientRect();

	return {
		"x" : elementRect.left,
		"y" : (clientHeight - elementRect.bottom),
		"w" : elementRect.width,
		"h" : elementRect.height
	};
};

Textual.copyOnSelectMouseUpEvent = function()
{
	if (window.event.metaKey || window.event.altKey) {
		return;
	}

	var selectedText = Textual.currentSelection();

	if (selectedText && selectedText.length > 0) {
		app.copySelectionWhenPermitted(selectedText,
		   function(returnValue) {
				if (returnValue) {
					Textual.clearSelection();
				}
		   }
		);
	}
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

/* Contextual menu management */
Textual.openGenericContextualMenu = function()
{
	/* Do not block if target element already has a callback. */
	if (event.target.oncontextmenu !== null) {
		return;
	}

	if (appInternal.isWebKit2()) {
		event.preventDefault();

		app.displayContextMenu();
	}
};

Textual.openChannelNameContextualMenu = function()
{
	Textual.setPolicyChannelName();

	if (appInternal.isWebKit2()) {
		Textual.clearSelectionAndPreventDefault();

		app.displayContextMenu();
	}
};

Textual.openURLManagementContextualMenu = function()
{
	Textual.setPolicyURLAddress();

	if (appInternal.isWebKit2()) {
		Textual.clearSelectionAndPreventDefault();

		app.displayContextMenu();
	}
};

Textual.openStandardNicknameContextualMenu = function()
{
	Textual.setPolicyStandardNickname();

	if (appInternal.isWebKit2()) {
		Textual.clearSelectionAndPreventDefault();

		app.displayContextMenu();
	}
};

Textual.openInlineNicknameContextualMenu = function()
{
	Textual.setPolicyInlineNickname();

	if (appInternal.isWebKit2()) {
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

/* Inline images */
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
			Textual.toggleInlineImageReally(object);
		}
	} else {
		Textual.toggleInlineImageReally(object);
	}

	return false;
};

Textual.toggleInlineImageReally = function(object)
{
	if (object.indexOf("inlineImage-") !== 0) {
		object = ("inlineImage-" + object);
	}

	var imageNode = document.getElementById(object);

	if (imageNode.style.display === "none") {
		imageNode.style.display = "";
	} else {
		imageNode.style.display = "none";
	}

	if (imageNode.style.display === "none") {
		Textual.didToggleInlineImageToHidden(imageNode);
	} else {
		Textual.didToggleInlineImageToVisible(imageNode);
	}
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

document.addEventListener("contextmenu", Textual.openGenericContextualMenu, false);

document.addEventListener("mouseup", Textual.mouseUpEventCallback, false);
