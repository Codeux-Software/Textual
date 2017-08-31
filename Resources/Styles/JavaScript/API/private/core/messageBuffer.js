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
MessageBuffer.replayBufferCountSoftLimit = 200; // 200

/* When old messages are being loaded, this 
is the number of elements we want to keep. */
MessageBuffer.replayBufferCountHardLimit = 1000; // 1000

/* The number of elements to keep in the main buffer. */
MessageBuffer.mainBufferMaximumCount = 100; // 100

/* The number of lines to fetch when loading old messages.
When old lines are fetched, the number of lines returned 
are also removed from the relevant buffer. */
MessageBuffer.loadMessagesBatchSize = 100; // 100

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

/* Line numbers */
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

/* Main message buffer */
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
		MessageBuffer.style.display = "";
	} else {
		MessageBuffer.style.display = "none";
	}
};

/* Replay message buffer */
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

	if (MessageBuffer.replayBufferCountSoftLimitPaused() === false &&
		MessageBuffer.replayBufferCurrentCount > MessageBuffer.replayBufferCountSoftLimit) 
	{
		replayBuffer.firstChild.remove();

		/* We removed from the top of the replay buffer which means
		we need to invalidate state. */
		MessageBuffer.replayBufferTopIsComplete = false;
	}
};

/* This function picks the best line to load old messages next to. */
/* When user is scrolling upwards, messages are removed from the
bottom of the replay buffer, and new messages are added to the top
of it. Therefore, when after === false, we use the first child 
as the line we want to append to. */
/* The opposite happens when the user is scrolling downward. 
We remove from the top and add to the bottom which means we
use the last child. */
MessageBuffer.loadMessages = function(after)
{
	/* MessageBuffer.loadMessages() is only called during scroll events by
	the user. We keep track of a request is already active then so that we
	do not keep sending them out while the user waits for one to finish. */
	if (after === false) 
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
	else // after === false
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
	
	if (after === false) {
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
		if (after) {
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
	console.log("Loading messages");
		
	if (after === false) {
		MessageBuffer.loadingMessagesBeforeLine = true;
	} else {
		MessageBuffer.loadingMessagesAfterLine = true;
	}

	MessageBuffer.loadMessagesWithPayload(
		{
			"after" : after,
			"line" : line,
			"lineInMainBuffer" : lineInMainBuffer,
			"resultOfLoadMessages" : true
		}	
	);
};

/* Given a line we want to load old messages next to, we do so. */
MessageBuffer.loadMessagesWithPayload = function(requestPayload)
{
	var after = requestPayload.after;
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

		if (after === false) {
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

			app.renderedMessagesInRange(
				lineNumber, 
				lineNumberEnd, 
				MessageBuffer.loadMessagesBatchSize, 
				postflightCallback
			);
		}
	});
	
	/* Present loading indicator then trigger logic. */
	MessageBuffer.addLoadingIndicator(after, line, loadMessagesLogic);
};

/* Postflight for loading old messages */
MessageBuffer.loadMessagesWithLinePostflight = function(requestPayload)
{
	/* Payload state */
	var after = requestPayload.after;
	var line = requestPayload.line;
	var lineInMainBuffer = requestPayload.lineInMainBuffer;
	var renderedMessages = requestPayload.renderedMessages;
	var resultOfLoadMessages = requestPayload.resultOfLoadMessages;
	
	/* Function that is used in multiple places to flush status. */
	var statusCallback = (function() {
		/* If the number of results is less than our batch size,
		then we can probably make a best guess that we have loaded
		all the old messages that are available. */
		if (renderedMessagesCount < MessageBuffer.loadMessagesBatchSize) {
			if (after === false) {
				MessageBuffer.replayBufferTopIsComplete = true;
			} else {
				MessageBuffer.replayBufferBottomIsComplete = true;
			
				MessageBuffer.mainBufferToggleVisiblity();
			}
		}
		
		if (resultOfLoadMessages) {
			if (after === false) {
				MessageBuffer.loadingMessagesBeforeLine = false;
			} else {
				MessageBuffer.loadingMessagesAfterLine = false;
			}
		}
	});
	
	/* Perform logging and exit if we have nothing. */
	var renderedMessagesCount = renderedMessages.length;

	console.log("Request to load messages for " + line.id + " returned " + renderedMessagesCount + " results");
		
	if (renderedMessagesCount === 0) {
		statusCallback();
		
		return;
	}

	/* Which buffer the line appears in will determine how we proceed. */
	/* We allow old messages to be loaded before the main buffer has 
	been completely filled up. If the line is in the main buffer, 
	then we have to take into account the max size of the main buffer
	and slide any messages that do not fit into it into the replay buffer. */
	/* We only allow this logic to proceed if after === false. 
	There is no case in which we should be loading messages before 
	a line that is in the main buffer. */
	if (lineInMainBuffer) {
		if (after) {
			throw "Cannot load old messages for line that appears in the main buffer";
		}
		
		var spaceRemainingInMainBuffer = (MessageBuffer.mainBufferMaximumCount - MessageBuffer.mainBufferCurrentCount);
	} else {
		var spaceRemainingInMainBuffer = 0;
	}

	/* Create an array which will house every line number that was loaded. 
	The style needs this information so it can perform whatever action. */
	var lineNumbers = new Array();
	
	/* Create an array which will house every segment of HTML to append. */
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
			
	if (after === false) {
		/* The html will be added before the line which means the html 
		has to be processed with special logic. We have to work backwards
		because the bottom of the array will be added to the main buffer
		and the remainder to the replay buffer. */
		if (spaceRemainingInMainBuffer > 0) {
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
	if (after === false) {
		TextualScroller.saveScrollHeightForRestore();
	}

	/* Append to main buffer */
	if (mainBufferHtml !== null) {
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

		if (after === false) {
			console.log("Appending HTML");

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
	
	/* Restore scroll position */
	if (after === false) {
		TextualScroller.restoreScrollPosition();
	}
	
	/* Post line numbers so style can do something with them. */
	Textual.newMessagePostedToViewInt(lineNumbers);

	/* Flush state */
	statusCallback();

	/* Flush arrays */
	lineNumbers = null;
	html = null;
	mainBufferHtml = null;
	replayBufferHtml = null;
};

/* Message buffer loading indicator */
MessageBuffer.addLoadingIndicator = function(after, toLine, callbackFunction)
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
			if (after === false) {
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

/* Buffer size */
MessageBuffer.replayBufferCountSoftLimitPaused = function()
{
	return TextualScroller.isScrolledByUser;
};

MessageBuffer.resizeBuffers = function()
{
	
};

/* Scrolling */
MessageBuffer.documentScrolledCallback = function(scrolledUpward)
{
	if (scrolledUpward && TextualScroller.isScrolledToTop()) {
		MessageBuffer.loadMessages(false);
	}
};
