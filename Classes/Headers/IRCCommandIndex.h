/* *********************************************************************
 *                  _____         _               _
 *                 |_   _|____  _| |_ _   _  __ _| |
 *                   | |/ _ \ \/ / __| | | |/ _` | |
 *                   | |  __/>  <| |_| |_| | (_| | |
 *                   |_|\___/_/\_\\__|\__,_|\__,_|_|
 *
 * Copyright (c) 2010 - 2015 Codeux Software, LLC & respective contributors.
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

/* Local commands are client-local commands */
typedef NS_ENUM(NSUInteger, IRCLocalCommand) {
	IRCLocalCommandAdchatIndex = 5001,
	IRCLocalCommandAmeIndex = 5002,
	IRCLocalCommandAmsgIndex = 5003,
	IRCLocalCommandAquoteIndex = 5095,
	IRCLocalCommandArawIndex = 5096,
	IRCLocalCommandAutojoinIndex = 5101,
	IRCLocalCommandAwayIndex = 5004,
	IRCLocalCommandBackIndex = 5105,
	IRCLocalCommandBanIndex = 5005,
	IRCLocalCommandCapIndex = 5006,
	IRCLocalCommandCapsIndex = 5007,
	IRCLocalCommandCcbadgeIndex = 5008,
	IRCLocalCommandChatopsIndex = 5009,
	IRCLocalCommandClearIndex = 5010,
	IRCLocalCommandClearallIndex = 5011,
	IRCLocalCommandCloseIndex = 5012,
	IRCLocalCommandConnIndex = 5013,
	IRCLocalCommandCtcpIndex = 5014,
	IRCLocalCommandCtcpreplyIndex = 5015,
	IRCLocalCommandCycleIndex = 5016,
	IRCLocalCommandDccIndex = 5017,
	IRCLocalCommandDebugIndex = 5018,
	IRCLocalCommandDefaultsIndex = 5092,
	IRCLocalCommandDehalfopIndex = 5019,
	IRCLocalCommandDeopIndex = 5020,
	IRCLocalCommandDevoiceIndex = 5021,
	IRCLocalCommandEchoIndex = 5022,
	IRCLocalCommandEmptycachesIndex = 5110,
	IRCLocalCommandFakerawdataIndex = 5087,
	IRCLocalCommandGetscriptsIndex = 5098,
	IRCLocalCommandGlineIndex = 5023,
	IRCLocalCommandGlobopsIndex = 5024,
	IRCLocalCommandGotoIndex = 5099,
	IRCLocalCommandGzlineIndex = 5025,
	IRCLocalCommandHalfopIndex = 5026,
	IRCLocalCommandHopIndex = 5027,
	IRCLocalCommandIcbadgeIndex = 5028,
	IRCLocalCommandIgnoreIndex = 5029,
	IRCLocalCommandInviteIndex = 5030,
	IRCLocalCommandIsonIndex = 5100,
	IRCLocalCommandJIndex = 5031,
	IRCLocalCommandJoinIndex = 5032,
	IRCLocalCommandJoinRandomIndex = 5109,
	IRCLocalCommandKbIndex = 5083,
	IRCLocalCommandKickIndex = 5033,
	IRCLocalCommandKickbanIndex = 5034,
	IRCLocalCommandKillIndex = 5035,
	IRCLocalCommandLagcheckIndex = 5084,
	IRCLocalCommandLeaveIndex = 5036,
	IRCLocalCommandListIndex = 5037,
	IRCLocalCommandLocopsIndex = 5039,
	IRCLocalCommandMIndex = 5040,
	IRCLocalCommandMeIndex = 5041,
	IRCLocalCommandModeIndex = 5042,
	IRCLocalCommandMonitorIndex = 5106,
	IRCLocalCommandMsgIndex = 5043,
	IRCLocalCommandMuteIndex = 5044,
	IRCLocalCommandMylagIndex = 5045,
	IRCLocalCommandMyversionIndex = 5046,
	IRCLocalCommandNachatIndex = 5047,
	IRCLocalCommandNamesIndex = 5094,
	IRCLocalCommandNickIndex = 5048,
	IRCLocalCommandNoticeIndex = 5050,
	IRCLocalCommandNotifybubble = 5112,
	IRCLocalCommandNotifysound = 5113,
	IRCLocalCommandNotifyspeak = 5114,
	IRCLocalCommandOmsgIndex = 5051,
	IRCLocalCommandOnoticeIndex = 5052,
	IRCLocalCommandOpIndex = 5053,
	IRCLocalCommandPartIndex = 5054,
	IRCLocalCommandPassIndex = 5055,
	IRCLocalCommandQueryIndex = 5056,
	IRCLocalCommandQuietIndex = 5107,
	IRCLocalCommandQuitIndex = 5057,
	IRCLocalCommandQuoteIndex = 5058,
	IRCLocalCommandRawIndex = 5059,
	IRCLocalCommandRejoinIndex = 5060,
	IRCLocalCommandReloadICLIndex = 5115,
	IRCLocalCommandRemoveIndex = 5061,
	IRCLocalCommandServerIndex = 5062,
	IRCLocalCommandSetcolorIndex = 5103,
	IRCLocalCommandSetquerynameIndex = 5117,
	IRCLocalCommandShunIndex = 5063,
	IRCLocalCommandSmeIndex = 5064,
	IRCLocalCommandSmsgIndex = 5065,
	IRCLocalCommandSslcontextIndex = 5066,
	IRCLocalCommandTIndex = 5067,
	IRCLocalCommandTageIndex = 5093,
	IRCLocalCommandTempshunIndex = 5068,
	IRCLocalCommandTimerIndex = 5069,
	IRCLocalCommandTopicIndex = 5070,
	IRCLocalCommandUmeIndex = 5089,
	IRCLocalCommandUmodeIndex = 5071,
	IRCLocalCommandUmsgIndex = 5088,
	IRCLocalCommandUnbanIndex = 5072,
	IRCLocalCommandUnignoreIndex = 5073,
	IRCLocalCommandUnmuteIndex = 5075,
	IRCLocalCommandUnoticeIndex = 5090,
	IRCLocalCommandUnquietIndex = 5108,
	IRCLocalCommandVoiceIndex = 5076,
	IRCLocalCommandWallopsIndex = 5077,
	IRCLocalCommandWatchIndex = 5097,
	IRCLocalCommandWhoIndex = 5079,
	IRCLocalCommandWhoisIndex = 5080,
	IRCLocalCommandWhowasIndex = 5081,
	IRCLocalCommandZlineIndex = 5082
};

/* Remote commands are server-side commands */
typedef NS_ENUM(NSUInteger, IRCRemoteCommand) {
	IRCRemoteCommandAdchatIndex = 1003,
	IRCRemoteCommandAuthenticateIndex = 1005,
	IRCRemoteCommandAwayIndex = 1050,
	IRCRemoteCommandBatchIndex = 1054,
	IRCRemoteCommandCapIndex = 1004,
	IRCRemoteCommandCertinfoIndex = 1055,
	IRCRemoteCommandChatopsIndex = 1006,
	IRCRemoteCommandChghostIndex = 1057,
	IRCRemoteCommandErrorIndex = 1016,
	IRCRemoteCommandGlineIndex = 1047,
	IRCRemoteCommandGlobopsIndex = 1017,
	IRCRemoteCommandGzlineIndex = 1048,
	IRCRemoteCommandInviteIndex = 1018,
	IRCRemoteCommandIsonIndex = 1019,
	IRCRemoteCommandJoinIndex = 1020,
	IRCRemoteCommandKickIndex = 1021,
	IRCRemoteCommandKillIndex = 1022,
	IRCRemoteCommandListIndex = 1023,
	IRCRemoteCommandLocopsIndex = 1024,
	IRCRemoteCommandModeIndex = 1026,
	IRCRemoteCommandMonitorIndex = 1056,
	IRCRemoteCommandNachatIndex = 1027,
	IRCRemoteCommandNamesIndex = 1028,
	IRCRemoteCommandNickIndex = 1029,
	IRCRemoteCommandNoticeIndex = 1030,
	IRCRemoteCommandPartIndex = 1031,
	IRCRemoteCommandPassIndex = 1032,
	IRCRemoteCommandPingIndex = 1033,
	IRCRemoteCommandPongIndex = 1034,
	IRCRemoteCommandPrivmsgIndex = 1035,
	IRCRemoteCommandPrivmsgActionIndex = 1002,
	IRCRemoteCommandQuitIndex = 1036,
	IRCRemoteCommandShunIndex = 1045,
	IRCRemoteCommandTempshunIndex = 1046,
	IRCRemoteCommandTimeIndex = 1012,
	IRCRemoteCommandTopicIndex = 1039,
	IRCRemoteCommandUserIndex = 1037,
	IRCRemoteCommandWallopsIndex = 1038,
	IRCRemoteCommandWatchIndex = 1053,
	IRCRemoteCommandWhoIndex = 1040,
	IRCRemoteCommandWhoisIndex = 1042,
	IRCRemoteCommandWhowasIndex = 1041,
	IRCRemoteCommandZlineIndex = 1049
};

/* Command index */
TEXTUAL_EXTERN NSString * _Nullable IRCPrivateCommandIndex(const char *indexKey) TEXTUAL_SYMBOL_USED TEXTUAL_DEPRECATED("Use strings instead");
TEXTUAL_EXTERN NSString * _Nullable IRCPublicCommandIndex(const char *indexKey) TEXTUAL_SYMBOL_USED TEXTUAL_DEPRECATED("Use strings instead");

/* Controlling class */
@interface IRCCommandIndex : NSObject
+ (NSArray<NSString *> *)localCommandList;

+ (NSUInteger)indexOfRemoteCommand:(NSString *)command;
+ (NSUInteger)indexOfLocalCommand:(NSString *)command;

+ (NSUInteger)colonPositionForRemoteCommand:(NSString *)command;

+ (nullable NSString *)syntaxForLocalCommand:(NSString *)command;
@end

#pragma mark -
#pragma mark Deprecated

typedef NS_ENUM(NSUInteger, IRCPublicCommand) {
	IRCPublicCommandAdchatIndex TEXTUAL_DEPRECATED("Use IRCLocalCommandAdchatIndex instead") = IRCLocalCommandAdchatIndex,
	IRCPublicCommandAmeIndex TEXTUAL_DEPRECATED("Use IRCLocalCommandAmeIndex instead") = IRCLocalCommandAmeIndex,
	IRCPublicCommandAmsgIndex TEXTUAL_DEPRECATED("Use IRCLocalCommandAmsgIndex instead") = IRCLocalCommandAmsgIndex,
	IRCPublicCommandAquoteIndex TEXTUAL_DEPRECATED("Use IRCLocalCommandAquoteIndex instead") = IRCLocalCommandAquoteIndex,
	IRCPublicCommandArawIndex TEXTUAL_DEPRECATED("Use IRCLocalCommandArawIndex instead") = IRCLocalCommandArawIndex,
	IRCPublicCommandAutojoinIndex TEXTUAL_DEPRECATED("Use IRCLocalCommandAutojoinIndex instead") = IRCLocalCommandAutojoinIndex,
	IRCPublicCommandAwayIndex TEXTUAL_DEPRECATED("Use IRCLocalCommandAwayIndex instead") = IRCLocalCommandAwayIndex,
	IRCPublicCommandBackIndex TEXTUAL_DEPRECATED("Use IRCLocalCommandBackIndex instead") = IRCLocalCommandBackIndex,
	IRCPublicCommandBanIndex TEXTUAL_DEPRECATED("Use IRCLocalCommandBanIndex instead") = IRCLocalCommandBanIndex,
	IRCPublicCommandCapIndex TEXTUAL_DEPRECATED("Use IRCLocalCommandCapIndex instead") = IRCLocalCommandCapIndex,
	IRCPublicCommandCapsIndex TEXTUAL_DEPRECATED("Use IRCLocalCommandCapsIndex instead") = IRCLocalCommandCapsIndex,
	IRCPublicCommandCcbadgeIndex TEXTUAL_DEPRECATED("Use IRCLocalCommandCcbadgeIndex instead") = IRCLocalCommandCcbadgeIndex,
	IRCPublicCommandChatopsIndex TEXTUAL_DEPRECATED("Use IRCLocalCommandChatopsIndex instead") = IRCLocalCommandChatopsIndex,
	IRCPublicCommandClearIndex TEXTUAL_DEPRECATED("Use IRCLocalCommandClearIndex instead") = IRCLocalCommandClearIndex,
	IRCPublicCommandClearallIndex TEXTUAL_DEPRECATED("Use IRCLocalCommandClearallIndex instead") = IRCLocalCommandClearallIndex,
	IRCPublicCommandCloseIndex TEXTUAL_DEPRECATED("Use IRCLocalCommandCloseIndex instead") = IRCLocalCommandCloseIndex,
	IRCPublicCommandConnIndex TEXTUAL_DEPRECATED("Use IRCLocalCommandConnIndex instead") = IRCLocalCommandConnIndex,
	IRCPublicCommandCtcpIndex TEXTUAL_DEPRECATED("Use IRCLocalCommandCtcpIndex instead") = IRCLocalCommandCtcpIndex,
	IRCPublicCommandCtcpreplyIndex TEXTUAL_DEPRECATED("Use IRCLocalCommandCtcpreplyIndex instead") = IRCLocalCommandCtcpreplyIndex,
	IRCPublicCommandCycleIndex TEXTUAL_DEPRECATED("Use IRCLocalCommandCycleIndex instead") = IRCLocalCommandCycleIndex,
	IRCPublicCommandDccIndex TEXTUAL_DEPRECATED("Use IRCLocalCommandDccIndex instead") = IRCLocalCommandDccIndex,
	IRCPublicCommandDebugIndex TEXTUAL_DEPRECATED("Use IRCLocalCommandDebugIndex instead") = IRCLocalCommandDebugIndex,
	IRCPublicCommandDefaultsIndex TEXTUAL_DEPRECATED("Use IRCLocalCommandDefaultsIndex instead") = IRCLocalCommandDefaultsIndex,
	IRCPublicCommandDehalfopIndex TEXTUAL_DEPRECATED("Use IRCLocalCommandDehalfopIndex instead") = IRCLocalCommandDehalfopIndex,
	IRCPublicCommandDeopIndex TEXTUAL_DEPRECATED("Use IRCLocalCommandDeopIndex instead") = IRCLocalCommandDeopIndex,
	IRCPublicCommandDevoiceIndex TEXTUAL_DEPRECATED("Use IRCLocalCommandDevoiceIndex instead") = IRCLocalCommandDevoiceIndex,
	IRCPublicCommandEchoIndex TEXTUAL_DEPRECATED("Use IRCLocalCommandEchoIndex instead") = IRCLocalCommandEchoIndex,
	IRCPublicCommandEmptycachesIndex TEXTUAL_DEPRECATED("Use IRCLocalCommandEmptycachesIndex instead") = IRCLocalCommandEmptycachesIndex,
	IRCPublicCommandFakerawdataIndex TEXTUAL_DEPRECATED("Use IRCLocalCommandFakerawdataIndex instead") = IRCLocalCommandFakerawdataIndex,
	IRCPublicCommandGetscriptsIndex TEXTUAL_DEPRECATED("Use IRCLocalCommandGetscriptsIndex instead") = IRCLocalCommandGetscriptsIndex,
	IRCPublicCommandGlineIndex TEXTUAL_DEPRECATED("Use IRCLocalCommandGlineIndex instead") = IRCLocalCommandGlineIndex,
	IRCPublicCommandGlobopsIndex TEXTUAL_DEPRECATED("Use IRCLocalCommandGlobopsIndex instead") = IRCLocalCommandGlobopsIndex,
	IRCPublicCommandGotoIndex TEXTUAL_DEPRECATED("Use IRCLocalCommandGotoIndex instead") = IRCLocalCommandGotoIndex,
	IRCPublicCommandGzlineIndex TEXTUAL_DEPRECATED("Use IRCLocalCommandGzlineIndex instead") = IRCLocalCommandGzlineIndex,
	IRCPublicCommandHalfopIndex TEXTUAL_DEPRECATED("Use IRCLocalCommandHalfopIndex instead") = IRCLocalCommandHalfopIndex,
	IRCPublicCommandHopIndex TEXTUAL_DEPRECATED("Use IRCLocalCommandHopIndex instead") = IRCLocalCommandHopIndex,
	IRCPublicCommandIcbadgeIndex TEXTUAL_DEPRECATED("Use IRCLocalCommandIcbadgeIndex instead") = IRCLocalCommandIcbadgeIndex,
	IRCPublicCommandIgnoreIndex TEXTUAL_DEPRECATED("Use IRCLocalCommandIgnoreIndex instead") = IRCLocalCommandIgnoreIndex,
	IRCPublicCommandInviteIndex TEXTUAL_DEPRECATED("Use IRCLocalCommandInviteIndex instead") = IRCLocalCommandInviteIndex,
	IRCPublicCommandIsonIndex TEXTUAL_DEPRECATED("Use IRCLocalCommandIsonIndex instead") = IRCLocalCommandIsonIndex,
	IRCPublicCommandJIndex TEXTUAL_DEPRECATED("Use IRCLocalCommandJIndex instead") = IRCLocalCommandJIndex,
	IRCPublicCommandJoinIndex TEXTUAL_DEPRECATED("Use IRCLocalCommandJoinIndex instead") = IRCLocalCommandJoinIndex,
	IRCPublicCommandJoinRandomIndex TEXTUAL_DEPRECATED("Use IRCLocalCommandJoinRandomIndex instead") = IRCLocalCommandJoinRandomIndex,
	IRCPublicCommandKbIndex TEXTUAL_DEPRECATED("Use IRCLocalCommandKbIndex instead") = IRCLocalCommandKbIndex,
	IRCPublicCommandKickIndex TEXTUAL_DEPRECATED("Use IRCLocalCommandKickIndex instead") = IRCLocalCommandKickIndex,
	IRCPublicCommandKickbanIndex TEXTUAL_DEPRECATED("Use IRCLocalCommandKickbanIndex instead") = IRCLocalCommandKickbanIndex,
	IRCPublicCommandKillIndex TEXTUAL_DEPRECATED("Use IRCLocalCommandKillIndex instead") = IRCLocalCommandKillIndex,
	IRCPublicCommandLagcheckIndex TEXTUAL_DEPRECATED("Use IRCLocalCommandLagcheckIndex instead") = IRCLocalCommandLagcheckIndex,
	IRCPublicCommandLeaveIndex TEXTUAL_DEPRECATED("Use IRCLocalCommandLeaveIndex instead") = IRCLocalCommandLeaveIndex,
	IRCPublicCommandListIndex TEXTUAL_DEPRECATED("Use IRCLocalCommandListIndex instead") = IRCLocalCommandListIndex,
	IRCPublicCommandLocopsIndex TEXTUAL_DEPRECATED("Use IRCLocalCommandLocopsIndex instead") = IRCLocalCommandLocopsIndex,
	IRCPublicCommandMIndex TEXTUAL_DEPRECATED("Use IRCLocalCommandMIndex instead") = IRCLocalCommandMIndex,
	IRCPublicCommandMeIndex TEXTUAL_DEPRECATED("Use IRCLocalCommandMeIndex instead") = IRCLocalCommandMeIndex,
	IRCPublicCommandModeIndex TEXTUAL_DEPRECATED("Use IRCLocalCommandModeIndex instead") = IRCLocalCommandModeIndex,
	IRCPublicCommandMonitorIndex TEXTUAL_DEPRECATED("Use IRCLocalCommandMonitorIndex instead") = IRCLocalCommandMonitorIndex,
	IRCPublicCommandMsgIndex TEXTUAL_DEPRECATED("Use IRCLocalCommandMsgIndex instead") = IRCLocalCommandMsgIndex,
	IRCPublicCommandMuteIndex TEXTUAL_DEPRECATED("Use IRCLocalCommandMuteIndex instead") = IRCLocalCommandMuteIndex,
	IRCPublicCommandMylagIndex TEXTUAL_DEPRECATED("Use IRCLocalCommandMylagIndex instead") = IRCLocalCommandMylagIndex,
	IRCPublicCommandMyversionIndex TEXTUAL_DEPRECATED("Use IRCLocalCommandMyversionIndex instead") = IRCLocalCommandMyversionIndex,
	IRCPublicCommandNachatIndex TEXTUAL_DEPRECATED("Use IRCLocalCommandNachatIndex instead") = IRCLocalCommandNachatIndex,
	IRCPublicCommandNamesIndex TEXTUAL_DEPRECATED("Use IRCLocalCommandNamesIndex instead") = IRCLocalCommandNamesIndex,
	IRCPublicCommandNickIndex TEXTUAL_DEPRECATED("Use IRCLocalCommandNickIndex instead") = IRCLocalCommandNickIndex,
	IRCPublicCommandNoticeIndex TEXTUAL_DEPRECATED("Use IRCLocalCommandNoticeIndex instead") = IRCLocalCommandNoticeIndex,
	IRCPublicCommandNotifybubble TEXTUAL_DEPRECATED("Use IRCLocalCommandNotifybubble instead") = IRCLocalCommandNotifybubble,
	IRCPublicCommandNotifysound TEXTUAL_DEPRECATED("Use IRCLocalCommandNotifysound instead") = IRCLocalCommandNotifysound,
	IRCPublicCommandNotifyspeak TEXTUAL_DEPRECATED("Use IRCLocalCommandNotifyspeak instead") = IRCLocalCommandNotifyspeak,
	IRCPublicCommandOmsgIndex TEXTUAL_DEPRECATED("Use IRCLocalCommandOmsgIndex instead") = IRCLocalCommandOmsgIndex,
	IRCPublicCommandOnoticeIndex TEXTUAL_DEPRECATED("Use IRCLocalCommandOnoticeIndex instead") = IRCLocalCommandOnoticeIndex,
	IRCPublicCommandOpIndex TEXTUAL_DEPRECATED("Use IRCLocalCommandOpIndex instead") = IRCLocalCommandOpIndex,
	IRCPublicCommandPartIndex TEXTUAL_DEPRECATED("Use IRCLocalCommandPartIndex instead") = IRCLocalCommandPartIndex,
	IRCPublicCommandPassIndex TEXTUAL_DEPRECATED("Use IRCLocalCommandPassIndex instead") = IRCLocalCommandPassIndex,
	IRCPublicCommandQueryIndex TEXTUAL_DEPRECATED("Use IRCLocalCommandQueryIndex instead") = IRCLocalCommandQueryIndex,
	IRCPublicCommandQuietIndex TEXTUAL_DEPRECATED("Use IRCLocalCommandQuietIndex instead") = IRCLocalCommandQuietIndex,
	IRCPublicCommandQuitIndex TEXTUAL_DEPRECATED("Use IRCLocalCommandQuitIndex instead") = IRCLocalCommandQuitIndex,
	IRCPublicCommandQuoteIndex TEXTUAL_DEPRECATED("Use IRCLocalCommandQuoteIndex instead") = IRCLocalCommandQuoteIndex,
	IRCPublicCommandRawIndex TEXTUAL_DEPRECATED("Use IRCLocalCommandRawIndex instead") = IRCLocalCommandRawIndex,
	IRCPublicCommandRejoinIndex TEXTUAL_DEPRECATED("Use IRCLocalCommandRejoinIndex instead") = IRCLocalCommandRejoinIndex,
	IRCPublicCommandReloadICLIndex TEXTUAL_DEPRECATED("Use IRCLocalCommandReloadICLIndex instead") = IRCLocalCommandReloadICLIndex,
	IRCPublicCommandRemoveIndex TEXTUAL_DEPRECATED("Use IRCLocalCommandRemoveIndex instead") = IRCLocalCommandRemoveIndex,
	IRCPublicCommandServerIndex TEXTUAL_DEPRECATED("Use IRCLocalCommandServerIndex instead") = IRCLocalCommandServerIndex,
	IRCPublicCommandSetcolorIndex TEXTUAL_DEPRECATED("Use IRCLocalCommandSetcolorIndex instead") = IRCLocalCommandSetcolorIndex,
	IRCPublicCommandSetquerynameIndex TEXTUAL_DEPRECATED("Use IRCLocalCommandSetquerynameIndex instead") = IRCLocalCommandSetquerynameIndex,
	IRCPublicCommandShunIndex TEXTUAL_DEPRECATED("Use IRCLocalCommandShunIndex instead") = IRCLocalCommandShunIndex,
	IRCPublicCommandSmeIndex TEXTUAL_DEPRECATED("Use IRCLocalCommandSmeIndex instead") = IRCLocalCommandSmeIndex,
	IRCPublicCommandSmsgIndex TEXTUAL_DEPRECATED("Use IRCLocalCommandSmsgIndex instead") = IRCLocalCommandSmsgIndex,
	IRCPublicCommandSslcontextIndex TEXTUAL_DEPRECATED("Use IRCLocalCommandSslcontextIndex instead") = IRCLocalCommandSslcontextIndex,
	IRCPublicCommandTIndex TEXTUAL_DEPRECATED("Use IRCLocalCommandTIndex instead") = IRCLocalCommandTIndex,
	IRCPublicCommandTageIndex TEXTUAL_DEPRECATED("Use IRCLocalCommandTageIndex instead") = IRCLocalCommandTageIndex,
	IRCPublicCommandTempshunIndex TEXTUAL_DEPRECATED("Use IRCLocalCommandTempshunIndex instead") = IRCLocalCommandTempshunIndex,
	IRCPublicCommandTimerIndex TEXTUAL_DEPRECATED("Use IRCLocalCommandTimerIndex instead") = IRCLocalCommandTimerIndex,
	IRCPublicCommandTopicIndex TEXTUAL_DEPRECATED("Use IRCLocalCommandTopicIndex instead") = IRCLocalCommandTopicIndex,
	IRCPublicCommandUmeIndex TEXTUAL_DEPRECATED("Use IRCLocalCommandUmeIndex instead") = IRCLocalCommandUmeIndex,
	IRCPublicCommandUmodeIndex TEXTUAL_DEPRECATED("Use IRCLocalCommandUmodeIndex instead") = IRCLocalCommandUmodeIndex,
	IRCPublicCommandUmsgIndex TEXTUAL_DEPRECATED("Use IRCLocalCommandUmsgIndex instead") = IRCLocalCommandUmsgIndex,
	IRCPublicCommandUnbanIndex TEXTUAL_DEPRECATED("Use IRCLocalCommandUnbanIndex instead") = IRCLocalCommandUnbanIndex,
	IRCPublicCommandUnignoreIndex TEXTUAL_DEPRECATED("Use IRCLocalCommandUnignoreIndex instead") = IRCLocalCommandUnignoreIndex,
	IRCPublicCommandUnmuteIndex TEXTUAL_DEPRECATED("Use IRCLocalCommandUnmuteIndex instead") = IRCLocalCommandUnmuteIndex,
	IRCPublicCommandUnoticeIndex TEXTUAL_DEPRECATED("Use IRCLocalCommandUnoticeIndex instead") = IRCLocalCommandUnoticeIndex,
	IRCPublicCommandUnquietIndex TEXTUAL_DEPRECATED("Use IRCLocalCommandUnquietIndex instead") = IRCLocalCommandUnquietIndex,
	IRCPublicCommandVoiceIndex TEXTUAL_DEPRECATED("Use IRCLocalCommandVoiceIndex instead") = IRCLocalCommandVoiceIndex,
	IRCPublicCommandWallopsIndex TEXTUAL_DEPRECATED("Use IRCLocalCommandWallopsIndex instead") = IRCLocalCommandWallopsIndex,
	IRCPublicCommandWatchIndex TEXTUAL_DEPRECATED("Use IRCLocalCommandWatchIndex instead") = IRCLocalCommandWatchIndex,
	IRCPublicCommandWhoIndex TEXTUAL_DEPRECATED("Use IRCLocalCommandWhoIndex instead") = IRCLocalCommandWhoIndex,
	IRCPublicCommandWhoisIndex TEXTUAL_DEPRECATED("Use IRCLocalCommandWhoisIndex instead") = IRCLocalCommandWhoisIndex,
	IRCPublicCommandWhowasIndex TEXTUAL_DEPRECATED("Use IRCLocalCommandWhowasIndex instead") = IRCLocalCommandWhowasIndex,
	IRCPublicCommandZlineIndex TEXTUAL_DEPRECATED("Use IRCLocalCommandZlineIndex instead") = IRCLocalCommandZlineIndex
};

typedef NS_ENUM(NSUInteger, IRCPrivateCommand) {
	IRCPrivateCommandAuthenticateIndex TEXTUAL_DEPRECATED("Use IRCRemoteCommandAuthenticateIndex instead") = IRCRemoteCommandAuthenticateIndex,
	IRCPrivateCommandAwayIndex TEXTUAL_DEPRECATED("Use IRCRemoteCommandAwayIndex instead") = IRCRemoteCommandAwayIndex,
	IRCPrivateCommandBatchIndex TEXTUAL_DEPRECATED("Use IRCRemoteCommandBatchIndex instead") = IRCRemoteCommandBatchIndex,
	IRCPrivateCommandCapIndex TEXTUAL_DEPRECATED("Use IRCRemoteCommandCapIndex instead") = IRCRemoteCommandCapIndex,
	IRCPrivateCommandCertinfoIndex TEXTUAL_DEPRECATED("Use IRCRemoteCommandCertinfoIndex instead") = IRCRemoteCommandCertinfoIndex,
	IRCPrivateCommandChatopsIndex TEXTUAL_DEPRECATED("Use IRCRemoteCommandChatopsIndex instead") = IRCRemoteCommandChatopsIndex,
	IRCPrivateCommandChghostIndex TEXTUAL_DEPRECATED("Use IRCRemoteCommandChghostIndex instead") = IRCRemoteCommandChghostIndex,
	IRCPrivateCommandErrorIndex TEXTUAL_DEPRECATED("Use IRCRemoteCommandErrorIndex instead") = IRCRemoteCommandErrorIndex,
	IRCPrivateCommandGlineIndex TEXTUAL_DEPRECATED("Use IRCRemoteCommandGlineIndex instead") = IRCRemoteCommandGlineIndex,
	IRCPrivateCommandGlobopsIndex TEXTUAL_DEPRECATED("Use IRCRemoteCommandGlobopsIndex instead") = IRCRemoteCommandGlobopsIndex,
	IRCPrivateCommandGzlineIndex TEXTUAL_DEPRECATED("Use IRCRemoteCommandGzlineIndex instead") = IRCRemoteCommandGzlineIndex,
	IRCPrivateCommandInviteIndex TEXTUAL_DEPRECATED("Use IRCRemoteCommandInviteIndex instead") = IRCRemoteCommandInviteIndex,
	IRCPrivateCommandIsonIndex TEXTUAL_DEPRECATED("Use IRCRemoteCommandIsonIndex instead") = IRCRemoteCommandIsonIndex,
	IRCPrivateCommandJoinIndex TEXTUAL_DEPRECATED("Use IRCRemoteCommandJoinIndex instead") = IRCRemoteCommandJoinIndex,
	IRCPrivateCommandKickIndex TEXTUAL_DEPRECATED("Use IRCRemoteCommandKickIndex instead") = IRCRemoteCommandKickIndex,
	IRCPrivateCommandKillIndex TEXTUAL_DEPRECATED("Use IRCRemoteCommandKillIndex instead") = IRCRemoteCommandKillIndex,
	IRCPrivateCommandListIndex TEXTUAL_DEPRECATED("Use IRCRemoteCommandListIndex instead") = IRCRemoteCommandListIndex,
	IRCPrivateCommandLocopsIndex TEXTUAL_DEPRECATED("Use IRCRemoteCommandLocopsIndex instead") = IRCRemoteCommandLocopsIndex,
	IRCPrivateCommandModeIndex TEXTUAL_DEPRECATED("Use IRCRemoteCommandModeIndex instead") = IRCRemoteCommandModeIndex,
	IRCPrivateCommandMonitorIndex TEXTUAL_DEPRECATED("Use IRCRemoteCommandMonitorIndex instead") = IRCRemoteCommandMonitorIndex,
	IRCPrivateCommandNachatIndex TEXTUAL_DEPRECATED("Use IRCRemoteCommandNachatIndex instead") = IRCRemoteCommandNachatIndex,
	IRCPrivateCommandNamesIndex TEXTUAL_DEPRECATED("Use IRCRemoteCommandNamesIndex instead") = IRCRemoteCommandNamesIndex,
	IRCPrivateCommandNickIndex TEXTUAL_DEPRECATED("Use IRCRemoteCommandNickIndex instead") = IRCRemoteCommandNickIndex,
	IRCPrivateCommandNoticeIndex TEXTUAL_DEPRECATED("Use IRCRemoteCommandNoticeIndex instead") = IRCRemoteCommandNoticeIndex,
	IRCPrivateCommandPartIndex TEXTUAL_DEPRECATED("Use IRCRemoteCommandPartIndex instead") = IRCRemoteCommandPartIndex,
	IRCPrivateCommandPassIndex TEXTUAL_DEPRECATED("Use IRCRemoteCommandPassIndex instead") = IRCRemoteCommandPassIndex,
	IRCPrivateCommandPingIndex TEXTUAL_DEPRECATED("Use IRCRemoteCommandPingIndex instead") = IRCRemoteCommandPingIndex,
	IRCPrivateCommandPongIndex TEXTUAL_DEPRECATED("Use IRCRemoteCommandPongIndex instead") = IRCRemoteCommandPongIndex,
	IRCPrivateCommandPrivmsgIndex TEXTUAL_DEPRECATED("Use IRCRemoteCommandPrivmsgIndex instead") = IRCRemoteCommandPrivmsgIndex,
	IRCPrivateCommandPrivmsgActionIndex TEXTUAL_DEPRECATED("Use IRCRemoteCommandPrivmsgActionIndex instead") = IRCRemoteCommandPrivmsgActionIndex,
	IRCPrivateCommandQuitIndex TEXTUAL_DEPRECATED("Use IRCRemoteCommandQuitIndex instead") = IRCRemoteCommandQuitIndex,
	IRCPrivateCommandShunIndex TEXTUAL_DEPRECATED("Use IRCRemoteCommandShunIndex instead") = IRCRemoteCommandShunIndex,
	IRCPrivateCommandTempshunIndex TEXTUAL_DEPRECATED("Use IRCRemoteCommandTempshunIndex instead") = IRCRemoteCommandTempshunIndex,
	IRCPrivateCommandTimeIndex TEXTUAL_DEPRECATED("Use IRCRemoteCommandTimeIndex instead") = IRCRemoteCommandTimeIndex,
	IRCPrivateCommandTopicIndex TEXTUAL_DEPRECATED("Use IRCRemoteCommandTopicIndex instead") = IRCRemoteCommandTopicIndex,
	IRCPrivateCommandUserIndex TEXTUAL_DEPRECATED("Use IRCRemoteCommandUserIndex instead") = IRCRemoteCommandUserIndex,
	IRCPrivateCommandWallopsIndex TEXTUAL_DEPRECATED("Use IRCRemoteCommandWallopsIndex instead") = IRCRemoteCommandWallopsIndex,
	IRCPrivateCommandWatchIndex TEXTUAL_DEPRECATED("Use IRCRemoteCommandWatchIndex instead") = IRCRemoteCommandWatchIndex,
	IRCPrivateCommandWhoIndex TEXTUAL_DEPRECATED("Use IRCRemoteCommandWhoIndex instead") = IRCRemoteCommandWhoIndex,
	IRCPrivateCommandWhoisIndex TEXTUAL_DEPRECATED("Use IRCRemoteCommandWhoisIndex instead") = IRCRemoteCommandWhoisIndex,
	IRCPrivateCommandWhowasIndex TEXTUAL_DEPRECATED("Use IRCRemoteCommandWhowasIndex instead") = IRCRemoteCommandWhowasIndex,
	IRCPrivateCommandZlineIndex TEXTUAL_DEPRECATED("Use IRCRemoteCommandZlineIndex instead") = IRCRemoteCommandZlineIndex
};

NS_ASSUME_NONNULL_END
