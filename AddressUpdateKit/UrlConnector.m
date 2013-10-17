
#import "UrlConnector.h"


@implementation UrlConnector

@synthesize timeoutInterval, stringDataEncoding;

- (id)init
{
  self = [super init];
  if (self) {
    receivedData = nil;
    timeoutInterval = 30;
    stringDataEncoding = NSUTF8StringEncoding;
  }
  return self;
}

+ (id)connector
{
  UrlConnector *connector = [[UrlConnector alloc] init];
  return [connector autorelease];
}

- (NSString *)stringDataFromUrl:(NSURL *)url
{
  NSData *data = [self dataFromUrl:url];
  NSString *stringData = [[NSString alloc] initWithData:data encoding:stringDataEncoding];
  return [stringData autorelease];
}

- (NSXMLDocument *)xmlDataFromUrl:(NSURL *)url
{
  NSString *stringData = [self stringDataFromUrl:url];
  if (!stringData) {
    return nil;
  }
  
  NSError *error;
  NSXMLDocument *xmlDocument = [[NSXMLDocument alloc] initWithXMLString:stringData options:NSXMLDocumentTidyHTML error:&error];
  
  if (!xmlDocument) {
    NSLog(@"Error when creating XML document. Error: %@", error);
  }
  
  return [xmlDocument autorelease];
}

- (NSData *)dataFromUrl:(NSURL*)url
{
  // If the url doesn't have the http prefix, add it.
  NSString *prefix = @"http://";
  NSString *urlString = [url absoluteString];
  if (![urlString hasPrefix:prefix]) {
    NSString *newUrl = [prefix stringByAppendingString:urlString];
    url = [NSURL URLWithString:newUrl];
  }
  
  NSURLRequest* request = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:timeoutInterval];
  NSURLConnection* connection = [NSURLConnection connectionWithRequest:request delegate:self];
  [connection start];
  
  // Wait until we've loaded all data (this is set in connectionDidFinishLoading: or connection:DidFailWithError:).
  while (!finnishedLoading) {
    [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
  }
  finnishedLoading = NO;
  
  return [receivedData autorelease];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
  [receivedData release];
  
  receivedData = [[NSMutableData alloc] init];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
  [receivedData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
  finnishedLoading = YES;
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
  NSLog(@"Connection failed with error: %@", [error localizedDescription]);
  finnishedLoading = YES;
}

@end
