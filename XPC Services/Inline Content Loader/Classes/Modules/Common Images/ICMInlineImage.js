/* ********************************************************************* 
                  _____         _               _
                 |_   _|____  _| |_ _   _  __ _| |
                   | |/ _ \ \/ / __| | | |/ _` | |
                   | |  __/>  <| |_| |_| | (_| | |
                   |_|\___/_/\_\\__|\__,_|\__,_|_|

 Copyright (c) 2010 - 2017 Codeux Software, LLC & respective contributors.
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

var _ICMInlineImage = {};

_ICMInlineImage.entrypoint = function(payload, callbackFunction) /* PRIVATE */
{
	/* Insert HTML */
	callbackFunction(payload.html);
	
	/* Replace onclick event for anchor link to point to custom .toggle() */
	_ICMInlineImage.replaceOnclickEventForPayload(payload);

	/* Wait until image has completely loaded before we toggle it's visbility. */
	_ICMInlineImage.togglePayload(payload);
};

/* ICMInlineImage has its own implementation of .toggleOnClick() so that the 
user isn't allowed to toggle the visiblity of an image until it finished loading. */
_ICMInlineImage.replaceOnclickEventForPayload = function(payload) /* PRIVATE */
{
	var mediaId = payload.uniqueIdentifier;

	var anchor = document.querySelector("a[inlineanchor=\"" + mediaId + "\"]");
	
	if (!anchor) {
		console.error("Failed to find inline media anchor that matches ID: " + mediaId);

		return;
	}
	
	anchor.onclick = (function() {
		return _ICMInlineImage.toggleOnClick(mediaId);
	});
};

/* ************************************************** */
/*                    Visibility                      */
/* ************************************************** */

_ICMInlineImage.toggleOnClick = function(mediaId) /* PRIVATE */
{
	if (InlineMedia.isSafeToPerformToggle() === false) {
		return true;
	}
	
	_ICMInlineImage.toggle(mediaId);
	
	return false;
};

_ICMInlineImage.togglePayload = function(payload) /* PRIVATE */
{
	_ICMInlineImage.toggle(payload.uniqueIdentifier);
};

_ICMInlineImage.toggle = function(mediaId) /* PRIVATE */
{
	var imageContainer = document.getInlineMediaById(mediaId);

	if (!imageContainer) {		
		console.error("Failed to find inline media element that matches ID: " + mediaId);

		return;
	}

	/* If the image is not hidden, then we make it so and finish. */
	var hidden = (imageContainer.style.display === "none");
	
	if (hidden === false) {
		imageContainer.prepareForMutation();

		imageContainer.style.display = "none";

		return;
	}

	/* If the image is not already loaded, then we observe 
	changes to that so that we only reveal once it is. */
	var imageElement = imageContainer.querySelector("a .image");

	var complete = imageElement.complete;
	
	if (complete === false) {
		/* Do not perform logic more than once. */
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
		
		imageElement.addEventListener("mousedown", InlineImageLiveResize.onMouseDown, false);
	});
	
	if (complete === false) {
		imageContainer.setAttribute("wants-reveal", "true");

		imageElement.addEventListener("load", { handleEvent: completeCallback }, false);
	} else {
		completeCallback();
	}
};
