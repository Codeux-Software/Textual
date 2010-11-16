Textual = {
	newMessagePostedToDisplay: function(ln) {
		// support the most important function of the old API with no changes
		// necessary to themes
		if (window.newMessagePostedToDisplay != undefined) {
			window.newMessagePostedToDisplay(ln)
			}
			//var newLine = document.getElementById("line" + lineNumber);
	},
	
	include_js: function(jsFile)
	{
	  document.write('<script type="text/javascript" src="' + jsFile + '"></scr' + 'ipt>'); 
	},
	include_css: function(cssFile)
	{
		document.write('<link href="' + cssFile + '" media="screen" rel="stylesheet" type="text/css" />'); 
	},
	
	/* The following function calls are required. */
	on_url: function() { app.setUrl(event.target.innerHTML); },
	on_addr: function() { app.setAddr(event.target.innerHTML); },
	on_chname: function() { app.setChan(event.target.innerHTML); },
	on_nick: function() { app.setNick(event.target.parentNode.parentNode.getAttribute('nick')); }
}