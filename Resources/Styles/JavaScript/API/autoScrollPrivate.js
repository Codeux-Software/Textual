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
TextualScroller.isScrollingProgrammatically = false;

TextualScroller.isScrolledToBottomOfView = true;

/* Core functions */
TextualScroller.documentScrolledCallback = function()
{
	if (TextualScroller.isScrollingProgrammatically) {
		TextualScroller.isScrollingProgrammatically = false;
	}

	if (TextualScroller.canScroll() == false) {
		return;
	}

	TextualScroller.isScrolledToBottomOfView = TextualScroller.viewingBottom();
};

TextualScroller.performAutoScroll = function()
{
	if (TextualScroller.canScroll() == false) {
		return;
	}

	if (TextualScroller.isScrolledToBottomOfView == false) {
		return;
	}

	TextualScroller.isScrollingProgrammatically = true;

	Textual.scrollToBottomOfView(false);
};

TextualScroller.canScroll = function()
{
	return (Math.floor(document.body.scrollHeight) > Math.floor(document.body.clientHeight));
};

TextualScroller.viewingTop = function()
{
	return (Math.floor(document.body.scrollTop) === 0);
};

TextualScroller.viewingBottom = function()
{
	var offsetHeight = Math.floor(document.body.offsetHeight);

	var scrollHeight = Math.floor(document.body.scrollHeight);
	var scrollTop = Math.floor(document.body.scrollTop);

	/* 7 is a fairly magical number subtracted from lastFrame to account
	 for very slight scrolling that may occur with a TrackPad or other
	 sensitive scrolling device. A line in the Tomorrow Night style is
	 15 pixels so we are basically saying as long as we are within half
	 a message of the bottom, we are actually at the bottom. */
	return ((scrollTop + 7) >= (scrollHeight - offsetHeight));
};

document.addEventListener("scroll", TextualScroller.documentScrolledCallback, false);
