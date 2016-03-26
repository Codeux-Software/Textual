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

/* Loading screen */
Textual.loadingScreenElement = function()
{
	return document.getElementById("loading_screen");
};

Textual.fadeInLoadingScreen = function(bodyOp, topicOp)
{
	console.error("Deprecated function. Use Textual.fadeOutLoadingScreen() instead.");

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

/* History indicator */
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

/* Text */
Textual.changeTextSizeMultiplier = function(sizeMultiplier)
{
	if (sizeMultiplier === 1.0) {
		document.body.style.fontSize = "";
	} else {
		document.body.style.fontSize = ((sizeMultiplier * 100.0) + "%");
	}
}
