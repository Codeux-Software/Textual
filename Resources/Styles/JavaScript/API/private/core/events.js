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

Textual.viewBodyDidLoadIntAnimationFrame = null;

/* State management */
Textual.notifyDidBecomeVisible = function()
{
	Textual.clearSelection();
};

Textual.notifyDidBecomeHidden = function()
{
	Textual.clearSelection();

	Textual.setHistoricMessagesTransitionEnabled(false);
};

Textual.notifySelectionChanged = function(isSelected)
{
	Textual.setTopicBarVisible(isSelected);

	Textual.setDocumentBodyPointerEventsEnabled(isSelected);
};

Textual.viewBodyDidLoadInt = function()
{
	/* On styles with a dark background, a white flash occurs because there is a very
	 small delay between the view being created and the background process laying out
	 its contents. To work around this, Textual presents an overlay view that matches
	 the background color of the style. We then request an animation frame that calls
	 app.finishedLayingOutView), instructing Textual that it can destroy the overlay view. */

	if (appInternal.isWebKit2()) {
		Textual.viewBodyDidLoadIntAnimationFrame =
		window.requestAnimationFrame(function() {
			Textual.viewBodyDidLoadIntTimed();
		});
	} else {
		Textual.viewBodyDidLoadIntTimed();
	}
};

Textual.viewBodyDidLoadIntTimed = function()
{
	app.finishedLayingOutView();

	Textual.viewBodyDidLoad();
};

Textual.viewFinishedLoadingInt = function(configuration)
{
	var isSelected = configuration.selected;
	var isVisible = configuration.visible;
	var isReloadingTheme = configuration.reloadingTheme;
	var textSizeMultiplier = configuration.textSizeMultiplier;
	var scrollbackLimit = configuration.scrollbackLimit;
	
	if (isVisible) {
		Textual.notifyDidBecomeVisible();
	
		if (isSelected) {
			Textual.notifySelectionChanged(true);
		} else {
			Textual.notifySelectionChanged(false);
		}
	}
	
	if (isReloadingTheme) {
		Textual.viewFinishedReload();
	} else {
		Textual.viewFinishedLoading();
	}

	/* If this view is not visible to the user, then cancel the animation
	 frame set by Textual.viewBodyDidLoadInt() because there is no use for it. */
	if (isVisible === false && isSelected === false) {
		if (Textual.viewBodyDidLoadIntAnimationFrame !== null) {
			window.cancelAnimationFrame(Textual.viewBodyDidLoadIntAnimationFrame);

			Textual.viewBodyDidLoadIntAnimationFrame = null;

			Textual.viewBodyDidLoadIntTimed();
		}
	}
	
	Textual.changeTextSizeMultiplier(textSizeMultiplier);
	
	if (scrollbackLimit !== 0) { // 0 = use default
		MessageBuffer.setBufferLimit(scrollbackLimit);
	}
};

Textual.viewFinishedLoadingHistoryInt = function()
{
	Textual.setHistoricMessagesLoaded(true);

	Textual.viewFinishedLoadingHistory();
};

Textual.messageAddedToViewInt = function(lineNumber, fromBuffer)
{
	var oldCallbackExists = (typeof Textual.newMessagePostedToView === "function");
	
	if (oldCallbackExists) {
		console.warn("Textual.newMessagePostedToView() is deprecated. Use Textual.messageAddedToView() instead.");
	}
	
	/* Allow lineNumber to be an array of line numbers or a single line number. */
	if (Array.isArray(lineNumber)) {
		for (var i = 0; i < lineNumber.length; i++) {
			if (oldCallbackExists) {
				Textual.newMessagePostedToView(lineNumber[i], fromBuffer);
			} else {
				Textual.messageAddedToView(lineNumber[i], fromBuffer);
			}
		}
	} else {
		if (oldCallbackExists) {
			Textual.newMessagePostedToView(lineNumber, fromBuffer);
		} else {
			Textual.messageAddedToView(lineNumber, fromBuffer);
		}
	}

	app.notifyLinesAddedToView(lineNumber);
};

Textual.messageRemovedFromViewInt = function(lineNumber)
{
	/* Allow lineNumber to be an array of line numbers or a single line number. */
	if (Array.isArray(lineNumber)) {
		for (var i = 0; i < lineNumber.length; i++) {
			Textual.messageRemovedFromView(lineNumber[i]);
		}
	} else {
		Textual.messageRemovedFromView(lineNumber);
	}

	app.notifyLinesRemovedFromView(lineNumber);
};

/* Events */
Textual.mouseUpEventCallback = function()
{
	Textual.copySelectionOnMouseUpEvent();
};

/* Bind to events */
document.addEventListener("mouseup", Textual.mouseUpEventCallback, false);
