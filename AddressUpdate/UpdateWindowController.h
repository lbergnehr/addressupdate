
#import <Cocoa/Cocoa.h>
#import "AddressBookUpdater.h"
#import "StatusItemView.h"

extern NSString * const kUpdateInformationProcessedRecords;
extern NSString * const kUpdateInformationUpdatedRecords;

@class CIFilter;
@interface UpdateWindowController : NSWindowController {

  id delegate;
  
  IBOutlet NSProgressIndicator  *progressBar;
  IBOutlet NSImageView          *addressBookImages;
  IBOutlet NSView               *imageViewWrapper;
  
  AddressBookUpdater            *updater;
  NSManagedObject               *site;
  NSWindow                      *dockWindow;
  StatusItemView                *statusView;
  
  NSString                      *personNameBeingUpdated;
  NSArray                       *filters;
  
  NSDictionary                  *updateInfomation;
  NSMutableDictionary           *internalUpdateInformation;
}

@property (retain, readwrite, nonatomic) AddressBookUpdater *updater;
@property (retain, readwrite, nonatomic) NSManagedObject *site;
@property (retain, readwrite, nonatomic) NSWindow *dockWindow;
@property (retain, readwrite, nonatomic) StatusItemView *statusView;
@property (retain, readwrite, nonatomic) NSString *personNameBeingUpdated;
@property (assign, readwrite, nonatomic) id delegate;
@property (retain, readwrite, nonatomic) NSArray *filters;
@property (retain, readonly, nonatomic) NSDictionary *updateInfomation;

- (void)updateAllRecordsWithSite:(NSManagedObject *)theSite statusView:(StatusItemView *)view;
- (IBAction)stopButtonClick:(id)sender;
- (NSArray *)filtersForImageView;

@end

@interface NSObject (UpdateWindowControllerInformalProtocol)

- (void)didFinnishUpdatingAllRecords:(UpdateWindowController *)controller;
- (void)didStopBeforeUpdatingAllRecords:(UpdateWindowController *)controller;

@end
