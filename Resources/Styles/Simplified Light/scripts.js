function newMessagePostedToDisplay(lineNumber)
{
	// Do Something With New Message
	
	//var newLine = document.getElementById("line" + lineNumber);
}

/* The following function calls are required. Add additonal code above it. */
function on_url() { app.setUrl(event.target.innerHTML); }
function on_addr() { app.setAddr(event.target.innerHTML); }
function on_chname() { app.setChan(event.target.innerHTML); }
function on_nick() { app.setNick(event.target.parentNode.parentNode.getAttribute('nick')); }