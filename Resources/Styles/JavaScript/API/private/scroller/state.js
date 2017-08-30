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

/* ************************************************** */
/*                   State Tracking                   */
/* ************************************************** */

TextualScroller.scrollTopUserConstant = 25;

TextualScroller.scrollLastPosition1 = 0;
TextualScroller.scrollLastPosition2 = 0;

TextualScroller.currentScrollTopValue = 0;

TextualScroller.scrollHeightCurrentValue = 0;
TextualScroller.scrollHeightPreviousValue = 0;

TextualScroller.isScrolledByUser = false;

TextualScroller.userScrolledUpwards = false;

/* Any changes made to this logic should be reflected in TVCWK1AutoScroller.m */
TextualScroller.documentScrolledCallback = function()
{
	/* Height of scrollabe area */
	var scrollHeight = TextualScroller.scrollHeight();

	TextualScroller.scrollHeightPreviousValue = TextualScroller.scrollHeightCurrentValue;

	TextualScroller.scrollHeightCurrentValue = scrollHeight;

	/* The current position scrolled to */
	var scrollPosition = window.scrollY;

	if (scrollPosition > scrollHeight) {
		return;
	}
	
	var scrolledUpwards = false;

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

		if (TextualScroller.scrollLastPosition1 < TextualScroller.scrollLastPosition2) {
			scrolledUpwards = true;
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

			scrolledUpwards = true;
		}

		/* 	If the user is scrolling downward and passes last threshold location, then
			move the location further downward. */
		if (TextualScroller.scrollLastPosition1 > TextualScroller.currentScrollTopValue) {
			TextualScroller.currentScrollTopValue = TextualScroller.scrollLastPosition1;
		}
	}
	
	/* Record direction we are scrolling */
	if (scrolledUpwards) {
		document.dispatchEvent(new Event('scrolledUpward'));
	} else {
		document.dispatchEvent(new Event('scrolledDownward'));
	}

	TextualScroller.userScrolledUpwards = scrolledUpwards;
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

TextualScroller.isScrolledToTop = function()
{
	return (TextualScroller.scrollLastPosition1 <= 0);
};

TextualScroller.lastScrollerPosition = function()
{
	return TextualScroller.scrollLastPosition1;
};

/* Bind to events */
document.addEventListener("scroll", TextualScroller.documentScrolledCallback, false);
