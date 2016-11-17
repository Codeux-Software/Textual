/* ********************************************************************* 
                  _____         _               _
                 |_   _|____  _| |_ _   _  __ _| |
                   | |/ _ \ \/ / __| | | |/ _` | |
                   | |  __/>  <| |_| |_| | (_| | |
                   |_|\___/_/\_\\__|\__,_|\__,_|_|

 Copyright (c) 2008 - 2010 Satoshi Nakagawa <psychs AT limechat DOT net>
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

NS_ASSUME_NONNULL_BEGIN

/* TVCLogLineManaged is a container class for TVCLogLine when stored in a 
 Core Data store. -data is the secure coded version of the class which is
 portable and can be stored in an offline database. */
@interface TVCLogLineManaged ()
{
@private
	TVCLogLine *_logLine;
}

@property (nonatomic, copy) NSString *channelId;
@property (nonatomic, copy) NSNumber *creationDate;
@property (nonatomic, copy) NSData *data;
@end

@implementation TVCLogLineManaged

@dynamic channelId;
@dynamic creationDate;
@dynamic data;

+ (instancetype)managedObjectWithLogLine:(TVCLogLine *)logLine inChannel:(IRCChannel *)channel context:(NSManagedObjectContext *)context
{
	NSParameterAssert(logLine != nil);
	NSParameterAssert(channel != nil);
	NSParameterAssert(context != nil);

	NSEntityDescription *entity = [NSEntityDescription entityForName:@"LogLine" inManagedObjectContext:context];

	TVCLogLineManaged *newEntry = (id)[[NSManagedObject alloc] initWithEntity:entity insertIntoManagedObjectContext:context];

	[newEntry setValue:@([NSDate timeIntervalSince1970]) forKey:@"creationDate"];

	[newEntry setValue:channel.uniqueIdentifier forKey:@"channelId"];

	/* When we init using this initalizer, we do not intend to reuse the log line.
	 Therefore, we do not store it in self->_logLine. If this changes, we should
	 store it in that instance variable so we don't have to worry about rebuilding. */
	NSData *data = [NSKeyedArchiver archivedDataWithRootObject:logLine];

	[newEntry setValue:data forKey:@"data"];

	return newEntry;
}

- (nullable TVCLogLine *)logLine
{
	if (self->_logLine == nil) {
		self->_logLine = [NSKeyedUnarchiver unarchiveObjectWithData:self.data];
	}

	return self->_logLine;
}

@end

NS_ASSUME_NONNULL_END
