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
/*                     Visibility                     */
/* ************************************************** */

TextualScroller.documentIsVisible = false;

TextualScroller.documentVisbilityChangedCallback = function()
{
	var documentHidden = false;

	if (typeof document.hidden !== "undefined") {
		documentHidden = document.hidden;
	} else if (typeof document.webkitHidden !== "undefined") {
		documentHidden = document.webkitHidden;
	}

	if (documentHidden) {
		TextualScroller.documentIsVisible = false;
	} else {
		TextualScroller.documentIsVisible = true;
	}
};

TextualScroller.documentResizedCallback = function()
{
	TextualScroller.performAutomaticScroll();
};

/* ************************************************** */
/*                 Automatic Scroller                 */
/* ************************************************** */

TextualScroller.automaticScrollingEnabled = true;

TextualScroller.performAutomaticScrollTimeout = null;

TextualScroller.performAutomaticScroll = function()
{
	if (TextualScroller.performAutomaticScrollTimeout) {
		return;
	}
	
	var performAutomaticScroll = (function() {
		TextualScroller.performAutomaticScrollInt();
		
		TextualScroller.performAutomaticScrollTimeout = null;
	});
	
	TextualScroller.performAutomaticScrollTimeout = 
	setTimeout(performAutomaticScroll, 0);
}

TextualScroller.performAutomaticScrollInt = function()
{	
	/* Do not perform automatic scroll if is disabled. */
	if (TextualScroller.automaticScrollingEnabled === false) {
		return;
	}
	
	/* Do not perform automatic scroll if the document is not visible. */
	if (TextualScroller.documentIsVisible === false) {
		return;
	}
	
	/* Do not perform automatic scroll if we weren't at bottom. */
	if (TextualScroller.scrolledAboveBottom) {
		return;
	}
	
	/* Do not perform scrolling if we are performing live resize. */
	/* Stop auto scroll before height is recorded so that once live resize is completed,
	scrolling will notice the new height of the view and use that. */
	if (Textual.hasLiveResize()) {
		if (InlineImageLiveResize.dragElement) {
			return;
		}
	}

	/* Scroll to bottom */
	TextualScroller.scrollToBottom();
};

/* This function sets a flag that tells the scroller not to do anything,
regardless of whether it is visible or not. Visbility will control whether
the timer itself is activate, not this function. */
TextualScroller.setAutomaticScrollingEnabled = function(enabled)
{
	TextualScroller.automaticScrollingEnabled = enabled;
};

/* ************************************************** */
/*                 Mutation Observer                  */
/* ************************************************** */

TextualScroller.mutationObserver = null;

TextualScroller.mutationObserverCallback = function(mutations)
{
	TextualScroller.performAutomaticScroll();
};

TextualScroller.createMutationObserver = function()
{
	var buffer = MessageBuffer.bufferElement();
	
	var observer = new MutationObserver(TextualScroller.mutationObserverCallback);
	
	observer.observe(
		buffer, 

		{
			childList: true,
			attributes: true,
			subtree: true
		}
	);

	TextualScroller.mutationObserver = observer;
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
