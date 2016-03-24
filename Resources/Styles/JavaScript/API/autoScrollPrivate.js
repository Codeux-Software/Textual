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
TextualScroller.scrollTopUserConstant = 25;

TextualScroller.scrollHeightLastValue = 0;
TextualScroller.scrollHeightTimerActive = false;

TextualScroller.scrollLastPosition1 = 0;
TextualScroller.scrollLastPosition2 = 0;

TextualScroller.currentScrollTopValue = 0;

TextualScroller.isScrolledByUser = false;

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
	TextualScroller.performAutoScrollInt(true);
};

TextualScroller.documentScrolledCallback = function()
{
	/* 	Record the last two known scrollY values. These properties are compared
		to determine if the user is scrolling upwards or downwards. */
	TextualScroller.scrollLastPosition2 = TextualScroller.scrollLastPosition1;

	TextualScroller.scrollLastPosition1 = window.scrollY;

	/* 	If the current scroll top value exceeds the view height, then it means
		that some lines were probably removed to enforce size limit. */
	/* 	Reset the value to be the absolute bottom when this occurs. */
	var scrollHeight = TextualScroller.scrollHeight();

	if (TextualScroller.currentScrollTopValue > scrollHeight) {
		TextualScroller.currentScrollTopValue = scrollHeight;

		if (TextualScroller.currentScrollTopValue < 0) {
			TextualScroller.currentScrollTopValue = 0;
		}
	}
	
	if (TextualScroller.isScrolledByUser) {
		/* Check whether the user has scrolled back to the bottom */
		var scrollTop = (scrollHeight - TextualScroller.scrollLastPosition1);

		if (scrollTop < TextualScroller.scrollTopUserConstant) {
			TextualScroller.isScrolledByUser = false;

			TextualScroller.currentScrollTopValue = TextualScroller.scrollLastPosition1;
		}
	}
	else 
	{
		/* 	Check if the user is scrolling upwards. If they are, then check if they have went
			above the threshold that defines whether its a user initated event or not. */
		if (TextualScroller.scrollLastPosition1 < TextualScroller.scrollLastPosition2) {
			var scrollTop = (TextualScroller.currentScrollTopValue - TextualScroller.scrollLastPosition1);

			if (scrollTop > TextualScroller.scrollTopUserConstant) {
				console.log("Scrolled above user threshold with difference: " + scrollTop);

				TextualScroller.isScrolledByUser = true;
			}
		}

		/* 	If the user is scrolling downward and passes last threshold location, then
			move the location further downward. */
		if (TextualScroller.scrollLastPosition1 > TextualScroller.currentScrollTopValue) {
			TextualScroller.currentScrollTopValue = TextualScroller.scrollLastPosition1;
		}
	}
};

/* 	Perform automatic scrolling */
TextualScroller.performAutoScroll = function()
{
	var performAutoScrollFunction = (function() {
		TextualScroller.performAutoScrollInt(false);

		if (TextualScroller.scrollHeightTimerActive) {
			TextualScroller.performAutoScroll();
		}
	});
	
	// if (typeof window.requestAnimationFrame === "undefined") {
		setTimeout(performAutoScrollFunction, 50);
	// } else {
	//	requestAnimationFrame(performAutoScrollFunction);
	// }
};

TextualScroller.performAutoScrollInt = function(skipScrollHeightCheck)
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
	var scrollHeightPrevious = TextualScroller.scrollHeightLastValue;
	
	TextualScroller.scrollHeightLastValue = scrollHeight;
	
	/* Do not perform scrolling if the user is believed to have scrolled */
	if (TextualScroller.isScrolledByUser) {
		return;
	}
	
	InlineImageLiveResize.onMouseDown

	/* Perform comparison test for scroll height */
	if (skipScrollHeightCheck === false) {
		if (scrollHeight === scrollHeightPrevious) {
			return;
		}
	}

	/* Scroll to new value */
	window.scrollTo(0, scrollHeight);
};

/* Function returns the scroll height accounting for offset height */
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

/* Functions that can be used to toggle automatic scrolling */
TextualScroller.enableScrollingTimerInt = function()
{
	TextualScroller.scrollHeightTimerActive = true;
	
	TextualScroller.performAutoScroll();
};

TextualScroller.disableScrollingTimerInt = function()
{
	TextualScroller.scrollHeightTimerActive = false;
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
document.addEventListener("scroll", TextualScroller.documentScrolledCallback, false);

window.addEventListener("resize", TextualScroller.documentResizedCallback, false);

if (typeof document.hidden !== "undefined") {
	document.addEventListener("visibilitychange", TextualScroller.documentVisbilityChangedCallback, false);
} else if (typeof document.webkitHidden !== "undefined") {
	document.addEventListener("webkitvisibilitychange", TextualScroller.documentVisbilityChangedCallback, false);
}

/* Populate initial visiblity state and maybe create timer */
TextualScroller.documentVisbilityChangedCallback();
