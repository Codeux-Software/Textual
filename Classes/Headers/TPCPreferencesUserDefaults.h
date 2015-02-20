/* ********************************************************************* 
                  _____         _               _
                 |_   _|____  _| |_ _   _  __ _| |
                   | |/ _ \ \/ / __| | | |/ _` | |
                   | |  __/>  <| |_| |_| | (_| | |
                   |_|\___/_/\_\\__|\__,_|\__,_|_|

 Copyright (c) 2010 - 2015 Codeux Software, LLC & respective contributors.
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

#define RZUserDefaults()						[TPCPreferencesUserDefaults sharedUserDefaults]
#define RZUserDefaultsController()				[TPCPreferencesUserDefaultsController sharedUserDefaultsController]

/* The user info dictionary of this notification contains the changed key. */
TEXTUAL_EXTERN NSString * const TPCPreferencesUserDefaultsDidChangeNotification;

/* TPCPreferencesUserDefaults subclasses NSUserDefaults to allow Textual to fire off
 notifications for changed keys on a per-key basis so that the iCloud controller can
 know what keys change instead of having to sync every single key, every time that it
 performs an upstream sync. */
@interface TPCPreferencesUserDefaults : NSUserDefaults
+ (TPCPreferencesUserDefaults *)sharedUserDefaults;

- (void)setColor:(NSColor *)color forKey:(NSString *)defaultName;

- (NSColor *)colorForKey:(NSString *)defaultName;

+ (BOOL)keyIsExcludedFromBeingExported:(NSString *)key;

/* Do not call the following method from a plugin. */
+ (void)migrateValuesToGroupContainer;
@end

/* Trying to create a new instance of TPCPreferencesUserDefaultsController will
 return the value of +sharedUserDefaultsController */
@interface TPCPreferencesUserDefaultsController : NSUserDefaultsController
+ (TPCPreferencesUserDefaultsController *)sharedUserDefaultsController;
@end

/* The following class is no longer used and is considered dangerous to use. */
#define RZUserDefaultsValueProxy()				[TPCPreferencesUserDefaultsObjectProxy userDefaultValues]

TEXTUAL_DEPRECATED("Use NSUserDefaultsController instead")
@interface TPCPreferencesUserDefaultsObjectProxy : NSObject
+ (id)userDefaultValues;
+ (id)localDefaultValues;
@end
