#!/usr/bin/perl -w

use strict;
require Foundation;

my $NSStrings;

my $dictionaries =
  { 'framework'            => NSDictionary->dictionaryWithContentsOfFile_(nsstring("$ENV{'DISTRIBUTION_TEMP_PACKAGES_DIR'}/$ENV{'DISTRIBUTION_PACKAGE_FRAMEWORK'}/Contents/Info.plist")),
    'instrumentsAdditions' => NSDictionary->dictionaryWithContentsOfFile_(nsstring("$ENV{'DISTRIBUTION_TEMP_PACKAGES_DIR'}/$ENV{'DISTRIBUTION_PACKAGE_INSTRUMENTS_ADDITIONS'}/Contents/Info.plist")),
    'htmlDocumentation'    => NSDictionary->dictionaryWithContentsOfFile_(nsstring("$ENV{'DISTRIBUTION_TEMP_PACKAGES_DIR'}/$ENV{'DISTRIBUTION_PACKAGE_HTML_DOCUMENTATION'}/Contents/Info.plist")),
    'sourcecode'           => NSDictionary->dictionaryWithContentsOfFile_(nsstring("$ENV{'DISTRIBUTION_TEMP_PACKAGES_DIR'}/$ENV{'DISTRIBUTION_PACKAGE_SOURCECODE'}/Contents/Info.plist"))
  };

my $packages = 
  { 'framework'            => getPackageInfo($dictionaries->{'framework'},            "$ENV{'DISTRIBUTION_PACKAGE_FRAMEWORK'}"),
    'instrumentsAdditions' => getPackageInfo($dictionaries->{'instrumentsAdditions'}, "$ENV{'DISTRIBUTION_PACKAGE_INSTRUMENTS_ADDITIONS'}"),
    'htmlDocumentation'    => getPackageInfo($dictionaries->{'htmlDocumentation'},    "$ENV{'DISTRIBUTION_PACKAGE_HTML_DOCUMENTATION'}"),
    'sourcecode'           => getPackageInfo($dictionaries->{'sourcecode'},           "$ENV{'DISTRIBUTION_PACKAGE_SOURCECODE'}")
  };

if($ENV{XCODE_VERSION_MAJOR} ne "0200") {
  $dictionaries->{docsetDocumentation} = NSDictionary->dictionaryWithContentsOfFile_(nsstring("$ENV{'DISTRIBUTION_TEMP_PACKAGES_DIR'}/$ENV{'DISTRIBUTION_PACKAGE_DOCSET_DOCUMENTATION'}/Contents/Info.plist"));
  $packages->{docsetDocumentation} = getPackageInfo($dictionaries->{'docsetDocumentation'}, "$ENV{'DISTRIBUTION_PACKAGE_DOCSET_DOCUMENTATION'}");

}

my ($pcreLineChoice, $pcreChoice, $pcrePkgRef, $pcreScripts) = ("", "", "", "");

if(defined($ENV{'DISTRIBUTION_INCLUDE_PCRE_PACKAGE'}) && ($ENV{'DISTRIBUTION_INCLUDE_PCRE_PACKAGE'} eq "YES")) {
  $dictionaries->{'pcre'} = NSDictionary->dictionaryWithContentsOfFile_(nsstring("$ENV{'DISTRIBUTION_TEMP_PACKAGES_DIR'}/$ENV{'DISTRIBUTION_PACKAGE_SOURCECODE_PCRE'}/Contents/Info.plist"));
  $packages->{'pcre'}     = getPackageInfo($dictionaries->{'pcre'}, "$ENV{'DISTRIBUTION_PACKAGE_SOURCECODE_PCRE'}");

  $pcreLineChoice = "<line choice=\"pcreChoice\"></line>";
  $pcreChoice = <<PCRE_CHOICE;
    <choice id="pcreChoice" title="PCRE $ENV{'PCRE_VERSION'} Distribution" description="The distribution of the PCRE library that this RegexKit was designed for.  This package is not required, and if not installed the build system will automatically download the PCRE distribution configured by the Xcode build setting PCRE_VERSION." tooltip="PCRE tarball distribution" start_selected="false" start_enabled="false" start_visible="true" selected="choices.sourcecodeChoice.selected" enabled="checkPcreEnabled()">
        <pkg-ref id="$packages->{'pcre'}->{'CFBundleIdentifier'}"></pkg-ref>
    </choice>
PCRE_CHOICE
  $pcrePkgRef = "$packages->{'pcre'}->{'pkgRef'}";
  $pcreScripts = <<PCRE_SCRIPTS;
    <script>
function checkPcreEnabled() {
  if(choices.sourcecodeChoice.selected == false) { choices.pcreChoice.tooltip = 'Can only be installed with the RegexKit Source Code'; return(false); }
  else { choices.pcreChoice.tooltip = 'PCRE tarball distribution'; return(true); }
}
</script>
PCRE_SCRIPTS
    
}

#<welcome file="Welcome.rtf"></welcome>
#<readme file="ReadMe.rtf"></readme>
#<license file="License.rtf"></license>
#<conclusion file="Conclusion.rtf"></conclusion>

print <<END_OF_DIST;
<?xml version="1.0" encoding="UTF-8"?>
<installer-gui-script minSpecVersion="1.0">
    <title>RegexKit</title>
    <readme file="ReadMe.rtf"></readme>
    <license file="License.rtf"></license>
    <options allow-external-scripts="no" customize="always" rootVolumeOnly="false"></options>
    <installation-check script="preflightChecks()"></installation-check>
    <volume-check script="volumeCheckTiger()"></volume-check>
    <script>
function preflightChecks() {
	var result = false;
	try {
		result = system.files.fileExistsAtPath('/Developer/Applications/Xcode.app') == true;
	} catch (e) {}

	if(!result) {
		my.result.type = 'Warn';
		my.result.title = 'Xcode.app Not Found';
		my.result.message = 'Installing the Xcode Development Tools is strongly recommended.  It is unlikely you will be able to use RegexKit without them.';
	}
	return result;
}
</script>
    <script>
function volumeCheckTiger() {
	var result = false;
	try {
		result = my.target.systemVersion.ProductVersion >= '10.4';
	} catch (e) {}
	
	if(!result) {
		my.result.type = 'Fatal';
		my.result.title = '';
		my.result.message = '';
	}
	return result;
}
</script>
<script>
function checkXcode3(whichChoice) {
  var result = false;
  try {
    result = isNotDowngrade(whichChoice) &amp;&amp; system.files.plistAtPath(my.target.mountpoint + '/Developer/Applications/Xcode.app/Contents/Info.plist').CFBundleShortVersionString >= '3.0';
  } catch (e) {}
  return(result);
}
</script>
<script>
function checkInstrumentsApp(whichChoice) {
  var result = false;
  try {
    result = isNotDowngrade(whichChoice) &amp;&amp; system.files.plistAtPath(my.target.mountpoint + '/Developer/Applications/Instruments.app/Contents/Info.plist').CFBundleShortVersionString >= '1.0';
  } catch (e) {}
  return(result);
}
</script>
<script>
function checkSourcecode() {
  var result = false;
  try {
    var action = choices.sourcecodeChoice.packageUpgradeAction;
    if((action == 'clean') || (action == 'downgrade') || (action == 'mixed')) { result = false; } else { result = true; }
  } catch (e) {}
  return(result);
}
</script>
    <script>
function isNotDowngrade(whichChoice) {
  var action = whichChoice.packageUpgradeAction;
  if ((action == 'downgrade') || (action == 'mixed')) { return(false); } else { return(true); }
}
</script>
<script>
function isNotDowngradeEnabled(whichChoice, okTooltip) {
  var action = whichChoice.packageUpgradeAction;
  if ((action == 'downgrade') || (action == 'mixed')) {
    var installedVersionArray = my.target.receiptForIdentifier(whichChoice.packages[0].identifier).version.match(/\\d+/g);
    var choiceVersionArray = whichChoice.packages[0].version.match(/\\d+/g);
    var installedVersion = installedVersionArray[0] + '.' + installedVersionArray[1] + '.' + installedVersionArray[2];
    var choiceVersion = choiceVersionArray[0] + '.' + choiceVersionArray[1] + '.' + choiceVersionArray[2];
    
    whichChoice.tooltip = 'The version you are attempting to install, ' + choiceVersion + ', is older than the version currently installed, ' + installedVersion + '.';  
    return(false);
  } else {
    whichChoice.tooltip = okTooltip;
    return(true);
  }
}
</script>

$pcreScripts
<choices-outline>
        <line choice="frameworkChoice"></line>
        <line choice="instrumentsAdditionsChoice"></line>
        <line choice="htmlDocumentationChoice"></line>
END_OF_DIST
if($ENV{XCODE_VERSION_MAJOR} ne "0200") {
  print <<END_OF_DOCSET;
        <line choice="docsetDocumentationChoice"></line>
END_OF_DOCSET
}
print <<END_OF_DIST;
        <line choice="sourcecodeChoice"></line>
        $pcreLineChoice
    </choices-outline>
    <choice id="frameworkChoice" title="RegexKit Framework" description="Contains the Mac OS X Universal Binary RegexKit.framework bundle for ppc, ppc64, i386, and x86_64. This is what your application will link to and copy in to its .App application bundle as a private embedded framework." tooltip="RegexKit.framework" start_selected="isNotDowngrade(choices.frameworkChoice)" start_enabled="isNotDowngradeEnabled(choices.frameworkChoice, 'RegexKit.framework')" start_visible="true">
        <pkg-ref id="$packages->{'framework'}->{'CFBundleIdentifier'}"></pkg-ref>
    </choice>
    <choice id="instrumentsAdditionsChoice" title="Instruments.app Additions" description="Suite of RegexKit instruments for Instruments.app." tooltip="Suite of RegexKit instruments for Instruments.app" start_selected="checkInstrumentsApp(choices.instrumentsAdditionsChoice)" start_enabled="isNotDowngradeEnabled(choices.instrumentsAdditionsChoice, 'Suite of RegexKit instruments for Instruments.app')" start_visible="true">
        <pkg-ref id="$packages->{'instrumentsAdditions'}->{'CFBundleIdentifier'}"></pkg-ref>
    </choice>
    <choice id="htmlDocumentationChoice" title="HTML Documentation" description="RegexKit Framework HTML Documentation." tooltip="RegexKit HTML Documentation" start_selected="isNotDowngrade(choices.htmlDocumentationChoice)" start_enabled="isNotDowngradeEnabled(choices.htmlDocumentationChoice, 'RegexKit HTML Documentation')" start_visible="true">
        <pkg-ref id="$packages->{'htmlDocumentation'}->{'CFBundleIdentifier'}"></pkg-ref>
    </choice>
END_OF_DIST
if($ENV{XCODE_VERSION_MAJOR} ne "0200") {
  print <<END_OF_DOCSET;
    <choice id="docsetDocumentationChoice" title="Xcode 3.0 DocSet Documentation" description="RegexKit Framework Documentation for Xcode 3.0 and Mac OS X 10.5 Leopard. Includes full support for Xcode 3.0's Research Assistant." tooltip="RegexKit Xcode 3.0 DocSet Documentation" start_selected="checkXcode3(choices.docsetDocumentationChoice)" start_enabled="isNotDowngradeEnabled(choices.docsetDocumentationChoice, 'RegexKit Xcode 3.0 DocSet Documentation')" start_visible="true">
        <pkg-ref id="$packages->{'docsetDocumentation'}->{'CFBundleIdentifier'}"></pkg-ref>
    </choice>
END_OF_DOCSET
}
print <<END_OF_DIST;    
    <choice id="sourcecodeChoice" title="Source Code" description="The complete source code for the RegexKit Framework. Building the framework from the source is not required nor recommended for most RegexKit end-users." tooltip="RegexKit source code" start_selected="checkSourcecode()" start_enabled="isNotDowngradeEnabled(choices.sourcecodeChoice, 'RegexKit source code')" start_visible="true">
        <pkg-ref id="$packages->{'sourcecode'}->{'CFBundleIdentifier'}"></pkg-ref>
    </choice>
    $pcreChoice
    $packages->{'framework'}->{'pkgRef'}
    $packages->{'instrumentsAdditions'}->{'pkgRef'}
    $packages->{'htmlDocumentation'}->{'pkgRef'}
END_OF_DIST
if($ENV{XCODE_VERSION_MAJOR} ne "0200") {
  print <<END_OF_DOCSET;
    $packages->{'docsetDocumentation'}->{'pkgRef'}
END_OF_DOCSET
}
print <<END_OF_DIST;    
    $packages->{'sourcecode'}->{'pkgRef'}
    $pcrePkgRef
</installer-gui-script>
END_OF_DIST

exit(0);

sub nsstring {
  my $string = shift;

  if(!defined($Main::NSStrings->{"$string"})) { $Main::NSStrings->{"$string"} = NSString->stringWithCString_("$string"); }
  return($Main::NSStrings->{"$string"});
}

sub stringForKey {
  my $dictionary = shift;
  my $key = shift;
  my $string = $dictionary->objectForKey_(nsstring($key));
  
  if($$string == 0) { return(undef); }
  return(sprintf("%s", $string->description->cString));
}

sub getPackageInfo {
  my $dictionary = shift;
  my $filename = shift;

  my $pkgInfo =
    {
     'CFBundleIdentifier'         => stringForKey($dictionary, "CFBundleIdentifier"),
     'CFBundleShortVersionString' => stringForKey($dictionary, "CFBundleShortVersionString"),
     'IFMajorVersion'             => stringForKey($dictionary, "IFMajorVersion"),
     'IFMinorVersion'             => stringForKey($dictionary, "IFMinorVersion"),
     'IFPkgFlagInstalledSize'     => stringForKey($dictionary, "IFPkgFlagInstalledSize")
    };

  $pkgInfo->{'version'} = "$pkgInfo->{'CFBundleShortVersionString'}.$pkgInfo->{'IFMajorVersion'}.$pkgInfo->{'IFMinorVersion'}";

  $pkgInfo->{'pkgRef'} = "<pkg-ref id=\"$pkgInfo->{'CFBundleIdentifier'}\" version=\"$pkgInfo->{'version'}\" installKBytes=\"$pkgInfo->{'IFPkgFlagInstalledSize'}\" auth=\"Admin\" onConclusion=\"None\">file:./Contents/Packages/$filename</pkg-ref>";

  return($pkgInfo);
}
