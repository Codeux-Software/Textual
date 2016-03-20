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

/*	Scrolling is very dependent on TextualScroller.scrollTopUserConstant
	JavaScript has no way to distinguish user scroll events and programatic
	scroll events which means everything is best guess. Each time an auto
	scroll is performed, the Y coordinate we are scrolling to is recorded.

	Take this coordinate and add TextualScroller.scrollTopUserConstant to it.
	If a scroll event is received that scrolls ABOVE this calculated height,
	the the event is believed to be the user.

	If a scroll event occurs at the exact bottom, or within the value of
	TextualScroller.scrollTopUserConstant from the exact bottom, then the
	user is believed to have scrolled back to the bottom.
*/

/* State tracking */
TextualScroller.isScrolledByUser = false;

TextualScroller.currentScrollTopValue = 0;

TextualScroller.scrollTopLastPosition1 = 0;
TextualScroller.scrollTopLastPosition2 = 0;

TextualScroller.scrollTopUserConstant = 20;

TextualScroller.scrollingEnabled = false;

/* Core functions */
TextualScroller.documentResizedCallback = function()
{
	TextualScroller.performAutoScroll();
};

TextualScroller.documentScrolledCallback = function()
{
	if (TextualScroller.scrollingEnabled === false) {
		return;
	}

	TextualScroller.scrollTopLastPosition2 = TextualScroller.scrollTopLastPosition1;

	TextualScroller.scrollTopLastPosition1 = document.body.scrollTop;

	if (TextualScroller.isScrolledByUser) {
		if (TextualScroller.isScrolledToBottom()) {
			TextualScroller.isScrolledByUser = false;

			TextualScroller.currentScrollTopValue = TextualScroller.scrollTopLastPosition1;
		}
	} else {
		if (TextualScroller.scrollTopLastPosition1 < TextualScroller.scrollTopLastPosition2) {
			if (TextualScroller.isScrolledAboveUserThreshold()) {
				TextualScroller.isScrolledByUser = true;
			}
		}

		if (TextualScroller.scrollTopLastPosition1 > TextualScroller.currentScrollTopValue) {
			TextualScroller.currentScrollTopValue = TextualScroller.scrollTopLastPosition1;
		}
	}
};

TextualScroller.performAutoScroll = function()
{
	var scrollHeight = TextualScroller.scrollHeight();

	if (scrollHeight === 0) {
		return;
	} else if (TextualScroller.scrollingEnabled === false) {
		TextualScroller.scrollingEnabled = true;
	}

	if (TextualScroller.isScrolledByUser) {
		return;
	}

	document.body.scrollTop = scrollHeight;
};

TextualScroller.scrollHeight = function()
{
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

TextualScroller.isScrolledAboveUserThreshold = function()
{
	var scrollTop = (TextualScroller.currentScrollTopValue - document.body.scrollTop);

	if (scrollTop > TextualScroller.scrollTopUserConstant) {
		return true;
	} else {
		return false;
	}
};

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

document.addEventListener("scroll", TextualScroller.documentScrolledCallback, false);

window.addEventListener("resize", TextualScroller.documentResizedCallback, false);
