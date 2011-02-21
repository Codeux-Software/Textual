
utils = {
 browserInfo: {
  matches: {
    webKit: navigator.userAgent.match(/AppleWebKit\/(\d+)/),
    opera: navigator.userAgent.match(/^Opera\/(\d+\.\d+)/),
    mozilla: navigator.userAgent.match(/^Mozilla\/(\d+\.\d+).*\srv:(\d+\.\d+)/)
  }
 },

 firstLast: { row: ["firstRow", "lastRow"], cell: ["firstCell", "lastCell"] },

 regex: {
  hasRows: /\bhasRows\b/,
  zebraRows: /\bzebraRows\b/,
  row: /\brow\b/,
  cell: /\bcell\b/,
  headerRow: /\bheaderRow\b/,
  hidden: /\bhidden\b/,
  remove1: /^.+\(.*\).+$/,
  remove2: /^\(.+\)$/,
  evenOdd: /\b(even|odd)\b/,
  evenOddRemove: /(^\s*)?(\s*?)\b(even|odd)\b(\s*$)?(\s*)?/,
  stripFirstLastRow: /(^\s*)?(\s*?)\b(firstRow|lastRow)\b(\s*$)?(\s*)?/,
  stripFirstLastCell: /(^\s*)?(\s*?)\b(firstCell|lastCell)\b(\s*$)?(\s*)?/
 },

 strip: function(stripRegex, inString) {
    return(inString.replace(stripRegex, function() { var a=arguments; if((typeof(a[2]) == "undefined") || (typeof(a[5]) == "undefined")) { return(""); } return((a[2].length > 0) && (a[5].length > 0) ? " ":""); } ));
  }
};


utils.browserInfo.webKit = (utils.browserInfo.matches.webKit != null) ? true : false;
if(utils.browserInfo.webKit == true) { utils.browserInfo.webKitVersion = utils.browserInfo.matches.webKit[1]; }

utils.browserInfo.opera = (utils.browserInfo.matches.opera != null) ? true : false;
if(utils.browserInfo.opera == true) { utils.browserInfo.operaVersion = utils.browserInfo.matches.opera[1]; }

utils.browserInfo.mozilla = (utils.browserInfo.matches.mozilla != null) ? true : false;
if(utils.browserInfo.mozilla == true) { utils.browserInfo.mozillaVersion = utils.browserInfo.matches.mozilla[1]; utils.browserInfo.geckoVersion = utils.browserInfo.matches.mozilla[2]; }

function fixupBoxRows () {
  var boxesWithRowsArray = getElementsByClassWithRegex(utils.regex.hasRows);
  for(var x=0; x<boxesWithRowsArray.length; x++) {
    fixupFirstLastRowsAndCellsWithBox(boxesWithRowsArray[x]);
    if(boxesWithRowsArray[x].className.search(utils.regex.zebraRows) != -1) { fixupZebraRowsBox(boxesWithRowsArray[x]); }
  }
}

function fixupFirstLastRowsAndCellsWithBox(boxWithRowsAndCells) {
  var rowArray = boxWithRowsAndCells.childNodes;

  fixupFirstLastClassArray(rowArray, utils.regex.stripFirstLastRow, utils.regex.row, utils.firstLast.row);
  for(var x=0; x<rowArray.length; x++) {
    if(rowArray[x].nodeType != 1) { continue; }
    if(rowArray[x].className.search(utils.regex.row) == -1) { continue; }
    fixupFirstLastClassArray(rowArray[x].childNodes, utils.regex.stripFirstLastCell, utils.regex.cell, utils.firstLast.cell);
  }
}

function fixupFirstLastClassArray(elementArray, stripRegex, classRegex, firstLastArray) {
  var firstVisibleElement = null, lastVisibleElement = null;

  for(var x=0; x<elementArray.length; x++) {
    if(elementArray[x].nodeType != 1) { continue; }

    elementArray[x].className = utils.strip(stripRegex, elementArray[x].className);
    if(isElementWithClassRegexVisible(elementArray[x], classRegex) == null) { continue; }
    if(firstVisibleElement == null) { firstVisibleElement = elementArray[x]; }
    lastVisibleElement = elementArray[x];
  }
  if(firstVisibleElement != null) { firstVisibleElement.className = firstVisibleElement.className + " " + firstLastArray[0]; }
  if(lastVisibleElement  != null) { lastVisibleElement.className  = lastVisibleElement.className  + " " + firstLastArray[1];  }
}

function fixupZebraRowsBox(zebraBox) {
  var childArray = zebraBox.childNodes, evenOddCount = 1;

  for(var x=0; x<childArray.length; x++) {
    if(childArray[x].nodeType != 1) { continue; }
    if(childArray[x].className.search(utils.regex.row) == -1) { continue; }
    if((childArray[x].className.search(utils.regex.headerRow) != -1) || (isElementWithClassRegexVisible(childArray[x], utils.regex.row) == null)) {
      childArray[x].className = utils.strip(utils.regex.evenOddRemove, childArray[x].className);
      continue;
    }
    childArray[x].className = childArray[x].className.replace(utils.regex.evenOdd, ((evenOddCount%2) == 1) ? "odd":"even");
    evenOddCount++;
  }
}

function isElementWithClassRegexVisible(element, classRegex) {
  if((element.className.search(classRegex) == -1) || (element.className.search(utils.regex.hidden) != -1)) { return(null); }
  if(typeof(element.scrollWidth) == "undefined") { return(null); }
  if((element.scrollWidth != 0) && (element.scrollHeight != 0)) { return(element); }
  if((utils.browserInfo.webKit == true) && (utils.browserInfo.webKitVersion < 522)) { return(element); }
  return(null);
}

function getElementsByClassWithRegex(withRegex) {
  var matchedElementsArray = new Array(), elementArray = document.getElementsByTagName("*");
  for(var i = 0; i < elementArray.length; i++) { if(elementArray[i].className.search(withRegex) != -1) { matchedElementsArray.push(elementArray[i]); } }
  return(matchedElementsArray);
}

addEventListener("load", fixupBoxRows, false);

