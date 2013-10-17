
#import <Cocoa/Cocoa.h>
#import <AddressBook/AddressBook.h>

enum {
  nothingFoundAtSite = 0,
  informationAlreadyUpToDate = 1,
  informationUpdated = 2,
  updateAborted = 3
};
typedef NSUInteger UpdateReturnValue;

@interface RecordUpdater : NSOperation {

  ABPerson        *theRecord;
  NSManagedObject *theEntity;
  id              delegate;
  BOOL            isCancelled;
  BOOL            isFinnished;
  
  BOOL shouldUpdateAddresses;
  BOOL shouldUpdateOtherPhoneNumbers;
  BOOL shouldUpdateCountryInAddress;
  BOOL shouldUpdateNames;
  
}

@property (retain, readwrite, nonatomic) ABPerson *theRecord;
@property (retain, readwrite, nonatomic) NSManagedObject *theEntity;
@property (assign, readwrite, nonatomic) id delegate;

@property (assign, readwrite, nonatomic) BOOL shouldUpdateAddresses;
@property (assign, readwrite, nonatomic) BOOL shouldUpdateOtherPhoneNumbers;
@property (assign, readwrite, nonatomic) BOOL shouldUpdateCountryInAddress;
@property (assign, readwrite, nonatomic) BOOL shouldUpdateNames;

@end

@interface NSObject (RecordUpdaterInformalProtocol)

- (void)updater:(RecordUpdater *)updater willBeginUpdatingRecord:(ABPerson *)record;
- (void)updater:(RecordUpdater *)updater didFinnishUpdatingRecord:(ABPerson *)record withChanges:(UpdateReturnValue)returnValue;
- (void)updater:(RecordUpdater *)updater didFailWithError:(NSError *)error forRecord:(ABPerson *)record;

@end
