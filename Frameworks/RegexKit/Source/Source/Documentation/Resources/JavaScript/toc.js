if(typeof(utils) == "undefined") { utils = {}; }

utils.toc = {
 regex: {
   tocID: /^tocID/,
   title: /\btitle\b/,
   section: /\bsection\b/,
   indicator: /\bindicator\b/,
   openClosed: /\b(open|closed)\b/,
   entries: /\bentries\b/,
   contents: /\bcontents\b/,
   toc: /\btoc\b/,
   open: /\bopen\b/,
   closed: /\bclosed\b/,
   header: /\bheader\b/,
   openSection: /(\bsection\b(.*)\bopen\b|\bopen\b(.*)\bsection\b)/
 }
}

function initialize_toc () {
  var elementArray = document.getElementsByTagName("*");
  
  for(var i = 0; i < elementArray.length; i++) {
    var atElement = elementArray[i];
    if((typeof(atElement.className) == undefined) || (atElement.className == null)) { continue; }
    if((atElement.className.search(utils.toc.regex.title) != -1) || (atElement.className.search(utils.toc.regex.indicator) != -1)) {
      atElement.onmousedown = toggle;
    } else if((atElement.className.search(utils.toc.regex.section) != -1) && (atElement.className.search(utils.toc.regex.openClosed) == -1)) {
      atElement.className += " closed";
    }
  }

  if((utils.browserInfo.mozilla == true) || (utils.browserInfo.opera == true)) { document.getElementById("tocOuterID").style.display = "table"; }
  if(utils.browserInfo.webKit == true) { document.getElementById("tocOuterID").style.maxWidth = "56ex"; }

  resetOpenTitlesFromCookie();
}

function toggleWithElement (element) {
  var atElement = element;

  while(atElement != null) {
    if(atElement.className.search(utils.toc.regex.toc) != -1) { return; }

    if(atElement.className.search(utils.toc.regex.section) != -1) {
      if(atElement.className.search(utils.toc.regex.closed) != -1) { atElement.className = atElement.className.replace(utils.toc.regex.closed, "open"); }
      else if(atElement.className.search(utils.toc.regex.open) != -1) { atElement.className = atElement.className.replace(utils.toc.regex.open, "closed"); }
      return;
    }

    atElement = atElement.parentNode;
  }
}

function toggle() {
  toggleWithElement(this);
  setOpenTitlesCookie();
}

function setOpenTitlesCookie () {
  var openArray = new Array();
  var elementArray = document.getElementsByTagName("*");

  for(var i = 0; i < elementArray.length; i++) {
    var atElement = elementArray[i];
    if(atElement.nodeType != 1) { continue; }
    if((atElement.className.search(utils.toc.regex.section) != -1) && (atElement.className.search(utils.toc.regex.open) != -1) && (atElement.id.search(utils.toc.regex.tocID) != -1)) { openArray.push('"'+atElement.id+'"'); }
  }

  document.cookie = "openTitles=\""+escape("["+openArray.join(", ")+"]")+"\";";
}

function openTitlesCookieArray () {
  var openTitlesCookie = null, openTitles = null;
  if((openTitlesCookie = document.cookie.match(/openTitles=\"(.*)\";?/)) == null) { return(null); }
  openTitlesCookie = unescape(openTitlesCookie[1]);
  if(openTitlesCookie.search(/[\{\}\(\)\;]/) != -1) { return(null); }
  try { openTitles = eval(unescape(openTitlesCookie)); } catch(e) { /*nothing*/ }
  return(openTitles);
}

function convertArray(inArray) {
  var convertedArray = {};
  for(var x=0; x<inArray.length; x++) { convertedArray[inArray[x]] = true; }
  return(convertedArray);
}

function resetOpenTitlesFromCookie () {
  var openTitlesArray = openTitlesCookieArray();
  if(openTitlesArray == null) { return; }

  for(var i = 0; i < openTitlesArray.length; i++) {
    var atElement = document.getElementById(openTitlesArray[i]);
    if(atElement == null) { continue; }
    if(atElement.className.search(utils.toc.regex.closed) != -1) { toggleWithElement(atElement); }
  }
}

function sectionForElement (searchElement) {
  var atElement = searchElement;

  while(atElement != null) {
    if(atElement.className.search(utils.toc.regex.toc) != -1) { return(null); }
    if(atElement.className.search(utils.toc.regex.section) != -1) { return(atElement); }
    atElement = atElement.parentNode;
  }
}

addEventListener("load", initialize_toc, false);
