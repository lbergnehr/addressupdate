
#import "AddressUpdateSiteImporter.h"
#import "SiteInformationMO.h"
#import "XPathMO.h"


@implementation AddressUpdateSiteImporter
@synthesize managedObjectContext, mainWindow;

- (id)initWithManagedObjectContext:(NSManagedObjectContext *)context
{
  self = [super init];
  if (self) {
    self.managedObjectContext = context;
  }
  
  return self;
}

- (void)importSiteFromFile:(NSString *)filePath presentError:(BOOL)presentError;
{
  NSError *error = nil;
  NSEntityDescription *entity = [NSEntityDescription entityForName:@"SiteInformation" inManagedObjectContext:managedObjectContext];
  SiteInformationMO *site = [[[SiteInformationMO alloc] initWithEntity:entity insertIntoManagedObjectContext:managedObjectContext] autorelease];
  [site loadSiteFromFile:filePath error:&error];
  
  if (error) {
    [managedObjectContext deleteObject:site];
    if (presentError) {
      [NSApp presentError:error modalForWindow:mainWindow delegate:nil didPresentSelector:nil contextInfo:nil];
    } else {
      NSLog(@"Error when loadin site: %@", error);
    }
  } else {
    error = nil;
    [managedObjectContext save:&error];
    if (error) {
      if (presentError) {
        [NSApp presentError:error modalForWindow:mainWindow delegate:nil didPresentSelector:nil contextInfo:nil];
      } else {
        NSLog(@"Error when saving managed object context: %@.", error);
      }

    }
  }

}

- (void)importSitesFromFiles:(NSArray *)filePaths presentError:(BOOL)presentError
{
  for (NSString *filePath in filePaths) {
    @try {
      [self importSiteFromFile:filePath presentError:presentError];
    } @catch (NSException *ex) {
      NSLog(@"Could not import site due to: %@", ex);
    }
  }
}

@end
