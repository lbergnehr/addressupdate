
#import <Cocoa/Cocoa.h>
#import "AUKSearchSiteInformation.h"


extern NSString *const kAUKFormFieldName;
extern NSString *const kAUKFormGetAction;

@interface AUKAddressretriever : NSObject {
  
  NSStringEncoding  stringDataEncoding;
  NSTimeInterval    connectionTimeout;
  
}

@property (assign, readwrite, nonatomic) NSStringEncoding stringDataEncoding;
@property (assign, readwrite, nonatomic) NSTimeInterval connectionTimeout;

- (NSString *)actionFromFormAtSiteUrl:(NSURL *)url;
- (NSDictionary *)addressDataFromSite:(AUKSearchSiteInformation *)site;

+ (id)retriever;

@end
