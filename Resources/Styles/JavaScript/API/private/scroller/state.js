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

var TextualScroller = {};
var _TextualScroller = {};

/* ************************************************** */
/*                   State Tracking                   */
/* ************************************************** */

/* Minimum distance from bottom to be scrolled upwards
before TextualScroller.scrolledAboveBottom is true. */
_TextualScroller.scrolledAboveBottomMinimum = 25; /* PRIVATE */

/* Position at which TextualScroller.scrolledAboveBottom
became true so once we scroll past it, going downward,
we can set the value back to false. */
_TextualScroller.scrolledAboveBottomThreshold = 0; /* PRIVATE */

/* Whether or not we are scrolled above the bottom. */
TextualScroller.scrolledAboveBottom = false; /* PUBLIC */

/* Set to true when scrolled upwards. */
TextualScroller.scrolledUpwards = false; /* PUBLIC */

/* Cached scroll position */
TextualScroller.scrollPositionCurrentValue = 0; /* PUBLIC */
TextualScroller.scrollPositionPreviousValue = 0; /* PUBLIC */

/* Cached scroll height */
TextualScroller.scrollHeightCurrentValue = 0; /* PUBLIC */
TextualScroller.scrollHeightPreviousValue = 0; /* PUBLIC */

_TextualScroller.documentScrolledCallback = function() /* PRIVATE */
{
	/* Height of scrollabe area */
	var scrollHeight = document.body.scrollHeight;

	TextualScroller.scrollHeightPreviousValue = TextualScroller.scrollHeightCurrentValue;

	TextualScroller.scrollHeightCurrentValue = scrollHeight;

	/* The current position scrolled to */
	var clientHeight = document.body.clientHeight;

	var scrollPosition = (document.body.scrollTop + clientHeight);

	if (scrollPosition < clientHeight ||
		scrollPosition > scrollHeight) 
	{
		return; // Ignore elastic scrolling
	}
	
	var scrolledUpwards = false;

	/* 	Record the last two known scrollY values. These properties are compared
		to determine if the user is scrolling upwards or downwards. */
	TextualScroller.scrollPositionPreviousValue = TextualScroller.scrollPositionCurrentValue;

	TextualScroller.scrollPositionCurrentValue = scrollPosition;

	/* 	If the current threshold exceeds the view height, then it means
		that some lines were probably removed to enforce size limit. */
	/* 	Reset the value to be the absolute bottom when this occurs. */
	if (_TextualScroller.scrolledAboveBottomThreshold > scrollHeight) {
		_TextualScroller.scrolledAboveBottomThreshold = scrollHeight;

		if (_TextualScroller.scrolledAboveBottomThreshold < 0) {
			_TextualScroller.scrolledAboveBottomThreshold = 0;
		}
	}

	if (TextualScroller.scrolledAboveBottom) {
		/* Check whether the user has scrolled back to the bottom. */
		var scrollTop = (scrollHeight - TextualScroller.scrollPositionCurrentValue);

		if (scrollTop < _TextualScroller.scrolledAboveBottomMinimum) {
			TextualScroller.scrolledAboveBottom = false;

			_TextualScroller.scrolledAboveBottomThreshold = 
			TextualScroller.scrollPositionCurrentValue;
		}

		/* Check whether user is scrolling upwards. */
		if (TextualScroller.scrollPositionCurrentValue < 
			TextualScroller.scrollPositionPreviousValue) 
		{
			scrolledUpwards = true;
		}
	}
	else
	{
		/* 	Check if the user is scrolling upwards. If they are, then check if they have went
			above the threshold that defines whether its a user initated event or not. */
		if (TextualScroller.scrollPositionCurrentValue < 
			TextualScroller.scrollPositionPreviousValue) 
		{
			var scrollTop = (_TextualScroller.scrolledAboveBottomThreshold - 
							 TextualScroller.scrollPositionCurrentValue);

			if (scrollTop > _TextualScroller.scrolledAboveBottomMinimum) {
				TextualScroller.scrolledAboveBottom = true;
			}

			scrolledUpwards = true;
		}

		/* 	If the user is scrolling downward and passes last threshold location, then
			move the location further downward. */
		if (TextualScroller.scrollPositionCurrentValue > 
			_TextualScroller.scrolledAboveBottomThreshold) 
		{
			_TextualScroller.scrolledAboveBottomThreshold = 
			TextualScroller.scrollPositionCurrentValue;
		}
	}
	
	/* Record direction we are scrolling */
	if (scrolledUpwards) {
		document.dispatchEvent(new Event('scrolledUpward'));
	} else {
		document.dispatchEvent(new Event('scrolledDownward'));
	}

	TextualScroller.scrolledUpwards = scrolledUpwards;
};

/* ************************************************** */
/*               Position Restore                     */
/* ************************************************** */

_TextualScroller.restoreScrolledUpwards = undefined; /* PRIVATE */
_TextualScroller.restoreScrollHeightFirstValue = undefined; /* PRIVATE */
_TextualScroller.restoreScrollHeightSecondValue = undefined; /* PRIVATE */

TextualScroller.saveRestorationFirstDataPoint = function() /* PUBLIC */
{
	_TextualScroller.restoreScrolledUpwards = TextualScroller.scrolledUpwards;

	_TextualScroller.restoreScrollHeightFirstValue = document.body.scrollHeight;
};

TextualScroller.saveRestorationSecondDataPoint = function() /* PUBLIC */
{
	_TextualScroller.restoreScrollHeightSecondValue = document.body.scrollHeight;
};

TextualScroller.restoreScrollPosition = function() /* PUBLIC */
{
	var scrollHeightDifference = (_TextualScroller.restoreScrollHeightSecondValue - 
								  _TextualScroller.restoreScrollHeightFirstValue);
	
	if (scrollHeightDifference === 0) {
		return;
	}
	
	if (_TextualScroller.restoreScrolledUpwards === false) {
		var scrollTo = (document.body.scrollHeight - scrollHeightDifference);
	} else {
		var scrollTo = (document.body.scrollHeight + scrollHeightDifference);
	}

	if (scrollTo < 0) {
		scrollTo = 0;
	}

	document.body.scrollTop = scrollTo;

	_TextualScroller.restoreScrollHeightFirstValue = undefined;
	_TextualScroller.restoreScrollHeightSecondValue = undefined;
	
	_TextualScroller.restoreScrolledUpwards = undefined;
};

/* Element prototypes */
Element.prototype.scrollToCenter = function() /* PUBLIC */
{
	var elementRect = this.getBoundingClientRect();
	var elementTop = (elementRect.top + window.scrollY);
	var elementCenter = (elementTop - (window.innerHeight / 2));

	window.scrollTo(0, elementCenter);
};

Element.prototype.percentScrolled = function() /* PUBLIC */
{
	return (((this.scrollTop + this.clientHeight) / this.scrollHeight) * 100.0);
}

Element.prototype.isScrolledToTop = function() /* PUBLIC */
{
	return (this.scrollTop <= 0);
};

Element.prototype.scrollToTop = function() /* PUBLIC */
{
	this.scrollTop = 0;
};

Element.prototype.isScrolledToBottom = function() /* PUBLIC */
{
	return ((this.scrollTop + this.clientHeight) >= this.scrollHeight);
};

Element.prototype.scrollToBottom = function() /* PUBLIC */
{
	this.scrollTop = this.scrollHeight;	
};

/* Element prototype proxy */
TextualScroller.scrollElementToCenter = function(element) /* PUBLIC */
{
	element.scrollToCenter();
};

TextualScroller.percentScrolled = function() /* PUBLIC */
{
	return document.body.percentScrolled();
};

TextualScroller.isScrolledToTop = function() /* PUBLIC */
{
	return document.body.isScrolledToTop();
};

TextualScroller.scrollToTop = function() /* PUBLIC */
{
	document.body.scrollToTop();
};

TextualScroller.isScrolledToBottom = function() /* PUBLIC */
{
	return document.body.isScrolledToBottom();
};

TextualScroller.scrollToBottom = function() /* PUBLIC */
{
	document.body.scrollToBottom();	
};

/* Bind to events */
document.addEventListener("scroll", _TextualScroller.documentScrolledCallback, false);
