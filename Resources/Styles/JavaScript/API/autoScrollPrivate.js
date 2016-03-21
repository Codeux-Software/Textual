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
TextualScroller.isScrolledByUser = false;

TextualScroller.currentScrollHeightValue = 0;
TextualScroller.currentScrollTopValue = 0;

TextualScroller.scrollTopUserConstant = 20;

TextualScroller.scrollTopLastPosition1 = 0;
TextualScroller.scrollTopLastPosition2 = 0;

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

TextualScroller.documentScrolledCallback = function()
{
	/* 	Record the last two known scrollTop values. These properties are compared
		to determine if the user is scrolling upwards or downwards. */
	TextualScroller.scrollTopLastPosition2 = TextualScroller.scrollTopLastPosition1;

	TextualScroller.scrollTopLastPosition1 = document.body.scrollTop;

	if (TextualScroller.isScrolledByUser) {
		/* Check whether the user has scrolled back to the bottom */
		if (TextualScroller.isScrolledToBottom()) {
			TextualScroller.isScrolledByUser = false;

			TextualScroller.currentScrollTopValue = TextualScroller.scrollTopLastPosition1;
		}
	} else {
		/* 	Check if the user is scrolling upwards. If they are, then check if they have went
			above the threshold that defines whether its a user initated event or not. */
		if (TextualScroller.scrollTopLastPosition1 < TextualScroller.scrollTopLastPosition2) {
			if (TextualScroller.isScrolledAboveUserThreshold()) {
				TextualScroller.isScrolledByUser = true;
			}
		}

		/* 	If the user is scrolling downward (or an automatic scroll is), then record 
			the last known position as the currentScrollTopValue */
		if (TextualScroller.scrollTopLastPosition1 > TextualScroller.currentScrollTopValue) {
			TextualScroller.currentScrollTopValue = TextualScroller.scrollTopLastPosition1;
		}
	}
};

/* 	Perform automatic scrolling */
TextualScroller.performAutoScroll = function(skipScrollHeightCheck)
{
	/* Do not perform scrolling if the user is believed to have scrolled */
	if (TextualScroller.isScrolledByUser) {
		return;
	}
	
	/* Set default value of argument */
	if (typeof skipScrollHeightCheck === "undefined") {
		skipScrollHeightCheck = false;
	}

	/* 	Check the current value of scrollHeight() and only perform a 
		scrolling event if its value has changed. */
	var scrollHeight = TextualScroller.scrollHeight();

	if (skipScrollHeightCheck === false) {
		if (scrollHeight === TextualScroller.scrollHeightLastValue) {
			return;
		}
	}
	
	TextualScroller.scrollHeightLastValue = scrollHeight;

	/* Scroll to new value */
	document.body.scrollTop = scrollHeight;
};

/* 	Function returns the scroll height accounting for offset height */
TextualScroller.scrollHeight = function()
{
	/* This function is called very early so add catch */
	if (typeof document.body === "undefined") {
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

/* 	Function returns true if the document is scrolled the offset defined 
	by the TextualScroller.scrollTopUserConstant property above the value 
	of TextualScroller.currentScrollTopValue */
TextualScroller.isScrolledAboveUserThreshold = function()
{
	var scrollTop = (TextualScroller.currentScrollTopValue - document.body.scrollTop);

	if (scrollTop > TextualScroller.scrollTopUserConstant) {
		return true;
	} else {
		return false;
	}
};

/* 	Function returns true if the document is scrolled to the bottom or within 
	a specific offset of it. The maximum offset allowed is defined by the 
	TextualScroller.scrollTopUserConstant property */
TextualScroller.isScrolledToBottom = function()
{
	var scrollTop = (TextualScroller.scrollTopUserConstant + document.body.scrollTop);

	var scrollHeight = TextualScroller.scrollHeight();

	if (scrollTop >= scrollHeight) {
		return true;
	} else {
		return false;
	}
};

/* Bind to events */
document.addEventListener("scroll", TextualScroller.documentScrolledCallback, false);

window.addEventListener("resize", TextualScroller.documentResizedCallback, false);

if (typeof document.hidden !== "undefined") {
	document.addEventListener("visibilitychange", TextualScroller.documentVisbilityChangedCallback, false);
} else if (typeof document.webkitHidden !== "undefined") {
	document.addEventListener("webkitvisibilitychange", TextualScroller.documentVisbilityChangedCallback, false);
}

/* Populate initial visiblity state and maybe create timer */
TextualScroller.documentVisbilityChangedCallback();
