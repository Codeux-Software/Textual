/* *********************************************************************
 *                  _____         _               _
 *                 |_   _|____  _| |_ _   _  __ _| |
 *                   | |/ _ \ \/ / __| | | |/ _` | |
 *                   | |  __/>  <| |_| |_| | (_| | |
 *                   |_|\___/_/\_\\__|\__,_|\__,_|_|
 *
 * Copyright (c) 2016 - 2018 Codeux Software, LLC & respective contributors.
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

/* *** XPC PROTOCOL HEADERS ARE PRIVATE *** */

NS_ASSUME_NONNULL_BEGIN

@class TVCLogLineXPC;

#pragma mark -
#pragma mark Server Protocol

@protocol HLSHistoricLogServerProtocol
- (void)openDatabaseAtPath:(NSString *)path withCompletionBlock:(void (NS_NOESCAPE ^ _Nullable)(BOOL success))completionBlock;

- (void)writeLogLine:(TVCLogLineXPC *)logLine;

- (void)saveDataWithCompletionBlock:(void (NS_NOESCAPE ^ _Nullable)(void))completionBlock;

- (void)forgetView:(NSString *)viewId;
- (void)resetDataForView:(NSString *)viewId;

- (void)fetchEntriesForView:(NSString *)viewId
				  ascending:(BOOL)ascending
				 fetchLimit:(NSUInteger)fetchLimit // optional (0 == no limit)
				limitToDate:(nullable NSDate *)limitToDate
		withCompletionBlock:(void (NS_NOESCAPE ^)(NSArray<TVCLogLineXPC *> *entries))completionBlock;

- (void)fetchEntriesForView:(NSString *)viewId
	   withUniqueIdentifier:(NSString *)uniqueId
		   beforeFetchLimit:(NSUInteger)fetchLimitBefore // optional (0 == only uniqueId)
			afterFetchLimit:(NSUInteger)fetchLimitAfter // optional (0 == only uniqueId)
				limitToDate:(nullable NSDate *)limitToDate
		withCompletionBlock:(void (NS_NOESCAPE ^)(NSArray<TVCLogLineXPC *> *entries))completionBlock;

- (void)fetchEntriesForView:(NSString *)viewId
	 beforeUniqueIdentifier:(NSString *)uniqueId
				 fetchLimit:(NSUInteger)fetchLimit // required (> 0)
				limitToDate:(nullable NSDate *)limitToDate
		withCompletionBlock:(void (NS_NOESCAPE ^)(NSArray<TVCLogLineXPC *> *entries))completionBlock;

- (void)fetchEntriesForView:(NSString *)viewId
	  afterUniqueIdentifier:(NSString *)uniqueId
				 fetchLimit:(NSUInteger)fetchLimit // required (> 0)
				limitToDate:(nullable NSDate *)limitToDate
		withCompletionBlock:(void (NS_NOESCAPE ^)(NSArray<TVCLogLineXPC *> *entries))completionBlock;

- (void)fetchEntriesForView:(NSString *)viewId
	  afterUniqueIdentifier:(NSString *)uniqueIdAfter
	 beforeUniqueIdentifier:(NSString *)uniqueIdBefore
				 fetchLimit:(NSUInteger)fetchLimit // optional (0 == no limit)
		withCompletionBlock:(void (NS_NOESCAPE ^)(NSArray<TVCLogLineXPC *> *entries))completionBlock;

- (void)setMaximumLineCount:(NSUInteger)maximumLineCount;
@end

#pragma mark -
#pragma mark Client Protocol

@protocol HLSHistoricLogClientProtocol
- (void)willDeleteUniqueIdentifiers:(NSArray<NSString *> *)uniqueIdentifiers
							 inView:(NSString *)viewId;
@end

NS_ASSUME_NONNULL_END
