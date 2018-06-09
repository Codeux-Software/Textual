/* *********************************************************************
 *                  _____         _               _
 *                 |_   _|____  _| |_ _   _  __ _| |
 *                   | |/ _ \ \/ / __| | | |/ _` | |
 *                   | |  __/>  <| |_| |_| | (_| | |
 *                   |_|\___/_/\_\\__|\__,_|\__,_|_|
 *
 *    Copyright (c) 2018 Codeux Software, LLC & respective contributors.
 *       Please see Acknowledgements.pdf for additional information.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 *  * Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 *  * Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *  * Neither the name of Textual, "Codeux Software, LLC", nor the
 *    names of its contributors may be used to endorse or promote products
 *    derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 *
 *********************************************************************** */

NS_ASSUME_NONNULL_BEGIN

@interface TVCAppearance : NSObject
/* TVCListAppearance will take care of all the hard work such as
 inheritance and retina. You only need to specify "MavericksDark"
 for example, not "MavericksDarkRetina" */
- (nullable instancetype)initWithAppearanceNamed:(NSString *)appearanceName
										   atURL:(NSURL *)appearanceLocation
								forRetinaDisplay:(BOOL)forRetinaDisplay NS_DESIGNATED_INITIALIZER;

/* Top level group */
/* Nonnull until -flushAppearanceProperties is called. */
@property (readonly, copy, nullable) NSDictionary<NSString *, id> *appearanceProperties;

/* When a subclass finishes applying all appearance values to properties,
 it can flush the top level group which will cause it to disappear from
 memory, thus reducing overall memory use. */
- (void)flushAppearanceProperties;

/* Properties */
@property (readonly) BOOL isHighResolutionAppearance;

/* Accessors */
- (nullable NSColor *)colorForKey:(NSString *)key; // forActiveWindow = YES
- (nullable NSColor *)colorForKey:(NSString *)key forActiveWindow:(BOOL)forActiveWindow;
- (nullable NSColor *)colorInGroup:(NSDictionary<NSString *, id> *)group withKey:(NSString *)key; // forActiveWindow = YES
- (nullable NSColor *)colorInGroup:(NSDictionary<NSString *, id> *)group withKey:(NSString *)key forActiveWindow:(BOOL)forActiveWindow;

- (nullable NSFont *)fontForKey:(NSString *)key; // forActiveWindow = YES
- (nullable NSFont *)fontForKey:(NSString *)key forActiveWindow:(BOOL)forActiveWindow;
- (nullable NSFont *)fontInGroup:(NSDictionary<NSString *, id> *)group withKey:(NSString *)key; // forActiveWindow = YES
- (nullable NSFont *)fontInGroup:(NSDictionary<NSString *, id> *)group withKey:(NSString *)key forActiveWindow:(BOOL)forActiveWindow;

- (nullable NSImage *)imageForKey:(NSString *)key; // forActiveWindow = YES
- (nullable NSImage *)imageForKey:(NSString *)key forActiveWindow:(BOOL)forActiveWindow;
- (nullable NSImage *)imageInGroup:(NSDictionary<NSString *, id> *)group withKey:(NSString *)key; // forActiveWindow = YES
- (nullable NSImage *)imageInGroup:(NSDictionary<NSString *, id> *)group withKey:(NSString *)key forActiveWindow:(BOOL)forActiveWindow;

- (CGFloat)measurementForKey:(NSString *)key;
- (CGFloat)measurementInGroup:(NSDictionary<NSString *, id> *)group withKey:(NSString *)key;
@end

NS_ASSUME_NONNULL_END
