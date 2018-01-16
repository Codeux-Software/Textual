/* jslint browser: true */
/* global app, Textual */

/* Defined in: "Textual.app -> Contents -> Resources -> JavaScript -> API -> core.js" */

/* Theme-wide preferences, as per milky's request */
var Equinox = {
  dateFormat: {
    day: 'numeric',
    month: 'long',
    weekday: 'long',
    year: 'numeric'
  },
  fadeNicks: true,            // fade out nicknames when they appear multiple times in a row
  fadeNicksFreq: 10,          // how frequently to display a nick if they have fadeNickCounts lines in a row
  showDateChanges: true,      // show date changes
  squashModes: true,          // if a duplicate mode gets posted to the channel, squash it
  squashTopics: true          // if a duplicate topic gets posted to the channel, squash it
};

/* Set the default statuses for everything tracked in the roomState */
var mappedSelectedUsers = [];
var rs                  = { // room state
  date: {
    year: 0,
    month: 0,
    day: 0
  },
  enableHistoryView: false,  // this doesn't get enabled until the history has finished loading
  mode: {
    mode: undefined
  },
  nick: {
    count: 1,
    delete: false,
    id: undefined,
    nick: undefined
  },
  topic: {
    delete: false,
    topic: undefined
  }
};

var NickColorGenerator = (function () {
  'use strict';

  function NickColorGenerator(message) {
    var i, inlineNicks, nick;

    // Start alternative nick colouring procedure
    var selectNick = message.querySelector('.sender');

    inlineNicks = message.querySelectorAll('.inlineSender');

    this.generateColorFromNickname(selectNick.dataset.nickname,
      function(nickcolor) {
        selectNick.style.color = nickcolor;

        if (message.dataset.lineType === 'action') {
          message.querySelector('.message').style.color = nickcolor;
        }
      }
    );

    var self = this;
    for (i = 0; i < inlineNicks.length; i++) {
      nick = inlineNicks[i].textContent;
      if (inlineNicks[i].dataset.mode.length > 0) {
        nick = nick.replace(inlineNicks[i].dataset.mode, '');
      }
      var inlineNick = inlineNicks[i];
      (function(inlineNickname) {
        self.generateColorFromNickname(nick,
          function(nickcolor) {
            inlineNickname.style.color = nickcolor;
          }
        );
      })(inlineNick);
    }
  }

  NickColorGenerator.prototype.generateColorFromNickname = function (nick, callbackFunction) {
    // First, sanitize the nicknames
    nick = nick.toLowerCase();      // make them lowercase (so that April and april produce the same color)
    nick = nick.replace(/[`_-]+$/, ''); // typically `, _, and - are used on the end of a nick
    nick = nick.replace(/|.*$/, '');  // remove |<anything> from the end

    // Generate the hashes
    app.nicknameColorStyleHash(nick, 'HSL-dark',
      function(hhash) {
        var shash = hhash >>> 1;
        var lhash = hhash >>> 2;

        var h       = hhash % 360;
        var s       = shash % 50 + 45;   // 50 - 95
        var l       = lhash % 36 + 45;   // 45 - 81

        // give the pinks a wee bit more lightness
        if (h >= 280 && h < 335) {
          l = lhash % 36 + 50; // 50 - 86
        }

        // Give the blues a smaller (but lighter) range
        if (h >= 210 && h < 280) {
          l = lhash % 25 + 65; // 65 - 90
        }

        // Give the reds a bit less saturation
        if (h <= 25 || h >= 335) {
          s = shash % 33 + 45; // 45 - 78
        }

        // Give the yellows and greens a bit less saturation as well
        if (h >= 50 && h <= 150) {
          s = shash % 50 + 40; // 40 - 90
        }

        var nickcolor = 'hsl(' + String(h) + ',' + String(s) + '%,' + String(l) + '%)';

        callbackFunction(nickcolor);
      }
    );
  };

  return NickColorGenerator;
})();

function isMessageInViewport(elem) {
  'use strict';

  if (!elem.getBoundingClientRect) {
    return true;
  }

  // Have to use Math.floor() because sometimes the getBoundingClientRect().bottom is a fraction of a pixel (!!!)
  return (Math.floor(elem.getBoundingClientRect().bottom) - 1) <= Math.floor(document.documentElement.clientHeight);
}

function toggleHistoryIfScrolled() {
  'use strict';

  var line, lines;
  var topic = document.getElementById('topicBar');

  lines = document.getElementById('body').getElementsByClassName('line');
  if (lines.length < 2) {
    return;
  }
  line = lines[lines.length - 1];

  if (isMessageInViewport(line) === false) {
    // scrollback
    rs.history.style.display = 'inline';
    if (topic) { topic.style.visibility = 'hidden'; }
  } else {
    // at the bottom
    rs.history.style.display = 'none';
    if (topic) { topic.style.visibility = 'visible'; }
  }
}

/* Insert a date, if the date has changed from the previous message */
function dateChange(e) {
  'use strict';
  var timestamp, datetime, year, month, day, id, ltype;
  var MAXTIMEOFFSET = 30000;  // 30 seconds

  // Only show date changes if the option is enabled
  if (!Equinox.showDateChanges) {
    return;
  }

  timestamp = parseFloat(e.dataset.timestamp) * 1000;
  datetime = new Date(timestamp);

  year = datetime.getFullYear();
  month = datetime.getMonth();
  day = datetime.getDate();
  id = 'date-' + String(year) + '-' + String(month + 1) + '-' + String(day);

  // Occasionally when replaying, Textual will post messages in the future, and then jump backwards
  // As such, we'll ignore all joins, modes, and topics, if they're more than MAXTIMEOFFSET milliseconds
  // from the current time
  ltype = e.dataset.lineType;
  if (ltype !== 'privmsg') {
    if (Date.now() - timestamp > MAXTIMEOFFSET) {
      return;
    }
  }

  // If the date is the same, then there's nothing to do here
  if (year === rs.date.year && month === rs.date.month && day === rs.date.day) {
    return;
  }

  var deleteLastlineDate = function (ll) {
    if (ll) {
      if ((ll.id === 'mark') || (ll.className === 'date')) {
        ll.parentNode.removeChild(ll);
      }
    }
  };

  // Create the date element: <div class="date"><hr /><span>...</span><hr /></div>
  var div = document.createElement('div');
  var span = document.createElement('span');
  div.className = 'date';
  div.id = id;
  div.appendChild(document.createElement('hr'));
  div.appendChild(span);
  div.appendChild(document.createElement('hr'));

  // Set the span's content to the current date (Friday, October 14th)
  span.textContent = datetime.toLocaleDateString('default', Equinox.dateFormat);

  // Insert the date before the newly posted message
  e.parentElement.insertBefore(div, e);

  // Update the previous state
  rs.date = {
    year: year,
    month: month,
    day: day
  };

  // Reset the nick count back to 1, so the nick always shows up after a date change
  rs.nick.count = 1;
  rs.nick.nick = undefined;
}

/* When you join a channel, delete all the old disconnected messages */
Textual.handleEvent = function (event) {
  'use strict';
  var i, messages;

  if (event === 'channelJoined') {
    messages = document.querySelectorAll('div[data-command="-100"]');
    for (i = 0; i < messages.length; i++) {
      if (messages[i].getElementsByClassName('message')[0].textContent.search('Disconnect') !== -1) {
        messages[i].parentNode.removeChild(messages[i]);
      }
    }
  }
};

Textual.messageAddedToView = function (line, fromBuffer) {
  'use strict';
  var message = document.getElementById('line-' + line);
  var clone, elem, getEmbeddedImages, i, mode, messageText, sender, topic;

  // reset the message count and previous nick, when you rejoin a channel
  if (message.dataset.lineType !== 'privmsg') {
    rs.nick.count = 1;
    rs.nick.nick = undefined;
  }

  // if it's a private message, colorize the nick and then track the state and fade away the nicks if needed
  if (message.dataset.lineType === 'privmsg' || message.dataset.lineType === 'action') {
    sender = message.getElementsByClassName('sender')[0];
    if (sender.dataset.overrideColor !== 'true') {
      new NickColorGenerator(message); // colorized the nick
    }

    // Delete (ie, make foreground and background color identical) the previous line's nick, if it was set to be deleted
    if (rs.nick.delete === true) {
      elem = document.getElementById(rs.nick.id).getElementsByClassName('sender')[0];
      elem.className += ' f';
    }

    // Track the nicks that submit messages, so that we can space out everything
    if ((rs.nick.nick === sender.textContent) && (rs.nick.count < Equinox.fadeNicksFreq)
      && (message.dataset.lineType !== 'action') && (Equinox.fadeNicks === true)) {
      rs.nick.delete = true;
      rs.nick.count += 1;
    } else {
      rs.nick.nick = sender.textContent;
      rs.nick.count  = 1;
      rs.nick.delete = false;
    }

    // Track the previous message's id
    rs.nick.id = message.getAttribute('id');

    // Copy the message into the hidden history
    clone = message.cloneNode(true);
    clone.removeAttribute('id');

    if (fromBuffer === false) {
      rs.history.appendChild(clone);
    }

    // Colorize it as well
    if (sender.dataset.overrideColor !== 'true') {
      new NickColorGenerator(clone); // colorized the nick
    }

    // Remove old messages, if the history is longer than three messages
    if (rs.history.childElementCount > 2) {
      rs.history.removeChild(rs.history.childNodes[0]);

      // Hide the first nick in the hidden history, if it's the same as the second
      if ((rs.nick.count > 1) && (message.dataset.lineType !== 'action')) {
        rs.history.getElementsByClassName('sender')[0].style.visibility = 'hidden';
      }
    }
  }

  /* Let's kill topics that appear where they had already been set before
     This happens when you join a room (like a reconnect) that you had been in and seen the topic before */
  if (Equinox.squashTopics === true && message.dataset.lineType === 'topic') {
    topic = message.getElementsByClassName('message')[0].textContent.replace('Topic is ', '').replace(/\s+/, '');

    if (message.dataset.command === '332') { // an actual topic change
      // hide the topic if it's the same topic again
      if (topic === rs.topic.topic) {
        message.parentNode.removeChild(message);
        rs.topic.delete = true;
      }

      rs.topic.topic = topic;
    }

    if ((message.dataset.command === '333') && (rs.topic.delete === true)) {
      message.parentNode.removeChild(message);
      rs.topic.delete = false;
    }
  }

  // much like we suppress duplicate topics, we want to suppress duplicate modes
  if (Equinox.squashModes === true && message.dataset.lineType === 'mode') {
    mode = message.getElementsByClassName('message')[0].textContent.replace(/\s+/, '');

    if (mode === rs.mode.mode) {
      message.parentNode.removeChild(message);
    } else {
      rs.mode.mode = mode;
    }
  }

  // hide messages about yourself joining
  if ((message.dataset.lineType === 'join') || (message.dataset.lineType === 'part')) {
    app.localUserNickname(
      function(returnValue) {
        if (returnValue == message.getElementsByClassName('message')[0].getElementsByTagName('b')[0].textContent) {
          message.parentNode.removeChild(message);
        }
      }
    );
  }

  /* clear out all the old disconnect messages, if you're currently connected to the channel
     note that normally Textual.handleEvent will catch this, but if you reload a theme, they will reappear */
  if ((message.dataset.lineType === 'debug') && (message.dataset.command === '-100')) {
    app.channelIsJoined(
      function(returnValue) {
        if (returnValue && message.getElementsByClassName('message')[0].textContent.search('Disconnect') !== -1) {
          message.parentNode.removeChild(message);
        }
      }
    );
  } else {
    // call the dateChange() function, for any message with a timestamp that's not a debug message
    if (message.dataset.timestamp) {
      dateChange(message);
    }
  }

  if (message.dataset.encrypted === 'true') {
    messageText = message.querySelector('.innerMessage');
    if (messageText.innerText.indexOf('+OK') !== -1) {
      message.dataset.encrypted = 'failed';
    }
  }

  getEmbeddedImages = message.querySelectorAll('img');
  if (getEmbeddedImages) {
    for (i = 0; i < getEmbeddedImages.length; i++) {
      getEmbeddedImages[i].onload = function (e) {
        setTimeout(function () {
          if (e.target.offsetHeight > (window.innerHeight - 150)) {
            e.target.style.height = (window.innerHeight - 150);
          }
        }, 1000);
      };
    }
  }

  ConversationTracking.updateNicknameWithNewMessage(message);
};

/* This is called when a .sender is clicked */
Textual.nicknameSingleClicked = function (e) {
  ConversationTracking.nicknameSingleClickEventCallback(e);
};

Textual.viewBodyDidLoad = function () {
  'use strict';
  Textual.fadeOutLoadingScreen(1.00, 0.95);
};

Textual.viewFinishedLoadingHistory = function () {
  'use strict';

  // enable the history view, but only a bit after this gets called
  setTimeout(function() {
    rs.enableHistoryView = true;
  }, 850);
}

Textual.viewInitiated = function () {
  'use strict';

  /* When the view is loaded, create a hidden history div which we display if there is scrollback */
  var body = document.getElementById('body'), div = document.createElement('div');
  div.id = 'scrolling_history';
  document.getElementsByTagName('body')[0].appendChild(div);
  rs.history = div;

  /* setup the scrolling event to display the hidden history if the bottom element isn't in the viewport
     also hide the topic bar when scrolling.  Note that we have to set a timer here so that the history
     div doesn't appear in the viewport on normal inserts, which cause scroll effects */
  window.addEventListener('scroll', function () {
    // check to see if a bit of time has passed since we loaded the history
    if (!rs.enableHistoryView) {
      return;
    }

    rs.scrollTimer = setTimeout(toggleHistoryIfScrolled, 100);
  });
};
