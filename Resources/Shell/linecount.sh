#!/bin/sh
# Created by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
# You can redistribute it and/or modify it under the new BSD license.

#
# Find command search pattern explained:
#
# -type d -name "build" -prune			— Exclude "build" Directory
#    -name '*.h'						— Objective-C Header
# -o -name '*.m'						— Objective-C Implementation
# -o -name '*.strings'					— Localization Strings
# -o -name '*.plist'					— Apple Property List
# -o -name '*.css'						— Cascading Style Sheet
# -o -name '*.js'						— JavaScript Source
# -o -name '*.mm'						– Objective-C++ Implementation
# -o -name '*.cpp'						— C++ Source
# -o -name '*.hpp'						— C++ Header
# -o -name '*.l'						– Lex Source
# -o -name '*.pch'						— Pre-compiled Header File
# -o -name '*.sh'						— Include Ourselves (joke!)
# -o -name '*.mustache'					— Mustache template files.
#
# AppleScript files (.scpt) are not included in our search
# because they are compiled so counting the number of lines
# they contain is not worth the time because it is compiled.
# code. So, pretty much rubbish.
#

find ../../ \
-type d -name "build" -prune -o -type f \( \
   -name '*.h' \
-o -name '*.m' \
-o -name '*.strings' \
-o -name '*.plist' \
-o -name '*.css' \
-o -name '*.js' \
-o -name '*.mm' \
-o -name '*.cpp' \
-o -name '*.hpp' \
-o -name '*.l' \
-o -name '*.pch' \
-o -name '*.sh' \
-o -name '*.mustache' \
\) -print0 | xargs -0 wc -l
