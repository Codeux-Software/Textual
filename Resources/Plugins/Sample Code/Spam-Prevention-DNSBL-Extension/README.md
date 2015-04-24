Spam-Prevention-Extension
=========================

When a user joins a channel, this extension will take the user's IP address and check it against a predefined list of DNS blacklists. If an IP address is found in a blacklist, then a message is displayed to the person using this extension.

This extension also defines the "/dnsbl" command which can be used to do a blacklist lookup for every user within the selected channel.

Example result for an open proxy:

```
Blacklist entry found for Demo-User in #textual-testing with a resolved IP address of 
109.207.50.105 — This entry was found on the EFnet RBL blacklist with the reason: “Open Proxy”
```

The contents of this project including all source files are released into the public domain for unlimited distribution.
