
#import "AddressBookUpdater.h"
#import <AddressUpdateKit/AddressUpdateKit.h>
#import "RecordUpdater.h"
#import <libkern/OSAtomic.h>
#import "UserDefaultsKeys.h"


@interface AddressBookUpdater ()
@property (assign, readwrite) NSUInteger count;
@end

@implementation AddressBookUpdater

@synthesize delegate, allRecords, site, count, shouldUpdateNames, shouldUpdateOtherPhoneNumbers, shouldUpdateAddresses, shouldUpdateCountryInAddress, useConcurrentLookups;

#pragma mark -
#pragma mark init/dealloc

- (id)init
{
  self = [super init];
  if (self) {
    updateQueue = nil;
    allRecords = nil;
    site = nil;
    count = 0;
    updatedRecords = nil;
  }
  return self;
}

+ (id)updater
{
  AddressBookUpdater *updater = [[AddressBookUpdater alloc] init];
  return [updater autorelease];
}

- (void)dealloc
{
  [updateQueue release];
  [allRecords release];
  [site release];
  [updatedRecords release];
  [super dealloc];
}

#pragma mark -
#pragma mark Updating Methods

- (void)updateAllRecordsWithSite:(NSManagedObject *)theSite
{
  NSArray *people = [[ABAddressBook sharedAddressBook] people];
  NSArray *ids = [people valueForKey:@"uniqueId"];
  [self updateRecords:ids usingSite:theSite];
}

- (void)updateRecords:(NSArray *)records usingSite:(NSManagedObject *)entity
{
  [updatedRecords release];
  updatedRecords = [[NSMutableArray alloc] initWithCapacity:[records count]];
  
  self.count = [records count] - 1;
  self.allRecords = records;
  self.site = entity;
  
  if ([delegate respondsToSelector:@selector(updaterWillUpdateRecords:usingSite:)]) {
    [delegate updaterWillUpdateRecords:records usingSite:entity];
  }
  
  // If the record is nil or empty or the entity is nil.
  if (!records || [records count] == 0 || !entity) {
    NSLog(@"Nothing to update or no site specified.");
    if ([delegate respondsToSelector:@selector(updaterDidFinnishUpdatingRecords:usingSite:)]) {
      [delegate updaterDidFinnishUpdatingRecords:[NSArray array] usingSite:entity];
    }
    
    return;
  }
  
  // Create the update queue if needed.
  if (!updateQueue) {
    updateQueue = [[NSOperationQueue alloc] init];
    if (useConcurrentLookups) {
      [updateQueue setMaxConcurrentOperationCount:NSOperationQueueDefaultMaxConcurrentOperationCount];
    } else {
      [updateQueue setMaxConcurrentOperationCount:1];
    }

  }
  
  // For every record.
  for (NSString *recordId in records) {
    ABRecord *record = [[ABAddressBook sharedAddressBook] recordForUniqueId:recordId];
    
    // Check if it's a person record and not a group record.
    if (![record isKindOfClass:[ABPerson class]]) {
      continue;
    }
    
    // Update the address in the record.
    RecordUpdater *updater = [[RecordUpdater alloc] init];
    updater.theEntity = entity;
    updater.theRecord = (ABPerson *)record;
    updater.delegate = self;
    
    updater.shouldUpdateAddresses = shouldUpdateAddresses;
    updater.shouldUpdateNames = shouldUpdateNames;
    updater.shouldUpdateOtherPhoneNumbers = shouldUpdateOtherPhoneNumbers;
    updater.shouldUpdateCountryInAddress = shouldUpdateCountryInAddress;
    
    // Add the operation.
    [updateQueue addOperation:[updater autorelease]];
  }
}

- (void)checkIfDone
{
  // If we are done.
  if (count == 0) {
    // All updating done, save the address book.
    BOOL isSuccess = [[ABAddressBook sharedAddressBook] save];
    if (!isSuccess) {
      NSLog(@"Could not save the address book");
    }
    
    if ([delegate respondsToSelector:@selector(updaterDidFinnishUpdatingRecords:usingSite:)]) {
      [delegate updaterDidFinnishUpdatingRecords:[[updatedRecords copy] autorelease] usingSite:site];
    }
  } else {
    // Decrease the number of records that are updating.
		int tmp = (int)count;
    OSAtomicDecrement32Barrier(&tmp);
  }
}

- (void)stopUpdatingRecords
{
  [updateQueue cancelAllOperations];
}

#pragma mark -
#pragma mark Delegate Methods

- (void)updater:(RecordUpdater *)updater willBeginUpdatingRecord:(ABPerson *)record
{
}

- (void)updater:(RecordUpdater *)updater didFinnishUpdatingRecord:(ABPerson *)record withChanges:(UpdateReturnValue)returnValue
{ 
  switch (returnValue) {
    case informationUpdated:
      [updatedRecords addObject:record];
      break;
    default:
      break;
  }
  
  if ([delegate respondsToSelector:@selector(updaterDidFinnishProcessingRecord:)]) {
    [delegate updaterDidFinnishProcessingRecord:[record uniqueId]];
  }
  
  [self checkIfDone];
}

- (void)updater:(RecordUpdater *)updater didFailWithError:(NSError *)error forRecord:(ABPerson *)record;
{
  NSLog(@"Updating failed with error %@", error);
  [self updater:updater didFinnishUpdatingRecord:record withChanges:NO];
}

@end