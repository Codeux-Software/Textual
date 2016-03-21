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
TextualScroller.currentScrollHeightValue = 0;

TextualScroller.scrollTopUserConstant = 25;

TextualScroller.scrollHeightChangedTimer = null;

/* Core functions */
TextualScroller.documentVisbilityChangedCallback = function()
{
	var documentHidden = false;

	if (typeof document.hidden !== "undefined") {
		documentHidden = document.hidden;
	} else if (typeof document.webkitHidden !== "undefined") {
		documentHidden = document.webkitHidden;
	}

	if (documentHidden) {
		TextualScroller.disableScrollingTimerInt();
	} else {
		TextualScroller.enableScrollingTimerInt();
	}
};

TextualScroller.documentResizedCallback = function()
{
	TextualScroller.performAutoScroll(true);
};

/* 	Perform automatic scrolling */
TextualScroller.performAutoScroll = function(skipScrollHeightCheck)
{
	/* Set default value of argument */
	if (typeof skipScrollHeightCheck === "undefined") {
		skipScrollHeightCheck = false;
	}

	/* 	Retrieve the current scroll height and return if it is zero */
	var scrollHeight = TextualScroller.scrollHeight();

	if (scrollHeight === 0) {
		return;
	}
	
	/* Make a copy of the previous scroll height and save the new */
	var scrollHeightPrevious = TextualScroller.currentScrollHeightValue;
	
	TextualScroller.currentScrollHeightValue = scrollHeight;
	
	/* Perform comparison test for scroll height */
	if (skipScrollHeightCheck === false) {
		if (scrollHeight === scrollHeightPrevious) {
			return;
		}
	}
	
	/* Check if we are at or near the bottom */
	var scrollTop = (document.body.scrollTop + TextualScroller.scrollTopUserConstant);

	if (scrollTop < scrollHeightPrevious) {
		return;
	}

	/* Scroll to new value */
	document.body.scrollTop = scrollHeight;
};

/* 	Function returns the scroll height accounting for offset height */
TextualScroller.scrollHeight = function()
{
	/* This function is called very early so add catch */
	if (document.body === null) {
		return 0;
	}
		
	var offsetHeight = document.body.offsetHeight;

	/*	offsetHeight /should/ never be zero but it can be at times
		when this function is called and the tree has not been fully
		rendered. In that case, we return zero instead of bad math. */
	if (offsetHeight === 0) {
		return 0;
	}

	var scrollHeight = document.body.scrollHeight;

	return (scrollHeight - offsetHeight);
};

/* 	Functions that can be used to toggle automatic scrolling */
TextualScroller.enableScrollingTimerInt = function()
{
	/* Catch possible edge cases */
	if (TextualScroller.scrollHeightChangedTimer) {
		throw "Tried to create timer when one already exists";
	}

	/* Perform automatic scroll the moment this function is called. */
	TextualScroller.performAutoScroll();

	/* Setup timer to continuously perform automatic scroll. */
	TextualScroller.scrollHeightChangedTimer = setInterval(function() {
		TextualScroller.performAutoScroll();
	}, 100);
};

TextualScroller.disableScrollingTimerInt = function()
{
	if (TextualScroller.scrollHeightChangedTimer) {
		clearInterval(TextualScroller.scrollHeightChangedTimer);

		TextualScroller.scrollHeightChangedTimer = null;
	}
};

/* 	TextualScroller.enableScrollingTimer and TextualScroller.disableScrollingTimer 
	are called by corePrivate.js when a view is switched to and switched away. 
	The timer is only managed here when document.hidden is not available. When 
	document.hidden is available, it is better to rely on state changes to it, 
	as it allows us to disable timer not only when the view is switched away,
	but when its host window is occluded. */
TextualScroller.enableScrollingTimer = function()
{
	if (typeof document.hidden === "undefined" && typeof document.webkitHidden === "undefined") {
		TextualScroller.enableScrollingTimerInt();
	}
};

TextualScroller.disableScrollingTimer = function()
{
	if (typeof document.hidden === "undefined" && typeof document.webkitHidden === "undefined") {
		TextualScroller.disableScrollingTimerInt();
	}
};


/* Bind to events */
window.addEventListener("resize", TextualScroller.documentResizedCallback, false);

if (typeof document.hidden !== "undefined") {
	document.addEventListener("visibilitychange", TextualScroller.documentVisbilityChangedCallback, false);
} else if (typeof document.webkitHidden !== "undefined") {
	document.addEventListener("webkitvisibilitychange", TextualScroller.documentVisbilityChangedCallback, false);
}

/* Populate initial visiblity state and maybe create timer */
TextualScroller.documentVisbilityChangedCallback();
