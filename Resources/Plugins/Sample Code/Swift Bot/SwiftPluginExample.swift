
/* We create a class that inherits from NSObject so we need Foundation. */
import Foundation

/* As Textual creates a new instance of our primary class when the plugin
loads, it must inherit NSObject to allow proper initialization. */
/* THOPluginProtocol is the protocol available for plugin specific callbacks.
It is appended to our new class object to inform swift that we conform to it.
However, all methods in this class are optional. The plugin does not have to
inherit anyone of them and can instead manipulate using any calls within its
public header files available at /Applications/Textual.app/Contents/Headers/ */
class TPI_SwiftPluginExample: NSObject, THOPluginProtocol
{
	func subscribedServerInputCommands() -> [String]
	{
		/* Accept all incoming server data corresponding to the
		commands PRIVMSG and NOTICE. The plugin will perform
		different actions for each value. */
		
		return ["privmsg", "notice"]
	}
	
	func didReceiveServerInputOnClient(client: IRCClient!, senderInformation senderDict: [NSObject : AnyObject]!, messageInformation messageDict: [NSObject : AnyObject]!)
	{
		/* Swift provides a very powerful switch statement so
		it is easier to use that for identifying commands than
		using an if statement if more than the two are added. */
		let commandValue = (messageDict["messageCommand"] as NSString)
		
		switch (commandValue) {
			case "PRIVMSG":
				self.handleIncomingPrivateMessageCommand(client, senderDict: senderDict, messageDict: messageDict)
			case "NOTICE":
				self.handleIncomingNoticeCommand(client, senderDict: senderDict, messageDict: messageDict)
			default:
				return;
		}
	}
	
	func handleIncomingPrivateMessageCommand(client: IRCClient!, senderDict: [NSObject : AnyObject]!, messageDict: [NSObject : AnyObject]!)
	{
		/* Get message sequence of incoming message. */
		let messageReceived = (messageDict["messageSequence"] as NSString)
		
		let messageParamaters = (messageDict["messageParamaters"] as NSArray)
		
		/* Get channel that message was sent from. */
		/* The first paramater of the PRIVMSG command is always
		the channel the message was targetted to. */
		let senderChannelString = (messageParamaters[0] as String);
		
		let senderChannel = client.findChannel(senderChannelString)
		
		/* Do not accept private messages. */
		if senderChannel.isChannel == false {
			return;
		}
		
		/* Get sender of message. */
		let messageSender = (senderDict["senderNickname"] as NSString)
		
		/* Ignore this user, he's kind of a jerk. :-( */
		if messageSender.hasPrefix("Alex") {
			return;
		}
		
		/* Compare it against a specific value. */
		if (messageReceived == "do you know what time it is?" ||
			messageReceived == "does anybody know what time it is?")
		{
			/* Format message. */
			let formattedString = (messageSender + " the time where I am is: " + self.formattedDateTimeString());
			
			/* Invoke the client on the main thread when sending. */
			self.performBlockOnMainThread({
				client.sendPrivmsg(formattedString, toChannel: senderChannel)
			});
		}
	}
	
	func handleIncomingNoticeCommand(client: IRCClient!, senderDict: [NSObject : AnyObject]!, messageDict: [NSObject : AnyObject]!)
	{
		// Not implemented.
	}
	
	/* Support a new command in text field. */
	func subscribedUserInputCommands() -> [String]
	{
		return ["datetime"]
	}
	
	func userInputCommandInvokedOnClient(client: IRCClient!, commandString: String!, messageString: String!)
	{
		/* Format message. */
		let formattedString = ("The current time is: " + self.formattedDateTimeString());
		
		/* iomt() is in DDExtensions.h. It invokes on the call on the main
		thread by proxying on the call. As printing a message involves
		interaction with WebKit, we have to do work on main thread. */
		self.performBlockOnMainThread({
			client.sendPrivmsg(formattedString, toChannel:self.masterController().mainWindow.selectedChannel)
		});
	}
	
	/* Helper functions. */
	func formattedDateTimeString() -> (String)
	{
		let dateFormatter = NSDateFormatter()
		
		dateFormatter.dateStyle = NSDateFormatterStyle.FullStyle
		dateFormatter.timeStyle = NSDateFormatterStyle.FullStyle
		
		let formattedDate = dateFormatter.stringFromDate(NSDate())
		
		return formattedDate
	}
}
