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

/* ************************************************** */
/*                  State Tracking                    */
/* ************************************************** */

TextualScroller.scrollHeightTimerActive = false;

TextualScroller.automaticScrollHeightCurrentValue = 0;
TextualScroller.automaticScrollHeightPreviousValue = 0;

TextualScroller.scrollerAnchorLinkReference = null;

TextualScroller.automaticScrollingEnabled = false;

/* ************************************************** */
/*                     Visibility                     */
/* ************************************************** */

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

/* ************************************************** */
/*                 Automatic Scroller                 */
/* ************************************************** */

TextualScroller.performAutoScroll = function()
{
	var performAutoScrollFunction = (function() {
		TextualScroller.performAutoScrollInt(false);

		if (TextualScroller.scrollHeightTimerActive) {
			 TextualScroller.performAutoScroll();
		}
	});

//	if (typeof window.requestAnimationFrame === "undefined") {
	setTimeout(performAutoScrollFunction, 50);
//	} else {
//		requestAnimationFrame(performAutoScrollFunction);
//	}
};

TextualScroller.performAutoScrollInt = function(skipScrollHeightCheck)
{
	/* Set default value of argument */
	if (typeof skipScrollHeightCheck === "undefined") {
		skipScrollHeightCheck = false;
	}

	/* Do not perform scrolling if the user is believed to have scrolled */
	if (TextualScroller.scrolledAboveBottom) {
		return;
	}
	
	/* Do not perform scrolling if it is disabled */
	if (TextualScroller.automaticScrollingEnabled) {
		return;
	}

	/* Do not perform scrolling if we are performing live resize */
	/* 	Stop auto scroll before height is recorded so that once live resize is completed,
		scrolling will notice the new height of the view and use that. */
	if (Textual.hasLiveResize()) {
		if (InlineImageLiveResize.dragElement) {
			return;
		}
	}

	/* 	Retrieve the current scroll height and return if it is zero */
	var scrollHeight = TextualScroller.scrollHeight();

	if (scrollHeight === 0) {
		return;
	}

	var scrollHeightPrevious = TextualScroller.automaticScrollHeightCurrentValue;

	/* Perform comparison test for scroll height */
	if (skipScrollHeightCheck === false) {
		if (scrollHeight === scrollHeightPrevious) {
			return;
		}
	}

	/* Make a copy of the previous scroll height and save the new */
	TextualScroller.automaticScrollHeightPreviousValue = scrollHeightPrevious;

	TextualScroller.automaticScrollHeightCurrentValue = scrollHeight;

	/* Scroll to new value */
	if (TextualScroller.scrollerAnchorLinkReference === null) {
		TextualScroller.scrollerAnchorLinkReference = document.getElementById("most_recent_anchor");
	}

	TextualScroller.scrollerAnchorLinkReference.click();
};

/* This function sets a flag that tells the scroller not to do anything,
regardless of whether it is visible or not. Visbility will control whether
the timer itself is activate, not this function. */
TextualScroller.setAutomaticScrollingEnabled = function(enabled)
{
	TextualScroller.automaticScrollingEnabled = enabled;
};

/* ************************************************** */
/*                        Timer                       */
/* ************************************************** */

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

/* ************************************************** */
/*                      Events                        */
/* ************************************************** */

window.addEventListener("resize", TextualScroller.documentResizedCallback, false);

if (typeof document.hidden !== "undefined") {
	document.addEventListener("visibilitychange", TextualScroller.documentVisbilityChangedCallback, false);
} else if (typeof document.webkitHidden !== "undefined") {
	document.addEventListener("webkitvisibilitychange", TextualScroller.documentVisbilityChangedCallback, false);
}

/* Populate initial visiblity state and maybe create timer */
TextualScroller.documentVisbilityChangedCallback();
