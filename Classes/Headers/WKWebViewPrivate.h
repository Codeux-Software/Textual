
typedef NS_OPTIONS(NSUInteger, _WKFindOptions) {
	_WKFindOptionsCaseInsensitive					= 1 << 0,
	_WKFindOptionsAtWordStarts						= 1 << 1,
	_WKFindOptionsTreatMedialCapitalAsWordStart		= 1 << 2,
	_WKFindOptionsBackwards							= 1 << 3,
	_WKFindOptionsWrapAround						= 1 << 4,
	_WKFindOptionsShowOverlay						= 1 << 5,
	_WKFindOptionsShowFindIndicator					= 1 << 6,
	_WKFindOptionsShowHighlight						= 1 << 7,
	_WKFindOptionsDetermineMatchIndex				= 1 << 8
};

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
