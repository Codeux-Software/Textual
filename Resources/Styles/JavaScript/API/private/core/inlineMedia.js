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
			Textual.toggleInlineImageReally(object);
		}
	} else {
		Textual.toggleInlineImageReally(object);
	}

	return false;
};

Textual.toggleInlineImageReally = function(object)
{
	if (object.indexOf("inlineImage-") !== 0) {
		object = ("inlineImage-" + object);
	}

	var imageNode = document.getElementById(object);

	if (imageNode.style.display === "none") {
		imageNode.style.display = "";
	} else {
		imageNode.style.display = "none";
	}

	if (imageNode.style.display === "none") {
		Textual.didToggleInlineImageToHidden(imageNode);
	} else {
		Textual.didToggleInlineImageToVisible(imageNode);
	}
};

Textual.didToggleInlineImageToHidden = function(imageElement)
{
	/* Do something here? */
};

Textual.didToggleInlineImageToVisible = function(imageElement)
{
	/* Start monitoring events for this image. */
	if (Textual.hasLiveResize()) {
		var realImageElement = imageElement.querySelector("a .image");

		realImageElement.addEventListener("mousedown", InlineImageLiveResize.onMouseDown, false);
	}
};
