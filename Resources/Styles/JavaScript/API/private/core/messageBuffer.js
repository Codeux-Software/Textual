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

var MessageBuffer = {};

/* ************************************************** */
/*                   State Tracking                   */
/* ************************************************** */

/* The number of elements in the buffer. 
This count only includes lines (messages). Not other
items that the style may insert into the buffer. */
MessageBuffer.bufferCurrentSize = 0;

/* When old messages are NOT being loaded, this 
is the number of elements we want to keep. */
MessageBuffer.bufferSizeSoftLimitDefault = 200;
MessageBuffer.bufferSizeSoftLimit = MessageBuffer.bufferSizeSoftLimitDefault;

/* When old messages are being loaded, this 
is the number of elements we want to keep. */
MessageBuffer.bufferSizeHardLimitDefault = 1000;
MessageBuffer.bufferSizeHardLimit = MessageBuffer.bufferSizeHardLimitDefault;

/* The number of lines to fetch when loading old messages.
When old lines are fetched, the number of lines returned 
are also removed from the relevant buffer. */
MessageBuffer.loadMessagesBatchSize = 200;

/* MessageBuffer.loadMessages() sets the following properties
when it performs an action. These proeprties are not used for
anything other than state tracking. If false, new messages are
loaded, else the event is ignored. */
/* The user can scroll downward while messages are still being
loaded from scrolling upward. Therefore, we use a separate 
property to keep track of each type of load. */ 
MessageBuffer.loadingMessagesBeforeLineDuringScroll = false;
MessageBuffer.loadingMessagesAfterLineDuringScroll = false;

/* Set to true once we have loaded all old messages. */
MessageBuffer.bufferTopIsComplete = false;
MessageBuffer.bufferBottomIsComplete = true;

/* MessageBuffer.jumpToLine() sets the following property
when it performs an action. */
MessageBuffer.loadingMessagesDuringJump = false;

/* Cache */
MessageBuffer.automaticScrollingEnabled = true;

MessageBuffer.bufferElementReference = null;

/* ************************************************** */
/*                  Line Management                   */
/* ************************************************** */

MessageBuffer.firstLineInBuffer = function(buffer)
{
	/* Note: speed this up if we begin using this function more often. */
	return buffer.querySelector("div.line[id^='line-']:first-child");
};

MessageBuffer.lastLineInBuffer = function(buffer)
{
	return buffer.querySelector("div.line[id^='line-']:last-child");
};

/* ************************************************** */
/*                  Main Buffer                       */
/* ************************************************** */

MessageBuffer.bufferElement = function()
{
	if (MessageBuffer.bufferElementReference === null) {
		MessageBuffer.bufferElementReference = document.getElementById("message_buffer");
	}
	
	return MessageBuffer.bufferElementReference;
};

MessageBuffer.bufferElementPrepend = function(html, lineNumbers)
{
	MessageBuffer.bufferElementInsert("afterbegin", html, lineNumbers)
};

MessageBuffer.bufferElementAppend = function(html, lineNumbers)
{
	MessageBuffer.bufferElementInsert("beforeend", html, lineNumbers);
};
	
MessageBuffer.bufferElementInsert = function(placement, html, lineNumbers)
{
	/* Do not append to bottom if bottom does not reflect
	the most recent state of the buffer. */
	if (MessageBuffer.bufferBottomIsComplete === false) {
		return;
	}
	
	var buffer = MessageBuffer.bufferElement();

	buffer.insertAdjacentHTML(placement, html);
	
	if (lineNumbers) {
		MessageBuffer.bufferCurrentSize += lineNumbers.length;
	
		MessageBuffer.resizeBufferIfNeeded();
	
		Textual.messageAddedToViewInt(lineNumbers, false);
	}
};

/* ************************************************** */
/*               Buffer Size Management               */
/* ************************************************** */

/* Allow user to set a custom buffer limit */
MessageBuffer.setBufferLimit = function(limit)
{
	if (limit < 100 || limit > 50000) {
		MessageBuffer.bufferSizeSoftLimit = MessageBuffer.bufferSizeSoftLimitDefault;
		MessageBuffer.bufferSizeHardLimit = MessageBuffer.bufferSizeHardLimitDefault;
	} else {
		MessageBuffer.bufferSizeSoftLimitDefault = limit;
		MessageBuffer.bufferSizeHardLimitDefault = limit;
	}
};

/* Determine whether buffer should be resized depending on status. */
MessageBuffer.resizeBufferIfNeeded = function()
{
	/* We remove lines under the conditions:
	1. Size limit must be exceeded. 
	2. When user is not scrolled, we remove from the top of the buffer.
	3. When user is scrolled below 50% of the scrollable area, then we
	   remove from the bottom of the buffer.
	4. When user is scrolled above 50% of the scrollable area, then we
	   remove form the top of the buffer. */

	/* Enforce soft limit for #2 */
	if (MessageBuffer.scrolledToBottomOfBuffer()) {
		MessageBuffer.enforceSoftLimit(true);
		
		return;
	}

	/* Enforce hard limit for #3 and #4 */
	var scrollPercent = TextualScroller.percentScrolled();

	var removeFromTop = (scrollPercent > 50.0);
	
	MessageBuffer.enforceHardLimit(removeFromTop);
};

/* Given number of lines added: enforce limit and remove from top or bottom. */
MessageBuffer.enforceSoftLimit = function(fromTop)
{
	MessageBuffer.enforceLimit(MessageBuffer.bufferSizeSoftLimit, fromTop);
};

MessageBuffer.enforceHardLimit = function(fromTop)
{
	MessageBuffer.enforceLimit(MessageBuffer.bufferSizeHardLimit, fromTop);
};

MessageBuffer.enforceLimit = function(limit, fromTop)
{
	var numberToRemove = (MessageBuffer.bufferCurrentSize - limit);

	if (numberToRemove <= 0) {
		return;	
	}

	MessageBuffer.resizeBuffer(numberToRemove, fromTop);
};

MessageBuffer.resizeBuffer = function(numberToRemove, fromTop)
{
	if (numberToRemove <= 0) {
		console.error("Silly number to remove");

		return;
	}
	
	var lineNumbers = new Array();

	var buffer = MessageBuffer.bufferElement();

	var numberRemoved = 0;

	/* To avoid an infinite loop by never having a 
	firstChild or lastChild that is a line, we use
	siblings and break when there are none left. */
	var currentElement = null;
	var nextElement = null;

	do {
		if (currentElement === null) {
			if (fromTop) {
				currentElement = buffer.firstChild;
			} else {
				currentElement = buffer.lastChild;
			}
		} else {
			currentElement = nextElement;
		}
		
		if (currentElement === null) {
			break;
		}

		if (fromTop) {
			nextElement = currentElement.nextElementSibling;
		} else {
			nextElement = currentElement.previousElementSibling;
		}

		var elementId = currentElement.id;
		
		if (elementId && elementId.indexOf("line-") === 0) {
			/* We wait until the next line element before 
			exiting loop so that we can remove markers or
			anything related to lines that were removed. */
			if (numberRemoved >= numberToRemove) {
				break;
			}

			lineNumbers.push(elementId);

			numberRemoved += 1;
		}
		
		currentElement.remove();
	} while (true); // lol, I know.
	
	if (fromTop) {
		MessageBuffer.bufferTopIsComplete = false;	
	} else {
		MessageBuffer.bufferBottomIsComplete = false;		
	}
	
	var lineNumbersCount = lineNumbers.length;

	if (lineNumbersCount > 0) {
		MessageBuffer.bufferCurrentSize -= lineNumbersCount;
	
		Textual.messageRemovedFromViewInt(lineNumbers);
	}

	console.log("Removed " + numberToRemove + " lines from buffer");
};

/* Timer set once user scrolls back to the bottom. */
/* Timer is used in case user scrolls back up shortly after. */
MessageBuffer.bufferHardLimitResizeTimer = null;

MessageBuffer.cancelHardLimitResize = function()
{
	if (MessageBuffer.bufferHardLimitResizeTimer === null) {
		return;
	}
	
	clearTimeout(MessageBuffer.bufferHardLimitResizeTimer);
	
	MessageBuffer.bufferHardLimitResizeTimer = null;
};

MessageBuffer.scheduleHardLimitResize = function()
{
	if (MessageBuffer.bufferHardLimitResizeTimer !== null) {
		return;
	}
	
	/* Do not create timer if we are scrolling programmatically */
	if (MessageBuffer.loadingMessagesDuringJump) {
		return;
	}

	/* No need to create timer if we haven't exceeded hard limit. */
	if (MessageBuffer.bufferCurrentSize <= MessageBuffer.bufferSizeSoftLimit) {
		return;
	}

	/* Do not create timer if we aren't at the true bottom. */
	if (MessageBuffer.scrolledToBottomOfBuffer() === false) {
		return;
	}
	
	/* Create timer */
	MessageBuffer.bufferHardLimitResizeTimer =
	setTimeout(function() {
		console.log("Buffer hard limit resize timer fired");
	
		var numberToRemove = (MessageBuffer.bufferCurrentSize - MessageBuffer.bufferSizeSoftLimit);
		
		if (numberToRemove <= 0) {
			return;
		}
		
		MessageBuffer.resizeBuffer(numberToRemove, true);
		
		MessageBuffer.bufferHardLimitResizeTimer = null;
	}, 5000);
	
	console.log("Buffer hard limit resize timer started");
};

/* ************************************************** */
/*                  Load Messages                     */
/* ************************************************** */

/* This function picks the best line to load old messages next to. */
MessageBuffer.loadMessagesDuringScroll = function(before)
{
	/* MessageBuffer.loadMessages() is only called during scroll events by
	the user. We keep track of a request is already active then so that we
	do not keep sending them out while the user waits for one to finish. */
	if (MessageBuffer.loadingMessagesDuringJump) {
		console.log("Cancelled request to load messages because another request is active");
		
		return;	
	}

	if (before) 
	{
		if (Textual.finishedLoadingHistory === false) {
			console.log("Cancelled request to load messages above line because history isn't loaded");
			
			return;
		}
		
		if (MessageBuffer.loadingMessagesBeforeLineDuringScroll) {
			console.log("Cancelled request to load messages above line because another request is active");
			
			return;
		}
		
		if (MessageBuffer.bufferTopIsComplete) {
			console.log("Cancelled request to load messages because there is nothing new to load");
			
			return;
		}
	} 
	else // before
	{
		if (MessageBuffer.loadingMessagesAfterLineDuringScroll) {
			console.log("Cancelled request to load messages below line because another request is active");
			
			return;
		}
		
		if (MessageBuffer.bufferBottomIsComplete) {
			console.log("Cancelled request to load messages because there is nothing new to load");
			
			return;
		}
	}

	/* Find first line */	
	var buffer = MessageBuffer.bufferElement();
	
	var line = null;
	
	if (before) {
		line = MessageBuffer.firstLineInBuffer(buffer);
	} else {
		line = MessageBuffer.lastLineInBuffer(buffer);
	}
	
	/* There is nothing in either buffer */
	if (line === null) {
		console.log("No line to load from");

		return;	
	}

	/* Load messages */
	if (before) {
		MessageBuffer.loadingMessagesBeforeLineDuringScroll = true;
	} else {
		MessageBuffer.loadingMessagesAfterLineDuringScroll = true;
	}

	var lineNumberContents = Textual.lineNumberContents(line.id);

	MessageBuffer.loadMessagesDuringScrollWithPayload(
		{
			"before" : before,
			"line" : line,
			"lineNumberContents" : lineNumberContents
		}	
	);
};

/* Given a line we want to load old messages next to, we do so. */
MessageBuffer.loadMessagesDuringScrollWithPayload = function(requestPayload)
{
	var before = requestPayload.before;
	var line = requestPayload.line;
	var lineNumberContents = requestPayload.lineNumberContents;

	/* Define logic that will be performed when 
	are are ready to load the messages. */
	var loadMessagesLogic = (function() {
		var postflightCallback = (function(renderedMessages) {
			requestPayload.renderedMessages = renderedMessages;

			MessageBuffer.loadMessagesDuringScrollWithPayloadPostflight(requestPayload);

			MessageBuffer.removeLoadingIndicator(line);
		});

		console.log("Loading messages before (" + before  + ") line " + lineNumberContents);
		
		if (before) {
			app.renderMessagesBefore(
				lineNumberContents, 
				MessageBuffer.loadMessagesBatchSize, 
				postflightCallback
			);
		} else {
			app.renderMessagesAfter(
				lineNumberContents, 
				MessageBuffer.loadMessagesBatchSize, 
				postflightCallback
			);
		}
	});
	
	/* Present loading indicator then trigger logic. */
	MessageBuffer.addLoadingIndicator(before, line, loadMessagesLogic);
};

/* Postflight for loading old messages */
MessageBuffer.loadMessagesDuringScrollWithPayloadPostflight = function(requestPayload)
{
	/* Payload state */
	var before = requestPayload.before;
	var line = requestPayload.line;
	var renderedMessages = requestPayload.renderedMessages;

	var lineNumbers = null;
	var html = null;

	/* Perform logging */
	var renderedMessagesCount = renderedMessages.length;

	console.log("Request to load messages for " + line.id + " returned " + renderedMessagesCount + " results");

	if (renderedMessagesCount > 0) {
		/* Array which will house every line number that was loaded. 
		The style needs this information so it can perform whatever action. */
		lineNumbers = new Array();
		
		/* Array which will house every segment of HTML to append. */
		html = new Array();
		
		/* Process result */
		for (var i = 0; i < renderedMessagesCount; i++) {
			var renderedMessage = renderedMessages[i];
			
			var lineNumber = renderedMessage.lineNumber;
			
			if (lineNumber) {
				lineNumbers.push(renderedMessage.lineNumber);
			}
			
			html.push(renderedMessage.html);
		}
		
		/* Appending HTML will cause the view to appear scrolled 
		for the user so we save the position for restore. */
		TextualScroller.saveRestorationFirstDataPoint();
		
		/* Append HTML */
		var htmlString = html.join("");

		if (before) {
			line.insertAdjacentHTML('beforebegin', htmlString);
		} else {
			line.insertAdjacentHTML('afterend', htmlString);
		}

		MessageBuffer.bufferCurrentSize += html.length;
	} // renderedMessagesCount > 0
	
	/* If the number of results is less than our batch size,
	then we can probably make a best guess that we have loaded
	all the old messages that are available. */
	if (renderedMessagesCount < MessageBuffer.loadMessagesBatchSize) {
		if (before) {
			MessageBuffer.bufferTopIsComplete = true;
		} else {
			MessageBuffer.bufferBottomIsComplete = true;
		}
	}
	
	if (renderedMessagesCount > 0) {
		/* Before we enforce size limit, we record the height with the appended
		HTML to allow scroller to learn proper amount to scroll. Without recording
		the height here, it wont change once we enforce size limit. */
		TextualScroller.saveRestorationSecondDataPoint();
		
		/* Enforce size limit. This function expects the count to already be 
		incremented which is why we call it AFTER the append. */
		/* Value of before is reversed because we want to remove from the
		opposite of where we added. */
		MessageBuffer.enforceHardLimit(!before);
		
		/* Restore scroll position */
		TextualScroller.restoreScrollPosition();
		
		/* Post line numbers so style can do something with them. */
		Textual.messageAddedToViewInt(lineNumbers, true);
	} // renderedMessagesCount > 0
	
	/* Toggle automatic scrolling */
	/* Call after resize so that it has latest state of bottom. */
	MessageBuffer.toggleAutomaticScrolling();

	/* Flush state */
	if (before) {
		MessageBuffer.loadingMessagesBeforeLineDuringScroll = false;
	} else {
		MessageBuffer.loadingMessagesAfterLineDuringScroll = false;
	}
};

MessageBuffer.loadMessagesWithJump = function(lineNumber, callbackFunction)
{
	/* Safety checks */
	if (MessageBuffer.loadingMessagesDuringJump) {
		console.log("Cancelled request to load messages because another request is active");
		
		return;	
	}

	if (Textual.finishedLoadingHistory === false) {
		console.log("Cancelled request to load messages because history isn't loaded");
		
		return;
	}
	
	if (MessageBuffer.loadingMessagesBeforeLineDuringScroll ||
		MessageBuffer.loadingMessagesAfterLineDuringScroll) 
	{
		console.log("Cancelled request to load messages because another request is active");
		
		return;
	}
	
	if (MessageBuffer.bufferTopIsComplete &&
		MessageBuffer.bufferBottomIsComplete) 
	{
		console.log("Cancelled request to load messages because there is nothing new to load");
		
		return;
	}
	
	/* This function may be called without scrolling which means we
	should cancel the resize timer. */
	MessageBuffer.cancelHardLimitResize();

	/* The line does not exist in the buffer, which means we have to 
	load it. When we load the message, we also load X number of messages
	above it and X number of messages below it. */
	/* When jumping, we do not use the message buffer loading indicator
	because the user does not require a visual indicator. */
	MessageBuffer.loadingMessagesDuringJump = true;

	var lineNumberContents = Textual.lineNumberContents(lineNumber);

	var requestPayload = {
		"lineNumberContents" : lineNumberContents,
		"lineNumberStandardized" : lineNumber,
		"callbackFunction" : callbackFunction
	};
	
	console.log("Loading line " + lineNumberContents);

	app.renderMessageWithSiblings(
		lineNumberContents,

		MessageBuffer.loadMessagesBatchSize, // load X above
		MessageBuffer.loadMessagesBatchSize, // laod X below

		(function(renderedMessages) {
			requestPayload.renderedMessages = renderedMessages;
			
			MessageBuffer.loadMessagesWithJumpPostflight(requestPayload);
		})
	);
};

MessageBuffer.loadMessagesWithJumpPostflight = function(requestPayload)
{
	/* Payload state */
	var callbackFunction = requestPayload.callbackFunction;
	var lineNumberContents = requestPayload.lineNumberContents;
	var lineNumberStandardized = requestPayload.lineNumberStandardized;
	var renderedMessages = requestPayload.renderedMessages;

	var lineNumbers = null;
	var html = null;

	/* Perform logging */
	var renderedMessagesCount = renderedMessages.length;

	console.log("Request to load messages for " + lineNumberContents + " returned " + renderedMessagesCount + " results");

	if (renderedMessagesCount > 0) {
		/* Array which will house every line number that was loaded. 
		The style needs this information so it can perform whatever action. */
		lineNumbers = new Array();
		
		/* Array which will house every segment of HTML to append. */
		html = new Array();
		
		/* Process result */
		for (var i = 0; i < renderedMessagesCount; i++) {
			var renderedMessage = renderedMessages[i];
			
			var lineNumber = renderedMessage.lineNumber;
			
			if (lineNumber) {
				lineNumbers.push(renderedMessage.lineNumber);
			}
			
			html.push(renderedMessage.html);
		}
	
		/* When we jump to a line that is not visible, we replace 
		the entire buffer with the rendered messages. This avoids 
		the hassle of having to navigate the DOM merging lines. 
		This may change in the future based on user feedback,
		but for now this is acceptable. */

		/* Append HTML */
		var htmlString = html.join("");
		
		var buffer = MessageBuffer.bufferElement();

		buffer.insertAdjacentHTML('afterbegin', htmlString);

		/* Resize the buffer by removing messages from the bottom
		so that the only lines that remain are those appended. */
		MessageBuffer.resizeBuffer(MessageBuffer.bufferCurrentSize, false);
		
		/* Update buffer size to include appended lines. */
		MessageBuffer.bufferCurrentSize += html.length;
		
		/* Post line numbers so style can do something with them. */
		Textual.messageAddedToViewInt(lineNumbers, true);

		/* Toggle automatic scrolling */
		/* Call after resize so that it has latest state of bottom. */
		MessageBuffer.toggleAutomaticScrolling();
	} // renderedMessagesCount > 0

	/* Try jumping to line and inform callback of result. */
	callbackFunction( 
		Textual.scrollToElement(lineNumberStandardized) 
	);

	/* Flush state */
	MessageBuffer.loadingMessagesDuringJump = false;
};

/* ************************************************** */
/*                Loading Indicator                   */
/* ************************************************** */

MessageBuffer.addLoadingIndicator = function(before, toLine, callbackFunction)
{
	callbackFunction();

/* The loading indicator was disabled after it was made because it served no
purpose when the buffer logic was created. Buffer loads fast enough. 
The loader indicator would flash on the screen for less a second. 
The code for it is kept around incase it can be repurposed in the future. */
/*
	app.renderTemplate(
		"messageBufferLoadingIndicator", 

		{
			"lineNumber" : Textual.lineNumberContents(toLine.id)
		},
		
		(function (html) {
			if (before) {
				toLine.insertAdjacentHTML('beforebegin', html);
			} else {
				toLine.insertAdjacentHTML('afterend', html);
			}
			
			callbackFunction();
		})
	);
*/
};

MessageBuffer.removeLoadingIndicator = function(fromLine)
{
/*
	var lineNumber = Textual.lineNumberContents(fromLine.id);

	var loadingIndicator = document.getElementById("mb_loading-" + lineNumber);
	
	if (loadingIndicator) {
		loadingIndicator.remove();
	}
*/
};

/* ************************************************** */
/*                  Scrolling                         */
/* ************************************************** */

/* Scrolling */
MessageBuffer.documentScrolledCallback = function(scrolledUpward)
{
	if (scrolledUpward) {
		if (TextualScroller.isScrolledToTop()) {
			MessageBuffer.loadMessagesDuringScroll(true);
		}
		
		MessageBuffer.cancelHardLimitResize();
	}
	
	if (scrolledUpward === false && TextualScroller.isScrolledToBottom()) {
		MessageBuffer.loadMessagesDuringScroll(false);

		MessageBuffer.scheduleHardLimitResize();
	}
};

MessageBuffer.toggleAutomaticScrollingOn = function(turnOn)
{
	if (MessageBuffer.automaticScrollingEnabled !== turnOn) {
		MessageBuffer.automaticScrollingEnabled = turnOn;
	} else {
		return;
	}
	
	if (turnOn) {
		app.setAutomaticScrollingEnabled(true);
	} else {
		app.setAutomaticScrollingEnabled(false);
	}
};
	
MessageBuffer.toggleAutomaticScrolling = function()
{
	MessageBuffer.toggleAutomaticScrollingOn(
		MessageBuffer.bufferBottomIsComplete
	);
};

MessageBuffer.scrolledToBottomOfBuffer = function()
{
	return (TextualScroller.scrolledAboveBottom === false);
};

MessageBuffer.jumpToLine = function(lineNumber, callbackFunction)
{
	var lineNumberStandardized = Textual.lineNumberStandardize(lineNumber);
	
	if (Textual.scrollToElement(lineNumberStandardized)) {
		callbackFunction(true);
		
		return;
	}
	
	MessageBuffer.loadMessagesWithJump(lineNumberStandardized, callbackFunction);
};
