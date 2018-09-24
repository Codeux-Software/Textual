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

#if canImport(Network)
import Network

@available(macOS 10.14, *)
final class ConnectionSocketNWF: ConnectionSocket, ConnectionSocketProtocol
{
	fileprivate var readInBuffer: Data?

	fileprivate var connection: NWConnection?

	fileprivate var socketDelegateQueue: DispatchQueue?

	fileprivate var trustRef: SecTrust?

	// MARK: - Grand Centeral Dispatch

	fileprivate func destroyDispatchQueues()
	{
		socketDelegateQueue = nil
	}

	fileprivate func createDispatchQueues()
	{
		let socketDelegateQueueName = "Textual.ConnectionSocket.socketDelegateQueue.\(uniqueIdentifier)"

		socketDelegateQueue = DispatchQueue(label: socketDelegateQueueName)
	}

	// MARK: - Open/Close Socket

	fileprivate var constructedParameters: NWParameters
	{
		var parameters: NWParameters

		if (config.connectionPrefersSecuredConnection) {
			parameters = NWParameters(tls: constructedTLSOptions)
		} else {
			parameters = .tcp
		}

		parameters.preferNoProxies = (config.proxyType == .none)

		if let internetProtocol = parameters.defaultProtocolStack.internetProtocol as? NWProtocolIP.Options {
			switch config.addressType {
				case .v4:
					internetProtocol.version = .v4
				case .v6:
					internetProtocol.version = .v6
				default:
					break
			}
		}

		return parameters
	}

	fileprivate var constructedTLSOptions: NWProtocolTLS.Options
	{
		let tlsOptions = NWProtocolTLS.Options()

		let secOptions = tlsOptions.securityProtocolOptions

		if let localIdentity = tlsLocalIdentity {
			sec_protocol_options_set_local_identity(secOptions, localIdentity)
		}

		if (config.cipherSuites == .none) {
			sec_protocol_options_add_tls_ciphersuite_group(secOptions, .default)
		} else {
			let cipherSuites = RCMSecureTransport.cipherSuites(in:  config.cipherSuites,
												includeDeprecated: (config.connectionPrefersModernCiphersOnly == false))

			for cipherSuite in cipherSuites {
				sec_protocol_options_add_tls_ciphersuite(secOptions, cipherSuite.uint32Value as SSLCipherSuite)
			}
		}

		sec_protocol_options_set_tls_min_version(secOptions, .tlsProtocol1)

		sec_protocol_options_set_verify_block(secOptions, { [weak self] (_, trust, completionBlock) in
			self?.tlsVerifySecProtocol(trust, response: completionBlock)
		}, socketDelegateQueue!)

		return tlsOptions
	}

	func open()
	{
		if (disconnected == false || disconnecting) {
			return
		}

		createDispatchQueues()

		let serverAddress = config.serverAddress
		let serverPort = config.serverPort

		let connection = NWConnection(host: NWEndpoint.Host(stringLiteral: serverAddress),
									  port: NWEndpoint.Port(integerLiteral: serverPort),
									  using: constructedParameters)

		connection.stateUpdateHandler = statusUpdateHandler

		self.connection = connection

		delegate?.connection(self, willConnectTo: serverAddress, on: serverPort)

		connect()
	}

	fileprivate func connect()
	{
		connecting = true

		connection?.start(queue: socketDelegateQueue!)
	}

	func close()
	{
		if (disconnected || disconnecting) {
			return
		}

		disconnecting = true

		connection?.cancel()
	}

	fileprivate func close(with error: NWError)
	{
		close(with: translateError(error))
	}

	override func resetState()
	{
		super.resetState()

		connection = nil

		destroyDispatchQueues()
	}

	// MARK: - Socket Read & Write

	func read()
	{
		if (connected == false || disconnecting) {
			return
		}

		connection?.receive(minimumIncompleteLength: 0,
							maximumLength: maximumDataLength,
							completion: readCompletionHandler)
	}

	func readIn(_ data: Data)
	{
		if (disconnected || disconnecting) {
			return
		}

		/* First combine the existing read buffer with the
		 new data so we can process it in mass. */
		/* Note: June 29, 2018 on Swift 4.2 on Xcode 10 beta 2
		 When I first wrote this code, I wrote the logic in the
		 form "newBuffer = (oldBuffer + data)" When writing it
		 using this syntax, Foundation would throw at random
		 an out of range exception similiar to the following:

		 *** Terminating app due to uncaught exception 'NSRangeException', reason: '*** -[NSConcreteMutableData subdataWithRange:]: range {12945, 87} exceeds data length 7282'

		 TODO: Maybe this should be revisited at a later time. */
		var newBuffer: Data

		if let oldBuffer = readInBuffer {
			newBuffer = oldBuffer
		} else {
			newBuffer = Data()
		}

		newBuffer.append(data)

		/* Regardless of the result, we need to update the
		 saved buffer with the updated buffer, but we prefer
		 to wait until then end to do that. */
		defer {
			readInBuffer = newBuffer
		}

		/* Split the data */
		guard let (lines, remainingData) = newBuffer.splitNetworkLines() else {
			return
		}

		for line in lines {
			delegate?.connection(self, received: line)
		}

		if let remainder = remainingData {
			newBuffer = remainder
		} else {
			/* "Pass true to request that the collection avoid releasing its
			 storage. Retaining the collection’s storage can be a useful
			 optimization when you’re planning to grow the collection again." */

			newBuffer.removeAll(keepingCapacity: true)
		}
	}

	func write(_ data: Data)
	{
		if (connected == false || disconnecting) {
			return
		}

		/* We only allow one write a time */
		if (sending) {
			return
		}

		sending = true

		delegate?.connection(self, willSend: data)

		connection?.send(content: data, completion: .contentProcessed(writeCompletionHandler))
	}

	// MARK: - Properties

	fileprivate var connectedHost: String?
	{
		guard let endpoint = connection?.currentPath?.remoteEndpoint else {
			return nil
		}

		if case let .hostPort(host, _) = endpoint {
			switch host {
				case .name(let address, _):
					return address
				case .ipv4(let address):
					return address.rawValue.IPv4Address
				case .ipv6(let address):
					return address.rawValue.IPv6Address
			}
		}

		return nil
	}

	fileprivate func onConnect()
	{
		connecting = false
		connected = true

		read()

		delegate?.connection(self, didConnectTo: connectedHost)

		onSecured()
	}

	fileprivate func onSecured()
	{
		/* We call onSecured() regardless of other preconditions then
		 only mark ourselves as secured if we have protocol information. */
		guard  let protocolVersion 	= tlsNegotiatedProtocol,
			   let cipherSuite 		= tlsNegotiatedCipherSuite else
		{
			return
		}

		secured = true

		delegate?.connection(self, securedWith: protocolVersion, cipherSuite: cipherSuite)
	}

	fileprivate func onDisconnect(with error: Error?)
	{
		defer {
			resetState()
		}

		var errorPayload: ConnectionError?

		if let alternateError = alternateDisconnectError {
			errorPayload = alternateError
		} else if let nwError = error as? NWError {
			errorPayload = translateError(nwError)
		}

		if (errorPayload == nil) {
			delegate?.connectionDisconnected(self)
		} else {
			delegate?.connection(self, disconnectedWith: errorPayload!)
		}
	}

	// NWConnection Delegate

	final func readCompletionHandler(_ content: Data?, _ contentContext: NWConnection.ContentContext?, _ isComplete: Bool, _ error: NWError?)
	{
		if (disconnecting) {
			return
		}

		if let error = error {
			close(with: error)

			return
		}

		if (contentContext?.isFinal == true && isComplete) {
			EOFReceived = true

			delegate?.connectionClosedReadStream(self)

			return
		}

		if (content == nil) {
			close(with: "Unexpected condition: There is no data when there is no error")

			return
		}

		readIn(content!)

		read()
	}

	final func writeCompletionHandler(_ error: NWError?)
	{
		if (disconnecting) {
			return
		}

		sending = false

		if let error = error {
			close(with: error)

			return
		}

		delegate?.connectionDidSend(self)
	}

	final func statusUpdateHandler(_ status: NWConnection.State)
	{
		switch status {
			case .waiting(let error):
				close(with: error)
			case .ready:
				onConnect()
			case .cancelled:
				onDisconnect(with: nil)
			case .failed(let error):
				onDisconnect(with: error)
			default:
				LogToConsoleDebug("Status changed \(status)")
		}
	}

	// MARK: - Security

	final func tlsVerifySecProtocol(_ trust: sec_trust_t, response: @escaping sec_protocol_verify_complete_t)
	{
		let trustRef = sec_trust_copy_ref(trust).takeUnretainedValue()

		self.trustRef = trustRef

		tlsVerify(trustRef) { (underlyingResponse) in
			response(underlyingResponse)
		}
	}

	var tlsNegotiatedProtocol: SSLProtocol?
	{
		var protocolVersion: SSLProtocol?

		accessTLSMetadata { (metadata) in
			protocolVersion = sec_protocol_metadata_get_negotiated_protocol_version(metadata)
		}

		return protocolVersion
	}

	var tlsNegotiatedCipherSuite: SSLCipherSuite?
	{
		var cipherSuite: SSLCipherSuite?

		accessTLSMetadata { (metadata) in
			cipherSuite = sec_protocol_metadata_get_negotiated_ciphersuite(metadata)
		}

		return cipherSuite
	}

	var tlsCertificateChainData: [Data]?
	{
		var certificateChain: [Data]?

		accessTLSTrustRef { (trustRef) in
			certificateChain = RCMSecureTransport.certificates(in: trustRef)
		}

		return certificateChain
	}

	var tlsPolicyName: String?
	{
		var policyName: String?

		accessTLSTrustRef { (trustRef) in
			policyName = RCMSecureTransport.policyName(in: trustRef)
		}

		return policyName
	}

	fileprivate func accessTLSMetadata(with closure: (sec_protocol_metadata_t) -> Void)
	{
		guard let genericMetadata = connection?.metadata(definition: NWProtocolTLS.definition) else {
			return
		}

		guard let tlsMetadata = genericMetadata as? NWProtocolTLS.Metadata else {
			return
		}

		closure(tlsMetadata.securityProtocolMetadata)
	}

	fileprivate func accessTLSTrustRef(with closure: (SecTrust) -> Void)
	{
		if let trustRef = trustRef {
			closure(trustRef)
		}
	}

	var tlsLocalIdentity: sec_identity_t?
	{
		guard let clientCertificate = clientSideCertificate else {
			return nil
		}

		/* And I thought I wrote verbose names... */
		return sec_identity_create_with_certificates(clientCertificate.identity,
													([clientCertificate.certificate] as CFArray))
	}

	// MARK: - Error Handling

	fileprivate func translateError(_ error: NWError) -> ConnectionError
	{
		switch error {
			case .dns(let errorCode):
				return ConnectionError(nwDNSError: errorCode)
			case .posix(let errorCode):
				return ConnectionError(nwPOSIXError: errorCode.rawValue)
			case .tls(let errorCode):
				return ConnectionError(nwTLSError: errorCode)
		}
	}
}

fileprivate extension ConnectionError
{
	init (nwDNSError: DNSServiceErrorType)
	{
		let errorCode = Int(nwDNSError)

		let errorReason: String

		switch errorCode {
			case kDNSServiceErr_NoError:
				errorReason = "No error"
			case kDNSServiceErr_NoSuchName:
				errorReason = "No such name"
			case kDNSServiceErr_NoMemory:
				errorReason = "No memory"
			case kDNSServiceErr_BadParam:
				errorReason = "Bad paramater"
			case kDNSServiceErr_BadReference:
				errorReason = "Bad reference"
			case kDNSServiceErr_BadState:
				errorReason = "Bad state"
			case kDNSServiceErr_BadFlags:
				errorReason = "Bad flags"
			case kDNSServiceErr_Unsupported:
				errorReason = "Unsupported"
			case kDNSServiceErr_NotInitialized:
				errorReason = "Not initialized"
			case kDNSServiceErr_AlreadyRegistered:
				errorReason = "Already registered"
			case kDNSServiceErr_NameConflict:
				errorReason = "Name conflict"
			case kDNSServiceErr_Invalid:
				errorReason = "Invalid"
			case kDNSServiceErr_Firewall:
				errorReason = "Firewall"
			case kDNSServiceErr_Incompatible: /* client library incompatible with daemon */
				errorReason = "Incompatible"
			case kDNSServiceErr_BadInterfaceIndex:
				errorReason = "Bad interface index"
			case kDNSServiceErr_Refused:
				errorReason = "Refused"
			case kDNSServiceErr_NoSuchRecord:
				errorReason = "No such record"
			case kDNSServiceErr_NoAuth:
				errorReason = "No authentication"
			case kDNSServiceErr_NoSuchKey:
				errorReason = "No such key"
			case kDNSServiceErr_NATTraversal:
				errorReason = "NAT traversal"
			case kDNSServiceErr_DoubleNAT:
				errorReason = "Double NAT"
			case kDNSServiceErr_BadTime: /* Codes up to here existed in Tiger */
				errorReason = "Bad time"
			case kDNSServiceErr_BadSig:
				errorReason = "Bad signature"
			case kDNSServiceErr_BadKey:
				errorReason = "Bad key"
			case kDNSServiceErr_Transient:
				errorReason = "Transient"
			case kDNSServiceErr_ServiceNotRunning: /* Background daemon not running */
				errorReason = "Service not running"
			case kDNSServiceErr_NATPortMappingUnsupported: /* NAT doesn't support PCP, NAT-PMP or UPnP */
				errorReason = "NAT port mapping unsupported"
			case kDNSServiceErr_NATPortMappingDisabled: /* NAT supports PCP, NAT-PMP or UPnP, but it's disabled by the administrator */
				errorReason = "NAT port mapping disabled"
			case kDNSServiceErr_NoRouter: /* No router currently configured (probably no network connectivity) */
				errorReason = "No router"
			case kDNSServiceErr_PollingMode:
				errorReason = "Polling mode"
			case kDNSServiceErr_Timeout:
				errorReason = "Timeout"
			default:
				errorReason = "Unknown"
		}

		let errorMessage = LocalizedString("DNS Error: %@ (%ld)", errorReason, errorCode, table: "ConnectionErrors")

		let nsError = NSError(domain: "NWErrorDomainDNS",
							  code: errorCode,
							  userInfo: [ NSLocalizedDescriptionKey : errorMessage ])

		self.init(socketError: nsError)
	}

	init (nwPOSIXError: Int32)
	{
		let errorCode = Int(nwPOSIXError)

		let errorReason: String

		if let errorReasonC = strerror(nwPOSIXError) {
			errorReason = String(cString: errorReasonC)
		} else {
			errorReason = "Unknown"
		}

		let errorMessage = LocalizedString("POSIX Error: %@ (%ld)", errorReason, errorCode, table: "ConnectionErrors")

		let nsError = NSError(domain: "NWErrorDomainPOSIX",
							  code: errorCode,
							  userInfo: [ NSLocalizedDescriptionKey : errorMessage ])

		self.init(socketError: nsError)
	}

	init (nwTLSError: OSStatus)
	{
		let errorCode = Int(nwTLSError)

		self.init(tlsError: errorCode)
	}
}

#endif
