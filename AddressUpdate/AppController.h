
#import <Cocoa/Cocoa.h>
#import <AddressBook/AddressBook.h>
#import "AddressBookUpdater.h"
#import "UpdateWindowController.h"


@class StatusItemView;

@interface AppController : NSObject {

  IBOutlet NSTextField        *statusLabel;
  IBOutlet NSButton           *startStopButton;
  IBOutlet NSArrayController  *sites;
  IBOutlet NSDictionary       *stringEncodings;
  IBOutlet NSPopUpButton      *pullDownButton;
  IBOutlet NSArrayController  *usedXpaths;
  IBOutlet NSPopUpButton      *sitesDropDownButton;
  IBOutlet NSView             *statusImageView;
  
	NSWindowController					*mainWindowController;
	NSPanel											*mainWindow;
  UpdateWindowController      *updateWindowController;
  BOOL                        isUpdating;
  AddressBookUpdater          *addressBookUpdater;
  NSStatusItem                *statusBarItem;
  StatusItemView              *statusItemView;
  ABAddressBook               *addressBook;
  NSDictionary                *pathDefinitions;
  NSString                    *applicationPath;
  NSMenuItem                  *statusMenuItem;
  NSMenuItem                  *onOffMenuItem;
  NSArray                     *xPathsSortDescriptors;
  
}

@property (assign, readonly) BOOL isUpdating;
@property (retain) NSArray *xPathsSortDescriptors;

- (void)addressBookChanged:(NSNotification *)note;
- (NSStatusItem *)createStatusItem;
- (void)initStringEncodingsDropDown;
- (void)initXpathDefinitionsDropDown;
- (void)setIsActivated:(BOOL)flag;
- (void)application:(NSApplication *)sender openFiles:(NSArray *)filenames;

#pragma mark -
#pragma mark Actions

- (IBAction)quitClick:(id)sender;
- (IBAction)preferencesClick:(id)sender;
- (IBAction)doneClick:(id)sender;
- (IBAction)startStopClick:(id)sender;
- (IBAction)doneClick:(id)sender;
- (IBAction)pullDownMenuItemSelected:(id)sender;
- (IBAction)updateEntireAddressBookClick:(id)sender;
- (IBAction)startAtLoginClick:(id)sender;
- (IBAction)sitesDropDownChanged:(id)sender;
- (IBAction)loadSiteClick:(id)sender;
- (IBAction)removeSiteClick:(id)sender;
- (IBAction)reloadDefaultSitesClick:(id)sender;
- (IBAction)helpButtonClick:(id)sender;

@end

#pragma mark -
#pragma mark Private Methods

@interface AppController (PrivateMethods)

- (void)enableLoginItemWithLoginItemsReference:(LSSharedFileListRef)theLoginItemsRefs forPath:(CFURLRef)thePath;
- (void)disableLoginItemWithLoginItemsReference:(LSSharedFileListRef)theLoginItemsRefs forPath:(CFURLRef)thePath;
- (void)initUpdateStatusWithItemsToUpdate:(NSNumber *)count;
- (void)finnishedUpdatingRecords;
- (void)loadDefaultSiteConfigurations;
- (NSArray *)siteConfigurationFilesForCountryCode:(NSString *)code;
- (void)rememberCurrentlySelectedSite;

@end
