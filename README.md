## Introduction to Textual

Textual is a highly modified version of the open source project known as [LimeChat](https://github.com/psychs/limechat) created by Satoshi Nakagawa. Much of the app uses the open standard of [WebKit](http://webkit.org/) which makes customization easy through the use of CSS 3 and HTML 5. [Plugins](http://www.codeux.com/textual/wiki/Writing-Plugins.wiki) written in Objective-C and [scripts](http://www.codeux.com/textual/wiki/Writing-Scripts.wiki) made with AppleScript (and other languages) are also supported.

## Supporting Textual

It is asked out of kindness that those with the power to build Textual do not abuse it to freely distribute it to hundreds of users. Textual exists as an open source project for two reasons: The first reason is to allow the open source community as a whole to contribute. The second reason is to assist other Objective-C developers by showing certain solutions to tasks they may face. A lot of work has been put into the project by the original authors as well as those who have contributed. The copy of Textual in the Mac App Store helps fund the project. Therefore, what is asked above, is asked out of respect so that the project can continue to thrive.

## Note Regarding Support

Please be aware while it is within your right to compile Textual and redistribute it unlimited times; **we will not provide support for the building process as it encourages use of potentially unstable code**. However, once built, general support for easy to answer questions related to the actual use of the application is still available at any time.

## Note Regarding Code Signing

**It is HIGHLY DISCOURAGED to turn off code signing.** Certain features rely on the fact that Textual is properly signed and is within a sandboxed enviornment. 

For example, Textual uses securiry scoped bookmarks issued by the kernel to access certain resources outside of its sandbox. These bookmarks rely on the kernel knowing whether the copy of Textual that you are running is the same assigned to the bookmark. This is done using the code signing identity. Therefore, certain features such as logging to disk will never work without code signing because Textual wont be able to save the bookmark to the specified logging location.

Another example is that Textual may have diffuclties accessing and assigning passwords when not code signed. This is a result of the OS X keychain internals relying on the trust defined by code signing identities. 

## Building on Mavericks

If building Textual on Mavericks, then **the option in Xcode to continue building after receiving a build error must be enabled**. Textual builds an interface file which contains code which is specific to the Yosemite SDK. Therefore, building on Mavericks will result in this file creating an error. This file is not accessed on Mavericks once built so ignoring this error by continuing the build is okay.

## Building Textual

The latest version of Textual requires two things to be built. One is a valid (does not need to be trusted) code signing certificate. The second is an installation of Xcode 5 or later on Mac OS Mavericks.

If you are an Apple registered developer, then obtaining a signing certificate is not very hard. However, if you are not, a self-signed certificate for "code signing" will do just as well. The steps to produce one of these is very simple so Google is the best destination to check for the steps on making one of these.

As long as a self-signed certificate or an Apple Developer issued certificate is available with its name containing "Mac Developer", then the only thing required to build Textual is to open it and build it using the "Standard Release" build scheme. There are no other special instructions.

In Xcode 6 and above you need to eddit Resources/Build Settings/Configurations/Code Signing Identity.xcconfig and replace "Mac Developer" with a different name. Xcode will fail to codesign using a self-signed certificate named "Mac Developer"

## Original Limechat License

The source code of Limechat did not fall under its current GPL license at the time that the source code was forked in 2010. Its original license, at the time of the fork, is displayed below:

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

Textual has indirectly incorporated work from several open source projects. Acknowledgement of these can be found in the respective files that were contributed including licensing information for distribution.

Work that originated from the authors of Textual and were not contributed by other open source projects or from Limechat itself fall under the following license:

<pre>
Copyright (c) 2010 — 2014 Codeux Software & respective contributors.
    Please see Acknowledgements.pdf for additional information.

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
</pre>
