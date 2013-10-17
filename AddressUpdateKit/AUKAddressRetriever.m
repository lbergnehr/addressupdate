
#import "AUKAddressretriever.h"
#import "UrlConnector.h"


NSString *const kAUKFormFieldName = @"kAUKFormFieldName";
NSString *const kAUKFormGetAction = @"kAUKFormGetAction";


#pragma mark -
#pragma mark Private Interface

@interface AUKAddressretriever ()

- (NSString *)_httpGetAddressFromBaseUrl:(NSString *)baseUrl
                           keyValuePairs:(NSDictionary *)keysAndValues;
- (NSDictionary *)_addressDataUsingGetFromAddress:(NSString *)address xPaths:(NSDictionary *)xPaths;
- (NSDictionary *)_addressDataUsingPostFromAddress:(NSString *)address withPostData:(NSDictionary *)keysAndValues xPaths:(NSDictionary *)xPaths;
- (NSDictionary *)_addressDataFromXmlData:(NSXMLDocument *)doc usingXpaths:(NSDictionary *)xPaths;

@end

#pragma mark -
#pragma mark Implementation

@implementation AUKAddressretriever

@synthesize stringDataEncoding, connectionTimeout;

/* Finds the action used in a form at the given URL. */
- (NSString *)actionFromFormAtSiteUrl:(NSURL *)url
{
  UrlConnector *connector = [UrlConnector connector];
  connector.stringDataEncoding = stringDataEncoding;
  connector.timeoutInterval    = connectionTimeout;
  NSXMLDocument *doc = [connector xmlDataFromUrl:url];
  
  NSString *formNodeXpath = @"//form[@method='get']";
  NSError *error;
  
  NSArray *formNodes = [doc nodesForXPath:formNodeXpath error:&error];
  if ([formNodes count] == 1) {
    NSXMLNode *node = [formNodes objectAtIndex:0];
    NSArray *array = [node nodesForXPath:@"@action" error:&error];
    if (array && [array count] == 1) {
      NSString *action = [[array objectAtIndex:0] stringValue];
      return action;
    } else {
      return nil;
    }
  } else {
    return nil;
  }

}

/* Gets data from the given site definition. */
- (NSDictionary *)addressDataFromSite:(AUKSearchSiteInformation *)site
{ 
  // Initial checking.
  if (!site.url || !site.searchKeyValuePairs || !site.xPaths) {
    [NSException raise:@"NilException" format:@"Site url, search value key pairs or xPaths is nil."];
  }
  
  // Get the base url and check that it ends with a '?'.
  NSString *baseUrl = [[site url] absoluteString];
  if (![baseUrl hasSuffix:@"?"]) {
    baseUrl = [baseUrl stringByAppendingString:@"?"];
  }
  
  NSString *fullUrl = nil;
  NSDictionary *addressData = nil;
  
  switch (site.searchType) {
    case AUKHttpGetSearchType:
      fullUrl = [self _httpGetAddressFromBaseUrl:baseUrl keyValuePairs:site.searchKeyValuePairs];
      addressData = [self _addressDataUsingGetFromAddress:fullUrl xPaths:site.xPaths];
      break;
    case AUKHttpPostSearchType:
      addressData = [self _addressDataUsingPostFromAddress:baseUrl withPostData:site.searchKeyValuePairs xPaths:site.xPaths];
      break;
    default:
      [NSException raise:@"" format:@"AUKSearchType not supported: %d.", site.searchType];
  }
  
  return addressData;
}

/* Constructs a URL that can be used in a get request from the baseUrl and the get parameters defined in a dictionary. */
- (NSString *)_httpGetAddressFromBaseUrl:(NSString *)baseUrl
                          keyValuePairs:(NSDictionary *)keysAndValues
{
  NSMutableString *fullUrl = [baseUrl mutableCopy];
  for (NSString *key in [keysAndValues allKeys]) {
    NSString *value = [keysAndValues valueForKey:key];
    [fullUrl appendFormat:@"%@=%@&", key, value];
  }
  
  // Remove the trailing ampersand.
  [fullUrl deleteCharactersInRange:NSMakeRange([fullUrl length] - 1, 1)];
  
  return [fullUrl autorelease];
}

- (NSDictionary *)_addressDataUsingGetFromAddress:(NSString *)address
                                          xPaths:(NSDictionary *)xPaths
{
  UrlConnector *con = [UrlConnector connector];
  con.stringDataEncoding  = stringDataEncoding;
  con.timeoutInterval     = connectionTimeout;
  NSXMLDocument *doc = [con xmlDataFromUrl:[NSURL URLWithString:address]];
  NSDictionary *addressData = [self _addressDataFromXmlData:doc usingXpaths:xPaths];
  return addressData;
}

- (NSDictionary *)_addressDataUsingPostFromAddress:(NSString *)address
                                     withPostData:(NSDictionary *)keysAndValues
                                           xPaths:(NSDictionary *)xPaths
{
  [NSException raise:@"NotImplementedException" format:@"Post is not yet supported. Use get instead"];
  return nil;
}

/* Fills a dictionar with data defined in the xPaths dictionary from the given XML-document. */
- (NSDictionary *)_addressDataFromXmlData:(NSXMLDocument *)doc usingXpaths:(NSDictionary *)xPaths
{ 
  if (!doc) {
    return nil;
  }
 
	NSMutableDictionary *addressData = [[NSMutableDictionary alloc] initWithCapacity:5];
	
  // For every XPath.
  for (NSString *pathKey in [xPaths allKeys]) {
    // The key is the name of the property in the address dictionary and the value is the path.
    // Get the array for that path.
    id pathValue = [xPaths valueForKey:pathKey];
    
    // If it's not a string attribute.
    if (![pathValue isKindOfClass:[NSString class]]) { continue; }
    pathValue = (NSString *)pathValue;
    
    NSError *error;
    NSArray *nodes = [doc nodesForXPath:pathValue error:&error];
    if (!nodes) {
      NSLog(@"Error when getting element for xpath %@: %@", pathValue, error);
    } else {
      // If the array only contains one element.
      if ([nodes count] == 1) {
        NSString *elementData = [[nodes objectAtIndex:0] stringValue];
        elementData = [elementData stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        
        // If the string is not empty or any whitespace character.
        if ([elementData length] != 0) {
          // Add the key for the path and the found element text to the address data.
          [addressData setValue:elementData forKey:pathKey];
        }
      } else if ([nodes count] != 0) {
        NSLog(@"Result from XPath search resulted in more than one match. Resulting nodes: %@", nodes);
      }
    }
  }
  
  // If nothing could be generated.
  if ([addressData count] == 0) {
    [addressData release];
    return nil;
  } else {
    return [addressData autorelease];
  }

}

+ (id)retriever
{
  AUKAddressretriever *ar = [[AUKAddressretriever alloc] init];
  return [ar autorelease];
}

@end