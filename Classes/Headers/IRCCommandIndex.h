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

/* Public commands are client-local commands (local) */
typedef NS_ENUM(NSUInteger, IRCPublicCommand) {
	IRCPublicCommandAdchatIndex = 5001,
	IRCPublicCommandAmeIndex = 5002,
	IRCPublicCommandAmsgIndex = 5003,
	IRCPublicCommandAquoteIndex = 5095,
	IRCPublicCommandArawIndex = 5096,
	IRCPublicCommandAutojoinIndex = 5101,
	IRCPublicCommandAwayIndex = 5004,
	IRCPublicCommandBackIndex = 5105,
	IRCPublicCommandBanIndex = 5005,
	IRCPublicCommandCapIndex = 5006,
	IRCPublicCommandCapsIndex = 5007,
	IRCPublicCommandCcbadgeIndex = 5008,
	IRCPublicCommandChatopsIndex = 5009,
	IRCPublicCommandClearIndex = 5010,
	IRCPublicCommandClearallIndex = 5011,
	IRCPublicCommandCloseIndex = 5012,
	IRCPublicCommandConnIndex = 5013,
	IRCPublicCommandCtcpIndex = 5014,
	IRCPublicCommandCtcpreplyIndex = 5015,
	IRCPublicCommandCycleIndex = 5016,
	IRCPublicCommandDccIndex = 5017,
	IRCPublicCommandDebugIndex = 5018,
	IRCPublicCommandDefaultsIndex = 5092,
	IRCPublicCommandDehalfopIndex = 5019,
	IRCPublicCommandDeopIndex = 5020,
	IRCPublicCommandDevoiceIndex = 5021,
	IRCPublicCommandEchoIndex = 5022,
	IRCPublicCommandEmptycachesIndex = 5110,
	IRCPublicCommandFakerawdataIndex = 5087,
	IRCPublicCommandGetscriptsIndex = 5098,
	IRCPublicCommandGlineIndex = 5023,
	IRCPublicCommandGlobopsIndex = 5024,
	IRCPublicCommandGotoIndex = 5099,
	IRCPublicCommandGzlineIndex = 5025,
	IRCPublicCommandHalfopIndex = 5026,
	IRCPublicCommandHopIndex = 5027,
	IRCPublicCommandIcbadgeIndex = 5028,
	IRCPublicCommandIgnoreIndex = 5029,
	IRCPublicCommandInviteIndex = 5030,
	IRCPublicCommandIsonIndex = 5100,
	IRCPublicCommandJIndex = 5031,
	IRCPublicCommandJoinIndex = 5032,
	IRCPublicCommandJoinRandomIndex = 5109,
	IRCPublicCommandKbIndex = 5083,
	IRCPublicCommandKickIndex = 5033,
	IRCPublicCommandKickbanIndex = 5034,
	IRCPublicCommandKillIndex = 5035,
	IRCPublicCommandLagcheckIndex = 5084,
	IRCPublicCommandLeaveIndex = 5036,
	IRCPublicCommandListIndex = 5037,
	IRCPublicCommandLocopsIndex = 5039,
	IRCPublicCommandMIndex = 5040,
	IRCPublicCommandMeIndex = 5041,
	IRCPublicCommandModeIndex = 5042,
	IRCPublicCommandMonitorIndex = 5106,
	IRCPublicCommandMsgIndex = 5043,
	IRCPublicCommandMuteIndex = 5044,
	IRCPublicCommandMylagIndex = 5045,
	IRCPublicCommandMyversionIndex = 5046,
	IRCPublicCommandNachatIndex = 5047,
	IRCPublicCommandNamesIndex = 5094,
	IRCPublicCommandNickIndex = 5048,
	IRCPublicCommandNoticeIndex = 5050,
	IRCPublicCommandNotifybubble = 5112,
	IRCPublicCommandNotifysound = 5113,
	IRCPublicCommandNotifyspeak = 5114,
	IRCPublicCommandOmsgIndex = 5051,
	IRCPublicCommandOnoticeIndex = 5052,
	IRCPublicCommandOpIndex = 5053,
	IRCPublicCommandPartIndex = 5054,
	IRCPublicCommandPassIndex = 5055,
	IRCPublicCommandQueryIndex = 5056,
	IRCPublicCommandQuietIndex = 5107,
	IRCPublicCommandQuitIndex = 5057,
	IRCPublicCommandQuoteIndex = 5058,
	IRCPublicCommandRawIndex = 5059,
	IRCPublicCommandRejoinIndex = 5060,
	IRCPublicCommandReloadICLIndex = 5115,
	IRCPublicCommandRemoveIndex = 5061,
	IRCPublicCommandServerIndex = 5062,
	IRCPublicCommandSetcolorIndex = 5103,
	IRCPublicCommandSetquerynameIndex = 5117,
	IRCPublicCommandShunIndex = 5063,
	IRCPublicCommandSmeIndex = 5064,
	IRCPublicCommandSmsgIndex = 5065,
	IRCPublicCommandSslcontextIndex = 5066,
	IRCPublicCommandTIndex = 5067,
	IRCPublicCommandTageIndex = 5093,
	IRCPublicCommandTempshunIndex = 5068,
	IRCPublicCommandTimerIndex = 5069,
	IRCPublicCommandTopicIndex = 5070,
	IRCPublicCommandUmeIndex = 5089,
	IRCPublicCommandUmodeIndex = 5071,
	IRCPublicCommandUmsgIndex = 5088,
	IRCPublicCommandUnbanIndex = 5072,
	IRCPublicCommandUnignoreIndex = 5073,
	IRCPublicCommandUnmuteIndex = 5075,
	IRCPublicCommandUnoticeIndex = 5090,
	IRCPublicCommandUnquietIndex = 5108,
	IRCPublicCommandVoiceIndex = 5076,
	IRCPublicCommandWallopsIndex = 5077,
	IRCPublicCommandWatchIndex = 5097,
	IRCPublicCommandWhoIndex = 5079,
	IRCPublicCommandWhoisIndex = 5080,
	IRCPublicCommandWhowasIndex = 5081,
	IRCPublicCommandZlineIndex = 5082
};

/* Private commands are server-side commands (remote) */
typedef NS_ENUM(NSUInteger, IRCPrivateCommand) {
	IRCPrivateCommandAdchatIndex = 1003,
	IRCPrivateCommandAuthenticateIndex = 1005,
	IRCPrivateCommandAwayIndex = 1050,
	IRCPrivateCommandBatchIndex = 1054,
	IRCPrivateCommandCapIndex = 1004,
	IRCPrivateCommandCertinfoIndex = 1055,
	IRCPrivateCommandChatopsIndex = 1006,
	IRCPrivateCommandErrorIndex = 1016,
	IRCPrivateCommandGlineIndex = 1047,
	IRCPrivateCommandGlobopsIndex = 1017,
	IRCPrivateCommandGzlineIndex = 1048,
	IRCPrivateCommandInviteIndex = 1018,
	IRCPrivateCommandIsonIndex = 1019,
	IRCPrivateCommandJoinIndex = 1020,
	IRCPrivateCommandKickIndex = 1021,
	IRCPrivateCommandKillIndex = 1022,
	IRCPrivateCommandListIndex = 1023,
	IRCPrivateCommandLocopsIndex = 1024,
	IRCPrivateCommandModeIndex = 1026,
	IRCPrivateCommandMonitorIndex = 1056,
	IRCPrivateCommandNachatIndex = 1027,
	IRCPrivateCommandNamesIndex = 1028,
	IRCPrivateCommandNickIndex = 1029,
	IRCPrivateCommandNoticeIndex = 1030,
	IRCPrivateCommandPartIndex = 1031,
	IRCPrivateCommandPassIndex = 1032,
	IRCPrivateCommandPingIndex = 1033,
	IRCPrivateCommandPongIndex = 1034,
	IRCPrivateCommandPrivmsgIndex = 1035,
	IRCPrivateCommandPrivmsgActionIndex = 1002,
	IRCPrivateCommandQuitIndex = 1036,
	IRCPrivateCommandShunIndex = 1045,
	IRCPrivateCommandTempshunIndex = 1046,
	IRCPrivateCommandTimeIndex = 1012,
	IRCPrivateCommandTopicIndex = 1039,
	IRCPrivateCommandUserIndex = 1037,
	IRCPrivateCommandWallopsIndex = 1038,
	IRCPrivateCommandWatchIndex = 1053,
	IRCPrivateCommandWhoIndex = 1040,
	IRCPrivateCommandWhoisIndex = 1042,
	IRCPrivateCommandWhowasIndex = 1041,
	IRCPrivateCommandZlineIndex = 1049
};

/* Command index */
TEXTUAL_EXTERN NSString * _Nullable IRCPrivateCommandIndex(const char *indexKey) TEXTUAL_DEPRECATED("Use strings instead");
TEXTUAL_EXTERN NSString * _Nullable IRCPublicCommandIndex(const char *indexKey) TEXTUAL_DEPRECATED("Use strings instead");

/* Controlling class */
@interface IRCCommandIndex : NSObject
+ (NSArray<NSString *> *)localCommandList;

+ (NSUInteger)indexOfRemoteCommand:(NSString *)command;
+ (NSUInteger)indexOfLocalCommand:(NSString *)command;

+ (NSUInteger)colonPositionForRemoteCommand:(NSString *)command;

+ (nullable NSString *)syntaxForLocalCommand:(NSString *)command;
@end

NS_ASSUME_NONNULL_END
