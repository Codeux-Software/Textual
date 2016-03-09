
typedef const struct OpaqueWKPage *WKPageRef;

typedef const struct OpaqueWKInspector *WKInspectorRef;

WKInspectorRef WKPageGetInspector(WKPageRef page);

void WKInspectorShow(WKInspectorRef inspectorRef);

@interface WKView : NSView
- (WKPageRef)pageRef;
@end

@interface _WKProcessPoolConfiguration : NSObject <NSCopying>
@property (nonatomic) NSUInteger maximumProcessCount;
@end

@interface WKProcessPool ()
- (instancetype)_initWithConfiguration:(_WKProcessPoolConfiguration *)configuration;

- (_WKProcessPoolConfiguration *)_configuration;
@end

@interface NSView (WKViewSwizzle)
@end
