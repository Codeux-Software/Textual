/*
 * The AutoHyperlinks Framework is the legal property of its developers (DEVELOPERS), 
 * whose names are listed in the copyright file included with this source distribution.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above copyright
 *       notice, this list of conditions and the following disclaimer in the
 *       documentation and/or other materials provided with the distribution.
 *     * Neither the name of the AutoHyperlinks Framework nor the
 *       names of its contributors may be used to endorse or promote products
 *       derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY ITS DEVELOPERS ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL ITS DEVELOPERS BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

typedef void					*yyscan_t;
typedef struct					AH_buffer_state *AH_BUFFER_STATE;

extern long						AHlex(yyscan_t yyscanner);
extern long						AHlex_init(yyscan_t *ptr_yy_globals);
extern long						AHlex_destroy(yyscan_t yyscanner);
extern long						AHget_leng(yyscan_t scanner);
extern void						AHset_in(FILE *in_str, yyscan_t scanner);
extern void						AH_switch_to_buffer(AH_BUFFER_STATE, yyscan_t scanner);
extern void						AH_delete_buffer(AH_BUFFER_STATE, yyscan_t scanner);
extern YY_EXTRA_TYPE			AHget_extra(yyscan_t scanner);
extern AH_BUFFER_STATE			AH_scan_string(const char *, yyscan_t scanner);

@interface AHHyperlinkScanner : NSObject 
{
	NSDictionary		*m_urlSchemes;
	NSString			*m_scanString;
	
	BOOL				m_strictChecking;
	BOOL				m_firstCharMismactch;
	
	unsigned long		m_scanLocation;
	unsigned long		m_scanStringLength;
}

@property (nonatomic, readonly) NSDictionary *urlSchemes;
@property (nonatomic, readonly) NSString *scanString;
@property (nonatomic, readonly) BOOL strictChecking;
@property (nonatomic, readonly) unsigned long scanLocation;
@property (nonatomic, readonly) unsigned long scanStringLength;

+ (AHHyperlinkScanner *)linkScanner;

- (NSArray *)matchesForString:(NSString *)inString;
- (NSArray *)strictMatchesForString:(NSString *)inString;
@end