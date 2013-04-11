#!/bin/sh
if [ -z "$CODE_SIGN_IDENTITY" ] || [ "$CODE_SIGN_IDENTITY" == "Don't Code Sign" ]; then
  osascript -e "tell application \"Xcode\"
    display alert \"Your build is not code signed\" message \"Signing your build is required due to OS X Sandbox restrictions. \n\nTo sign your build, change CODE_SIGN_IDENTITY in 'Resources/Build Configurations/Code Signing Identity.xcconfig' to your developer certificate or name your certificate in Keychain Access to '3rd Party Mac Developer Application'\n\nFurther instructions can be found in the CodeSign.txt file in the project folder.\"
    end tell"
  exit 1
fi
