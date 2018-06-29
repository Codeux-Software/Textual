/* *********************************************************************
*                  _____         _               _
*                 |_   _|____  _| |_ _   _  __ _| |
*                   | |/ _ \ \/ / __| | | |/ _` | |
*                   | |  __/>  <| |_| |_| | (_| | |
*                   |_|\___/_/\_\\__|\__,_|\__,_|_|
*
*    Copyright (c) 2018 Codeux Software, LLC & respective contributors.
*       Please see Acknowledgements.pdf for additional information.
*
* Redistribution and use in source and binary forms, with or without
* modification, are permitted provided that the following conditions
* are met:
*
*  * Redistributions of source code must retain the above copyright
*    notice, this list of conditions and the following disclaimer.
*  * Redistributions in binary form must reproduce the above copyright
*    notice, this list of conditions and the following disclaimer in the
*    documentation and/or other materials provided with the distribution.
*  * Neither the name of Textual, "Codeux Software, LLC", nor the
*    names of its contributors may be used to endorse or promote products
*    derived from this software without specific prior written permission.
*
* THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
* ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
* IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
* ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
* FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
* DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
* OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
* HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
* LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
* OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
* SUCH DAMAGE.
*
*********************************************************************** */

extension ConnectionSocket
{
	class func socket(with config: IRCConnectionConfig) -> ConnectionSocket & ConnectionSocketProtocol
	{

#if canImport(Network)
		if #available(macOS 10.14, *) {
			if (config.connectionPrefersModernSockets) {
				return ConnectionSocketNWF(with: config)
			}
		}
#endif

		return ConnectionSocketClassic(with: config)
	}
}

@objc(IRCConnection)
class Connection: NSObject, ConnectionSocketDelegate
{
	fileprivate let config: IRCConnectionConfig

	fileprivate let socket: ConnectionSocket & ConnectionSocketProtocol

	fileprivate let serviceConnection: NSXPCConnection

	fileprivate var sendQueue: [Data] = []

	fileprivate lazy var floodControlTimer: TLOTimer = {
		return TLOTimer(actionBlock: { _ in
			self.onFloodControlTimer()
		}, on: DispatchQueue.global(priority: .default))
	}()

	fileprivate var floodControlCurrentMessageCount = 0
	fileprivate var floodControlEnforced = false

	fileprivate var workerQueue: DispatchQueue?

	fileprivate var disconnectingManually = false

	// MARK: - Initialization

	@objc(initWithConfig:onConnection:)
	init (with config: IRCConnectionConfig, on connection: NSXPCConnection)
	{
		self.config = config

		socket = ConnectionSocket.socket(with: config)

		serviceConnection = connection

		super.init()

		socket.delegate = self
	}

	// MARK: - Grand Central Dispatch

	fileprivate func destroyWorkerDispatchQueue()
	{
		workerQueue = nil
	}

	fileprivate func createWorkerDispatchQueue()
	{
		let workerQueueName = "Textual.IRCConnection.workerQueue.\(socket.uniqueIdentifier)"

		workerQueue = DispatchQueue(label: workerQueueName)
	}

	// MARK: - Open/Close

	@objc
	func open()
	{
		LogToConsoleDebug("Opening connection \(socket.uniqueIdentifier)...")

		if (socket.disconnected == false) {
			LogToConsoleError("Already connected")

			return
		}

		createWorkerDispatchQueue()

		startFloodControlTimer()

		disconnectingManually = true

		socket.open()
	}

	@objc
	func close()
	{
		LogToConsoleDebug("Closing connection \(socket.uniqueIdentifier)...")

		if (socket.disconnected) {
			LogToConsoleError("Not connected")

			return
		}

		floodControlEnforced = false

		clearSendQueue()

		stopFloodControlTimer()

		disconnectingManually = true

		socket.close()
	}

	func resetState()
	{
		/* Method invoked when a disconnect occurs. */
		/* disconnectingManually prevents us doing redundant work. */
		if (disconnectingManually) {
			disconnectingManually = false
		} else {
			floodControlEnforced = false

			clearSendQueue()

			stopFloodControlTimer()
		}

		destroyWorkerDispatchQueue()
	}

	// MARK: - Send Queue

	fileprivate var sendQueueCount: Int
	{
		var sendQueueCount = 0

		workerQueue?.sync {
			sendQueueCount = sendQueue.count
		}

		return sendQueueCount
	}

	fileprivate func nextEntryInSendQueue() -> Data?
	{
		var nextEntry: Data?

		workerQueue?.sync {
			nextEntry = sendQueue.first
		}

		return nextEntry
	}

	fileprivate func sendQueue(add data: Data)
	{
		workerQueue?.sync {
			sendQueue.append(data)
		}
	}

	fileprivate func sendQueue(remove data: Data)
	{
		workerQueue?.sync {
			if let index = sendQueue.firstIndex(of: data) {
				sendQueue.remove(at: index)
			}
		}
	}

	@objc
	func clearSendQueue()
	{
		workerQueue?.sync {
			sendQueue.removeAll()
		}
	}

	@discardableResult
	fileprivate func tryToSend() -> Bool
	{
		if (socket.sending) {
			return false
		}

		if (sendQueueCount == 0) {
			return false
		}

		if (floodControlEnforced) {
			if (floodControlCurrentMessageCount >= config.floodControlMaximumMessages) {
				return false
			}
		}

		floodControlCurrentMessageCount += 1

		sendNextLine()

		return true
	}

	fileprivate func sendNextLine()
	{
		guard let line = nextEntryInSendQueue() else {
			return
		}

		send(line, removeFromQueue: true)
	}

	@objc(sendData:bypassQueue:)
	func send(_ data: Data, bypassQueue: Bool = false)
	{
		if (socket.disconnected) {
			LogToConsoleError("Cannot send data while disconnected")

			return
		}

		if (bypassQueue) {
			send(data, removeFromQueue: false)
		}

		sendQueue(add: data)

		tryToSend()
	}

	fileprivate func send(_ data: Data, removeFromQueue: Bool = false)
	{
		if (removeFromQueue) {
			sendQueue(remove: data)
		}

		socket.write(data)
	}

	// MARK: - Flood Control

	@objc
	func enforceFloodControl()
	{
		floodControlEnforced = true
	}

	fileprivate func startFloodControlTimer()
	{
		if (floodControlTimer.timerIsActive) {
			return
		}

		let timerInterval = Double(config.floodControlDelayInterval)

		floodControlTimer.start(timerInterval, onRepeat: true)
	}

	fileprivate func stopFloodControlTimer()
	{
		if (floodControlTimer.timerIsActive == false) {
			return
		}

		floodControlTimer.stop()
	}

	fileprivate func onFloodControlTimer()
	{
		floodControlCurrentMessageCount = 0

		while (tryToSend()) {

		}
	}

	// MARK: - Sockety Proxy

	@objc(exportSecureConnectionInformation:error:)
	func exportSecureConnectionInformation(to receiver: RCMSecureConnectionInformationCompletionBlock) throws
	{
		try socket.exportSecureConnectionInformation(to: receiver)
	}

	// MARK: - Socket Delegate

	var remoteObjectProxy: RCMConnectionManagerClientProtocol
	{
		return serviceConnection.remoteObjectProxy as! RCMConnectionManagerClientProtocol
	}

	func connection(_ connection: ConnectionSocket, willConnectToProxy address: String, on port: UInt16)
	{
		remoteObjectProxy.ircConnectionWillConnect(toProxy: address, port: port)
	}

	func connection(_ connection: ConnectionSocket, willConnectTo address: String, on port: UInt16)
	{

	}

	func connection(_ connection: ConnectionSocket, didConnectTo address: String?)
	{
		remoteObjectProxy.ircConnectionDidConnect(toHost: address)
	}

	func connection(_ connection: ConnectionSocket, securedWith protocol: SSLProtocol, cipherSuite: SSLCipherSuite)
	{
		remoteObjectProxy.ircConnectionDidSecureConnection(withProtocolVersion: `protocol`, cipherSuite: cipherSuite)
	}

	func connection(_ connection: ConnectionSocket, requiresTrust response: @escaping (Bool) -> Void)
	{
		remoteObjectProxy.ircConnectionRequestInsecureCertificateTrust(response)
	}

	func connectionClosedReadStream(_ connection: ConnectionSocket)
	{
		remoteObjectProxy.ircConnectionDidCloseReadStream()
	}

	func connectionDisconnected(_ connection: ConnectionSocket)
	{
		resetState()

		remoteObjectProxy.ircConnectionDidDisconnectWithError(nil)
	}

	func connection(_ connection: ConnectionSocket, disconnectedWith error: ConnectionSocket.ConnectionError)
	{
		resetState()

		remoteObjectProxy.ircConnectionDidDisconnectWithError(error.toNSError())
	}

	func connection(_ connection: ConnectionSocket, received data: Data)
	{
		remoteObjectProxy.ircConnectionDidReceive(data)
	}

	func connection(_ connection: ConnectionSocket, willSend data: Data)
	{
		remoteObjectProxy.ircConnectionWillSend(data)
	}

	func connectionDidSend(_ connection: ConnectionSocket)
	{
		remoteObjectProxy.ircConnectionDidSendData()

		tryToSend()
	}
}
