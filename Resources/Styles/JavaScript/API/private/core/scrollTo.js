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

/* Scrolling */
Textual.scrollToBottomOfView = function(fireNotification)
{
	var documentBody = Textual.documentBodyElement();

	if (documentBody === null) {
		return;
	}

	var lastChild = documentBody.lastChild;

	if (typeof lastChild.scrollIntoView === "function") {
		lastChild.scrollIntoView(false);

		if (fireNotification === false) {
			return;
		}
		
		Textual.viewPositionMovedToBottom();
	}
};

Textual.scrollToTopOfView = function(fireNotification)
{
	var documentBody = Textual.documentBodyElement();

	if (documentBody === null) {
		return;
	}

	var firstChild = documentBody.firstChild;

	if (typeof firstChild.scrollIntoView === "function") {
		firstChild.scrollIntoView(true);

		if (fireNotification === false) {
			return;
		}
		
		Textual.viewPositionMovedToTop();
	}
};

Textual.scrollToLine = function(lineNumber)
{
	Textual.jumpToLine(lineNumber);
};

Textual.jumpToLine = function(lineNumber)
{
	MessageBuffer.jumpToLine(
		lineNumber, 
		
		(function(success) {
			if (success) {
				Textual.viewPositionMovedToLine(lineNumber);
			}

			app.notifyJumpToLineCallback(lineNumber, success);
		})
	);
};

Textual.scrollToElement = function(elementName)
{
	var element = document.getElementById(elementName);

	if (element) {
		element.scrollIntoViewIfNeeded(true);

		return true;
	}
	
	return false;
};

Textual.scrollToHistoryIndicator = function()
{
	if (Textual.scrollToElement("mark")) {
		Textual.viewPositionModToHistoryIndicator();
	}
};
