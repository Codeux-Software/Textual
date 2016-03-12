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

/* *********************************************************************** */
/*																		   */
/* DO NOT EDIT ANYTHING BELOW THIS LINE FROM WITHIN A STYLE. 			   */
/* THE FUNCTIONS DELCARED WITHIN THIS FILE ARE USED FOR INTERNAL		   */
/* PURPOSES AND THE RESULT OF OVERRIDING A FUNCTION IS UNDEFINED.		   */
/*																		   */
/* *********************************************************************** */

var TextualScroller = {};

/* State tracking */
TextualScroller.isScrolledByCode = false;
TextualScroller.isScrolledByUser = false;

TextualScroller.scrolledToBottomTimer = null;

/* Core functions */
TextualScroller.debugDataLog = function(message)
{
	var channelName = document.body.getAttribute("channelname");

	if (channelName === null) {
		channelName = "(server console)";
	}

	app.logToConsole("TextualScroller.debugDataLog(): " + channelName + " - " + message);
};

TextualScroller.documentResizedCallback = function()
{
	TextualScroller.performAutoScroll();
};

TextualScroller.documentScrolledCallback = function()
{
	/*	If JavaScript has determined that we are not at the bottom even though
		we are supposed to be (isScrollingByCode == true), then set a timer to
		to perform manual scroll one more time to try and fix this problem. */
	var viewingBottom = TextualScroller.viewingBottom();
	
	var createTimer = false;
	
	if (TextualScroller.isScrolledByCode) {
		TextualScroller.isScrolledByCode = false;

		if (viewingBottom) {
			createTimer = false;
		} else {
			createTimer = true;
		}
	} else {
		if (viewingBottom) {
			TextualScroller.isScrolledByUser = false;
		} else {
			TextualScroller.isScrolledByUser = true;
		}
	}
	
	if (createTimer) {
		if (TextualScroller.scrolledToBottomTimer) {
			return;
		}
		
		TextualScroller.debugDataLog("viewingBottom === false, creating timer to try to fix")

		TextualScroller.scrolledToBottomTimer = 
			setTimeout(function() {
				TextualScroller.scrolledToBottomTimer = null;

				TextualScroller.performAutoScroll();
			}, 500);
	}
};

TextualScroller.performAutoScroll = function()
{
	if (TextualScroller.isScrolledByUser) {
		return;
	}

	TextualScroller.isScrolledByCode = true;

	Textual.scrollToBottomOfView(false);
};

TextualScroller.viewingTop = function()
{
	if (Math.floor(document.body.scrollTop) === 0) {
		return true;
	} else {
		return false;
	}
};

TextualScroller.viewingBottom = function()
{
	var documentBody = Textual.documentBodyElement();

	var lastChild = documentBody.lastChild;

	if (lastChild) {
		var elementBottom = Math.floor(lastChild.getBoundingClientRect().bottom);

		var documentBottom = Math.floor(document.documentElement.offsetHeight);

		/*	15 is a fairly magical number subtracted from elementBottom to 
			account for very slight scrolling that may occur with a TrackPad 
			or other sensitive scrolling device. */
		if ((elementBottom - 15) > documentBottom) {
			return false;
		}
	}

	return true;
};

document.addEventListener("scroll", TextualScroller.documentScrolledCallback, false);

window.addEventListener("resize", TextualScroller.documentResizedCallback, false);
