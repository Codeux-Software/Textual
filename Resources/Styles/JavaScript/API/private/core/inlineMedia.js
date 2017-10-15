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

/* ************************************************** */
/*              Document Prototypes                   */
/* ************************************************** */

HTMLDocument.prototype.getInlineMediaById = function(mediaId) /* PUBLIC */
{
	if (mediaId.indexOf("inlineMedia-") !== 0) {
		mediaId = ("inlineMedia-" + mediaId);
	}
	
	return this.getElementById(mediaId);
};

HTMLDocument.prototype.getInlineMediaAnchorById = function(mediaId) /* PUBLIC */
{
	return document.body.querySelector("a[inlineanchor=\"" + mediaId + "\"]");
};

/* ************************************************** */
/*                 Media Prototype                    */
/* ************************************************** */

var InlineMediaPrototype = function() {

};

InlineMediaPrototype.prototype._isSubclass = function()
{
	return (Object.getPrototypeOf(this) !== InlineMediaPrototype.prototype);
};

InlineMediaPrototype.prototype.showOnClick = function(mediaId) /* PUBLIC */
{
	this.show(mediaId);
	
	return false; // Do not perform navigation
};

InlineMediaPrototype.prototype.hideOnClick = function(mediaId) /* PUBLIC */
{
	this.hide(mediaId);
	
	return false; // Do not perform navigation
};

InlineMediaPrototype.prototype.toggleOnClick = function(mediaId) /* PUBLIC */
{
	if (this.isSafeToPerformToggle() === false) {
		console.log("Cancelled toggling inline media because of isSafeToPerformToggle() condition.");
		
		return true; // Perform navigation
	}
	
	this.toggle(mediaId);
	
	return false; // Do not perform navigation
};

InlineMediaPrototype.prototype.showPayload = function(payload) /* PUBLIC */
{
	this.show(payload.uniqueIdentifier);
};
 
InlineMediaPrototype.prototype.show = function(mediaId) /* PUBLIC */
{
	this._setDisplay(mediaId, "show");
};

InlineMediaPrototype.prototype.hidePayload = function(payload) /* PUBLIC */
{
	this.hide(payload.uniqueIdentifier);
};

InlineMediaPrototype.prototype.hide = function(mediaId) /* PUBLIC */
{
	this._setDisplay(mediaId, "hide");
};

InlineMediaPrototype.prototype.togglePayload = function(payload) /* PUBLIC */
{
	this.toggle(payload.uniqueIdentifier);
};

InlineMediaPrototype.prototype.toggle = function(mediaId) /* PUBLIC */
{
	this._setDisplay(mediaId, "toggle");
};

InlineMediaPrototype.prototype._setDisplay = function(mediaId, display) /* PRIVATE */
{
	var element = document.getInlineMediaById(mediaId);

	if (!element) {
		console.error("Failed to find inline media element that matches ID: " + mediaId);

		return false;
	}
	
	var displayNone;
	
	if (display === "hide") {
		displayNone = true;
	} else if (display === "show") {
		displayNone = false;
	} else {
		displayNone = (element.style.display !== "none");
	}

	if (displayNone) 
	{
		/* Hide element */
		if (this.willHideElement(element, mediaId) === false) {
			return;
		}

		element.style.display = "none";
		
		this.didHideElement(element, mediaId);
	} 
	else 
	{
		/* Show element */
		if (this.willShowElement(element, mediaId) === false) {
			return;
		}
		
		element.style.display = "";
		
		this.didShowElement(element, mediaId);
	}
};

InlineMediaPrototype.prototype.isSafeToPerformToggle = function() /* PUBLIC */
{
	/* This logic is placed in a function to leave room for expansion. */

	return (window.event.shiftKey === true);
};

InlineMediaPrototype.prototype.willShowElement = function(element, mediaId) /* PUBLIC */
{
	element.prepareForMutation();

	return true;
};

InlineMediaPrototype.prototype.didShowElement = function(element, mediaId) /* PUBLIC */
{

};

InlineMediaPrototype.prototype.willHideElement = function(element, mediaId) /* PUBLIC */
{
	element.prepareForMutation();

	return true;
};

InlineMediaPrototype.prototype.didHideElement = function(element, mediaId) /* PUBLIC */
{

};

InlineMediaPrototype.prototype.replaceAnchorOnclickCallbackForPayload = function(payload) /* PUBLIC */
{
	this.replaceAnchorOnclickCallback(payload.uniqueIdentifier);
};

InlineMediaPrototype.prototype.replaceAnchorOnclickCallback = function(mediaId) /* PUBLIC */
{
	var anchor = document.getInlineMediaAnchorById(mediaId);
	
	if (!anchor) {
		console.error("Failed to find inline media anchor that matches ID: " + mediaId);

		return;
	}
	
	anchor.onclick = (function() {
		return this.toggleOnClick(mediaId);
	}).bind(this);
};

InlineMediaPrototype.prototype.entrypoint = function(payload, insertHTMLCallback)
{
	document.prepareForMutation();
	
	insertHTMLCallback(payload.html);
	
	if (this._isSubclass()) {
		this.replaceAnchorOnclickCallbackForPayload(payload);
	}
};

/* ************************************************** */
/*                Media Public Interface              */
/* ************************************************** */

var InlineMedia = Object.create(InlineMediaPrototype.prototype);

/* ************************************************** */
/*                Media Private Interface             */
/* ************************************************** */

var _InlineMedia = {};

_InlineMedia._loadedStyleResources = new Array(); /* PRIVATE */
_InlineMedia._loadedScriptResources = new Array(); /* PRIVATE */

_InlineMedia.processPayload = function(payload) /* PRIVATE */
{
	/* Load CSS resources */
	var styleResources = payload.styleResources;

	if (Array.isArray(styleResources)) {
		for (var i = 0; i < styleResources.length; i++) {
			var file = styleResources[i];
			
			if (_InlineMedia._loadedStyleResources.indexOf(file) < 0) {
				_InlineMedia._loadedStyleResources.push(file);
				
				Textual.includeStyleResourceFile(file);
			}
		}
	}

	/* Load JavaScript resources */
	var scriptResources = payload.scriptResources;

	if (Array.isArray(scriptResources)) {
		for (var i = 0; i < scriptResources.length; i++) {
			var file = scriptResources[i];
			
			if (_InlineMedia._loadedScriptResources.indexOf(file) < 0) {
				_InlineMedia._loadedScriptResources.push(file);
				
				Textual.includeScriptResourceFile(file);
			}
		}
	}

	/* Insert HTML */
	var entrypoint = payload.entrypoint;
	
	if (typeof entrypoint === "string" && entrypoint.length > 0) {
		_InlineMedia.processPayloadWithEntrypoint(payload);
	} else {
		_InlineMedia.processPayloadWithoutEntrypoint(payload);
	}
};

_InlineMedia.processPayloadWithoutEntrypoint = function(payload) /* PRIVATE */
{
	_InlineMedia.insertPayload(
		payload.lineNumber, 
		payload.html,
		payload.index, 
		true
	);
};

_InlineMedia.processPayloadWithEntrypoint = function(payload) /* PRIVATE */
{
	var insertHTML = (function(html) {
		/* The entrypoint is expeted to call prepareForMutation() for us. */
		_InlineMedia.insertPayload(
			payload.lineNumber, 
			html, 
			payload.index,
			false);
	});

	var callToEntrypoint = (function(i) {
		try {
			var entrypoint = window[payload.entrypoint];
		} catch (error) {
			
		}

		/* If the entrypoint exists as a function already, 
		 then we call out to it and exit. */
		if (typeof entrypoint === "object") {
			entrypoint.entrypoint(payload.entrypointPayload, insertHTML);
			
			return;
		}
		
		/* If the entrypoint does not exist as a function yet,
		 then we loop this function several times until it is
		 one (script resource is loading), or until we exhaust
		 the tries we are willing to take. */
		if (i === 20) { // 2 seconds
			console.error("Failed to process payload because entrypoint is not an object.");
			
			return;
		}
		
		setTimeout((function() {
			callToEntrypoint(i + 1);
		}), 100);
	});
	
	callToEntrypoint(0);
};

_InlineMedia.insertPayload = function(lineNumber, html, index, prepareForMutation) /* PRIVATE */
{
	var line = document.getElementByLineNumber(lineNumber);
	
	if (!line) {
		console.error("Failed to find line that matches ID: " + lineNumber);

		return;
	}

	var mediaContainer = line.querySelector(".inlineMediaContainer");

	if (mediaContainer) 
	{
		if (prepareForMutation) {
			mediaContainer.prepareForMutation();
		}
		
		/* Given index of this item, find item before that index
		to insert the HTML at, or insert at end of container. */
		if (index === 0) {
			/* Insert at beginning */
			mediaContainer.insertAdjacentHTML("afterbegin", html);
		} else {
			var childIndex = (index - 1);
			var childNode = null;
			var childNodes = mediaContainer.children;
	
			if (childNodes.length > childIndex) {
				childNode = childNodes[childIndex];
			}
	
			if (childNode) {
				childNode.insertAdjacentHTML("afterend", html);
				
				return;
			}
		
			/* Insert at end */
			mediaContainer.insertAdjacentHTML("beforeend", html)
		}
	} 
	else // mediaContainer
	{
		console.warning("The template for this style appears to be missing a span with the class" +
						"'inlineMediaContainer' — please fix this to support inline media.");
	}
};
