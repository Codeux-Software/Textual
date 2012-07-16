/* ********************************************************************* 
       _____        _               _    ___ ____   ____
      |_   _|___  _| |_ _   _  __ _| |  |_ _|  _ \ / ___|
       | |/ _ \ \/ / __| | | |/ _` | |   | || |_) | |
       | |  __/>  <| |_| |_| | (_| | |   | ||  _ <| |___
       |_|\___/_/\_\\__|\__,_|\__,_|_|  |___|_| \_\\____|

 Copyright (c) 2010 — 2012 Codeux Software & respective contributors.
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

#define IRCCommandIndexAction				@"ACTION"
#define IRCCommandIndexAdchat				@"ADCHAT"
#define IRCCommandIndexAuthenticate			@"AUTHENTICATE"
#define IRCCommandIndexAme					@"AME"
#define IRCCommandIndexAmsg					@"AMSG"
#define IRCCommandIndexAway					@"AWAY"
#define IRCCommandIndexBan					@"BAN"
#define IRCCommandIndexChatops				@"CHATOPS"
#define IRCCommandIndexCap					@"CAP"
#define IRCCommandIndexCaps					@"CAPS"
#define IRCCommandIndexClear				@"CLEAR"
#define IRCCommandIndexClearall				@"CLEARALL"
#define IRCCommandIndexClientinfo			@"CLIENTINFO"
#define IRCCommandIndexClose				@"CLOSE"
#define IRCCommandIndexConn					@"CONN"
#define IRCCommandIndexConnect				@"CONN"
#define IRCCommandIndexCtcp					@"CTCP"
#define IRCCommandIndexCtcpreply			@"CTCPREPLY"
#define IRCCommandIndexCycle				@"CYCLE"
#define IRCCommandIndexDcc					@"DCC"
#define IRCCommandIndexDebug				@"DEBUG"
#define IRCCommandIndexDehalfop				@"DEHALFOP"
#define IRCCommandIndexDeop					@"DEOP"
#define IRCCommandIndexDevoice				@"DEVOICE"
#define IRCCommandIndexEcho					@"ECHO"
#define IRCCommandIndexError				@"ERROR"
#define IRCCommandIndexGline				@"GLINE"
#define IRCCommandIndexGzline				@"GZLINE"
#define IRCCommandIndexGlobops				@"GLOBOPS"
#define IRCCommandIndexHalfop				@"HALFOP"
#define IRCCommandIndexHop					@"HOP"
#define IRCCommandIndexIcbadge				@"ICBADGE"
#define IRCCommandIndexCcbadge				@"CCBADGE"
#define IRCCommandIndexIgnore				@"IGNORE"
#define IRCCommandIndexInvite				@"INVITE"
#define IRCCommandIndexIson					@"ISON"
#define IRCCommandIndexJ					@"J"
#define IRCCommandIndexJoin					@"JOIN"
#define IRCCommandIndexKb					@"KB"
#define IRCCommandIndexKick					@"KICK"
#define IRCCommandIndexKickban				@"KICKBAN"
#define IRCCommandIndexKill					@"KILL"
#define IRCCommandIndexLeave				@"LEAVE"
#define IRCCommandIndexLagcheck				@"LAGCHECK"
#define IRCCommandIndexList					@"LIST"
#define IRCCommandIndexLoadPlugins			@"LOAD_PLUGINS"
#define IRCCommandIndexLocops				@"LOCOPS"
#define IRCCommandIndexM					@"M"
#define IRCCommandIndexMe					@"ME"
#define IRCCommandIndexMode					@"MODE"
#define IRCCommandIndexMsg					@"MSG"
#define IRCCommandIndexMute					@"MUTE"
#define IRCCommandIndexMylag				@"MYLAG"
#define IRCCommandIndexMyversion			@"MYVERSION"
#define IRCCommandIndexNachat				@"NACHAT"
#define IRCCommandIndexNames				@"NAMES"
#define IRCCommandIndexNick					@"NICK"
#define IRCCommandIndexNncoloreset			@"NNCOLORESET"
#define IRCCommandIndexNotice				@"NOTICE"
#define IRCCommandIndexOmsg					@"OMSG"
#define IRCCommandIndexOnotice				@"ONOTICE"
#define IRCCommandIndexOp					@"OP"
#define IRCCommandIndexPart					@"PART"
#define IRCCommandIndexPass					@"PASS"
#define IRCCommandIndexPing					@"PING"
#define IRCCommandIndexPong					@"PONG"
#define IRCCommandIndexPrivmsg				@"PRIVMSG"
#define IRCCommandIndexQuery				@"QUERY"
#define IRCCommandIndexQuit					@"QUIT"
#define IRCCommandIndexQuote				@"QUOTE"
#define IRCCommandIndexRaw					@"RAW"
#define IRCCommandIndexRejoin				@"REJOIN"
#define IRCCommandIndexRemove				@"REMOVE"
#define IRCCommandIndexSend					@"SEND"
#define IRCCommandIndexServer				@"SERVER"
#define IRCCommandIndexShun					@"SHUN"
#define IRCCommandIndexSslcontext			@"SSLCONTEXT"
#define IRCCommandIndexT					@"T"
#define IRCCommandIndexTempshun				@"TEMPSHUN"
#define IRCCommandIndexTime					@"TIME"
#define IRCCommandIndexTimer				@"TIMER"
#define IRCCommandIndexTopic				@"TOPIC"
#define IRCCommandIndexUmode				@"UMODE"
#define IRCCommandIndexUnban				@"UNBAN"
#define IRCCommandIndexUnignore				@"UNIGNORE"
#define IRCCommandIndexUnloadPlugins		@"UNLOAD_PLUGINS"
#define IRCCommandIndexUnmute				@"UNMUTE"
#define IRCCommandIndexUser					@"USER"
#define IRCCommandIndexUserinfo				@"USERINFO"
#define IRCCommandIndexVersion				@"VERSION"
#define IRCCommandIndexVoice				@"VOICE"
#define IRCCommandIndexWallops				@"WALLOPS"
#define IRCCommandIndexWatch				@"WATCH"
#define IRCCommandIndexWeights				@"WEIGHTS"
#define IRCCommandIndexWho					@"WHO"
#define IRCCommandIndexWhois				@"WHOIS"
#define IRCCommandIndexWhowas				@"WHOWAS"
#define IRCCommandIndexZline				@"ZLINE"
#define IRCCommandIndexSme					@"SME"
#define IRCCommandIndexSmsg					@"SMSG"

#define TXMaximumIRCBodyLength				520
#define TXMaximumNodesPerModeCommand		4
