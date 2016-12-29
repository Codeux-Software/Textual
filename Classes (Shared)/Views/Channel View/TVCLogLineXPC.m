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

#import "TVCLogLineXPC.h"

#import <CocoaExtensions/CocoaExtensions.h>

NS_ASSUME_NONNULL_BEGIN

/* TVCLogLineXPC is a container class for TVCLogLine when stored in a
 Core Data store. -data is the secure coded version of the class which is
 portable and can be stored in an offline database. */
@interface TVCLogLineXPC ()
@property (nonatomic, copy, readwrite) NSString *channelId;
@property (nonatomic, copy, readwrite) NSNumber *creationDate;
@property (nonatomic, copy, readwrite) NSData *data;
@end

@implementation TVCLogLineXPC

- (instancetype)initWithLogLineData:(NSData *)data inChannel:(NSString *)channelId
{
	NSParameterAssert(data != nil);
	NSParameterAssert(channelId != nil);

	return [self initWithLogLineData:data
						   inChannel:channelId
					withCreationDate:[NSDate date]];
}

- (instancetype)initWithLogLineData:(NSData *)data inChannel:(NSString *)channelId withCreationDate:(NSDate *)creationDate
{
	NSParameterAssert(data != nil);
	NSParameterAssert(channelId != nil);
	NSParameterAssert(creationDate != nil);

	if ((self = [super init])) {
		self.channelId = channelId;

		self.creationDate = @([creationDate timeIntervalSince1970]);

		self.data = data;

		return self;
	}

	return nil;
}

- (instancetype)initWithManagedObject:(NSManagedObject *)managedObject
{
	NSParameterAssert(managedObject != nil);

	if ((self = [super init])) {
		self.channelId = [managedObject valueForKey:@"channelId"];

		self.creationDate = [managedObject valueForKey:@"creationDate"];

		self.data = [managedObject valueForKey:@"data"];

		return self;
	}

	return nil;
}

- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder
{
	NSParameterAssert(aDecoder != nil);

	if ((self = [super init])) {
		self->_creationDate = [aDecoder decodeObjectOfClass:[NSNumber class] forKey:@"creationDate"];

		self->_channelId = [aDecoder decodeObjectOfClass:[NSString class] forKey:@"channelId"];

		self->_data = [aDecoder decodeObjectOfClass:[NSData class] forKey:@"data"];

		return self;
	}

	return nil;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
	[aCoder encodeObject:self.creationDate forKey:@"creationDate"];

	[aCoder encodeObject:self.channelId forKey:@"channelId"];

	[aCoder encodeObject:self.data forKey:@"data"];
}

+ (BOOL)supportsSecureCoding
{
	return YES;
}

@end

NS_ASSUME_NONNULL_END
