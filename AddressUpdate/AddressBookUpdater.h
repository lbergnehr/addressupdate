
#import <Cocoa/Cocoa.h>
#import <AddressBook/AddressBook.h>


@interface AddressBookUpdater : NSObject {
  
  NSOperationQueue  *updateQueue;
  NSArray           *allRecords;
  NSMutableArray    *updatedRecords;
  NSManagedObject   *site;
  id                delegate;
  NSUInteger        count;
  BOOL              isUpdating;
  
  BOOL shouldUpdateAddresses;
  BOOL shouldUpdateOtherPhoneNumbers;
  BOOL shouldUpdateCountryInAddress;
  BOOL shouldUpdateNames;
  BOOL useConcurrentLookups;
  
}

@property (assign, readwrite) id delegate;
@property (retain, readwrite) NSArray *allRecords;
@property (retain, readwrite) NSManagedObject *site;
@property (assign, readonly) NSUInteger count;

@property (assign, readwrite, nonatomic) BOOL shouldUpdateAddresses;
@property (assign, readwrite, nonatomic) BOOL shouldUpdateOtherPhoneNumbers;
@property (assign, readwrite, nonatomic) BOOL shouldUpdateCountryInAddress;
@property (assign, readwrite, nonatomic) BOOL shouldUpdateNames;
@property (assign, readwrite, nonatomic) BOOL useConcurrentLookups;

- (void)updateRecords:(NSArray *)records usingSite:(NSManagedObject *)entity;
- (void)updateAllRecordsWithSite:(NSManagedObject *)theSite;
- (void)stopUpdatingRecords;

+ (id)updater;

@end

@interface NSObject (AddresUpdaterInformalProtocol)

- (void)updaterWillUpdateRecords:(NSArray *)recordIDs usingSite:(NSManagedObject *)site;
- (void)updaterDidFinnishProcessingRecord:(NSString *)recordID;
- (void)updaterDidFinnishUpdatingRecords:(NSArray *)recordIDs usingSite:(NSManagedObject *)site;

@end
