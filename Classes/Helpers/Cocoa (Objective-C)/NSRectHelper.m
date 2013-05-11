/* ********************************************************************* 
       _____        _               _    ___ ____   ____
      |_   _|___  _| |_ _   _  __ _| |  |_ _|  _ \ / ___|
       | |/ _ \ \/ / __| | | |/ _` | |   | || |_) | |
       | |  __/>  <| |_| |_| | (_| | |   | ||  _ <| |___
       |_|\___/_/\_\\__|\__,_|\__,_|_|  |___|_| \_\\____|

 Copyright (c) 2010 — 2013 Codeux Software & respective contributors.
        Please see Contributors.pdf and Acknowledgements.pdf

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of the Textual IRC Client & Codeux Software nor the
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

#import "TextualApplication.h"

NSPoint NSRectCenter(NSRect rect)
{
	return NSMakePoint((rect.origin.x + (rect.size.width / 2)), 
					   (rect.origin.y + (rect.size.height / 2)));
}

NSRect NSRectAdjustInRect(NSRect r, NSRect bounds)
{
	if (NSMaxX(bounds) < NSMaxX(r)) {
		r.origin.x = (NSMaxX(bounds) - r.size.width);
	}
	
	if (NSMaxY(bounds) < NSMaxY(r)) {
		r.origin.y = (NSMaxY(bounds) - r.size.height);
	}
	
	if (r.origin.x < bounds.origin.x) {
		r.origin.x = bounds.origin.x;
	}
	
	if (r.origin.y < bounds.origin.y) {
		r.origin.y = bounds.origin.y;
	}
	
	return r;
}

/* Make a rectangle that'll fit in the screen... because sometimes the stored
 rect is stupid and makes the window practically invisible. */
NSRect NSMakeRectThatFitsMainScreen(CGFloat x, CGFloat y, CGFloat w, CGFloat h)
{
	NSRect usable = [RZMainScreen() visibleFrame];
	
	NSSize minimum = [TPCPreferences minimumWindowSize];

	if (w < minimum.width) {
		w = minimum.width;
	}

	if (h < minimum.height) {
		h = minimum.height;
	}

	if (x < usable.origin.x) {
		x = usable.origin.x;
	} else if (x > (usable.size.width - w)) {
		x = usable.size.width - w;
	}

	if (y < usable.origin.y) {
		y = usable.origin.y;
	} else if (y > (usable.size.height - h)) {
		y = usable.size.height - h;
	}

	return NSMakeRect(x, y, w, h);
}

NSRect NSMakeRectFitMainScreen(NSRect rect)
{
	return NSMakeRectThatFitsMainScreen(rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);
}
