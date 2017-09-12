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

"use strict";

/* ************************************************** */
/*                                                    */
/* DO NOT OVERRIDE ANYTHING BELOW THIS LINE           */
/*                                                    */
/* ************************************************** */

/* Inline media */
Textual.hasLiveResize = function()
{
	if (typeof InlineImageLiveResize !== 'undefined') {
		return true;
	} else {
		return false;
	}
};

Textual.toggleInlineImage = function(object, onlyPerformForShiftKey)
{
	/* We only want certain actions to happen for shift key. */
	if (onlyPerformForShiftKey) {
		if (window.event.shiftKey === false) {
			return true;
		}
	}

	/* toggleInlineImage() is called when an onclick event is thrown on the associated
	link anchor of an inline image. If the last mouse down event was related to a resize,
	then we return false to stop link from opening. Else, we pass the event information
	to the internals of Textual itself to determine whether to cancel the request. */
	if (Textual.hasLiveResize()) {
		if (InlineImageLiveResize.previousMouseActionWasForResizing === false) {
			_Textual.toggleInlineImageVisibility(object);
		}
	} else {
		_Textual.toggleInlineImageVisibility(object);
	}

	return false;
};

_Textual.toggleInlineImageVisibility = function(object)
{
	if (object.indexOf("inlineImage-") !== 0) {
		object = ("inlineImage-" + object);
	}

	var imageContainer = document.getElementById(object);

	/* If the image is not hidden, then we make it so and finish. */
	var hidden = (imageContainer.style.display === "none");
	
	if (hidden === false) {
		imageContainer.prepareForMutation();

		imageContainer.style.display = "none";
		
		_Textual.didToggleInlineImageToHidden(imageContainer, imageElement);
		
		return;
	}
	
	/* If the image is not already loaded, then we observe 
	changes to that so that we only reveal once it is. */
	var imageElement = imageContainer.querySelector("a .image");

	var complete = imageElement.complete;
	
	if (complete === false) {
		if (imageContainer.hasAttribute("wants-reveal")) {
			return;
		}
	}
	
	var completeCallback = (function() {
		/* It is important that we reveal the inline image immediately
		after preparing the scroller for mutation. If we do not, then 
		the mutation will be swallowed without changing the height. */
		imageContainer.prepareForMutation();

		imageContainer.style.display = "";
		
		imageContainer.removeAttribute("wants-reveal");
		
		_Textual.didToggleInlineImageToVisible(imageContainer, imageElement);
	});
	
	if (complete === false) {
		imageContainer.setAttribute("wants-reveal", "true");

		imageElement.addEventListener("load", { handleEvent: completeCallback }, false);
	} else {
		completeCallback();
	}
};

_Textual.didToggleInlineImageToHidden = function(imageContainer, imageElement)
{
	Textual.didToggleInlineImageToHidden(imageContainer);
};

_Textual.didToggleInlineImageToVisible = function(imageContainer, imageElement)
{
	if (Textual.hasLiveResize()) {
		imageElement.addEventListener("mousedown", InlineImageLiveResize.onMouseDown, false);
	}

	Textual.didToggleInlineImageToVisible(imageContainer);
};

Textual.didToggleInlineImageToHidden = function(imageContainer)
{
	/* Do something here? */
};

Textual.didToggleInlineImageToVisible = function(imageContainer)
{
	/* Do something here? */
};
