Textual is a highly modified version of the open source project known as [LimeChat](https://github.com/psychs/limechat) created by Satoshi Nakagawa. Much of the app uses the open standard of [WebKit](http://webkit.org/) which makes customization easy through the use of CSS 3 and HTML 5. Plugins written in [Objective-C](http://www.codeux.com/textual/wiki/Writing-Plugins.wiki) and [scripts](http://www.codeux.com/textual/wiki/Writing-Scripts.wiki) made with AppleScript (and other languages) are also supported.

## Building Textual

Please be aware while it is within your right to compile Textual and redistribute it unlimited times; **we will not actively provide support for the actual building process as it has been known to introduce  some bugs (even while supervised) that do not exist in the Mac App Store version of Textual.** General support for easy to answer questions related to the actual use of the client is still available. 

The repository is in a constant state of development so the code produced may not be stable at the time of a clone.

**Anyways, to build it…**

The latest version of Textual requires two things to be built. One is a valid (does not need to be trusted) code signing certificate. The second is an installation of Xcode 5 or later. 

If you are an Apple registered developer, then obtaining a signing certificate is not very hard. However, if you are not, a self-signed certificate for "code signing" will do just as well. The steps to produce one of these is very simple so Google is the best destination to check for the steps on making one of these.

**It is HIGHLY DISCOURAGED to turn off code signing.** Doing so will introduce some very common bugs which are a result of Textual expecting to be within a code signed sandbox. One bug that will be  introduced is the inability to write log files to disk. Another is the possibility of Textual being denied write access for passwords. 

These bugs are not intentionally built into Textual to discourage building. They are a result of Apple's own APIs being dependent on the fact that Textual is code signed. 

As long as a self-signed certificate or an Apple Developer issued certificate is available with its name containing "Developer ID Application" then the only thing required to build Textual is to open it and built it within Textual using the "Standard Release" build scheme. There is no other special instructions. 

99% of build errors are related to code signing so making sure there is some type of certificate available for signing will normally result in a successful build every time.

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
Copyright (c) 2010 — 2013 Codeux Software & respective contributors.
       Please see Contributors.rtfd and Acknowledgements.rtfd

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