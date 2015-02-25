
/* A portion of this source file contains copyrighted work derived from one or more
 3rd party, open source projects. The use of this work is hereby acknowledged. */

//
// This source file is based off the work located at the following web page(s):
// <https://code.google.com/p/chromium/codesearch#chromium/src/net/ssl/ssl_cipher_suite_names.cc>
// <https://github.com/adium/adium/blob/master/Plugins/Purple%20Service/libpurple_extensions/ssl-cdsa.c>
//

/*
 * CDSA SSL-plugin for purple
 *
 * Copyright (c) 2007 Andreas Monitzer <andy@monitzer.com>
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 */

// Copyright (c) 2013 The Chromium Authors. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are
// met:
//
//    * Redistributions of source code must retain the above copyright
// notice, this list of conditions and the following disclaimer.
//    * Redistributions in binary form must reproduce the above
// copyright notice, this list of conditions and the following disclaimer
// in the documentation and/or other materials provided with the
// distribution.
//    * Neither the name of Google Inc. nor the names of its
// contributors may be used to endorse or promote products derived from
// this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
// LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
// A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
// OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
// SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
// LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
// DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
// THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#import "TextualApplication.h"

static const int kAEADMACValue = 7;

typedef struct {
	uint16 cipher_suite, encoded;
} CipherSuite;

static const CipherSuite kCipherSuites[] = {
	{0x0, 0x0},        // TLS_NULL_WITH_NULL_NULL
	{0x1, 0x101},      // TLS_RSA_WITH_NULL_MD5
	{0x2, 0x102},      // TLS_RSA_WITH_NULL_SHA
	{0x3, 0x209},      // TLS_RSA_EXPORT_WITH_RC4_40_MD5
	{0x4, 0x111},      // TLS_RSA_WITH_RC4_128_MD5
	{0x5, 0x112},      // TLS_RSA_WITH_RC4_128_SHA
	{0x6, 0x219},      // TLS_RSA_EXPORT_WITH_RC2_CBC_40_MD5
	{0x7, 0x122},      // TLS_RSA_WITH_IDEA_CBC_SHA
	{0x8, 0x22a},      // TLS_RSA_EXPORT_WITH_DES40_CBC_SHA
	{0x9, 0x132},      // TLS_RSA_WITH_DES_CBC_SHA
	{0xa, 0x13a},      // TLS_RSA_WITH_3DES_EDE_CBC_SHA
	{0xb, 0x32a},      // TLS_DH_DSS_EXPORT_WITH_DES40_CBC_SHA
	{0xc, 0x432},      // TLS_DH_DSS_WITH_DES_CBC_SHA
	{0xd, 0x43a},      // TLS_DH_DSS_WITH_3DES_EDE_CBC_SHA
	{0xe, 0x52a},      // TLS_DH_RSA_EXPORT_WITH_DES40_CBC_SHA
	{0xf, 0x632},      // TLS_DH_RSA_WITH_DES_CBC_SHA
	{0x10, 0x63a},     // TLS_DH_RSA_WITH_3DES_EDE_CBC_SHA
	{0x11, 0x72a},     // TLS_DHE_DSS_EXPORT_WITH_DES40_CBC_SHA
	{0x12, 0x832},     // TLS_DHE_DSS_WITH_DES_CBC_SHA
	{0x13, 0x83a},     // TLS_DHE_DSS_WITH_3DES_EDE_CBC_SHA
	{0x14, 0x92a},     // TLS_DHE_RSA_EXPORT_WITH_DES40_CBC_SHA
	{0x15, 0xa32},     // TLS_DHE_RSA_WITH_DES_CBC_SHA
	{0x16, 0xa3a},     // TLS_DHE_RSA_WITH_3DES_EDE_CBC_SHA
	{0x17, 0xb09},     // TLS_DH_anon_EXPORT_WITH_RC4_40_MD5
	{0x18, 0xc11},     // TLS_DH_anon_WITH_RC4_128_MD5
	{0x19, 0xb2a},     // TLS_DH_anon_EXPORT_WITH_DES40_CBC_SHA
	{0x1a, 0xc32},     // TLS_DH_anon_WITH_DES_CBC_SHA
	{0x1b, 0xc3a},     // TLS_DH_anon_WITH_3DES_EDE_CBC_SHA
	{0x2f, 0x142},     // TLS_RSA_WITH_AES_128_CBC_SHA
	{0x30, 0x442},     // TLS_DH_DSS_WITH_AES_128_CBC_SHA
	{0x31, 0x642},     // TLS_DH_RSA_WITH_AES_128_CBC_SHA
	{0x32, 0x842},     // TLS_DHE_DSS_WITH_AES_128_CBC_SHA
	{0x33, 0xa42},     // TLS_DHE_RSA_WITH_AES_128_CBC_SHA
	{0x34, 0xc42},     // TLS_DH_anon_WITH_AES_128_CBC_SHA
	{0x35, 0x14a},     // TLS_RSA_WITH_AES_256_CBC_SHA
	{0x36, 0x44a},     // TLS_DH_DSS_WITH_AES_256_CBC_SHA
	{0x37, 0x64a},     // TLS_DH_RSA_WITH_AES_256_CBC_SHA
	{0x38, 0x84a},     // TLS_DHE_DSS_WITH_AES_256_CBC_SHA
	{0x39, 0xa4a},     // TLS_DHE_RSA_WITH_AES_256_CBC_SHA
	{0x3a, 0xc4a},     // TLS_DH_anon_WITH_AES_256_CBC_SHA
	{0x3b, 0x103},     // TLS_RSA_WITH_NULL_SHA256
	{0x3c, 0x143},     // TLS_RSA_WITH_AES_128_CBC_SHA256
	{0x3d, 0x14b},     // TLS_RSA_WITH_AES_256_CBC_SHA256
	{0x3e, 0x443},     // TLS_DH_DSS_WITH_AES_128_CBC_SHA256
	{0x3f, 0x643},     // TLS_DH_RSA_WITH_AES_128_CBC_SHA256
	{0x40, 0x843},     // TLS_DHE_DSS_WITH_AES_128_CBC_SHA256
	{0x41, 0x152},     // TLS_RSA_WITH_CAMELLIA_128_CBC_SHA
	{0x42, 0x452},     // TLS_DH_DSS_WITH_CAMELLIA_128_CBC_SHA
	{0x43, 0x652},     // TLS_DH_RSA_WITH_CAMELLIA_128_CBC_SHA
	{0x44, 0x852},     // TLS_DHE_DSS_WITH_CAMELLIA_128_CBC_SHA
	{0x45, 0xa52},     // TLS_DHE_RSA_WITH_CAMELLIA_128_CBC_SHA
	{0x46, 0xc52},     // TLS_DH_anon_WITH_CAMELLIA_128_CBC_SHA
	{0x67, 0xa43},     // TLS_DHE_RSA_WITH_AES_128_CBC_SHA256
	{0x68, 0x44b},     // TLS_DH_DSS_WITH_AES_256_CBC_SHA256
	{0x69, 0x64b},     // TLS_DH_RSA_WITH_AES_256_CBC_SHA256
	{0x6a, 0x84b},     // TLS_DHE_DSS_WITH_AES_256_CBC_SHA256
	{0x6b, 0xa4b},     // TLS_DHE_RSA_WITH_AES_256_CBC_SHA256
	{0x6c, 0xc43},     // TLS_DH_anon_WITH_AES_128_CBC_SHA256
	{0x6d, 0xc4b},     // TLS_DH_anon_WITH_AES_256_CBC_SHA256
	{0x84, 0x15a},     // TLS_RSA_WITH_CAMELLIA_256_CBC_SHA
	{0x85, 0x45a},     // TLS_DH_DSS_WITH_CAMELLIA_256_CBC_SHA
	{0x86, 0x65a},     // TLS_DH_RSA_WITH_CAMELLIA_256_CBC_SHA
	{0x87, 0x85a},     // TLS_DHE_DSS_WITH_CAMELLIA_256_CBC_SHA
	{0x88, 0xa5a},     // TLS_DHE_RSA_WITH_CAMELLIA_256_CBC_SHA
	{0x89, 0xc5a},     // TLS_DH_anon_WITH_CAMELLIA_256_CBC_SHA
	{0x96, 0x162},     // TLS_RSA_WITH_SEED_CBC_SHA
	{0x97, 0x462},     // TLS_DH_DSS_WITH_SEED_CBC_SHA
	{0x98, 0x662},     // TLS_DH_RSA_WITH_SEED_CBC_SHA
	{0x99, 0x862},     // TLS_DHE_DSS_WITH_SEED_CBC_SHA
	{0x9a, 0xa62},     // TLS_DHE_RSA_WITH_SEED_CBC_SHA
	{0x9b, 0xc62},     // TLS_DH_anon_WITH_SEED_CBC_SHA
	{0x9c, 0x16f},     // TLS_RSA_WITH_AES_128_GCM_SHA256
	{0x9d, 0x177},     // TLS_RSA_WITH_AES_256_GCM_SHA384
	{0x9e, 0xa6f},     // TLS_DHE_RSA_WITH_AES_128_GCM_SHA256
	{0x9f, 0xa77},     // TLS_DHE_RSA_WITH_AES_256_GCM_SHA384
	{0xa0, 0x66f},     // TLS_DH_RSA_WITH_AES_128_GCM_SHA256
	{0xa1, 0x677},     // TLS_DH_RSA_WITH_AES_256_GCM_SHA384
	{0xa2, 0x86f},     // TLS_DHE_DSS_WITH_AES_128_GCM_SHA256
	{0xa3, 0x877},     // TLS_DHE_DSS_WITH_AES_256_GCM_SHA384
	{0xa4, 0x46f},     // TLS_DH_DSS_WITH_AES_128_GCM_SHA256
	{0xa5, 0x477},     // TLS_DH_DSS_WITH_AES_256_GCM_SHA384
	{0xa6, 0xc6f},     // TLS_DH_anon_WITH_AES_128_GCM_SHA256
	{0xa7, 0xc77},     // TLS_DH_anon_WITH_AES_256_GCM_SHA384
	{0xba, 0x153},     // TLS_RSA_WITH_CAMELLIA_128_CBC_SHA256
	{0xbb, 0x453},     // TLS_DH_DSS_WITH_CAMELLIA_128_CBC_SHA256
	{0xbc, 0x653},     // TLS_DH_RSA_WITH_CAMELLIA_128_CBC_SHA256
	{0xbd, 0x853},     // TLS_DHE_DSS_WITH_CAMELLIA_128_CBC_SHA256
	{0xbe, 0xa53},     // TLS_DHE_RSA_WITH_CAMELLIA_128_CBC_SHA256
	{0xbf, 0xc53},     // TLS_DH_anon_WITH_CAMELLIA_128_CBC_SHA256
	{0xc0, 0x15b},     // TLS_RSA_WITH_CAMELLIA_256_CBC_SHA256
	{0xc1, 0x45b},     // TLS_DH_DSS_WITH_CAMELLIA_256_CBC_SHA256
	{0xc2, 0x65b},     // TLS_DH_RSA_WITH_CAMELLIA_256_CBC_SHA256
	{0xc3, 0x85b},     // TLS_DHE_DSS_WITH_CAMELLIA_256_CBC_SHA256
	{0xc4, 0xa5b},     // TLS_DHE_RSA_WITH_CAMELLIA_256_CBC_SHA256
	{0xc5, 0xc5b},     // TLS_DH_anon_WITH_CAMELLIA_256_CBC_SHA256
	{0xc001, 0xd02},   // TLS_ECDH_ECDSA_WITH_NULL_SHA
	{0xc002, 0xd12},   // TLS_ECDH_ECDSA_WITH_RC4_128_SHA
	{0xc003, 0xd3a},   // TLS_ECDH_ECDSA_WITH_3DES_EDE_CBC_SHA
	{0xc004, 0xd42},   // TLS_ECDH_ECDSA_WITH_AES_128_CBC_SHA
	{0xc005, 0xd4a},   // TLS_ECDH_ECDSA_WITH_AES_256_CBC_SHA
	{0xc006, 0xe02},   // TLS_ECDHE_ECDSA_WITH_NULL_SHA
	{0xc007, 0xe12},   // TLS_ECDHE_ECDSA_WITH_RC4_128_SHA
	{0xc008, 0xe3a},   // TLS_ECDHE_ECDSA_WITH_3DES_EDE_CBC_SHA
	{0xc009, 0xe42},   // TLS_ECDHE_ECDSA_WITH_AES_128_CBC_SHA
	{0xc00a, 0xe4a},   // TLS_ECDHE_ECDSA_WITH_AES_256_CBC_SHA
	{0xc00b, 0xf02},   // TLS_ECDH_RSA_WITH_NULL_SHA
	{0xc00c, 0xf12},   // TLS_ECDH_RSA_WITH_RC4_128_SHA
	{0xc00d, 0xf3a},   // TLS_ECDH_RSA_WITH_3DES_EDE_CBC_SHA
	{0xc00e, 0xf42},   // TLS_ECDH_RSA_WITH_AES_128_CBC_SHA
	{0xc00f, 0xf4a},   // TLS_ECDH_RSA_WITH_AES_256_CBC_SHA
	{0xc010, 0x1002},  // TLS_ECDHE_RSA_WITH_NULL_SHA
	{0xc011, 0x1012},  // TLS_ECDHE_RSA_WITH_RC4_128_SHA
	{0xc012, 0x103a},  // TLS_ECDHE_RSA_WITH_3DES_EDE_CBC_SHA
	{0xc013, 0x1042},  // TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA
	{0xc014, 0x104a},  // TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA
	{0xc015, 0x1102},  // TLS_ECDH_anon_WITH_NULL_SHA
	{0xc016, 0x1112},  // TLS_ECDH_anon_WITH_RC4_128_SHA
	{0xc017, 0x113a},  // TLS_ECDH_anon_WITH_3DES_EDE_CBC_SHA
	{0xc018, 0x1142},  // TLS_ECDH_anon_WITH_AES_128_CBC_SHA
	{0xc019, 0x114a},  // TLS_ECDH_anon_WITH_AES_256_CBC_SHA
	{0xc023, 0xe43},   // TLS_ECDHE_ECDSA_WITH_AES_128_CBC_SHA256
	{0xc024, 0xe4c},   // TLS_ECDHE_ECDSA_WITH_AES_256_CBC_SHA384
	{0xc025, 0xd43},   // TLS_ECDH_ECDSA_WITH_AES_128_CBC_SHA256
	{0xc026, 0xd4c},   // TLS_ECDH_ECDSA_WITH_AES_256_CBC_SHA384
	{0xc027, 0x1043},  // TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA256
	{0xc028, 0x104c},  // TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA384
	{0xc029, 0xf43},   // TLS_ECDH_RSA_WITH_AES_128_CBC_SHA256
	{0xc02a, 0xf4c},   // TLS_ECDH_RSA_WITH_AES_256_CBC_SHA384
	{0xc02b, 0xe6f},   // TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256
	{0xc02c, 0xe77},   // TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384
	{0xc02d, 0xd6f},   // TLS_ECDH_ECDSA_WITH_AES_128_GCM_SHA256
	{0xc02e, 0xd77},   // TLS_ECDH_ECDSA_WITH_AES_256_GCM_SHA384
	{0xc02f, 0x106f},  // TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256
	{0xc030, 0x1077},  // TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384
	{0xc031, 0xf6f},   // TLS_ECDH_RSA_WITH_AES_128_GCM_SHA256
	{0xc032, 0xf77},   // TLS_ECDH_RSA_WITH_AES_256_GCM_SHA384
	{0xc072, 0xe53},   // TLS_ECDHE_ECDSA_WITH_CAMELLIA_128_CBC_SHA256
	{0xc073, 0xe5c},   // TLS_ECDHE_ECDSA_WITH_CAMELLIA_256_CBC_SHA384
	{0xc074, 0xd53},   // TLS_ECDH_ECDSA_WITH_CAMELLIA_128_CBC_SHA256
	{0xc075, 0xd5c},   // TLS_ECDH_ECDSA_WITH_CAMELLIA_256_CBC_SHA384
	{0xc076, 0x1053},  // TLS_ECDHE_RSA_WITH_CAMELLIA_128_CBC_SHA256
	{0xc077, 0x105c},  // TLS_ECDHE_RSA_WITH_CAMELLIA_256_CBC_SHA384
	{0xc078, 0xf53},   // TLS_ECDH_RSA_WITH_CAMELLIA_128_CBC_SHA256
	{0xc079, 0xf5c},   // TLS_ECDH_RSA_WITH_CAMELLIA_256_CBC_SHA384
	{0xc07a, 0x17f},   // TLS_RSA_WITH_CAMELLIA_128_GCM_SHA256
	{0xc07b, 0x187},   // TLS_RSA_WITH_CAMELLIA_256_GCM_SHA384
	{0xc07c, 0xa7f},   // TLS_DHE_RSA_WITH_CAMELLIA_128_GCM_SHA256
	{0xc07d, 0xa87},   // TLS_DHE_RSA_WITH_CAMELLIA_256_GCM_SHA384
	{0xc07e, 0x67f},   // TLS_DH_RSA_WITH_CAMELLIA_128_GCM_SHA256
	{0xc07f, 0x687},   // TLS_DH_RSA_WITH_CAMELLIA_256_GCM_SHA384
	{0xc080, 0x87f},   // TLS_DHE_DSS_WITH_CAMELLIA_128_GCM_SHA256
	{0xc081, 0x887},   // TLS_DHE_DSS_WITH_CAMELLIA_256_GCM_SHA384
	{0xc082, 0x47f},   // TLS_DH_DSS_WITH_CAMELLIA_128_GCM_SHA256
	{0xc083, 0x487},   // TLS_DH_DSS_WITH_CAMELLIA_256_GCM_SHA384
	{0xc084, 0xc7f},   // TLS_DH_anon_WITH_CAMELLIA_128_GCM_SHA256
	{0xc085, 0xc87},   // TLS_DH_anon_WITH_CAMELLIA_256_GCM_SHA384
	{0xc086, 0xe7f},   // TLS_ECDHE_ECDSA_WITH_CAMELLIA_128_GCM_SHA256
	{0xc087, 0xe87},   // TLS_ECDHE_ECDSA_WITH_CAMELLIA_256_GCM_SHA384
	{0xc088, 0xd7f},   // TLS_ECDH_ECDSA_WITH_CAMELLIA_128_GCM_SHA256
	{0xc089, 0xd87},   // TLS_ECDH_ECDSA_WITH_CAMELLIA_256_GCM_SHA384
	{0xc08a, 0x107f},  // TLS_ECDHE_RSA_WITH_CAMELLIA_128_GCM_SHA256
	{0xc08b, 0x1087},  // TLS_ECDHE_RSA_WITH_CAMELLIA_256_GCM_SHA384
	{0xc08c, 0xf7f},   // TLS_ECDH_RSA_WITH_CAMELLIA_128_GCM_SHA256
	{0xc08d, 0xf87},   // TLS_ECDH_RSA_WITH_CAMELLIA_256_GCM_SHA384
	{0xcc13, 0x108f},  // TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305
	{0xcc14, 0x0e8f},  // TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305
	{0xcc15, 0x0a8f},  // TLS_DHE_RSA_WITH_CHACHA20_POLY1305
};

static const char *kKeyExchangeNames[] = {
	"NULL",
	"RSA",
	"RSA-EXPORT",
	"DH-DSS-EXPORT",
	"DH-DSS",
	"DH-RSA-EXPORT",
	"DH-RSA",
	"DHE-DSS-EXPORT",
	"DHE-DSS",
	"DHE-RSA-EXPORT",
	"DHE-RSA",
	"DH-anon-EXPORT",
	"DH-anon",
	"ECDH-ECDSA",
	"ECDHE-ECDSA",
	"ECDH-RSA",
	"ECDHE-RSA",
	"ECDH-anon",
};

static const char *kCipherNames[] = {
	"NULL",
	"RC4-40",
	"RC4-128",
	"RC2-CBC-40",
	"IDEA-CBC",
	"DES40-CBC",
	"DES-CBC",
	"3DES-EDE-CBC",
	"AES-128-CBC",
	"AES-256-CBC",
	"CAMELLIA-128-CBC",
	"CAMELLIA-256-CBC",
	"SEED-CBC",
	"AES-128-GCM",
	"AES-256-GCM",
	"CAMELLIA-128-GCM",
	"CAMELLIA-256-GCM",
	"CHACHA20-POLY1305",
};

static const char *kMacNames[] = {
	"NULL",
	"MD5",
	"SHA1",
	"SHA256",
	"SHA384",
};

@implementation GCDAsyncSocket (GCDsyncSocketCipherNamesExtension)

- (SSLProtocol)sslNegotiatedProtocol
{
	__block SSLProtocol protocol;

	dispatch_block_t block = ^{
		OSStatus status = SSLGetNegotiatedProtocolVersion(self.sslContext, &protocol);

#pragma unused(status)
	};

	[self performBlock:block];

	return protocol;
}

- (SSLCipherSuite)sslNegotiatedCipherSuite
{
	__block SSLCipherSuite cipher;

	dispatch_block_t block = ^{
		OSStatus status = SSLGetNegotiatedCipher(self.sslContext, &cipher);

#pragma unused(status)
	};

	[self performBlock:block];

	return cipher;
}

- (NSString *)sslNegotiatedProtocolString
{
	SSLProtocol protocol = [self sslNegotiatedProtocol];

	NSString *protocolString = @"Unknown";

	switch (protocol) {
		case kSSLProtocol2:
		{
			protocolString = @"Secure Sockets Layer (SSL) version 2.0";

			break;
		}
		case kSSLProtocol3:
		{
			protocolString = @"Secure Sockets Layer (SSL), version 3.0";

			break;
		}
		case kTLSProtocol1:
		{
			protocolString = @"Transport Layer Security (TLS), version 1.0";

			break;
		}
		case kTLSProtocol11:
		{
			protocolString = @"Transport Layer Security (TLS), version 1.1";

			break;
		}
		case kTLSProtocol12:
		{
			protocolString = @"Transport Layer Security (TLS), version 1.2";

			break;
		}
		default:
		{
			break;
		}
	}

	return protocolString;
}

- (NSString *)sslNegotiatedCipherSuiteString
{
	SSLCipherSuite cipher = [self sslNegotiatedCipherSuite];

	for (unsigned long pos = 0; pos < sizeof(kCipherSuites) / sizeof(CipherSuite); pos++) {
		CipherSuite cs = kCipherSuites[pos];

		if (cs.cipher_suite == cipher) {
			/* Begin building cipher suite string. */
			NSMutableString *resultString = [NSMutableString string];

#define _append(store, index)	[resultString appendString:[NSString stringWithUTF8String:(store)[(index)]]];

// -

			_append(kKeyExchangeNames, (cs.encoded >> 8))

			[resultString appendString:@" "];

// -

			_append(kCipherNames, ((cs.encoded >> 3) & 0x1f));

			[resultString appendString:@" "];

// -

			NSInteger macIndex = (cs.encoded & 0x7);

			if (macIndex == kAEADMACValue) {
				macIndex = 0; // Default to NULL
			}

			_append(kMacNames, macIndex);

// -

#undef _append

			return resultString;
		}
	}
	
	return @"Unknown";
}

@end
