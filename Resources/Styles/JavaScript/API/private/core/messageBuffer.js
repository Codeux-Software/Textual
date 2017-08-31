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

/* The number of elements in the replay buffer. 
This count only includes lines (messages). Not other
items that the style may insert into the buffer. */
MessageBuffer.replayBufferCurrentCount = 0;

/* The number of elements in the main buffer. 
This count only includes lines (messages). Not other
items that the style may insert into the buffer. */
MessageBuffer.mainBufferCurrentCount = 0;

/* When old messages are NOT being loaded, this 
is the number of elements we want to keep. */
MessageBuffer.replayBufferSoftLimit = 200;

/* When old messages are being loaded, this 
is the number of elements we want to keep. */
MessageBuffer.replayBufferHardLimit = 600;

/* The number of elements to keep in the main buffer. */
MessageBuffer.mainBufferMaximumCount = 100;

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
MessageBuffer.loadingMessagesBeforeLine = false;
MessageBuffer.loadingMessagesAfterLine = false;

/* Set to true once we have loaded all old messages. */
MessageBuffer.replayBufferTopIsComplete = false;

/* Set to false when messages have been removed from the 
bottom of the replay buffer. When false, the main buffer 
is also set to hidden so that when the user scrolls down,
the bottom is that of the replay buffer, making it replay
removed messages until all are restored. */
MessageBuffer.replayBufferBottomIsComplete = true;

/* Cache */
MessageBuffer.mainBufferElementReference = null;
MessageBuffer.replayBufferElementReference = null;

/* ************************************************** */
/*                  Line Management                   */
/* ************************************************** */

MessageBuffer.lineNumberStandardize = function(lineNumber)
{
	if (lineNumber.indexOf("line-") !== 0) {
		lineNumber = ("line-" + lineNumber);
	}
	
	return lineNumber;
};

MessageBuffer.lineNumberContents = function(lineNumber)
{
	if (lineNumber.indexOf("line-") !== 0) {
		return lineNumber;
	}
	
	return lineNumber.substr(5);
};

MessageBuffer.firstLineInBuffer = function(buffer)
{
	/* Note: speed this up if we begin using this function more often. */
	return buffer.querySelector("*[id^='line-']:first-child");
};

MessageBuffer.lastLineInBuffer = function(buffer)
{
	return buffer.querySelector("*[id^='line-']:last-child");
};

/* ************************************************** */
/*                  Main Buffer                       */
/* ************************************************** */

MessageBuffer.mainBufferElement = function()
{
	if (MessageBuffer.mainBufferElementReference === null) {
		MessageBuffer.mainBufferElementReference = document.getElementById("main_message_buffer");
	}
	
	return MessageBuffer.mainBufferElementReference;
};

MessageBuffer.mainBufferElementAppend = function(templateHTML)
{
	var mainBuffer = MessageBuffer.mainBufferElement();

	mainBuffer.insertAdjacentHTML("beforeend", templateHTML);
	
	if (MessageBuffer.mainBufferCurrentCount < MessageBuffer.mainBufferMaximumCount) {
		MessageBuffer.mainBufferCurrentCount += 1;
	} else {
		MessageBuffer.shiftMessageIntoReplayBuffer();
	}
};

MessageBuffer.mainBufferToggleVisiblity = function()
{
	var mainBuffer = MessageBuffer.mainBufferElement();
	
	if (MessageBuffer.replayBufferBottomIsComplete) {
		if (mainBuffer.style.display === "none") {
			mainBuffer.style.display = "";

			app.setAutomaticScrollingEnabled(true);
		}
	} else {
		if (mainBuffer.style.display !== "none") {
			mainBuffer.style.display = "none";

			app.setAutomaticScrollingEnabled(false);
		}
	}
};

MessageBuffer.mainBufferIsVisible = function()
{
	var mainBuffer = MessageBuffer.mainBufferElement();
	
	return (mainBuffer.style.display !== "none");
};

/* ************************************************** */
/*                  Replay Buffer                     */
/* ************************************************** */

MessageBuffer.replayBufferElement = function()
{
	if (MessageBuffer.replayBufferElementReference === null) {
		MessageBuffer.replayBufferElementReference = document.getElementById("replay_message_buffer");
	}
	
	return MessageBuffer.replayBufferElementReference;
};

MessageBuffer.shiftMessageIntoReplayBuffer = function()
{
	var mainBuffer = MessageBuffer.mainBufferElement();
	var replayBuffer = MessageBuffer.replayBufferElement();

	/* If the given child is a reference to an existing node in the 
	document, appendChild() moves it from its current position to the 
	new position (there is no requirement to remove the node from its 
	parent node before appending it to some other node). */
	/* firstChild might not be a message. It could be a mark or other
	style defined container. It doesn't really matter. Just shift
	whatever to the post buffer. */
	replayBuffer.appendChild(mainBuffer.firstChild);
	
	MessageBuffer.replayBufferCurrentCount += 1;

	MessageBuffer.replayBufferCalculateResize(1);
};

/* ************************************************** */
/*         Replay Buffer Size Management              */
/* ************************************************** */

/* Determine whether buffer should be resized depending on status. */
MessageBuffer.replayBufferCalculateResize = function(numberAdded)
{
	/* When we add new lines, we begin to remove some from the replay 
	buffer under specific conditions:
	1. Size limit must be exceeded. 
	2. When user is not scrolled, we remove from the top of the buffer.
	3. When user is scrolled below 50% of the scrollable area, then we
	   remove from the bottom of the buffer.
	4. When user is scrolled above 50% of the scrollable area, then we
	   remove form the top of the buffer. */

	/* Enforce soft limit for #2 */
	if (MessageBuffer.scrolledToBottomOfMainBuffer()) {
		MessageBuffer.replayBufferEnforceSoftLimit(numberAdded, true);
		
		return;
	}

	/* Enforce hard limit for #3 and #4 */
	var scrollPercent = TextualScroller.percentScrolled();

	var removeFromTop = (scrollPercent > 50.0);
	
	MessageBuffer.replayBufferEnforceHardLimit(numberAdded, removeFromTop);
};

/* Given number of lines added: enforce limit and remove from top or bottom. */
MessageBuffer.replayBufferEnforceSoftLimit = function(numberAdded, fromTop)
{
	MessageBuffer.replayBufferEnforceLimit(numberAdded, MessageBuffer.replayBufferSoftLimit, fromTop);
};

MessageBuffer.replayBufferEnforceHardLimit = function(numberAdded, fromTop)
{
	MessageBuffer.replayBufferEnforceLimit(numberAdded, MessageBuffer.replayBufferHardLimit, fromTop);
};

MessageBuffer.replayBufferEnforceLimit = function(numberAdded, limit, fromTop)
{
	if (MessageBuffer.replayBufferCurrentCount <= limit) {
		return;	
	}
	
	MessageBuffer.replayBufferPerformResize(numberAdded, fromTop);
};

MessageBuffer.replayBufferPerformResize = function(numberToRemove, fromTop)
{
	if (numberToRemove <= 0) {
		console.error("Silly number to remove");

		return;
	}

	var replayBuffer = MessageBuffer.replayBufferElement();

	var numberRemoved = 0;
	
	do {
		if (fromTop) {
			var element = replayBuffer.firstChild;
		} else {
			var element = replayBuffer.lastChild;
		}
		
		element.remove();

		if (element.id && element.id.indexOf("line-") === 0) {
			numberRemoved += 1;
		}
	} while (numberRemoved < numberToRemove);
	
	if (fromTop) {
		MessageBuffer.replayBufferTopIsComplete = false;	
	} else {
		MessageBuffer.replayBufferBottomIsComplete = false;		
	}
	
	MessageBuffer.replayBufferCurrentCount -= numberToRemove;
	
	console.log("Removed " + numberToRemove + " lines from replay buffer");
};

/* Timer set once user scrolls back to the bottom. */
/* Timer is used in case user scrolls back up shortly after. */
MessageBuffer.replayBufferHardLimitResizeTimer = null;

MessageBuffer.replayBufferCancelHardLimitResize = function()
{
	if (MessageBuffer.replayBufferHardLimitResizeTimer === null) {
		return;
	}
	
	clearTimeout(MessageBuffer.replayBufferHardLimitResizeTimer);
	
	MessageBuffer.replayBufferHardLimitResizeTimer = null;
};

MessageBuffer.replayBufferScheduleHardLimitResize = function()
{
	if (MessageBuffer.replayBufferHardLimitResizeTimer !== null) {
		return;
	}
	
	/* No need to create timer if we haven't exceeded hard limit. */
	if (MessageBuffer.replayBufferCurrentCount <= MessageBuffer.replayBufferSoftLimit) {
		return;
	}

	/* Do not create timer if we aren't at the true bottom. */
	if (MessageBuffer.scrolledToBottomOfMainBuffer() === false) {
		return;
	}
	
	/* Create timer */
	MessageBuffer.replayBufferHardLimitResizeTimer =
	setTimeout(function() {
		console.log("Replay buffer hard limit resize timer fired");
	
		var numberToRemove = (MessageBuffer.replayBufferHardLimit - MessageBuffer.replayBufferSoftLimit);
		
		if (numberToRemove <= 0) {
			return;
		}
		
		MessageBuffer.replayBufferPerformResize(numberToRemove, true);
		
		MessageBuffer.replayBufferHardLimitResizeTimer = null;
	}, 5000);
	
	console.log("Replay buffer hard limit resize timer started");
};

/* ************************************************** */
/*                  Load Messages                     */
/* ************************************************** */

/* This function picks the best line to load old messages next to. */
/* When user is scrolling upwards, messages are removed from the
bottom of the replay buffer, and new messages are added to the top
of it. Therefore, when after === false, we use the first child 
as the line we want to append to. */
/* The opposite happens when the user is scrolling downward. 
We remove from the top and add to the bottom which means we
use the last child. */
MessageBuffer.loadMessages = function(before)
{
	/* MessageBuffer.loadMessages() is only called during scroll events by
	the user. We keep track of a request is already active then so that we
	do not keep sending them out while the user waits for one to finish. */
	if (before) 
	{
		if (MessageBuffer.loadingMessagesBeforeLine) {
			console.log("Cancelled request to load messages above line because another request is active");
			
			return;
		}
		
		if (MessageBuffer.replayBufferTopIsComplete) {
			console.log("Cancelled request to load messages because there is nothing new to load");
			
			return;
		}
	} 
	else // before
	{
		if (MessageBuffer.loadingMessagesAfterLine) {
			console.log("Cancelled request to load messages below line because another request is active");
			
			return;
		}
		
		if (MessageBuffer.replayBufferBottomIsComplete) {
			console.log("Cancelled request to load messages because there is nothing new to load");
			
			return;
		}
	}

	/* Context */	
	var line = null;

	/* We first look at the replay buffer because 
	the oldest messages are in that container. */
	var replayBuffer = MessageBuffer.replayBufferElement();
	
	if (before) {
		line = MessageBuffer.firstLineInBuffer(replayBuffer);
	} else {
		line = MessageBuffer.lastLineInBuffer(replayBuffer);
	}
	
	/* If no line was retrieved from the replay buffer, then we
	get one from the main buffer. We check both buffers because
	when we populate messages on launch, we only populate so
	much, but this gives user the option to reveal more. */
	var lineInMainBuffer = false;

	if (line === null) {
		/* It does not make sense to add after if we have no
		message in the replay buffer. */
		if (before === false) {
			return;
		}
		
		/* Retrieve the first line of the main buffer. */
		var mainBuffer = MessageBuffer.mainBufferElement();

		line = MessageBuffer.firstLineInBuffer(mainBuffer);
		
		lineInMainBuffer = true;
	}
	
	/* There is nothing in either buffer. */
	if (line === null) {
		console.log("No line to load from");

		return;	
	}

	/* Load messages */
	if (before) {
		MessageBuffer.loadingMessagesBeforeLine = true;
	} else {
		MessageBuffer.loadingMessagesAfterLine = true;
	}

	MessageBuffer.loadMessagesWithPayload(
		{
			"before" : before,
			"line" : line,
			"lineInMainBuffer" : lineInMainBuffer,
			"resultOfLoadMessages" : true
		}	
	);
};

/* Given a line we want to load old messages next to, we do so. */
MessageBuffer.loadMessagesWithPayload = function(requestPayload)
{
	var before = requestPayload.before;
	var line = requestPayload.line;

	/* Define logic that will be performed when 
	are are ready to load the messages. */
	var loadMessagesLogic = (function() {
		var postflightCallback = (function(renderedMessages) {
			requestPayload.renderedMessages = renderedMessages;

			MessageBuffer.loadMessagesWithLinePostflight(requestPayload);

			MessageBuffer.removeLoadingIndicator(line);
		});

		var lineNumber = MessageBuffer.lineNumberContents(line.id);

		if (before) {
			console.log("Loading messages before " + lineNumber);
		
			app.renderMessagesBefore(
				lineNumber, 
				MessageBuffer.loadMessagesBatchSize, 
				postflightCallback
			);
		} else {
			/* When we are rendering after, we render a range between the given line
			and the first child in the main buffer. */
			/* Logic defined by the message buffers do not allow us to render after 
			for a line thats in the main buffer. Only those that are in the replay
			buffer. We therefore have to fill in the gap between the two. */
			var mainBuffer = MessageBuffer.mainBufferElement();
			var mainBufferFirstLine = MessageBuffer.firstLineInBuffer(mainBuffer);

			var lineNumberEnd = MessageBuffer.lineNumberContents(mainBufferFirstLine.id);

			console.log("Loading messages between " + lineNumber + " and " + lineNumberEnd);

			app.renderMessagesInRange(
				lineNumber, 
				lineNumberEnd, 
				MessageBuffer.loadMessagesBatchSize, 
				postflightCallback
			);
		}
	});
	
	/* Present loading indicator then trigger logic. */
	MessageBuffer.addLoadingIndicator(before, line, loadMessagesLogic);
};

/* Postflight for loading old messages */
MessageBuffer.loadMessagesWithLinePostflight = function(requestPayload)
{
	/* Payload state */
	var before = requestPayload.before;
	var line = requestPayload.line;
	var renderedMessages = requestPayload.renderedMessages;
	var resultOfLoadMessages = requestPayload.resultOfLoadMessages;

	/* Perform logging */
	var renderedMessagesCount = renderedMessages.length;

	console.log("Request to load messages for " + line.id + " returned " + renderedMessagesCount + " results");

	if (renderedMessagesCount > 0) {
		/* Which buffer the line appears in will determine how we proceed. */
		/* We allow old messages to be loaded before the main buffer has 
		been completely filled up. If the line is in the main buffer, 
		then we have to take into account the max size of the main buffer
		and slide any messages that do not fit into it into the replay buffer. */
		/* We only allow this logic to proceed if after === false. 
		There is no case in which we should be loading messages before 
		a line that is in the main buffer. */
		var lineInMainBuffer = requestPayload.lineInMainBuffer;
	
		if (lineInMainBuffer) {
			if (before === false) {
				throw "Cannot load old messages for line that appears in the main buffer";
			}
			
			var spaceRemainingInMainBuffer = (MessageBuffer.mainBufferMaximumCount - MessageBuffer.mainBufferCurrentCount);
		} else {
			var spaceRemainingInMainBuffer = 0;
		}
	
		/* Array which will house every line number that was loaded. 
		The style needs this information so it can perform whatever action. */
		var lineNumbers = new Array();
		
		/* Array which will house every segment of HTML to append. */
		var html = new Array();
		
		/* Process result */
		for (var i = 0; i < renderedMessagesCount; i++) {
			var renderedMessage = renderedMessages[i];
			
			lineNumbers.push(renderedMessage.lineNumber);
			
			html.push(renderedMessage.html);
		}
		
		/* Depending on whether after === false or not, which segment of the
		html array will apply to which buffer will vary. Here we divide the
		arrays up into two. One for each buffer. */
		var mainBufferHtml = null;
		var replayBufferHtml = null;
				
		if (before) {
			/* The html will be added before the line which means the html 
			has to be processed with special logic. We have to work backwards
			because the bottom of the array will be added to the main buffer
			and the remainder to the replay buffer. */
			if (renderedMessagesCount > 0 && spaceRemainingInMainBuffer > 0) {
				mainBufferHtml = html.splice((renderedMessagesCount - spaceRemainingInMainBuffer), spaceRemainingInMainBuffer);
				replayBufferHtml = html.splice(0, (renderedMessagesCount - spaceRemainingInMainBuffer));
			}
		}
		
		/* Fill in the replay buffer HTML if it was not spliced. */
		if (replayBufferHtml === null) {
			replayBufferHtml = html;
		}
		
		/* Appending HTML above line will cause the view to appear 
		scrolled for the user so we save the position for restore. */
		TextualScroller.saveFirstScrollHeightForRestore();
	
		/* Append to main buffer */
		if (mainBufferHtml !== null && mainBufferHtml.length > 0) {
			console.log("Appending HTML");
	
			var mainBufferHtmlString = mainBufferHtml.join("");
			
			/* As defined by the above logic, mainBufferHtml shold only ever be 
			non-null when we have messages to add to the top of the main buffer. */
			line.insertAdjacentHTML('beforebegin', mainBufferHtmlString);
	
			MessageBuffer.mainBufferCurrentCount += mainBufferHtml.length;
		}
		
		/* Append to replay buffer */
		if (replayBufferHtml.length > 0) {
			var replayBufferHtmlString = replayBufferHtml.join("");
	
			if (before) {
				if (lineInMainBuffer) {
					/* When the line is in the main buffer and we have items to add to 
					the replay buffer, we obviously can't append to the line itself. 
					We instead append to the bottom of the replay buffer itself. */
					var replayBuffer = MessageBuffer.replayBufferElement();
					
					replayBuffer.insertAdjacentHTML('beforeend', replayBufferHtmlString);
				} else {
					line.insertAdjacentHTML('beforebegin', replayBufferHtmlString);
				}
			} else {
				line.insertAdjacentHTML('afterend', replayBufferHtmlString);
			}
	
			MessageBuffer.replayBufferCurrentCount += replayBufferHtml.length;
		}
	} // renderedMessagesCount > 0
	
	/* If the number of results is less than our batch size,
	then we can probably make a best guess that we have loaded
	all the old messages that are available. */
	if (renderedMessagesCount < MessageBuffer.loadMessagesBatchSize) {
		if (before) {
			MessageBuffer.replayBufferTopIsComplete = true;
		} else {
			MessageBuffer.replayBufferBottomIsComplete = true;
		}
	}
	
	/* Toggle visiblity of main buffer */
	MessageBuffer.mainBufferToggleVisiblity();
	
	if (renderedMessagesCount > 0) {
		/* Before we enforce size limit, we record the height with the appended
		HTML to allow scroller to learn proper amount to scroll. Without recording
		the height here, it wont change once we enforce size limit. */
		TextualScroller.saveSecondScrollHeightForRestore();
		
		/* Enforce size limit. This function expects the count to already be 
		incremented which is why we call it AFTER the append. */
		/* Value of before is reversed because we want to remove from the
		opposite of where we added. */
		MessageBuffer.replayBufferEnforceHardLimit(renderedMessagesCount, !before);
		
		/* Restore scroll position */
		TextualScroller.restoreScrollPosition();
		
		/* Post line numbers so style can do something with them. */
		Textual.newMessagePostedToViewInt(lineNumbers);
	} // renderedMessagesCount > 0
	
	/* Flush state */
	if (resultOfLoadMessages) {
		if (before) {
			MessageBuffer.loadingMessagesBeforeLine = false;
		} else {
			MessageBuffer.loadingMessagesAfterLine = false;
		}
	}
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
			"lineNumber" : MessageBuffer.lineNumberContents(toLine.id)
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
	var lineNumber = MessageBuffer.lineNumberContents(fromLine.id);

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
			MessageBuffer.loadMessages(true);
		}
		
		MessageBuffer.replayBufferCancelHardLimitResize();
	}
	
	if (scrolledUpward === false && TextualScroller.isScrolledToBottom()) {
		MessageBuffer.loadMessages(false);

		MessageBuffer.replayBufferScheduleHardLimitResize();
	}
};

MessageBuffer.scrolledToBottomOfMainBuffer = function()
{
	return (TextualScroller.scrolledAboveBottom === false &&
			MessageBuffer.mainBufferIsVisible());
};
