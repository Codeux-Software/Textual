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

var _ICMYouTube = {};

_ICMYouTube.entrypoint = function(payload, callbackFunction) /* PRIVATE */
{
	/* Prepare scroller */
	document.body.prepareForMutation();
	
	/* Insert HTML */
	callbackFunction(payload.html);
	
	/* Replace onclick event for anchor link to point to custom .toggle() */
	_ICMYouTube.replaceOnclickEventForPayload(payload);
};

/* _ICMYouTube has its own implementation of .toggleOnClick() so that the 
video can be automatically paused when hidden. */
_ICMYouTube.replaceOnclickEventForPayload = function(payload) /* PRIVATE */
{
	var mediaId = payload.uniqueIdentifier;

	var anchor = document.querySelector("a[inlineanchor=\"" + mediaId + "\"]");
	
	if (!anchor) {
		console.error("Failed to find inline media anchor that matches ID: " + mediaId);

		return;
	}
	
	anchor.onclick = (function() {
		return _ICMYouTube.toggleOnClick(mediaId);
	});
};

/* ************************************************** */
/*                    Visibility                      */
/* ************************************************** */

_ICMYouTube.toggleOnClick = function(mediaId) /* PRIVATE */
{
	if (InlineMedia.isSafeToPerformToggle() === false) {
		return true;
	}
	
	_ICMYouTube.toggle(mediaId);
	
	return false;
};

_ICMYouTube.toggle = function(mediaId) /* PRIVATE */
{
	var videoContainer = document.getInlineMediaById(mediaId);

	if (!videoContainer) {
		console.error("Failed to find inline media element that matches ID: " + mediaId);

		return;
	}
	
	/* Prepare for mutation */
	videoContainer.prepareForMutation();
	
	/* Toggle video visible */
	/* It is possible to play video here if it was paused when
	hidden by the user, but that might catch the user off guard. */
	if (videoContainer.style.display === "none") {
		videoContainer.style.display = "";
		
		return;
	}
	
	/* Toggle video hidden */
	videoContainer.style.display = "none";
	
	/* Send message to iframe to pause video. */
	var videoIframe = videoContainer.getElementsByTagName("iframe")[0].contentWindow;
	
	var postMessagePayload = {
		"event" : "command",
		"func" : "pauseVideo",
		"args" : ""	
	};
	
	videoIframe.postMessage(JSON.stringify(postMessagePayload), "*");
};
