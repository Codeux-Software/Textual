/* ********************************************************************* 
                  _____         _               _
                 |_   _|____  _| |_ _   _  __ _| |
                   | |/ _ \ \/ / __| | | |/ _` | |
                   | |  __/>  <| |_| |_| | (_| | |
                   |_|\___/_/\_\\__|\__,_|\__,_|_|

 Copyright (c) 2010 — 2014 Codeux Software, LLC & respective contributors.
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

#import "TextualApplication.h"

@interface TVCMemberListYosemiteUserInterface : TVCMemberListSharedUserInterface
@property (readonly) NSInteger cellRowHeight;

@property (readonly, copy) NSColor *normalCellTextColorForActiveWindow;
@property (readonly, copy) NSColor *normalCellTextColorForInactiveWindow;

@property (readonly, copy) NSColor *awayUserCellTextColorForActiveWindow;
@property (readonly, copy) NSColor *awayUserCellTextColorForInactiveWindow;

@property (readonly, copy) NSColor *selectedCellTextColorForActiveWindow;
@property (readonly, copy) NSColor *selectedCellTextColorForInactiveWindow;

@property (readonly, copy) NSColor *userMarkBadgeNormalTextColor;

@property (readonly, copy) NSColor *userMarkBadgeSelectedBackgroundColor;
@property (readonly, copy) NSColor *userMarkBadgeSelectedTextColor;

@property (readonly, copy) NSColor *rowSelectionColorForActiveWindow;
@property (readonly, copy) NSColor *rowSelectionColorForInactiveWindow;

@property (readonly, copy) NSColor *userMarkBadgeBackgroundColor;
@end

@interface TVCMemberListLightYosemiteUserInterface : TVCMemberListYosemiteUserInterface
@end

@interface TVCMemberListDarkYosemiteUserInterface : TVCMemberListYosemiteUserInterface
@end
