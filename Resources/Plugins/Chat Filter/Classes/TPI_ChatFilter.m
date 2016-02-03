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

#import "TPI_ChatFilter.h"

@implementation TPI_ChatFilter

- (instancetype)init
{
	if ((self = [super init])) {
		[self populateDefaults];
	}
	
	return self;
}

- (instancetype)initWithDictionary:(NSDictionary *)dic
{
	if ((self = [self init])) {
		[self populateDictionaryValues:dic];
	}

	return self;
}

- (NSDictionary *)defaults
{
	static id _defaults = nil;

	if (_defaults == nil) {
		NSDictionary *defaults = @{
			@"filterCommandNOTICE"				: @(NO),
			@"filterCommandPRIVMSG"				: @(YES),
			@"filterCommandPRIVMSG_ACTION"		: @(YES),
			@"filterIgnoreContent"				: @(NO),
			@"filterIgnoresOperators"			: @(YES),
			@"filterLogMatch"					: @(NO),

			@"filterLimitedToValue"				: @(TPI_ChatFilterLimitToNoLimitValue),
		};

		_defaults = [defaults copy];
	}
	
	return _defaults;
}

- (void)populateDefaults
{
	NSDictionary *defaults = [self defaults];

	self.filterItemID = [NSString stringWithUUID];

	self.filterLimitedToValue = [defaults integerForKey:@"filterLimitedToValue"];

	self.filterIgnoresOperators = [defaults boolForKey:@"filterIgnoresOperators"];

	self.filterIgnoreContent = [defaults boolForKey:@"filterIgnoreContent"];

	self.filterLogMatch = [defaults boolForKey:@"filterLogMatch"];

	self.filterCommandPRIVMSG = [defaults boolForKey:@"filterCommandPRIVMSG"];
	self.filterCommandPRIVMSG_ACTION = [defaults boolForKey:@"filterCommandPRIVMSG_ACTION"];

	self.filterCommandNOTICE = [defaults boolForKey:@"filterCommandNOTICE"];
}

- (void)populateDictionaryValues:(NSDictionary *)dic
{
	[dic assignArrayTo:&_filterLimitedToChannelsIDs forKey:@"filterLimitedToChannelsIDs"];
	[dic assignArrayTo:&_filterLimitedToClientsIDs forKey:@"filterLimitedToClientsIDs"];

	[dic assignBoolTo:&_filterCommandNOTICE forKey:@"filterCommandNOTICE"];
	[dic assignBoolTo:&_filterCommandPRIVMSG forKey:@"filterCommandPRIVMSG"];
	[dic assignBoolTo:&_filterCommandPRIVMSG_ACTION forKey:@"filterCommandPRIVMSG_ACTION"];
	[dic assignBoolTo:&_filterIgnoreContent forKey:@"filterIgnoreContent"];
	[dic assignBoolTo:&_filterIgnoresOperators forKey:@"filterIgnoresOperators"];
	[dic assignBoolTo:&_filterLogMatch forKey:@"filterLogMatch"];

	[dic assignStringTo:&_filterAction forKey:@"filterAction"];
	[dic assignStringTo:&_filterForwardToDestination forKey:@"filterForwardToDestination"];
	[dic assignStringTo:&_filterItemID forKey:@"filterItemID"];
	[dic assignStringTo:&_filterMatch forKey:@"filterMatch"];
	[dic assignStringTo:&_filterNotes forKey:@"filterNotes"];
	[dic assignStringTo:&_filterSenderMatch forKey:@"filterSenderMatch"];
	[dic assignStringTo:&_filterTitle forKey:@"filterTitle"];

	[dic assignUnsignedIntegerTo:&_filterLimitedToValue forKey:@"filterLimitedToValue"];
}

- (NSDictionary *)dictionaryValue
{
	NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithCapacity:6];

	[dic maybeSetObject:self.filterLimitedToChannelsIDs forKey:@"filterLimitedToChannelsIDs"];
	[dic maybeSetObject:self.filterLimitedToClientsIDs forKey:@"filterLimitedToClientsIDs"];

	[dic maybeSetObject:self.filterAction forKey:@"filterAction"];
	[dic maybeSetObject:self.filterForwardToDestination forKey:@"filterForwardToDestination"];
	[dic maybeSetObject:self.filterItemID forKey:@"filterItemID"];
	[dic maybeSetObject:self.filterMatch forKey:@"filterMatch"];
	[dic maybeSetObject:self.filterNotes forKey:@"filterNotes"];
	[dic maybeSetObject:self.filterSenderMatch forKey:@"filterSenderMatch"];
	[dic maybeSetObject:self.filterTitle forKey:@"filterTitle"];

	[dic setBool:self.filterCommandNOTICE forKey:@"filterCommandNOTICE"];
	[dic setBool:self.filterCommandPRIVMSG forKey:@"filterCommandPRIVMSG"];
	[dic setBool:self.filterCommandPRIVMSG_ACTION forKey:@"filterCommandPRIVMSG_ACTION"];
	[dic setBool:self.filterIgnoreContent forKey:@"filterIgnoreContent"];
	[dic setBool:self.filterIgnoresOperators forKey:@"filterIgnoresOperators"];
	[dic setBool:self.filterLogMatch forKey:@"filterLogMatch"];

	[dic setUnsignedInteger:self.filterLimitedToValue forKey:@"filterLimitedToValue"];

	return [dic dictionaryByRemovingDefaults:[self defaults]];
}

- (instancetype)copyWithZone:(NSZone *)zone
{
	return [[TPI_ChatFilter allocWithZone:zone] initWithDictionary:[self dictionaryValue]];
}

- (NSString *)filterDescription
{
	return TPILocalizedString(@"TPI_ChatFilter[0001]", [self filterTitle]);
}

@end
