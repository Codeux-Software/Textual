

NS_ASSUME_NONNULL_BEGIN

@interface IRCConnection ()
@property (nonatomic, copy, readwrite) IRCConnectionConfig *config;
@property (nonatomic, assign, readwrite) BOOL isConnected;
@property (nonatomic, assign, readwrite) BOOL isConnecting;
@property (nonatomic, assign, readwrite) BOOL isSending;
@property (nonatomic, assign, readwrite) BOOL isSecured;
@property (nonatomic, assign, readwrite) BOOL isConnectedWithClientSideCertificate;
@property (nonatomic, strong) dispatch_queue_t dispatchQueue;
@property (nonatomic, strong) dispatch_queue_t socketQueue;
@property (nonatomic, strong) GCDAsyncSocket *socketConnection;
@property (nonatomic, copy) NSError *alternateDisconnectError;
@end

NS_ASSUME_NONNULL_END
