#import "Preferences.h"
#import "NSDictionaryHelper.h"
#import "NSStringHelper.h"
#import "LogLine.h"

@implementation Preferences

static NSInteger startUpTime;

+ (NSInteger)startTime
{
	return startUpTime;
}

#pragma mark -
#pragma mark URL Regex

static NSString *urlAddrRegexComplex;
+ (NSString*)complexURLRegularExpression
{
	if (!urlAddrRegexComplex) {
		urlAddrRegexComplex = [NSString stringWithFormat:@"((((\\b(?:[a-zA-Z][a-zA-Z0-9+.-]{2,6}://)?)([a-zA-Z0-9-]+\\.))+%@\\b)|((\\b([a-zA-Z][a-zA-Z0-9+.-]{2,6}://))+(([0-9]{1,3}\\.){3})+([0-9]{1,3})\\b))(?:\\:([0-9]+))?(?:/[a-zA-Z0-9;/\\?\\:\\,\\]\\[\\)\\(\\=\\&\\._\\#\\>\\<\\$\\'\\\"\\}\\{\\`\\~\\!\\@\\^\\|\\*\\+\\-\\%%]*)?", TXTLS(@"ALL_DOMAIN_EXTENSIONS")];
	}
	
	return urlAddrRegexComplex;
}

+ (NSArray*)bannedURLRegexChars
{
	return [NSArray arrayWithObjects:@")", @"]", @"'", @"\"", @":", @">", @"<", @"}", @"|", @",", nil];
}

+ (NSArray*)bannedURLRegexBufferChars
{
	return [NSArray arrayWithObjects:@".", @"@", nil];
}

+ (NSArray*)bannedURLRegexLineTypes
{
	return [NSArray arrayWithObjects:@"mode", @"join", @"nick", @"invite", nil];
}

#pragma mark -
#pragma mark Version Dictonaries

static NSDictionary *textualPlist;
static NSDictionary *systemVersionPlist;

#if defined(__ppc__)
static NSString *processor = @"PowerPC 32-bit";
#elif defined(__ppc64__)
static NSString *processor = @"PowerPC 64-bit";
#elif defined(__i386__) 
static NSString *processor = @"Intel 32-bit";
#elif defined(__x86_64__)
static NSString *processor = @"Intel 64-bit";
#else
static NSString *processor = @"Unknown Architecture";
#endif

+ (NSDictionary*)textualInfoPlist
{
	return textualPlist;
}

+ (NSDictionary*)systemInfoPlist 
{
	return systemVersionPlist;
}

+ (NSString*)systemProcessor
{
	return processor;
}

#pragma mark -
#pragma mark Command Index

static NSMutableDictionary *commandIndex;

+ (void)populateCommandIndex
{
	commandIndex = [[NSMutableDictionary alloc] init];
	
	[commandIndex setObject:@"3" forKey:@"AWAY"];
	[commandIndex setObject:@"4" forKey:@"ERROR"];
	[commandIndex setObject:@"5" forKey:@"INVITE"];
	[commandIndex setObject:@"6" forKey:@"ISON"];
	[commandIndex setObject:@"7" forKey:@"JOIN"];
	[commandIndex setObject:@"8" forKey:@"KICK"];
	[commandIndex setObject:@"9" forKey:@"KILL"];
	[commandIndex setObject:@"10" forKey:@"LIST"];
	[commandIndex setObject:@"11" forKey:@"MODE"];
	[commandIndex setObject:@"12" forKey:@"NAMES"];
	[commandIndex setObject:@"13" forKey:@"NICK"];
	[commandIndex setObject:@"14" forKey:@"NOTICE"];
	[commandIndex setObject:@"15" forKey:@"PART"];
	[commandIndex setObject:@"16" forKey:@"PASS"];
	[commandIndex setObject:@"17" forKey:@"PING"];
	[commandIndex setObject:@"18" forKey:@"PONG"];
	[commandIndex setObject:@"19" forKey:@"PRIVMSG"];
	[commandIndex setObject:@"20" forKey:@"QUIT"];
	[commandIndex setObject:@"21" forKey:@"TOPIC"];
	[commandIndex setObject:@"22" forKey:@"USER"];
	[commandIndex setObject:@"23" forKey:@"WHO"];
	[commandIndex setObject:@"24" forKey:@"WHOIS"];
	[commandIndex setObject:@"25" forKey:@"WHOWAS"];
	[commandIndex setObject:@"27" forKey:@"ACTION"];
	[commandIndex setObject:@"28" forKey:@"DCC"];
	[commandIndex setObject:@"29" forKey:@"SEND"];
	[commandIndex setObject:@"31" forKey:@"CLIENTINFO"];
	[commandIndex setObject:@"32" forKey:@"CTCP"];
	[commandIndex setObject:@"33" forKey:@"CTCPREPLY"];
	[commandIndex setObject:@"34" forKey:@"TIME"];
	[commandIndex setObject:@"35" forKey:@"USERINFO"];
	[commandIndex setObject:@"36" forKey:@"VERSION"];
	[commandIndex setObject:@"38" forKey:@"OMSG"];
	[commandIndex setObject:@"39" forKey:@"ONOTICE"];
	[commandIndex setObject:@"41" forKey:@"BAN"];
	[commandIndex setObject:@"42" forKey:@"CLEAR"];
	[commandIndex setObject:@"43" forKey:@"CLOSE"];
	[commandIndex setObject:@"44" forKey:@"CYCLE"];
	[commandIndex setObject:@"45" forKey:@"DEHALFOP"];
	[commandIndex setObject:@"46" forKey:@"DEOP"];
	[commandIndex setObject:@"47" forKey:@"DEVOICE"];
	[commandIndex setObject:@"48" forKey:@"HALFOP"];
	[commandIndex setObject:@"49" forKey:@"HOP"];
	[commandIndex setObject:@"50" forKey:@"IGNORE"];
	[commandIndex setObject:@"51" forKey:@"J"];
	[commandIndex setObject:@"52" forKey:@"LEAVE"];
	[commandIndex setObject:@"53" forKey:@"M"];
	[commandIndex setObject:@"54" forKey:@"ME"];
	[commandIndex setObject:@"55" forKey:@"MSG"];
	[commandIndex setObject:@"56" forKey:@"OP"];
	[commandIndex setObject:@"57" forKey:@"RAW"];
	[commandIndex setObject:@"58" forKey:@"REJOIN"];
	[commandIndex setObject:@"59" forKey:@"QUERY"];
	[commandIndex setObject:@"60" forKey:@"QUOTE"];
	[commandIndex setObject:@"61" forKey:@"T"];
	[commandIndex setObject:@"62" forKey:@"TIMER"];
	[commandIndex setObject:@"63" forKey:@"VOICE"];
	[commandIndex setObject:@"64" forKey:@"UNBAN"];
	[commandIndex setObject:@"65" forKey:@"UNIGNORE"];
	[commandIndex setObject:@"66" forKey:@"UMODE"];
	[commandIndex setObject:@"67" forKey:@"VERSION"];
	[commandIndex setObject:@"68" forKey:@"WEIGHTS"];
	[commandIndex setObject:@"69" forKey:@"ECHO"];
	[commandIndex setObject:@"70" forKey:@"DEBUG"];
	[commandIndex setObject:@"71" forKey:@"CLEARALL"];
	[commandIndex setObject:@"72" forKey:@"AMSG"];
	[commandIndex setObject:@"73" forKey:@"AME"];
	[commandIndex setObject:@"74" forKey:@"WRECK"];
	[commandIndex setObject:@"75" forKey:@"AVALOVE"];
	[commandIndex setObject:@"76" forKey:@"JIMC"];
	[commandIndex setObject:@"77" forKey:@"REMOVE"];
	[commandIndex setObject:@"78" forKey:@"KB"];
	[commandIndex setObject:@"79" forKey:@"KICKBAN"];
	[commandIndex setObject:@"80" forKey:@"WALLOPS"]; 
	[commandIndex setObject:@"81" forKey:@"ICBADGE"];
	[commandIndex setObject:@"82" forKey:@"SERVER"];
	[commandIndex setObject:@"83" forKey:@"CONN"];
	[commandIndex setObject:@"84" forKey:@"MYVERSION"];
	[commandIndex setObject:@"85" forKey:@"CHATOPS"];
	[commandIndex setObject:@"86" forKey:@"GLOBOPS"];
	[commandIndex setObject:@"87" forKey:@"LOCOPS"];
	[commandIndex setObject:@"88" forKey:@"NACHAT"];
	[commandIndex setObject:@"89" forKey:@"ADCHAT"];
}

+ (NSInteger)commandUIndex:(NSString *)command 
{
	return [[commandIndex objectForKey:[command uppercaseString]] integerValue];
}

#pragma mark -
#pragma mark Path Index

+ (NSString*)whereScriptsPath
{
	return [@"~/Library/Application Support/Textual/Scripts" stringByExpandingTildeInPath];
}

+ (NSString*)whereThemesPath
{
	return [@"~/Library/Application Support/Textual/Styles" stringByExpandingTildeInPath];
}

+ (NSString*)wherePluginsPath
{
	return [@"~/Library/Application Support/Textual/Extensions" stringByExpandingTildeInPath];
}

+ (NSString*)whereScriptsLocalPath
{
	return [[self whereResourcePath] stringByAppendingPathComponent:@"Scripts"];
}

+ (NSString*)whereThemesLocalPath
{
	return [[self whereResourcePath] stringByAppendingPathComponent:@"Styles"];	
}

+ (NSString*)wherePluginsLocalPath
{
	return [[self whereResourcePath] stringByAppendingPathComponent:@"Extensions"];	
}

+ (NSString*)whereResourcePath 
{
	return [[NSBundle mainBundle] resourcePath];
}

#pragma mark -
#pragma mark Flood Control

+ (BOOL)floodControlIsEnabled
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	return [ud boolForKey:@"Preferences.FloodControl.enabled"];
}

+ (NSInteger)floodControlMaxMessages
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	return [ud integerForKey:@"Preferences.FloodControl.maxmsg"];
}

+ (NSInteger)floodControlDelayTimer
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	return [ud integerForKey:@"Preferences.FloodControl.timer"];
}

#pragma mark -
#pragma mark Default Identity

+ (NSString*)defaultNickname
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	return [ud objectForKey:@"Preferences.Identity.nickname"];
}

+ (NSString*)defaultUsername
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	return [ud objectForKey:@"Preferences.Identity.username"];
}

+ (NSString*)defaultRealname
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	return [ud objectForKey:@"Preferences.Identity.realname"];
}

#pragma mark - 
#pragma mark General Preferences

+ (DCCActionType)dccAction
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	return [ud integerForKey:@"Preferences.DCC.action"];
}

+ (AddressDetectionType)dccAddressDetectionMethod
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	return [ud integerForKey:@"Preferences.DCC.address_detection_method"];
}

+ (BOOL)displayServerMOTD
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	return [ud boolForKey:@"Preferences.General.display_servmotd"];
}

+ (BOOL)copyOnSelect
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	return [ud boolForKey:@"Preferences.General.copyonselect"];
}

+ (BOOL)autoAddScrollbackMark
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	return [ud boolForKey:@"Preferences.General.autoadd_scrollbackmark"];
}

+ (BOOL)removeAllFormatting
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	return [ud boolForKey:@"Preferences.General.strip_formatting"];
}

+ (BOOL)rightToLeftFormatting
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	return [ud boolForKey:@"Preferences.General.rtl_formatting"];
}

+ (NSString*)dccMyaddress
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	return [ud objectForKey:@"Preferences.DCC.myaddress"];
}

+ (NSString*)completionSuffix
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	return [ud objectForKey:@"Preferences.General.completion_suffix"];
}

+ (BOOL)displayDockBadge
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	return [ud boolForKey:@"Preferences.General.dockbadges"];
}

+ (BOOL)handleIRCopAlerts
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	return [ud boolForKey:@"Preferences.General.handle_operalerts"];
}

+ (BOOL)handleServerNotices
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	return [ud boolForKey:@"Preferences.General.handle_server_notices"];
}

+ (BOOL)amsgAllConnections
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	return [ud boolForKey:@"Preferences.General.amsg_allconnections"];
}

+ (BOOL)awayAllConnections
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	return [ud boolForKey:@"Preferences.General.away_allconnections"];
}

+ (BOOL)nickAllConnections
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	return [ud boolForKey:@"Preferences.General.nick_allconnections"];
}

+ (BOOL)indentOnHang
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	return [ud boolForKey:@"Preferences.Theme.indent_onwordwrap"];
}

+ (BOOL)confirmQuit
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	return [ud boolForKey:@"Preferences.General.confirm_quit"];
}

+ (BOOL)processChannelModes
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	return [ud boolForKey:@"Preferences.General.process_channel_modes"];
}

+ (BOOL)rejoinOnKick
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	return [ud boolForKey:@"Preferences.General.rejoin_onkick"];
}

+ (BOOL)autoJoinOnInvite
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	return [ud boolForKey:@"Preferences.General.autojoin_oninvite"];
}

+ (BOOL)connectOnDoubleclick
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	return [ud boolForKey:@"Preferences.General.connect_on_doubleclick"];
}

+ (BOOL)disconnectOnDoubleclick
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	return [ud boolForKey:@"Preferences.General.disconnect_on_doubleclick"];
}

+ (BOOL)joinOnDoubleclick
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	return [ud boolForKey:@"Preferences.General.join_on_doubleclick"];
}

+ (BOOL)leaveOnDoubleclick
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	return [ud boolForKey:@"Preferences.General.leave_on_doubleclick"];
}

+ (BOOL)logTranscript
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	return [ud boolForKey:@"Preferences.General.log_transcript"];
}

+ (BOOL)openBrowserInBackground
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	return [ud boolForKey:@"Preferences.General.open_browser_in_background"];
}

+ (BOOL)showInlineImages
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	return [ud boolForKey:@"Preferences.General.show_inline_images"];
}

+ (BOOL)showJoinLeave
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	return [ud boolForKey:@"Preferences.General.show_join_leave"];
}

+ (BOOL)stopGrowlOnActive
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	return [ud boolForKey:@"Preferences.General.stop_growl_on_active"];
}

+ (TabActionType)tabAction
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	return [ud integerForKey:@"Preferences.General.tab_action"];
}

+ (BOOL)keywordCurrentNick
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	return [ud boolForKey:@"Preferences.Keyword.current_nick"];
}

+ (NSArray*)keywordDislikeWords
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	return [ud objectForKey:@"Preferences.Keyword.dislike_words"];
}

+ (KeywordMatchType)keywordMatchingMethod
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	return [ud integerForKey:@"Preferences.Keyword.matching_method"];
}

+ (NSArray*)keywordWords
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	return [ud objectForKey:@"Preferences.Keyword.words"];
}

#pragma mark -
#pragma mark Theme

+ (NSString*)themeName
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	return [ud objectForKey:@"Preferences.Theme.name"];
}

+ (void)setThemeName:(NSString*)value
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	[ud setObject:value forKey:@"Preferences.Theme.name"];
}

+ (NSString*)themeLogFontName
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	return [ud objectForKey:@"Preferences.Theme.log_font_name"];
}

+ (void)setThemeLogFontName:(NSString*)value
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	[ud setObject:value forKey:@"Preferences.Theme.log_font_name"];
}

+ (double)themeLogFontSize
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	return [ud doubleForKey:@"Preferences.Theme.log_font_size"];
}

+ (void)setThemeLogFontSize:(double)value
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	[ud setDouble:value forKey:@"Preferences.Theme.log_font_size"];
}

+ (NSString*)themeNickFormat
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	return [ud objectForKey:@"Preferences.Theme.nick_format"];
}

+ (BOOL)themeOverrideLogFont
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	return [ud boolForKey:@"Preferences.Theme.override_log_font"];
}

+ (BOOL)themeOverrideNickFormat
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	return [ud boolForKey:@"Preferences.Theme.override_nick_format"];
}

+ (BOOL)themeOverrideTimestampFormat
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	return [ud boolForKey:@"Preferences.Theme.override_timestamp_format"];
}

+ (NSString*)themeTimestampFormat
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	return [ud objectForKey:@"Preferences.Theme.timestamp_format"];
}

+ (double)themeTransparency
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	return [ud doubleForKey:@"Preferences.Theme.transparency"];
}

#pragma mark -
#pragma mark Completion Suffix

+ (void)setCompletionSuffix:(NSString*)value
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	[ud setObject:value forKey:@"Preferences.General.completion_suffix"];
}

#pragma mark -
#pragma mark DCC Ports

+ (NSInteger)dccFirstPort
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	return [ud integerForKey:@"Preferences.DCC.first_port"];
}

+ (void)setDccFirstPort:(NSInteger)value
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	[ud setInteger:value forKey:@"Preferences.DCC.first_port"];
}

+ (NSInteger)dccLastPort
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	return [ud integerForKey:@"Preferences.DCC.last_port"];
}

+ (void)setDccLastPort:(NSInteger)value
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	[ud setInteger:value forKey:@"Preferences.DCC.last_port"];
}

#pragma mark -
#pragma mark Max Log Lines

+ (NSInteger)maxLogLines
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	return [ud integerForKey:@"Preferences.General.max_log_lines"];
}

+ (void)setMaxLogLines:(NSInteger)value
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	[ud setInteger:value forKey:@"Preferences.General.max_log_lines"];
}

#pragma mark -
#pragma mark Transcript Folder

+ (NSString*)transcriptFolder
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	return [ud objectForKey:@"Preferences.General.transcript_folder"];
}

+ (void)setTranscriptFolder:(NSString*)value
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	[ud setObject:value forKey:@"Preferences.General.transcript_folder"];
}

#pragma mark -
#pragma mark Events

+ (NSString*)titleForEvent:(GrowlNotificationType)event
{
	switch (event) {
		case GROWL_HIGHLIGHT:
			return TXTLS(@"GROWL_HIGHLIGHT");
		case GROWL_NEW_TALK:
			return TXTLS(@"GROWL_NEW_TALK");
		case GROWL_CHANNEL_MSG:
			return TXTLS(@"GROWL_CHANNEL_MSG");
		case GROWL_CHANNEL_NOTICE:
			return TXTLS(@"GROWL_CHANNEL_NOTICE");
		case GROWL_TALK_MSG:
			return TXTLS(@"GROWL_TALK_MSG");
		case GROWL_TALK_NOTICE:
			return TXTLS(@"GROWL_TALK_NOTICE");
		case GROWL_KICKED:
			return TXTLS(@"GROWL_KICKED");
		case GROWL_INVITED:
			return TXTLS(@"GROWL_INVITED");
		case GROWL_LOGIN:
			return TXTLS(@"GROWL_LOGIN");
		case GROWL_DISCONNECT:
			return TXTLS(@"GROWL_DISCONNECT");
		case GROWL_ADDRESS_BOOK_MATCH:
			return TXTLS(@"GROWL_ADDRESS_BOOK_MATCH");
		case GROWL_FILE_RECEIVE_REQUEST:
			return TXTLS(@"GROWL_FILE_RECEIVE_REQUEST");
		case GROWL_FILE_RECEIVE_SUCCESS:
			return TXTLS(@"GROWL_FILE_RECEIVE_SUCCESS");
		case GROWL_FILE_RECEIVE_ERROR:
			return TXTLS(@"GROWL_FILE_RECEIVE_ERROR");
		case GROWL_FILE_SEND_SUCCESS:
			return TXTLS(@"GROWL_FILE_SEND_SUCCESS");
		case GROWL_FILE_SEND_ERROR:
			return TXTLS(@"GROWL_FILE_SEND_ERROR");
	}
	
	return nil;
}

+ (NSString*)keyForEvent:(GrowlNotificationType)event
{
	switch (event) {
		case GROWL_HIGHLIGHT:
			return @"eventHighlight";
		case GROWL_NEW_TALK:
			return @"eventNewtalk";
		case GROWL_CHANNEL_MSG:
			return @"eventChannelText";
		case GROWL_CHANNEL_NOTICE:
			return @"eventChannelNotice";
		case GROWL_TALK_MSG:
			return @"eventTalkText";
		case GROWL_TALK_NOTICE:
			return @"eventTalkNotice";
		case GROWL_KICKED:
			return @"eventKicked";
		case GROWL_INVITED:
			return @"eventInvited";
		case GROWL_LOGIN:
			return @"eventLogin";
		case GROWL_DISCONNECT:
			return @"eventDisconnect";
		case GROWL_ADDRESS_BOOK_MATCH:
			return @"eventAddressBookMatch";
		case GROWL_FILE_RECEIVE_REQUEST:
			return @"eventFileReceiveRequest";
		case GROWL_FILE_RECEIVE_SUCCESS:
			return @"eventFileReceiveSuccess";
		case GROWL_FILE_RECEIVE_ERROR:
			return @"eventFileReceiveFailure";
		case GROWL_FILE_SEND_SUCCESS:
			return @"eventFileSendSuccess";
		case GROWL_FILE_SEND_ERROR:
			return @"eventFileSendFailure";
	}
	
	return nil;
}

+ (NSString*)soundForEvent:(GrowlNotificationType)event
{
	NSString* key = [[self keyForEvent:event] stringByAppendingString:@"Sound"];
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	return [ud objectForKey:key];
}

+ (void)setSound:(NSString*)value forEvent:(GrowlNotificationType)event
{
	NSString* key = [[self keyForEvent:event] stringByAppendingString:@"Sound"];
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	[ud setObject:value forKey:key];
}

+ (BOOL)growlEnabledForEvent:(GrowlNotificationType)event
{
	NSString* key = [[self keyForEvent:event] stringByAppendingString:@"Growl"];
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	return [ud boolForKey:key];
}

+ (void)setGrowlEnabled:(BOOL)value forEvent:(GrowlNotificationType)event
{
	NSString* key = [[self keyForEvent:event] stringByAppendingString:@"Growl"];
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	[ud setBool:value forKey:key];
}

+ (BOOL)growlStickyForEvent:(GrowlNotificationType)event
{
	NSString* key = [[self keyForEvent:event] stringByAppendingString:@"GrowlSticky"];
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	return [ud boolForKey:key];
}

+ (void)setGrowlSticky:(BOOL)value forEvent:(GrowlNotificationType)event
{
	NSString* key = [[self keyForEvent:event] stringByAppendingString:@"GrowlSticky"];
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	[ud setBool:value forKey:key];
}

#pragma mark -
#pragma mark World

+ (BOOL)spellCheckEnabled
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	if (![ud objectForKey:@"spellCheck2"]) return YES;
	return [ud boolForKey:@"spellCheck2"];
}

+ (void)setSpellCheckEnabled:(BOOL)value
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	[ud setBool:value forKey:@"spellCheck2"];
}

+ (BOOL)grammarCheckEnabled
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	return [ud boolForKey:@"grammarCheck"];
}

+ (void)setGrammarCheckEnabled:(BOOL)value
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	[ud setBool:value forKey:@"grammarCheck"];
}

+ (BOOL)spellingCorrectionEnabled
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	return [ud boolForKey:@"spellingCorrection"];
}

+ (void)setSpellingCorrectionEnabled:(BOOL)value
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	[ud setBool:value forKey:@"spellingCorrection"];
}

+ (BOOL)smartInsertDeleteEnabled
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	if (![ud objectForKey:@"smartInsertDelete"]) return YES;
	return [ud boolForKey:@"smartInsertDelete"];
}

+ (void)setSmartInsertDeleteEnabled:(BOOL)value
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	[ud setBool:value forKey:@"smartInsertDelete"];
}

+ (BOOL)quoteSubstitutionEnabled
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	return [ud boolForKey:@"quoteSubstitution"];
}

+ (void)setQuoteSubstitutionEnabled:(BOOL)value
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	[ud setBool:value forKey:@"quoteSubstitution"];
}

+ (BOOL)dashSubstitutionEnabled
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	return [ud boolForKey:@"dashSubstitution"];
}

+ (void)setDashSubstitutionEnabled:(BOOL)value
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	[ud setBool:value forKey:@"dashSubstitution"];
}

+ (BOOL)linkDetectionEnabled
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	return [ud boolForKey:@"linkDetection"];
}

+ (void)setLinkDetectionEnabled:(BOOL)value
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	[ud setBool:value forKey:@"linkDetection"];
}

+ (BOOL)dataDetectionEnabled
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	return [ud boolForKey:@"dataDetection"];
}

+ (void)setDataDetectionEnabled:(BOOL)value
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	[ud setBool:value forKey:@"dataDetection"];
}

+ (BOOL)textReplacementEnabled
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	return [ud boolForKey:@"textReplacement"];
}

+ (void)setTextReplacementEnabled:(BOOL)value
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	[ud setBool:value forKey:@"textReplacement"];
}

#pragma mark -
#pragma mark Growl

+ (BOOL)registeredToGrowl
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	return [ud boolForKey:@"registeredToGrowl"];
}

+ (void)setRegisteredToGrowl:(BOOL)value
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	[ud setBool:value forKey:@"registeredToGrowl"];
}

#pragma mark -
#pragma mark World

+ (NSDictionary*)loadWorld
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	return [ud objectForKey:@"world"];
}

+ (void)saveWorld:(NSDictionary*)value
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	[ud setObject:value forKey:@"world"];
}

#pragma mark -
#pragma mark Window

+ (NSDictionary*)loadWindowStateWithName:(NSString*)name
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	return [ud objectForKey:name];
}

+ (void)saveWindowState:(NSDictionary*)value name:(NSString*)name
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	[ud setObject:value forKey:name];
}

#pragma mark -
#pragma mark Keywords

static NSMutableArray* keywords;
static NSMutableArray* excludeWords;

+ (void)loadKeywords
{
	if (keywords) {
		[keywords removeAllObjects];
	} else {
		keywords = [NSMutableArray new];
	}
	
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	NSArray* ary = [ud objectForKey:@"keywords"];
	for (NSDictionary* e in ary) {
		NSString* s = [e objectForKey:@"string"];
		if (s) [keywords addObject:s];
	}
}

+ (void)loadExcludeWords
{
	if (excludeWords) {
		[excludeWords removeAllObjects];
	} else {
		excludeWords = [NSMutableArray new];
	}
	
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	NSArray* ary = [ud objectForKey:@"excludeWords"];
	for (NSDictionary* e in ary) {
		NSString* s = [e objectForKey:@"string"];
		if (s) [excludeWords addObject:s];
	}
}

+ (void)cleanUpWords:(NSString*)key
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	NSArray* src = [ud objectForKey:key];
	
	NSMutableArray* ary = [NSMutableArray array];
	for (NSDictionary* e in src) {
		NSString* s = [e objectForKey:@"string"];
		if (s.length) {
			[ary addObject:s];
		}
	}
	
	[ary sortUsingSelector:@selector(caseInsensitiveCompare:)];
	
	NSMutableArray* saveAry = [NSMutableArray array];
	for (NSString* s in ary) {
		NSMutableDictionary* dic = [NSMutableDictionary dictionary];
		[dic setObject:s forKey:@"string"];
		[saveAry addObject:dic];
	}
	[ud setObject:saveAry forKey:key];
	[ud synchronize];
}

+ (void)cleanUpWords
{
	[self cleanUpWords:@"keywords"];
	[self cleanUpWords:@"excludeWords"];
}

+ (NSArray*)keywords
{
	return keywords;
}

+ (NSArray*)excludeWords
{
	return excludeWords;
}

#pragma mark -
#pragma mark KVO

+ (void)observeValueForKeyPath:(NSString*)key
					  ofObject:(id)object
						change:(NSDictionary *)change
					   context:(void *)context
{
	if ([key isEqualToString:@"keywords"]) {
		[self loadKeywords];
	} else if ([key isEqualToString:@"excludeWords"]) {
		[self loadExcludeWords];
	}
}

+ (void)initPreferences
{
	startUpTime = (long)[[NSDate date] timeIntervalSince1970];
	
	NSString* nick = NSUserName();
	nick = [nick stringByReplacingOccurrencesOfString:@" " withString:@"_"];
	nick = [nick stringByMatching:@"[^a-zA-Z0-9-_]" replace:RKReplaceAll withReferenceString:@""];

	if (nick == nil) {
		nick = @"User";
	}
	
	NSMutableDictionary* d = [NSMutableDictionary dictionary];
	[d setBool:YES forKey:@"WebKitDeveloperExtras"];
	[d setInt:DCC_SHOW_DIALOG forKey:@"Preferences.DCC.action"];
	[d setInt:ADDRESS_DETECT_JOIN forKey:@"Preferences.DCC.address_detection_method"];
	[d setObject:@"" forKey:@"Preferences.DCC.myaddress"];
	[d setObject:nick forKey:@"Preferences.Identity.nickname"];
	[d setBool:NO forKey:@"Preferences.General.copyonselect"];
	[d setBool:NO forKey:@"Preferences.General.strip_formatting"];
	[d setBool:NO forKey:@"Preferences.General.rtl_formatting"];
	[d setBool:YES forKey:@"Preferences.General.display_servmotd"];
	[d setObject:@"textual" forKey:@"Preferences.Identity.username"];
	[d setObject:@"Textual User" forKey:@"Preferences.Identity.realname"];
	[d setBool:YES forKey:@"Preferences.General.dockbadges"];
	[d setBool:YES forKey:@"Preferences.General.autoadd_scrollbackmark"];
	[d setBool:NO forKey:@"Preferences.General.handle_server_notices"];
	[d setBool:NO forKey:@"Preferences.FloodControl.enabled"];
	[d setInt:2 forKey:@"Preferences.FloodControl.timer"];
	[d setInt:100 forKey:@"Preferences.FloodControl.maxmsg"];
	[d setBool:NO forKey:@"Preferences.General.handle_operalerts"];
	[d setBool:NO forKey:@"Preferences.General.process_channel_modes"];
	[d setBool:NO forKey:@"Preferences.General.rejoin_onkick"];
	[d setBool:NO forKey:@"Preferences.General.autojoin_oninvite"];
	[d setBool:NO forKey:@"Preferences.General.amsg_allconnections"];
	[d setBool:NO forKey:@"Preferences.General.away_allconnections"];
	[d setBool:NO forKey:@"Preferences.General.nick_allconnections"];
	[d setBool:YES forKey:@"Preferences.General.confirm_quit"];
	[d setBool:NO forKey:@"Preferences.General.connect_on_doubleclick"];
	[d setBool:NO forKey:@"Preferences.General.disconnect_on_doubleclick"];
	[d setBool:NO forKey:@"Preferences.General.join_on_doubleclick"];
	[d setBool:NO forKey:@"Preferences.General.leave_on_doubleclick"];
	[d setBool:YES forKey:@"Preferences.General.log_transcript"];
	[d setBool:NO forKey:@"Preferences.General.open_browser_in_background"];
	[d setBool:NO forKey:@"Preferences.General.show_inline_images"];
	[d setBool:YES forKey:@"PrefWebKitDeveloperExtraserences.General.show_join_leave"];
	[d setBool:YES forKey:@"Preferences.General.use_growl"];
	[d setBool:YES forKey:@"Preferences.General.stop_growl_on_active"];
	[d setBool:YES forKey:@"eventHighlightGrowl"];
	[d setBool:YES forKey:@"eventNewtalkGrowl"];
	[d setInt:TAB_COMPLETE_NICK forKey:@"Preferences.General.tab_action"];
	[d setBool:YES forKey:@"Preferences.Keyword.current_nick"];
	[d setInt:KEYWORD_MATCH_PARTIAL forKey:@"Preferences.Keyword.matching_method"];
	[d setObject:@"user:Simplified Dark" forKey:@"Preferences.Theme.name"];
	[d setObject:@"Lucida Grande" forKey:@"Preferences.Theme.log_font_name"];
	[d setDouble:12 forKey:@"Preferences.Theme.log_font_size"];
	[d setObject:@"<%@%n>" forKey:@"Preferences.Theme.nick_format"];
	[d setBool:NO forKey:@"Preferences.Theme.override_log_font"];
	[d setBool:NO forKey:@"Preferences.Theme.override_nick_format"];
	[d setBool:YES forKey:@"Preferences.Theme.indent_onwordwrap"];
	[d setBool:NO forKey:@"Preferences.Theme.override_timestamp_format"];
	[d setObject:@"[%m/%d/%Y -:- %I:%M:%S %p]" forKey:@"Preferences.Theme.timestamp_format"];
	[d setDouble:1 forKey:@"Preferences.Theme.transparency"];
	[d setInt:1096 forKey:@"Preferences.DCC.first_port"];
	[d setInt:1115 forKey:@"Preferences.DCC.last_port"];
	[d setInt:300 forKey:@"Preferences.General.max_log_lines"];
	[d setObject:@"~/Documents/Textual Logs" forKey:@"Preferences.General.transcript_folder"];
	
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	[ud registerDefaults:d];
	[ud addObserver:(NSObject*)self forKeyPath:@"keywords" options:NSKeyValueObservingOptionNew context:NULL];
	[ud addObserver:(NSObject*)self forKeyPath:@"excludeWords" options:NSKeyValueObservingOptionNew context:NULL];

	systemVersionPlist = [[NSDictionary allocWithZone:nil] initWithContentsOfFile:@"/System/Library/CoreServices/ServerVersion.plist"];
	if( !systemVersionPlist ) systemVersionPlist = [[NSDictionary allocWithZone:nil] initWithContentsOfFile:@"/System/Library/CoreServices/SystemVersion.plist"];
	textualPlist = [[NSBundle mainBundle] infoDictionary];
	
	[self loadKeywords];
	[self loadExcludeWords];
	[self populateCommandIndex];
}

+ (void)sync
{
	[[NSUserDefaults standardUserDefaults] synchronize];
}

@end