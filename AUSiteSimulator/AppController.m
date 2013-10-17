
#import "AppController.h"
#import "XPathMO.h"
#import "SiteInformationMO.h"
#import <AddressUpdateKit/AddressUpdateKit.h>
#import "objpcre.h"


@implementation AppController
@synthesize siteConfiguration, xpathResults, currentDirectory, isSearching, phoneNumber;

- (IBAction)loadSiteConfigurationClick:(NSButton *)sender
{
  NSOpenPanel *panel = [NSOpenPanel openPanel];
  [panel setCanChooseFiles:YES];
  [panel setCanChooseDirectories:NO];
  [panel setCanCreateDirectories:NO];
  [panel setAllowsMultipleSelection:NO];
  NSArray *types = [NSArray arrayWithObjects:@"ausite", @"plist", @"xml", nil];
  
  [panel runModalForDirectory:currentDirectory ?: NSHomeDirectory() file:nil types:types];
  
  NSString *file = [panel filename];
  
  self.siteConfiguration = [NSDictionary dictionaryWithContentsOfFile:file];
  self.xpathResults = [self loadSiteConfiguration:siteConfiguration];
  self.currentDirectory = [file stringByDeletingLastPathComponent];
}

- (NSArray *)loadSiteConfiguration:(NSDictionary *)siteFromFile
{
  NSMutableArray *items = [NSMutableArray arrayWithCapacity:7];
  for (NSDictionary *xpath in [siteConfiguration valueForKey:kSiteXpathsRelationship]) {
    NSString *name = [xpath valueForKey:kXPathNameAttribute];
    NSString *path = [xpath valueForKey:kXPathPathAttribute];
    NSString *regexp = [xpath valueForKey:kXPathRegExpAttribute];
    NSMutableDictionary *item = [NSMutableDictionary dictionaryWithCapacity:4];
    [item setValue:name forKey:@"name"];
    [item setValue:path forKey:@"path"];
    [item setValue:regexp forKey:@"regExp"];
    [items addObject:item];
  }
  
  return [NSArray arrayWithArray:items];
}

- (IBAction)searchClick:(NSButton *)sender
{
  self.isSearching = YES;
  
  if (phoneNumber) {
    self.phoneNumber = [phoneNumber stringByReplacingOccurrencesOfString:@" " withString:@""];
  }
  
  @try {
    if (!siteConfiguration) {
      [NSAlert alertWithMessageText:@"Load a site configuration before initiating a search." defaultButton:nil alternateButton:nil otherButton:nil informativeTextWithFormat:nil];
      return;
    }
    
    NSString *urlString = [siteConfiguration valueForKey:kSiteURLAttribute];
    NSStringEncoding encoding = (NSStringEncoding)[[siteConfiguration valueForKey:kSiteStringEncodingAttribute] integerValue];
    NSString *searchAttribute = [siteConfiguration valueForKey:kSiteSearchAttributeAttribute];
    
    NSURL *url = [NSURL URLWithString:urlString];
    
    AUKSearchSiteInformation *site = [AUKSearchSiteInformation searchSite];
    site.url = url;
    site.searchKeyValuePairs = [NSDictionary dictionaryWithObject:phoneNumber forKey:searchAttribute];
    site.xPaths = [NSDictionary dictionaryWithObjects:[xpathResults valueForKey:@"path"] forKeys:[xpathResults valueForKey:@"name"]];
    site.searchType = AUKHttpGetSearchType;
    
    AUKAddressretriever *retriever = [AUKAddressretriever retriever];
    retriever.stringDataEncoding = encoding;
    retriever.connectionTimeout = 10.0;
    
    // Get the data.
    NSDictionary *addressData = [retriever addressDataFromSite:site];
    
    if (addressData) {
      
      NSArray *names = [siteConfiguration valueForKeyPath:@"xpaths.name"];
      NSArray *patterns = [siteConfiguration valueForKeyPath:@"xpaths.regExp"];
      NSDictionary *namesAndPatterns = [NSDictionary dictionaryWithObjects:patterns forKeys:names];
      addressData = [self applyRegExpToData:addressData fromPatterns:namesAndPatterns];
      
      NSMutableArray *items = [NSMutableArray arrayWithCapacity:[addressData count]];
      xpathResults = [[self loadSiteConfiguration:siteConfiguration] retain];
      for (NSDictionary *row in xpathResults) {
        NSString *name = [row valueForKey:@"name"];
        // If the value exist in our fetched data.
        NSString *result = nil;
        if ((result = [addressData valueForKey:name]) != nil) {
          NSString *path = [row valueForKey:@"path"];
          // Set the value in the 'result' property of the row dictionary.
          NSDictionary *newRow = [NSDictionary dictionaryWithObjectsAndKeys:name, @"name", path, @"path", result, @"result", nil];
          [items addObject:newRow];
        } else {
          result = @"Nothing found";
          NSString *path = [row valueForKey:@"path"];
          NSString *regExp = [row valueForKey:@"regExp"];
          NSDictionary *newRow = [NSDictionary dictionaryWithObjectsAndKeys:name, @"name", path, @"path", result, @"result", regExp, @"regExp", nil];
          [items addObject:newRow];
        }
      }
      
      // Set the new xpathResults array.
      self.xpathResults = [NSArray arrayWithArray:items];
    } else {
      NSLog(@"Could not find any data.");
      self.xpathResults = [self loadSiteConfiguration:siteConfiguration];
      NSMutableArray *results = [xpathResults mutableCopy];
      [results setValue:@"Nothing found" forKey:@"result"];
      self.xpathResults = [NSArray arrayWithArray:results];
    }
  }
  @finally {
    self.isSearching = NO;
  }
}

- (NSDictionary *)applyRegExpToData:(NSDictionary *)data fromPatterns:(NSDictionary *)patterns
{
  NSMutableDictionary *result = [NSMutableDictionary dictionaryWithDictionary:data];
  
  // For each data found.
  for (NSString *name in patterns) {
    NSString *pattern = [patterns valueForKey:name];
    if (!pattern || [pattern isKindOfClass:[NSNull class]] || [pattern length] == 0) {
      continue;
    }
    
    NSString *value = [data valueForKey:name];
    
    ObjPCRE *regexp = [ObjPCRE regexWithPattern:pattern];
    BOOL didMatch = [regexp regexMatches:value options:0 startOffset:0];
    if (didMatch) {
      NSString *modifiedString = [regexp match:value];
      [result setObject:modifiedString forKey:name];
    } else {
      [result setObject:@"" forKey:name];
    }
  }
  
  return [NSDictionary dictionaryWithDictionary:result];
}

@end
