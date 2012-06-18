// Mechanism to pull in additional CSS or JavaScript files

// Textual.include_js("jquery.min.js");
// Textual.include_css("more_theme.css");


// Function called when new message from IRC has been posted to display

// Textual.newMessagePostedToDisplay = function(lineNumber)
// {
//		var newLine = document.getElementById("line" + lineNumber);
// }


// Functions called for contextual menus used within WebView
// DO NOT change without knowledge of what to do. 
// Safe to remove from source code if not needed. 

// Textual.on_url = function() { app.setUrl(event.target.innerHTML); }
// Textual.on_chname = function() { app.setChan(event.target.innerHTML); }
// Textual.on_ct_nick: function() { app.setNick(event.target.innerHTML); }
// Textual.on_nick = function() { app.setNick(event.target.getAttribute("nick")); }