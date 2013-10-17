
#import <Cocoa/Cocoa.h>


@interface UrlConnector : NSObject {
  
  NSMutableData*    receivedData;
  BOOL              finnishedLoading;
  
  NSTimeInterval    timeoutInterval;
  NSStringEncoding  stringDataEncoding;
}

@property (assign, readwrite, nonatomic) NSTimeInterval timeoutInterval;
@property (assign, readwrite, nonatomic) NSStringEncoding stringDataEncoding;

- (NSData *)dataFromUrl:(NSURL *)url;
- (NSString*)stringDataFromUrl:(NSURL *)url;
- (NSXMLDocument *)xmlDataFromUrl:(NSURL *)url;

+ (id)connector;

@end
