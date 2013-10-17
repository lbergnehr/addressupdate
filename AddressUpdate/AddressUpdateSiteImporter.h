
#import <Cocoa/Cocoa.h>


@interface AddressUpdateSiteImporter : NSObject {
  
  NSManagedObjectContext *managedObjectContext;
  NSWindow *mainWindow;
}

@property (retain, readwrite, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (assign, readwrite, nonatomic) NSWindow               *mainWindow;

- (id)initWithManagedObjectContext:(NSManagedObjectContext *)context;
- (void)importSiteFromFile:(NSString *)filePath presentError:(BOOL)presentError;
- (void)importSitesFromFiles:(NSArray *)filePaths presentError:(BOOL)presentError;

@end
