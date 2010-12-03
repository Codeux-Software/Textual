Textual = {
	newMessagePostedToDisplay: function(ln) {
		// support the most important function of the 
		// old API with no changes necessary to themes
		
		if (window.newMessagePostedToDisplay != undefined) {
			window.newMessagePostedToDisplay(ln)
		}
		
		//var newLine = document.getElementById("line" + lineNumber);
	},
	
	include_js: function(jsFile)
	{
		if (/loaded|complete/.test(document.readyState)) {
			var js = document.createElement("script");
			js.src = jsFile;
			js.type = "text/javascript";
			document.getElementsByTagName("HEAD")[0].appendChild(js);
		} else {
			document.write('<script type="text/javascript" src="' + jsFile + '"></scr' + 'ipt>'); 
		}
	},
	
	include_css: function(cssFile)
	{
		document.write('<link href="' + cssFile + '" media="screen" rel="stylesheet" type="text/css" />'); 
	},
	
	// check for the old API functions and call if they exist
	old_api:function(str)
	{
		if (window[str]) {
			window[str]();
			return true
		} else { return false }
	},
	
	// should be overridden by your class to do 
	// any clean up logic prior to themes changing
	willDoThemeChange:function() {},
	
	// should be overridden by your class to do any clean 
	// up logic needed after the theme has been changed
	doneThemeChange:function() {},
	
	/* The following function calls are required. */
	on_url: function() { Textual.old_api("on_url") || app.setUrl(event.target.innerHTML); },
	on_addr: function() { Textual.old_api("on_addr") || app.setAddr(event.target.innerHTML); },
	on_chname: function() { Textual.old_api("on_chname") || app.setChan(event.target.innerHTML); },
	on_nick: function() { Textual.old_api("on_nick") || app.setNick(event.target.parentNode.parentNode.getAttribute('nick')); }
}