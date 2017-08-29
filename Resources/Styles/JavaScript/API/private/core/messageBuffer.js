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
MessageBuffer.replayBufferCountSoftLimit = 500;

/* When old messages are being loaded, this 
is the number of elements we want to keep. */
MessageBuffer.replayBufferCountHardLimit = 3000;

/* The number of elements to keep in the main buffer. */
MessageBuffer.mainBufferMaximumCount = 500;

/* The number of lines to fetch when loading old messages.
When old lines are fetched, the number of lines returned 
are also removed from the relevant buffer. */
MessageBuffer.loadMessagesBatchSize = 500;

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
	replayBufferElement.appendChild(mainBuffer.firstChild);
	
	MessageBuffer.replayBufferCurrentCount += 1;

	if (MessageBuffer.replayBufferCurrentCount > MessageBuffer.replayBufferCountSoftLimit) {
		replayBuffer.firstChild.remove();
	}
};

/* This function picks the best line to load old messages next to. */
/* When user is scrolling upwards, messages are removed from the
bottom of the replay buffer, and new messages are added to the top
of it. Therefore, when after == false, we use the first child 
as the line we want to append to. */
/* The opposite happens when the user is scrolling downward. 
We remove from the top and add to the bottom which means we
use the last child. */
MessageBuffer.loadMessages = function(after)
{
	var line = null;

	/* We first look at the replay buffer because 
	the oldest messages are in that container. */
	var replayBuffer = MessageBuffer.replayBufferElement();
	
	if (after === false) {
		line = replayBuffer.firstChild;
	} else {
		line = replayBuffer.lastChild;
	}
	
	/* If no line was retrieved from the replay buffer, then we
	get one from the main buffer. We check both buffers because
	when we populate messages on launch, we only populate so
	much, but this gives user the option to reveal more. */
	if (line === null) {
		/* It does not make sense to add after if we have no
		message in the replay buffer. */
		if (after) {
			return;
		}
		
		/* Retrieve the first line of the main buffer. */
		var mainBuffer = MessageBuffer.mainBufferElement();

		line = mainBuffer.firstChild;
	}
	
	/* There is nothing in either buffer. */
	if (line === null) {
		return;	
	}
	
	/* Load messages */
	MessageBuffer.loadMessagesWithLine(after, line);
};

/* Given a line we want to load old messages next to, we do so. */
MessageBuffer.loadMessagesWithLine = function(after, line)
{
	/* Define logic that will be performed when 
	are are ready to load the messages. */
	var loadMessagesLogic = (function() {
		var postflightCallback = (function(renderedMessages) {
			MessageBuffer.loadMessagesWithLinePostflight(after, line, renderedMessages);
		});

		var lineNumber = MessageBuffer.lineNumberContents(line.id);

		if (after === false) {
			app.renderMessagesBefore(lineNumber, MessageBuffer.loadMessagesBatchSize, postflightCallback);
		} else {
			app.renderMessagesAfter(lineNumber, MessageBuffer.loadMessagesBatchSize, postflightCallback);
		}
	});
	
	/* Present loading indicator then trigger logic. */
	MessageBuffer.addLoadingIndicator(after, line, loadMessagesLogic);
};

/* Postflight for loading old messages */
MessageBuffer.loadMessagesWithLinePostflight = function(after, line, renderedMessages)
{
	console.log(renderedMessages);
	
	/* Hide loading indicator */
	MessageBuffer.removeLoadingIndicator(line);
};

/* Message buffer loading indicator */
MessageBuffer.addLoadingIndicator = function(after, toLine, callbackFunction)
{
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
};

MessageBuffer.removeLoadingIndicator = function(fromLine)
{
	var lineNumber = MessageBuffer.lineNumberContents(fromLine.id);

	var loadingIndicator = document.getElementById("mb_loading-" + lineNumber);
	
	if (loadingIndicator) {
		loadingIndicator.remove();
	}
};
