
#import "AUKSearchSiteInformation.h"


@implementation AUKSearchSiteInformation

@synthesize url, searchType, xPaths, searchKeyValuePairs;

- (id)init
{
  self = [super init];
  if (self) {
    // Placeholder.
  }
  return self;
}

- (void)dealloc
{
  [xPaths release];
  [searchKeyValuePairs release];
  [super dealloc];
}

+ (id)searchSite
{
  AUKSearchSiteInformation *site = [[AUKSearchSiteInformation alloc] init];
  return [site autorelease];
}

@end
