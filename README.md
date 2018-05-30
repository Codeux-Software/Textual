# Textual [![GitHub release](https://img.shields.io/github/tag/Codeux-Software/Textual.svg)](https://github.com/Codeux-Software/Textual/blob/master) [![Platform](https://img.shields.io/badge/platform-OS%20X-lightgrey.svg)](http://www.textualapp.com/mac-app-store)

Textual is an customizable application for interacting with Internet Relay Chat (IRC) on OS X.

Textual can be customized with styles written in CSS 3, HTML 5, and JavaScript;  [plugins](https://help.codeux.com/textual/Writing-Plugins.kb) written in Objective-C and Swift, and [scripts](https://help.codeux.com/textual/Writing-Scripts.kb) written in AppleScript (and many other languages)

Precompiled versions of Textual can be purchased in the [Mac App Store](http://www.textualapp.com/mac-app-store) or [directly from Codeux Software](https://www.textualapp.com/fastspring-store/).

## Screenshots

[![Light Screenshot](https://www.codeux.com/textual/private/images/v600media/YosemiteLightThumbnail.png)](https://www.codeux.com/textual/private/images/v600media/YosemiteLightFullscreen.png) 
[![Dark Screenshot](https://www.codeux.com/textual/private/images/v600media/YosemiteDarkThumbnail.png)](https://www.codeux.com/textual/private/images/v600media/YosemiteDarkFullscreen.png)

## Resources

- [Homepage](https://codeux.com/textual)
- [Frequently Asked Questions](https://help.codeux.com/textual/Frequently-Asked-Questions.kb)
- [Support](https://help.codeux.com/textual/Support.kb)
- \#textual on chat.freenode.net
- Guides: [Writing Plugins](https://help.codeux.com/textual/Writing-Plugins.kb), [Writing Scripts](https://help.codeux.com/textual/Writing-Scripts.kb)

## Note Regarding Support

Please be aware that while it is within your right to compile Textual, **Codeux Software will not provide support for the building process because it encourages the use of potentially unstable code**. If you do succeed in building Textual, then you will not be turned away when asking for support using the application itself.

## Note Regarding Downloading Textual

Textual is dependent on several other projects to build. This repository is automatically linked against these other projects using what are known as "submodules" — Clicking the "Download ZIP" button to build a copy of Textual will not download a copy of these projects that Textual depends on. Therefore, to properly build Textual, Textual must be cloned using [Github for Mac](https://mac.github.com/) or by using the following commands in Terminal:

```
git clone https://github.com/Codeux-Software/Textual.git Textual
cd Textual
git submodule update --init --recursive
```

## Note Regarding Code Signing

**It is HIGHLY DISCOURAGED to turn off code signing.** Certain features rely on the fact that Textual is properly signed and is within a sandboxed environment.

**TEXTUAL DOES NOT REQUIRE A CERTIFICATE ISSUED BY APPLE TO BUILD** which means there is absolutely no reason to turn code signing off.

## Note Regarding Trial Mode

To avoid patch files and/or a separate repository; the code which is responsible for licensing paid copies of Textual is in the source code that you download from here.

If you do not have a license key, then set the ``TEXTUAL_BUILT_WITH_LICENSE_MANAGER`` flag to 0 in the Standard Release configuration file to disable the inclusion of this code at build time.

## Building Textual

The latest version of Textual requires two things to be built. One is a valid (does not need to be issued by Apple) code signing certificate. The second is an installation of Xcode 7.0 or newer on OS X El Capitan. **Building on OS X Yosemite or earlier is not possible.**

If you are an Apple registered developer, then obtaining a signing certificate is not very difficult. However, if you are not, a self-signed certificate for "code signing" will work fine. The steps to produce one of these self-signed certificates is very simple to find using Google.

Once you have your code signing certificate, **do not modify the Build Settings of Textual through Xcode**. Instead,    modify the file at the path: **Resources ➜ Build Configurations ➜ Code Signing Identity.xcconfig** — The contents of this file defines the name of the certificate which will be used for code signing.

After defining your code signing certificate, build Textual using the "Standard Release" build scheme.

When you build Textual for the first time, a framework that Textual is dependent on (Encryption Kit) will download several open source libraries (libgpg-error, libgcrypt, and libotr) from the Internet which means if you do not have an active Internet connection, these files will not download and the build will fail.

The build process can take up to a minute or more to complete because in addition to building Textual itself, Xcode has to build these open source libraries as well.

## Original Limechat License

Textual began as a "fork" of [LimeChat](https://github.com/psychs/limechat) in 2010

LimeChat's original license is presented below.

<pre>
The New BSD License

Copyright (c) 2008 - 2010 Satoshi Nakagawa < psychs AT limechat DOT net >
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions
are met:
1. Redistributions of source code must retain the above copyright
   notice, this list of conditions and the following disclaimer.
2. Redistributions in binary form must reproduce the above copyright
   notice, this list of conditions and the following disclaimer in the
   documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
SUCH DAMAGE.
</pre>

## License for content originating from Textual

Unless stated otherwise by Textual's [Acknowledgements.pdf](Acknowledgements.pdf) document, the license presented below shall govern the distribution of and modifications to; the work hosted by this repository.

<pre>
Copyright (c) 2010 - 2016 Codeux Software, LLC & respective contributors.
      Please see Acknowledgements.pdf for additional information.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions
are met:

   * Redistributions of source code must retain the above copyright
     notice, this list of conditions and the following disclaimer.
   * Redistributions in binary form must reproduce the above copyright
     notice, this list of conditions and the following disclaimer in the
     documentation and/or other materials provided with the distribution.
   * Neither the name of Textual, "Codeux Software, LLC", nor the
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
</pre>
