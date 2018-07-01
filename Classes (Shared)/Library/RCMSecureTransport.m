
/* A portion of this source file contains copyrighted work derived from one or more
 3rd-party, open source projects. The use of this work is hereby acknowledged. */

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

#import "RCMSecureTransport.h"

NS_ASSUME_NONNULL_BEGIN

static const int kAEADMACValue = 7;

static const int kTLS13KeyExchangeValue = 31;

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
	{0x1301, 0x1f6f},  // TLS_AES_128_GCM_SHA256
	{0x1302, 0x1f77},  // TLS_AES_256_GCM_SHA384
	{0x1303, 0x1f8f},  // TLS_CHACHA20_POLY1305_SHA256
	{0x16b7, 0x128f},  // TLS_CECPQ1_RSA_WITH_CHACHA20_POLY1305_SHA256 (exper)
	{0x16b8, 0x138f},  // TLS_CECPQ1_ECDSA_WITH_CHACHA20_POLY1305_SHA256 (exper)
	{0x16b9, 0x1277},  // TLS_CECPQ1_RSA_WITH_AES_256_GCM_SHA384 (exper)
	{0x16ba, 0x1377},  // TLS_CECPQ1_ECDSA_WITH_AES_256_GCM_SHA384 (exper)
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
	{0xcc13, 0x108f},  // TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305 (non-standard)
	{0xcc14, 0x0e8f},  // TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305 (non-standard)
	{0xcca8, 0x108f},  // TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305_SHA256
	{0xcca9, 0x0e8f},  // TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305_SHA256
};

static const char * _Nonnull kKeyExchangeNames[] = {
	"NULL",            // 0
	"RSA",             // 1
	"RSA-EXPORT",      // 2
	"DH-DSS-EXPORT",   // 3
	"DH-DSS",          // 4
	"DH-RSA-EXPORT",   // 5
	"DH-RSA",          // 6
	"DHE-DSS-EXPORT",  // 7
	"DHE-DSS",         // 8
	"DHE-RSA-EXPORT",  // 9
	"DHE-RSA",         // 10
	"DH-anon-EXPORT",  // 11
	"DH-anon",         // 12
	"ECDH-ECDSA",      // 13
	"ECDHE-ECDSA",     // 14
	"ECDH-RSA",        // 15
	"ECDHE-RSA",       // 16
	"ECDH-anon",       // 17
	"CECPQ1-RSA",      // 18
	"CECPQ1-ECDSA",    // 19
	// 31 is reserved to indicate a TLS 1.3 AEAD-only suite.
};

static const char * _Nonnull kCipherNames[] = {
	"NULL",  // 0
	"RC4-40",  // 1
	"RC4-128",  // 2
	"RC2-CBC-40",  // 3
	"IDEA-CBC",  // 4
	"DES40-CBC",  // 5
	"DES-CBC",  // 6
	"3DES-EDE-CBC",  // 7
	"AES-128-CBC",  // 8
	"AES-256-CBC",  // 9
	"CAMELLIA-128-CBC",  // 10
	"CAMELLIA-256-CBC",  // 11
	"SEED-CBC",  // 12
	"AES-128-GCM",  // 13
	"AES-256-GCM",  // 14
	"CAMELLIA-128-GCM",  // 15
	"CAMELLIA-256-GCM",  // 16
	"CHACHA20-POLY1305",  // 17
};

static const char * _Nonnull kMacNames[] = {
	"NULL",  // 0
	"MD5",  // 1
	"SHA1",  // 2
	"SHA256",  // 3
	"SHA384",  // 4
	// 7 is reserved to indicate an AEAD cipher suite.
};

@implementation RCMSecureTransport

+ (nullable NSString *)descriptionForProtocolVersion:(SSLProtocol)protocolVersion
{
	NSString *protocolString = @"Unknown";

	switch (protocolVersion) {
		case kSSLProtocol2:
		{
			protocolString = @"Secure Sockets Layer (SSL), version 2.0";

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

#ifdef TXSystemIsOSXHighSierraOrLater
		case kTLSProtocol13:
		{
			protocolString = @"Transport Layer Security (TLS), version 1.3";

			break;
		}
#endif

		default:
		{
			break;
		}
	}

	return protocolString;
}

+ (NSArray<NSString *> *)descriptionsForCipherListCollection:(RCMCipherSuiteCollection)collection
{
	return [self descriptionsForCipherListCollection:collection withProtocol:NO];
}

+ (NSArray<NSString *> *)descriptionsForCipherListCollection:(RCMCipherSuiteCollection)collection withProtocol:(BOOL)appendProtocol
{
	NSArray *cipherSuites = [self cipherSuitesInCollection:collection];

	return [self descriptionsForCipherSuites:cipherSuites withProtocol:appendProtocol];
}

+ (NSArray<NSString *> *)descriptionsForCipherSuites:(NSArray<NSNumber *> *)cipherSuites
{
	return [self descriptionsForCipherSuites:cipherSuites withProtocol:NO];
}

+ (NSArray<NSString *> *)descriptionsForCipherSuites:(NSArray<NSNumber *> *)cipherSuites withProtocol:(BOOL)appendProtocol
{
	NSParameterAssert(cipherSuites != nil);

	NSMutableArray<NSString *> *descriptions = [NSMutableArray arrayWithCapacity:cipherSuites.count];

	for (NSNumber *cipherSuite in cipherSuites) {
		[descriptions addObject:
		 [self descriptionForCipherSuite:cipherSuite.intValue withProtocol:appendProtocol]];
	}

	return [descriptions copy];
}

+ (nullable NSString *)descriptionForCipherSuite:(SSLCipherSuite)cipherSuite
{
	return [self descriptionForCipherSuite:cipherSuite withProtocol:NO];
}

+ (nullable NSString *)descriptionForCipherSuite:(SSLCipherSuite)cipherSuite withProtocol:(BOOL)appendProtocol
{
	for (unsigned long pos = 0; pos < sizeof(kCipherSuites) / sizeof(CipherSuite); pos++) {
		CipherSuite cs = kCipherSuites[pos];

		if (cs.cipher_suite != cipherSuite) {
			continue;
		}

		NSMutableString *resultString = [NSMutableString string];

#define _append(store, index)	[resultString appendString:@(store[index])];

		NSInteger keyExchangeNameIndex = (cs.encoded >> 8);

		if (keyExchangeNameIndex != kTLS13KeyExchangeValue) {
			_append(kKeyExchangeNames, keyExchangeNameIndex);

			[resultString appendString:@"-"];
		}

		_append(kCipherNames, ((cs.encoded >> 3) & 0x1f));

		NSInteger macNameIndex = (cs.encoded & 0x7);

		if (macNameIndex != kAEADMACValue) {
			[resultString appendString:@"-"];

			_append(kMacNames, macNameIndex);
		}

		if (appendProtocol && keyExchangeNameIndex == kTLS13KeyExchangeValue) {
			[resultString appendString:@" (TLS 1.3)"];
		}

#undef _append

		return resultString;
	}

	return @"Unknown";
}

+ (BOOL)isCipherSuiteDeprecated:(SSLCipherSuite)cipherSuite
{
	return [[self cipherListDeprecated] containsObject:@(cipherSuite)];
}

+ (NSArray<NSNumber *> *)cipherSuitesInCollection:(RCMCipherSuiteCollection)collection includeDeprecated:(BOOL)includeDepecated
{
	if (includeDepecated == NO) {
		return [self cipherSuitesInCollection:collection];
	}

	NSMutableArray<NSNumber *> *_cipherList = [NSMutableArray array];

	[_cipherList addObjectsFromArray:[self cipherSuitesInCollection:collection]];
	[_cipherList addObjectsFromArray:[self cipherListDeprecated]];

	return [_cipherList copy];
}

+ (NSArray<NSNumber *> *)cipherSuitesInCollection:(RCMCipherSuiteCollection)collection
{
	switch (collection) {
		case RCMCipherSuiteCollectionNone:
		{
			return @[];
		}
		case RCMCipherSuiteCollectionMozilla2015:
		{
			/* The following list of ciphers, which is ordered from most important
			 to least important, was aquired from Mozilla's wiki on December 2, 2015. */

			return @[
				 @(TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256),			// ECDHE-RSA-AES128-GCM-SHA256
				 @(TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256),		// ECDHE-ECDSA-AES128-GCM-SHA256
				 @(TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384),			// ECDHE-RSA-AES256-GCM-SHA384
				 @(TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384),		// ECDHE-ECDSA-AES256-GCM-SHA384
				 @(TLS_DHE_RSA_WITH_AES_128_GCM_SHA256),			// DHE-RSA-AES128-GCM-SHA256
				 @(TLS_DHE_DSS_WITH_AES_128_GCM_SHA256),			// DHE-DSS-AES128-GCM-SHA256
				 @(TLS_DHE_DSS_WITH_AES_256_GCM_SHA384),			// DHE-DSS-AES256-GCM-SHA384
				 @(TLS_DHE_RSA_WITH_AES_256_GCM_SHA384),			// DHE-RSA-AES256-GCM-SHA384
				 @(TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA256),			// ECDHE-RSA-AES128-SHA256
				 @(TLS_ECDHE_ECDSA_WITH_AES_128_CBC_SHA256),		// ECDHE-ECDSA-AES128-SHA256
				 @(TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA),				// ECDHE-RSA-AES128-SHA
				 @(TLS_ECDHE_ECDSA_WITH_AES_128_CBC_SHA),			// ECDHE-ECDSA-AES128-SHA
				 @(TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA384),			// ECDHE-RSA-AES256-SHA384
				 @(TLS_ECDHE_ECDSA_WITH_AES_256_CBC_SHA384),		// ECDHE-ECDSA-AES256-SHA384
				 @(TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA),				// ECDHE-RSA-AES256-SHA
				 @(TLS_ECDHE_ECDSA_WITH_AES_256_CBC_SHA),			// ECDHE-ECDSA-AES256-SHA
				 @(TLS_DHE_RSA_WITH_AES_128_CBC_SHA256),			// DHE-RSA-AES128-SHA256
				 @(TLS_DHE_RSA_WITH_AES_128_CBC_SHA),				// DHE-RSA-AES128-SHA
				 @(TLS_DHE_DSS_WITH_AES_128_CBC_SHA256),			// DHE-DSS-AES128-SHA256
				 @(TLS_DHE_RSA_WITH_AES_256_CBC_SHA256),			// DHE-RSA-AES256-SHA256
				 @(TLS_DHE_DSS_WITH_AES_256_CBC_SHA),				// DHE-DSS-AES256-SHA
				 @(TLS_DHE_RSA_WITH_AES_256_CBC_SHA),				// DHE-RSA-AES256-SHA
			 ];

			break;
		}
		case RCMCipherSuiteCollectionDefault:
		case RCMCipherSuiteCollectionMozilla2017:
		default:
		{
			/* The following list of ciphers, which is ordered from most important
			 to least important, was aquired from Mozilla's wiki on July 5, 2017. */
			/* This list has some slight differences compared to the original wiki
			 article. Mozilla had/has recommended use of ECDHE-ECDSA-CHACHA20-POLY1305
			 and ECDHE-RSA-CHACHA20-POLY1305. These are not ciphers that Apple
			 provides support for. These entries have been omited and a comment
			 is shown in the place where they would originally sit. */
			/* This list includes three cipher suites for TLS 1.3 which were not
			 included in Mozilla's list as well. */

			return @[
				 /* TLS 1.3 */
#ifdef TXSystemIsOSXHighSierraOrLater
				 @(TLS_AES_256_GCM_SHA384),
				 @(TLS_CHACHA20_POLY1305_SHA256),
				 @(TLS_AES_128_GCM_SHA256),
#endif

				 /* TLS 1.2 */
				 @(TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384), 	// ECDHE-ECDSA-AES256-GCM-SHA384
				 @(TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384), 		// ECDHE-RSA-AES256-GCM-SHA384

#ifdef TXSystemIsOSXHighSierraOrLater
				 @(TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305_SHA256), // ECDHE-ECDSA-CHACHA20-POLY1305
				 @(TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305_SHA256), // ECDHE-RSA-CHACHA20-POLY1305
#endif

				 @(TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256), 	// ECDHE-ECDSA-AES128-GCM-SHA256
				 @(TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256), 		// ECDHE-RSA-AES128-GCM-SHA256
				 @(TLS_ECDHE_ECDSA_WITH_AES_256_CBC_SHA384), 	// ECDHE-ECDSA-AES256-SHA384
				 @(TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA384), 		// ECDHE-RSA-AES256-SHA384
				 @(TLS_ECDHE_ECDSA_WITH_AES_128_CBC_SHA256), 	// ECDHE-ECDSA-AES128-SHA256
				 @(TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA256), 		// ECDHE-RSA-AES128-SHA256
			 ];

			break;
		}
	}

	return @[];
}

+ (NSArray<NSNumber *> *)cipherListDeprecated
{
	// These were originally going to be excluded but certain large
	// IRC networks including OFTC (~10,000 users) still use older
	// configurations. We should phase these out soon...

	return @[
		 @(TLS_RSA_WITH_AES_128_GCM_SHA256),				// AES128-GCM-SHA256
		 @(TLS_RSA_WITH_AES_256_GCM_SHA384),				// AES256-GCM-SHA384
		 @(TLS_RSA_WITH_AES_128_CBC_SHA256),				// AES128-SHA256
		 @(TLS_RSA_WITH_AES_256_CBC_SHA256),				// AES256-SHA256
		 @(TLS_RSA_WITH_AES_128_CBC_SHA),					// AES128-SHA
		 @(TLS_RSA_WITH_AES_256_CBC_SHA)					// AES256-SHA
	];
}

+ (BOOL)isTLSError:(NSError *)error
{
	NSParameterAssert(error != nil);

	return [error.domain isEqualToString:@"kCFStreamErrorDomainSSL"];
}

+ (nullable NSString *)descriptionForError:(NSError *)error
{
	NSParameterAssert(error != nil);

	if ([self isTLSError:error] == NO) {
		return nil;
	}

	return [self descriptionForErrorCode:error.code];
}

+ (nullable NSString *)descriptionForErrorCode:(NSInteger)errorCode
{
	if (errorCode > (-9800) || errorCode < (-9865)) {
		return nil;
	}

	/* Request the heading for the formatted error message. */
	NSString *headingFormat =
	[[NSBundle mainBundle] localizedStringForKey:@"heading"
										   value:@""
										   table:@"SecureTransportErrorCodes"];

	/* Request the reason for the formatting error message. */
	NSString *lookupKey = [NSString stringWithInteger:errorCode];

	NSString *localizedError =
	[[NSBundle mainBundle] localizedStringForKey:lookupKey
										   value:@""
										   table:@"SecureTransportErrorCodes"];

	/* Maybe format the error message. */
	return [NSString stringWithFormat:headingFormat, localizedError, errorCode];
}

+ (nullable NSString *)descriptionForBadCertificateError:(NSError *)error
{
	NSParameterAssert(error != nil);

	if ([self isTLSError:error] == NO) {
		return nil;
	}

	return [self descriptionForErrorCode:error.code];
}

+ (nullable NSString *)descriptionForBadCertificateErrorCode:(NSInteger)errorCode
{
	if ([self isBadCertificateErrorCode:errorCode] == NO) {
		return nil;
	}

	return [self descriptionForErrorCode:errorCode];
}

+ (BOOL)isBadCertificateError:(NSError *)error
{
	NSParameterAssert(error != nil);

	if ([self isTLSError:error] == NO) {
		return NO;
	}

	return [self isBadCertificateErrorCode:error.code];
}

+ (BOOL)isBadCertificateErrorCode:(NSInteger)errorCode
{
	switch (errorCode) {
		case errSSLBadCert:
		case errSSLNoRootCert:
		case errSSLCertExpired:
		case errSSLPeerBadCert:
		case errSSLPeerCertRevoked:
		case errSSLPeerCertExpired:
		case errSSLPeerCertUnknown:
		case errSSLUnknownRootCert:
		case errSSLCertNotYetValid:
		case errSSLXCertChainInvalid:
		case errSSLPeerUnsupportedCert:
		case errSSLPeerUnknownCA:
		case errSSLHostNameMismatch:
		{
			return YES;
		}
		default:
		{
			break;
		}
	}

	return NO;
}

+ (SecTrustRef)trustFromCertificateChain:(NSArray<NSData *> *)certificatecChain withPolicyName:(NSString *)policyName
{
	NSParameterAssert(certificatecChain != nil);
	NSParameterAssert(policyName != nil);

	CFMutableArrayRef certificatesMutableRef = CFArrayCreateMutable(kCFAllocatorDefault, 0, &kCFTypeArrayCallBacks);

	for (NSData *certificate in certificatecChain) {
		CFDataRef certificateDataRef = (__bridge CFDataRef)certificate;

		SecCertificateRef certificateRef = SecCertificateCreateWithData(kCFAllocatorDefault, certificateDataRef);

		if (certificateRef == NULL) {
			continue;
		}

		CFArrayAppendValue(certificatesMutableRef, certificateRef);

		CFRelease(certificateRef);
	}

	SecPolicyRef policyRef = SecPolicyCreateSSL(TRUE, (__bridge CFStringRef)policyName);

	SecTrustRef trustRef;

	OSStatus trustRefStatus = SecTrustCreateWithCertificates(certificatesMutableRef, policyRef, &trustRef);

	if (trustRefStatus != noErr) {
		LogToConsoleError("SecTrustCreateWithCertificates() returned %i", trustRefStatus);
	}

	CFRelease(certificatesMutableRef);
	CFRelease(policyRef);

	return trustRef;
}

+ (nullable NSArray<NSData *> *)certificatesInTrust:(SecTrustRef)trustRef
{
	NSParameterAssert(trustRef != NULL);

	CFIndex trustCertificateCount = SecTrustGetCertificateCount(trustRef);

	NSMutableArray<NSData *> *results = [NSMutableArray arrayWithCapacity:trustCertificateCount];

	for (CFIndex trustCertificateIndex = 0; trustCertificateIndex < trustCertificateCount; trustCertificateIndex++) {
		SecCertificateRef certificateRef = SecTrustGetCertificateAtIndex(trustRef, trustCertificateIndex);

		NSData *certificateData = (__bridge_transfer NSData *)SecCertificateCopyData(certificateRef);

		if (certificateData == nil) {
			LogToConsoleError("Bad certificate data at index: %lu", trustCertificateIndex);

			continue;
		}

		[results addObject:certificateData];
	}

	return [results copy];
}

+ (nullable NSString *)policyNameInTrust:(SecTrustRef)trustRef
{
	NSParameterAssert(trustRef != NULL);

	CFArrayRef trustPolicies = NULL;

	OSStatus trustPoliciesStatus = SecTrustCopyPolicies(trustRef, &trustPolicies);

	if (trustPoliciesStatus != noErr) {
		LogToConsoleError("SecTrustCopyPolicies() returned %i", trustPoliciesStatus);

		return nil;
	}

	NSString *policyName = nil;

	CFIndex trustPolicyCount = CFArrayGetCount(trustPolicies);

	for (CFIndex trustPolicyIndex = 0; trustPolicyIndex < trustPolicyCount; trustPolicyIndex++) {
		SecPolicyRef policy = (SecPolicyRef)CFArrayGetValueAtIndex(trustPolicies, trustPolicyIndex);

		CFDictionaryRef properties = SecPolicyCopyProperties(policy);

		if (properties) {
			if (CFGetTypeID(properties) == CFDictionaryGetTypeID()) {
				CFStringRef name = CFDictionaryGetValue(properties, kSecPolicyName);

				if (name && CFGetTypeID(name) == CFStringGetTypeID()) {
					policyName = (__bridge NSString *)(name);
				}
			}

			CFRelease(properties);
		}
	}

	return policyName;
}

@end

NS_ASSUME_NONNULL_END
