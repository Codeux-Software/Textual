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
			
			js.src  = jsFile;
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
	
	// should be overridden by your class to do 
	// any clean up logic prior to themes changing
	willDoThemeChange:function() {},
	
	// should be overridden by your class to do any clean 
	// up logic needed after the theme has been changed
	doneThemeChange:function() {},
	
	/* The following function calls are required. */
	on_url: function() { app.setUrl(event.target.innerHTML); },
	on_addr: function() { app.setAddr(event.target.innerHTML); },
	on_chname: function() { app.setChan(event.target.innerHTML); },
	on_ct_nick: function() { app.setNick(event.target.innerHTML); },
	on_nick: function() { app.setNick(event.target.getAttribute("nick")); },
	
	on_dblclick_nick: function() { 
		Textual.on_nick();
		app.nicknameDoubleClicked();
	},
	
	on_dblclick_chname: function() {
		Textual.on_chname();
		app.channelDoubleClicked();
	},
	
	on_dblclick_ct_nick: function() {
		Textual.on_ct_nick();
		app.nicknameDoubleClicked();
	},
    
    hide_inline_image: function(object) {
        if (app.hideInlineImage(object) == "false") {
            return false;
        }
        
        return true;
    },
}