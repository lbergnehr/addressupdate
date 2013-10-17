
#import <Cocoa/Cocoa.h>

@class AppController;

@interface AddressUpdate_AppDelegate : NSObject 
{
  IBOutlet NSWindow       *window;
  IBOutlet AppController  *appController;
  
  NSPersistentStoreCoordinator *persistentStoreCoordinator;
  NSManagedObjectModel *managedObjectModel;
  NSManagedObjectContext *managedObjectContext;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator;
- (NSManagedObjectModel *)managedObjectModel;
- (NSManagedObjectContext *)managedObjectContext;

- (IBAction)saveAction:sender;

@end
