
#import <Cocoa/Cocoa.h>


@interface AppController : NSObject {

  NSDictionary *siteConfiguration;
  NSArray *xpathResults;
  NSString *phoneNumber;
  NSString *currentDirectory;
  BOOL isSearching;
  
}

@property (retain, readwrite, nonatomic) NSDictionary *siteConfiguration;
@property (retain, readwrite, nonatomic) NSArray *xpathResults;
@property (retain, readwrite, nonatomic) NSString *currentDirectory;
@property (assign, readwrite, nonatomic) BOOL isSearching;
@property (retain, readwrite, nonatomic) NSString *phoneNumber;

- (IBAction)loadSiteConfigurationClick:(NSButton *)sender;
- (IBAction)searchClick:(NSButton *)sender;
- (NSArray *)loadSiteConfiguration:(NSDictionary *)siteFromFile;
- (NSDictionary *)applyRegExpToData:(NSDictionary *)data fromPatterns:(NSDictionary *)patterns;

@end
