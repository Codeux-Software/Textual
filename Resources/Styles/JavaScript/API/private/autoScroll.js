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

var TextualScroller = {};

/* State tracking */
TextualScroller.scrollTopUserConstant = 25;

TextualScroller.isScrolledByUser = false;

TextualScroller.scrollLastPosition1 = 0;
TextualScroller.scrollLastPosition2 = 0;

TextualScroller.currentScrollTopValue = 0;

TextualScroller.currentViewHeightValue = 0;
TextualScroller.previousViewHeightValue = 0;

TextualScroller.adjustScrollerPosition = false;

/* Core functions */
TextualScroller.documentResizedCallback = function()
{
	TextualScroller.performAutoScroll();
};

TextualScroller.documentScrolledCallback = function()
{
	/* Ignore events that are related to elastic scrolling. */
	var scrollHeight = TextualScroller.scrollHeight();
	
	var scrollPosition = window.scrollY;
	
	if (scrollPosition > scrollHeight) {
		return;
	}

	/* 	Record the last two known scrollY values. These properties are compared
		to determine if the user is scrolling upwards or downwards. */
	TextualScroller.scrollLastPosition2 = TextualScroller.scrollLastPosition1;

	TextualScroller.scrollLastPosition1 = scrollPosition;

	/* 	If the current scroll top value exceeds the view height, then it means
		that some lines were probably removed to enforce size limit. */
	/* 	Reset the value to be the absolute bottom when this occurs. */
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

/* Perform automatic scrolling */
/* This function might be a bit misleading. Textual itself, at least higher up,
   never invokes this function. This function exists for two purposes:
   1) To correct scrolling when resizing the window 
   2) Allow style authors to easily scroll to the bottom */
/* When Textual performs auto scroll, it is done using Objective-C. 
   See -moveToEndOfDocument: - 
   https://developer.apple.com/reference/appkit/nsresponder/1533165-movetoendofdocument */
TextualScroller.performAutoScroll = function() 
{
	var scrollHeight = TextualScroller.scrollHeight();

	if (scrollHeight === 0) {
		return;
	}
	
	var requestAnimationFrame = (window.requestAnimationFrame || window.webkitRequestAnimationFrame);

	requestAnimationFrame(function() {
		if (TextualScroller.viewHeightChanged(scrollHeight) === false) {
			return;
		}

		document.body.scrollTop = scrollHeight;
	 });
};

/* TextualScroller.viewHeightChanged() is invoked by Textual, higher up, when the height of the
   view (the scrollable area) changes. The logic of this function can then perform many actions,
   but when completed, must either return true or false. If it returns true, then Textual will 
   scroll the WebView to the bottom, without relying on JavaScript to do it. */
TextualScroller.viewHeightChanged = function(viewHeight)
{
	/* Make a copy of the new view height */
	TextualScroller.previousViewHeightValue = TextualScroller.currentViewHeightValue;
	
	TextualScroller.currentViewHeightValue = viewHeight;
	
	/* Do not perform scrolling if we are performing live resize */
	/* Stop auto scroll before height is recorded so that once live resize is completed,
	   scrolling will notice the new height of the view and use that. */
	if (Textual.hasLiveResize()) {
		if (InlineImageLiveResize.dragElement) {
			return false;
		}
	}

	/* Do not perform scrolling if the user is believed to have scrolled */
	if (TextualScroller.isScrolledByUser) {
		/* If the height of the view changed while the user is scrolled up,
		   such as when inserting elements above the current position,
		   then we should adjust the position so the scroller follows 
		   the changes that has been made. */
		if (TextualScroller.adjustScrollerPosition) {
			TextualScroller.adjustScrollerPosition = false;

			TextualScroller.adjustScrollerPositionInt();
		}

		return false;
	} else {
		/* Unset property incase it's set but we aren't scrolled by user. */
		TextualScroller.adjustScrollerPosition = false;
	}

	/* Tell Textual to scroll to bottom */
	return true;
};

/* Move scroll position based on height difference of view. 
   If the user is scrolled up and content is added at the top of the view, 
   or removed from there, then the content will move but the scroll position
   will remove stationary. This function moves the scroll positions so that
   the user isn't even aware that something was changed. */
TextualScroller.adjustScrollerPositionInt = function()
{
	var heightDifference = (TextualScroller.currentViewHeightValue - TextualScroller.previousViewHeightValue);
	
	if (heightDifference === 0) {
		return;
	}
	
	var newScrollTop = (document.body.scrollTop + heightDifference);
	
	if (newScrollTop < 0) {
		newScrollTop = 0;
	}
	
	console.log("Height difference: " + heightDifference);
	
	var completionFunction = (function() {
		document.body.scrollTop = newScrollTop;
	});

	/* Depending on how much the frame has changed, it may be better to
	   scroll right away or use an animation frame. This magic number 
	   was determined by trial and error. This can probably use rewrite. */
	if (heightDifference <= (-25)) {
		completionFunction();
	} else {
		var requestAnimationFrame = (window.requestAnimationFrame || window.webkitRequestAnimationFrame);

		requestAnimationFrame(completionFunction);
	}
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

/* Bind to events */
document.addEventListener("scroll", TextualScroller.documentScrolledCallback, false);

window.addEventListener("resize", TextualScroller.documentResizedCallback, false);
