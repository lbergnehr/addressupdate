
#import <Cocoa/Cocoa.h>

typedef enum tagAUKSearchType {
  AUKHttpGetSearchType = 0,
  AUKHttpPostSearchType = 1
} AUKSearchType;

@interface AUKSearchSiteInformation : NSObject {

  NSURL *url;
  AUKSearchType searchType;
  NSDictionary *xPaths;
  NSDictionary *searchKeyValuePairs;
  
}

@property (retain, readwrite, nonatomic) NSURL *url;
@property (assign, readwrite, nonatomic) AUKSearchType searchType;
@property (retain, readwrite, nonatomic) NSDictionary *xPaths;
@property (retain, readwrite, nonatomic) NSDictionary *searchKeyValuePairs;

+ (id)searchSite;

@end
