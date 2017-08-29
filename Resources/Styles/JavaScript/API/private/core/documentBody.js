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

Textual.documentBodyElementReference = null;
Textual.messageBufferPastElementReference = null;
Textual.messageBufferElementReference = null;
Textual.topicBarElementReference = null;
Textual.historicMessagesElementReference = null;

/* The number of elements in the past buffer. 
This count only includes lines (messages). Not other
items that the style may insert into the buffer. */
Textual.messageBufferPastCurrentCount = 0;

/* The number of elements in the main buffer. 
This count only includes lines (messages). Not other
items that the style may insert into the buffer. */
Textual.messageBufferCurrentCount = 0;

/* When old messages are NOT being loaded, this 
is the number of elements we want to keep. */
Textual.messageBufferPastCountSoftLimit = 500;

/* When old messages are being loaded, this 
is the number of elements we want to keep. */
Textual.messageBufferPastCountHardLimit = 3000;

/* The number of elements to keep in the main buffer. */
Textual.messageBufferMaximumCount = 500;

/* The number of lines to fetch when loading old messages.
When old lines are fetched, the number of lines returned 
are also removed from the relevant buffer. */
Textual.messageBufferLoadMessagesBatchSize = 500;

/* Line numbers */
Textual.lineNumberStandardize = function(lineNumber)
{
	if (lineNumber.indexOf("line-") !== 0) {
		lineNumber = ("line-" + lineNumber);
	}
	
	return lineNumber;
};

Textual.lineNumberContents = function(lineNumber)
{
	if (lineNumber.indexOf("line-") !== 0) {
		return lineNumber;
	}
	
	return lineNumber.substr(5);
};

/* Loading screen */
Textual.loadingScreenElement = function()
{
	return document.getElementById("loading_screen");
};

Textual.fadeInLoadingScreen = function(bodyOp, topicOp)
{
	console.warn("Deprecated function. Use Textual.fadeOutLoadingScreen() instead.");

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
	if (Textual.topicBarElementReference === null) {
		Textual.topicBarElementReference = document.getElementById("topic_bar");
	}

	return Textual.topicBarElementReference;
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

Textual.setTopicBarVisible = function(isVisible)
{
	var topicBar = Textual.topicBarElement();

	if (topicBar) {
		if (isVisible) {
			topicBar.style.display = "";
		} else {
			topicBar.style.display = "none";
		}
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
	if (Textual.documentBodyElementReference === null) {
		Textual.documentBodyElementReference = document.getElementById("body_home");
	}
	
	return Textual.documentBodyElementReference;
};

Textual.setDocumentBodyPointerEventsEnabled = function(enablePointerEvents)
{
	var documentBody = Textual.documentBodyElement();

	if (documentBody) {
		if (enablePointerEvents) {
			documentBody.style.pointerEvents = "";
		} else {
			documentBody.style.pointerEvents = "none";
		}
	}
};

Textual.documentHTML = function()
{
	return document.documentElement.innerHTML;
};

/* Current message buffer */
Textual.messageBufferElement = function()
{
	if (Textual.messageBufferElementReference === null) {
		Textual.messageBufferElementReference = document.getElementById("message_buffer");
	}
	
	return Textual.messageBufferElementReference;
};

Textual.messageBufferElementAppend = function(templateHTML)
{
	var messageBuffer = Textual.messageBufferElement();

	messageBuffer.insertAdjacentHTML("beforeend", templateHTML);
	
	if (Textual.messageBufferCurrentCount < Textual.messageBufferMaximumCount) {
		Textual.messageBufferCurrentCount += 1;
	} else {
		Textual.messageBufferPastShiftInMessage();
	}
};

/* Past message buffer */
Textual.messageBufferPastElement = function()
{
	if (Textual.messageBufferPastElementReference === null) {
		Textual.messageBufferPastElementReference = document.getElementById("message_buffer_past");
	}
	
	return Textual.messageBufferPastElementReference;
};

Textual.messageBufferPastShiftInMessage = function()
{
	var messageBuffer = Textual.messageBufferElement();
	var messageBufferPast = Textual.messageBufferPastElement();

	/* If the given child is a reference to an existing node in the 
	document, appendChild() moves it from its current position to the 
	new position (there is no requirement to remove the node from its 
	parent node before appending it to some other node). */
	/* firstChild might not be a message. It could be a mark or other
	style defined container. It doesn't really matter. Just shift
	whatever to the post buffer. */
	messageBufferPast.appendChild(messageBuffer.firstChild);
	
	Textual.messageBufferPastCurrentCount += 1;

	if (Textual.messageBufferCurrentCount > Textual.messageBufferPastCountSoftLimit) {
		messageBufferPast.removeChild(messageBufferPast.firstChild);
	}
};

/* This function picks the best line to load old messages next to. */
/* When user is scrolling upwards, messages are removed from the
bottom of the past buffer, and new messages are added to the top
of it. Therefore, when after == false, we use the first child 
as the line we want to append to. */
/* The opposite happens when the user is scrolling downward. 
We remove from the top and add to the bottom which means we
use the last child. */
Textual.messageBufferLoadMessages = function(after)
{
	var line = null;

	/* We first look at the past buffer because the 
	oldest messages are in that container. */
	var messageBufferPast = Textual.messageBufferPastElement();
	
	if (after === false) {
		line = messageBufferPast.firstChild;
	} else {
		line = messageBufferPast.lastChild;
	}
	
	/* If no line was retrieved from the past buffer, then we
	get one from the main buffer. We check both buffers because
	when we populate messages on launch, we only populate so
	much, but this gives user the option to reveal more. */
	if (line === null) {
		/* It does not make sense to add after if we have no
		message in the past buffer. */
		if (after) {
			return;
		}
		
		/* Retrieve the first line of the main buffer. */
		var messageBuffer = Textual.messageBufferElement();

		line = messageBuffer.firstChild;
	}
	
	/* There is nothing in either buffer. */
	if (line === null) {
		return;	
	}
	
	/* Load messages */
	Textual.messageBufferLoadMessagesWithLine(after, line);
};

/* Given a line we want to load old messages next to, we do so. */
Textual.messageBufferLoadMessagesWithLine = function(after, line)
{
	/* Define logic that will be performed when 
	are are ready to load the messages. */
	var loadMessagesLogic = (function() {
		var postflightCallback = (function(renderedMessages) {
			Textual.messageBufferLoadMessagesPostflight(after, line, renderedMessages);
		});

		var lineNumber = Textual.lineNumberContents(line.id);

		if (after === false) {
			app.renderMessagesBefore(lineNumber, Textual.messageBufferLoadMessagesBatchSize, postflightCallback);
		} else {
			app.renderMessagesAfter(lineNumber, Textual.messageBufferLoadMessagesBatchSize, postflightCallback);
		}
	});
	
	/* Present loading indicator then trigger logic. */
	Textual.addMessageBufferLoadingIndicator(after, line, loadMessagesLogic);
};

/* Postflight for loading old messages */
Textual.messageBufferLoadMessagesPostflight = function(after, line, renderedMessages)
{
	console.log(renderedMessages);
	
	/* Hide loading indicator */
	Textual.removeMessageBufferLoadingIndicator(line);
};

/* Message buffer loading indicator */
Textual.addMessageBufferLoadingIndicator = function(after, toLine, callbackFunction)
{
	app.renderTemplate(
		"messageBufferLoadingIndicator", 

		{
			"lineNumber" : Textual.lineNumberContents(toLine.id)
		},
		
		(function (html) {
			if (after === false) {
				toLine.insertAdjacentHTML('beforebegin', html);
			} else {
				toLine.insertAdjacentHTML('afterend', html);
			}
			
			callbackFunction();
		})
	);
};

Textual.removeMessageBufferLoadingIndicator = function(fromLine)
{
	var lineNumber = Textual.lineNumberContents(fromLine.id);

	var loadingIndicator = document.getElementById("mb_loading-" + lineNumber);
	
	if (loadingIndicator) {
		loadingIndicator.remove();
	}
};

/* History */
Textual.historicMessagesElement = function()
{
	if (Textual.historicMessagesElementReference === null) {
		Textual.historicMessagesElementReference = document.getElementById("historic_messages");
	}
	
	return Textual.historicMessagesElementReference;
}

Textual.documentBodyAppendHistoric = function(templateHTML, isReload)
{
	var documentBody = Textual.documentBodyElement();

	var elementToAppendTo = null;

	var historicMessagesDiv = Textual.historicMessagesElement();

	if (historicMessagesDiv) {
		elementToAppendTo = historicMessagesDiv;
	}

	if (elementToAppendTo === null) {
		elementToAppendTo = documentBody;
	}

	elementToAppendTo.insertAdjacentHTML("afterbegin", templateHTML);

	TextualScroller.adjustScrollerPosition = true;
};

Textual.setHistoricMessagesLoaded = function(isLoaded)
{
	var historicMessages = Textual.historicMessagesElement();

	if (historicMessages) {
		if (isLoaded) {
			historicMessages.classList.add("loaded");
		} else {
			historicMessages.classList.remove("loaded");
		}
	}
};

Textual.setHistoricMessagesTransitionEnabled = function(enableTransition)
{
	var historicMessages = Textual.historicMessagesElement();

	if (historicMessages) {
		if (enableTransition) {
			historicMessages.classList.remove("notransition");
		} else {
			historicMessages.classList.add("notransition");
		}
	}
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
