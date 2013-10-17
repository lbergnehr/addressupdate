
#import "AppController.h"
#import "NSImage-Extras.h"
#import <QuartzCore/CoreAnimation.h>
#import "StatusItemView.h"
#import "SiteInformationMO.h"
#import "XPathMO.h"
#import "AddressUpdateSiteImporter.h"
#import "XPathsSortDescriptor.h"
#import "UserDefaultsKeys.h"

static NSString * homePageUrl = @"http://addressupdate.bergnehr.se/sites.html";

static NSString * removeSiteAlertContext = @"removeSiteAlertContext";
static NSString * updateEntireAddressBookAlertContext = @"updateEntireAddressBookAlertContext";
static NSString * noSitesFoundAlertContext = @"noSitesFoundAlertContext";
static NSString * reloadDefaultSitesAlertContext = @"reloadDefaultSitesAlertContext";

static NSString * selectedObjectsObservingContext = @"selectedObjectsObservingContext";
static NSString * arrangedObjectsObservingContext = @"arrangedObjectsObservingContext";

@interface AppController ()
@property (readwrite) BOOL isUpdating;
@end

@implementation AppController

@synthesize isUpdating, xPathsSortDescriptors;

#pragma mark -
#pragma mark init/deallc

+ (void)initialize
{
  // Register the standard defaults.
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  NSString *appDefaultsPath = [[[NSBundle mainBundle] resourcePath]
                               stringByAppendingPathComponent:@"AppDefaults.plist"];
  NSDictionary *appDefaults = [NSDictionary dictionaryWithContentsOfFile:appDefaultsPath];
  [defaults registerDefaults:appDefaults];
}

- (void)awakeFromNib
{
  // Load the sort descriptors for the used XPaths.
  XPathsSortDescriptor *categoryDescriptor = [[[XPathsSortDescriptor alloc] initWithKey:kXPathNameAttribute ascending:YES] autorelease];
  self.xPathsSortDescriptors = [NSArray arrayWithObject:categoryDescriptor];
  
  // Init the address book updater.
  addressBookUpdater = nil;
  
  // Set the application path.
  applicationPath = [[NSBundle mainBundle] bundlePath];
  
  // Get the status bar item.
  statusBarItem = [self createStatusItem];
  
  // Invoke the sharedAddress book method in order for notifications to be sent.
  addressBook = [ABAddressBook sharedAddressBook];
  
  // Set the correct status from last time the application was used.
  NSNumber *isActiveNumber = [[NSUserDefaults standardUserDefaults] valueForKey:kUserDefaultsIsActive];
  BOOL isActive = [isActiveNumber boolValue];
  [self setIsActivated:isActive];
  
  // Fill the drop down of string encodings.
  [self initStringEncodingsDropDown];
  
  // Fill the drop down of possible XPath definitions to use.
  [self initXpathDefinitionsDropDown];
  
  // Start observing the XPaths array controller in order to change the drop down when appropriate.
  [usedXpaths addObserver:self forKeyPath:@"arrangedObjects" options:0 context:nil];
  // Observe the sites array controller since it hasn't been loaded yet.
  [sites addObserver:self forKeyPath:@"arrangedObjects" options:0 context:arrangedObjectsObservingContext];
  // Add an observer for the selected objects.
  [sites addObserver:self forKeyPath:@"selectedObjects" options:0 context:selectedObjectsObservingContext];
  
  // If this is the first launch of the application.
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  BOOL isFirstTimeLaunch = [[defaults valueForKey:kUserDefaultsIsFirstTimeLaunch] boolValue];
  if (isFirstTimeLaunch) {
    [self loadDefaultSiteConfigurations];
    [defaults setValue:[NSNumber numberWithBool:NO] forKey:kUserDefaultsIsFirstTimeLaunch];
  }
}

- (void)dealloc
{
  [addressBookUpdater release];
  [statusBarItem release];
  [statusItemView release];
  [pathDefinitions release];
  
  [sites removeObserver:self forKeyPath:@"selectedObjects"];
  
  [super dealloc];
}

- (NSStatusItem *)createStatusItem
{
  // Get the item.
  NSStatusItem *item = [[[NSStatusBar systemStatusBar] statusItemWithLength:-1] retain];
  
  // Create the context menu for the item.
  NSZone *zone = [NSMenu menuZone];
  NSMenu *menu = [[[NSMenu allocWithZone:zone] init] autorelease];
  
  // Create a status menu item.
  statusMenuItem = [menu addItemWithTitle:@"" action:nil keyEquivalent:@""];
  [statusMenuItem setEnabled:NO];
  
  // Create a switch in order to turn on/off
  onOffMenuItem = [menu addItemWithTitle:@"" action:@selector(startStopClick:) keyEquivalent:@""];
  [onOffMenuItem setTarget:self];
  
  // Add a separator item.
  [menu addItem:[NSMenuItem separatorItem]];
  
  // Add the preferences item.
  NSMenuItem *preferencesItem = [menu addItemWithTitle:NSLocalizedString(@"Preferences...", @"Preferences menu item")
                                                action:@selector(preferencesClick:)
                                         keyEquivalent:@""];
  [preferencesItem setTarget:self];
  
  // Add a separator item.
  [menu addItem:[NSMenuItem separatorItem]];
  
  // Add the quit menu item.
  NSMenuItem *quitItem = [menu addItemWithTitle:NSLocalizedString(@"Quit", @"Quit menu item.")
                                         action:@selector(quitClick:)
                                  keyEquivalent:@""];
  [quitItem setTarget:self];
  
  // Set the menu.
  [item setMenu:menu];
  
  // Add the custom view.
  statusItemView = [[StatusItemView alloc] initWithFrame:NSMakeRect(0, 0, 30, 20)];
  statusItemView.statusItem = item;
  [statusItemView setMenu:menu];
  
  [item setView:statusItemView];
  
  return item;
}

- (void)initStringEncodingsDropDown
{
  NSMutableDictionary *stringEncodingsTmp = [NSMutableDictionary dictionaryWithCapacity:17];
  const NSStringEncoding *encodings = [NSString availableStringEncodings];
  while (*encodings) {
    if ((NSInteger)*encodings > 0) {
      // Add the string encoding.
      NSNumber *encoding = [NSNumber numberWithInteger:(NSInteger)*encodings];
      NSString *name = [NSString localizedNameOfStringEncoding:*encodings];
      [stringEncodingsTmp setObject:encoding forKey:name];
    }
    encodings++;
  }
  [self setValue:[NSDictionary dictionaryWithDictionary:stringEncodingsTmp] forKey:@"stringEncodings"];
}

- (void)initXpathDefinitionsDropDown
{
  NSMenu *menu = [[NSMenu allocWithZone:[NSMenu menuZone]] init];
  [menu setAutoenablesItems:NO];
  
  // Title
  NSMenuItem *titleItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"XPath definitions", @"Title for xpaths pull down menu.") action:nil keyEquivalent:@""];
  [menu addItem:[titleItem autorelease]];
  
  NSArray *names = [NSArray arrayWithObjects:
                    [NSNull null], 
                    kXPathCommonKeyFirstName,
                    kXPathCommonKeySecondName,
                    [NSNull null], 
                    kXPathCommonKeyStreetAddress, 
                    kXPathCommonKeyStreetNumber,
                    kXPathCommonKeyStreetNumberSuffix,
                    kXPathCommonKeyPostalCode, 
                    kXPathCommonKeyLocality,
                    kXPathCommonKeyState,
                    [NSNull null], 
                    kXPathCommonKeyHomePhone,
                    kXPathCommonKeyWorkPhone,
                    kXPathCommonKeyMobilePhone, nil];
  
  NSArray *titles = [NSArray arrayWithObjects:
                     NSLocalizedString(@"Name", @"Drop down name title"),
                     NSLocalizedString(@"Address", @"Drop down address title"),
                     NSLocalizedString(@"Phone", @"Drop down phone title"), nil];
  
  NSUInteger titleCount = 0;
  for (int i = 0; i < [names count]; i++) {
    if ([names objectAtIndex:i] == [NSNull null]) {
      NSString *title = [titles objectAtIndex:titleCount++];
      NSMenuItem *item = [[[NSMenuItem alloc] initWithTitle:title action:nil keyEquivalent:@""] autorelease];
      [menu addItem:[NSMenuItem separatorItem]];
      [item setEnabled:NO];
      [menu addItem:item];
    } else {
      NSString *name = [names objectAtIndex:i];
      NSString *title = [XPathMO displayNameForAttribute:name];
      
      if ([[title stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] length] == 0) {
        continue;
      }
      
      NSMenuItem *item = [[[NSMenuItem alloc] initWithTitle:title action:nil keyEquivalent:@""] autorelease];
      NSDictionary *representedObject = [NSDictionary dictionaryWithObject:name forKey:kXPathNameAttribute];
      [item setRepresentedObject:representedObject];
      [menu addItem:item];
    }
  }
  
  [pullDownButton setMenu:[menu autorelease]];
}

#pragma mark -
#pragma mark Accessor Methods

- (void)setIsActivated:(BOOL)flag
{
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  if (flag) {
    // Add self as an observer to changes in the address book database.
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserver:self
               selector:@selector(addressBookChanged:)
                   name:kABDatabaseChangedExternallyNotification
                 object:nil];
    
    NSLog(@"AddressUpdate activated");
    
    [defaults setValue:[NSNumber numberWithBool:YES] forKeyPath:kUserDefaultsIsActive];
    
    NSString *stopTitle = NSLocalizedString(@"Stop", @"Stop button title");
    [startStopButton setTitle:stopTitle];
    [onOffMenuItem setTitle:stopTitle];
    
    NSString *statusTitle = NSLocalizedString(@"AddressUpdate is on", @"Status message in menu and in preferences");
    [statusLabel setStringValue:statusTitle];
    [statusMenuItem setTitle:statusTitle];
    
    // Set the status image.
    NSImage *statusImage = [NSImage imageNamed:@"OnButton.png"];
    CGImageRef imageRef = [statusImage copyAsCgImage];
    [[statusImageView layer] setContents:(id)imageRef];
    CGImageRelease(imageRef);
  } else {
    // Remove the oberving of the address book changes.
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center removeObserver:self
                      name:kABDatabaseChangedExternallyNotification
                    object:nil];
    
    NSLog(@"AddressUpdate deactivated");
    
    [defaults setValue:[NSNumber numberWithBool:NO] forKeyPath:kUserDefaultsIsActive];
    NSString *startTitle = NSLocalizedString(@"Start", @"Start button");
    [startStopButton setTitle:startTitle];
    [onOffMenuItem setTitle:startTitle];
    
    NSString *statusTitle = NSLocalizedString(@"AddressUpdate is off", @"Status message in menu and in preferences");
    [statusLabel setStringValue:statusTitle];
    [statusMenuItem setTitle:statusTitle];
    
    // Set the status image.
    NSImage *statusImage = [NSImage imageNamed:@"OffButton.png"];
    CGImageRef imageRef = [statusImage copyAsCgImage];
    [[statusImageView layer] setContents:(id)imageRef];
    CGImageRelease(imageRef);
  }
}

#pragma mark -
#pragma mark Actions

- (void)quitClick:(id)sender
{
  [NSApp terminate:self];
}

- (void)preferencesClick:(id)sender
{
  if ([mainWindow isVisible]) {
    [NSApp activateIgnoringOtherApps:YES];
  } else {
    [NSApp activateIgnoringOtherApps:YES];
    [mainWindow makeKeyAndOrderFront:self];
  }
}

- (IBAction)doneClick:(id)sender
{
  NSManagedObjectContext *context = [[NSApp delegate] managedObjectContext];
  NSError *error = NULL;
  [context save:&error];
  if (error) {
    NSLog(@"Could not save context to persistent store: %@", error);
  }
  
  [mainWindow orderOut:self];
}

- (IBAction)startStopClick:(id)sender
{
  BOOL activated = [[[NSUserDefaults standardUserDefaults] valueForKey:kUserDefaultsIsActive] boolValue];
  if (activated) {
    [self setIsActivated:NO];
  } else {
    [self setIsActivated:YES];
  }   
}

- (IBAction)pullDownMenuItemSelected:(id)sender
{
  // If the selected item has the state NSOffState.
  NSPopUpButton *button = (NSPopUpButton *)sender;
  NSMenuItem *selectedItem = [button selectedItem];
  
  if ([selectedItem state] == NSOffState) {
    // Create an entity for that XPath.
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"XPath"
                                              inManagedObjectContext:[[NSApp delegate] managedObjectContext]];
    NSManagedObject *xpath = [[NSManagedObject alloc] initWithEntity:entity
                                      insertIntoManagedObjectContext:[[NSApp delegate] managedObjectContext]];
    
    // Set the values of the new xpath.
    [xpath setValuesForKeysWithDictionary:(NSDictionary *)[selectedItem representedObject]];
    
    // Add the new xpath to the current site.
    [usedXpaths addObject:[xpath autorelease]];
    
    // Report any observers that we have changed the number of xpaths.
    NSUInteger count = [[usedXpaths arrangedObjects] count];
    NSNotificationCenter *center =  [NSNotificationCenter defaultCenter];
    [center postNotification:[NSNotification notificationWithName:@"XPathCollectionChanged" object:nil userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithInteger:count] forKey:@"count"]]];
  } else if ([selectedItem state] == NSOnState) {
    // Remove the selected item from the used xpaths for the selected item.
    NSString *selectedItemName = [[selectedItem representedObject] valueForKey:kXPathNameAttribute];
    
    NSArray *usedXpathsArray = [usedXpaths arrangedObjects];  
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K = %@",
                              kXPathNameAttribute, selectedItemName];
    NSArray *xpaths = [usedXpathsArray filteredArrayUsingPredicate:predicate];
    
    [usedXpaths removeObjects:xpaths];
    
    // Report any observers that we have changed the number of xpaths.
    NSUInteger count = [[usedXpaths arrangedObjects] count];
    NSNotificationCenter *center =  [NSNotificationCenter defaultCenter];
    [center postNotification:[NSNotification notificationWithName:@"XPathCollectionChanged" object:nil userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithInteger:count] forKey:@"count"]]];
  }
}

- (IBAction)updateEntireAddressBookClick:(id)sender
{
  NSString *message = NSLocalizedString(@"Are you sure you want to update your entire Address Book?", @"When updating the entire address book.");
  NSString *longerMessage = NSLocalizedString(@"Updating the entire Address Book might result in a lot of your contacts having addresses, telephone numbers and names changed or added to them. Make sure you do a backup of your Address Book before continuing.", @"");
  NSString *update = NSLocalizedString(@"Update", @"Button for updating all records");
  NSString *cancel = NSLocalizedString(@"Cancel", @"Button for canceling all records update");
  
  NSAlert *alert = [NSAlert alertWithMessageText:message defaultButton:update alternateButton:cancel otherButton:nil informativeTextWithFormat:longerMessage];
  [alert beginSheetModalForWindow:mainWindow modalDelegate:self didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:updateEntireAddressBookAlertContext];
}

- (IBAction)startAtLoginClick:(id)sender
{
  NSButton *button = sender;
  NSURL *appUrl = [NSURL fileURLWithPath:applicationPath];
  CFURLRef appUrlRef = (CFURLRef)appUrl;
  LSSharedFileListRef itemsRef = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
  
  if ([button state] == NSOnState) {
    [self enableLoginItemWithLoginItemsReference:itemsRef forPath:appUrlRef];
  } else if ([button state] == NSOffState) {
    [self disableLoginItemWithLoginItemsReference:itemsRef forPath:appUrlRef];
  }
  
  CFRelease(itemsRef);
}

- (IBAction)sitesDropDownChanged:(id)sender
{
  //[self rememberCurrentlySelectedSite];
}

- (IBAction)loadSiteClick:(id)sender
{
  NSOpenPanel *openPanel = [NSOpenPanel openPanel];
  [openPanel setCanChooseFiles:YES];
  [openPanel setCanChooseDirectories:NO];
  [openPanel setAllowsMultipleSelection:YES];
  [openPanel setAllowedFileTypes:[NSArray arrayWithObjects:@"ausite", @"xml", @"plist", nil]];
  [openPanel runModal];
  
  NSArray *selectedFiles = [openPanel filenames];
  @try {
    [self application:NSApp openFiles:selectedFiles];
  }
  @catch (NSException *ex) {
    NSLog(@"Exception caught when loading site: %@", ex);
  }
}

- (IBAction)removeSiteClick:(id)sender
{
  NSString *alertText = NSLocalizedString(@"Are you sure you want to remove the site \"%@\" from your active sites?", @"Removing a site");
  NSString *informativeText = NSLocalizedString(@"Removing the site will not delete any site configuration files that you might have used to import the site to AddressUpdate.", @"Informative text");
  NSString *cancelButton = NSLocalizedString(@"Cancel", @"Cancel button");
  NSString *okButton = NSLocalizedString(@"Remove", @"Remove button");
  
  SiteInformationMO *site = [sites selection];
  NSAlert *alert = [NSAlert alertWithMessageText:[NSString stringWithFormat:alertText, [site valueForKey:kSiteNameAttribute]] defaultButton:cancelButton alternateButton:okButton otherButton:nil informativeTextWithFormat:informativeText];
  [alert beginSheetModalForWindow:mainWindow modalDelegate:self didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:removeSiteAlertContext];
}

- (IBAction)reloadDefaultSitesClick:(id)sender
{
  NSLocale *locale = [NSLocale currentLocale];
  NSString *countryCode = [locale objectForKey:NSLocaleCountryCode];
  NSArray *siteConfigurationFiles = [self siteConfigurationFilesForCountryCode:countryCode];
  if ([siteConfigurationFiles count] == 0) {
    NSString *noDefaultFilesAlert = NSLocalizedString(@"Unfortunately no default site configurations have been created for your country.", @"When no site configurations are available for the current system country");
    NSString *noDefaultFilesdetailed = NSLocalizedString(@"You can still add configurations manually. Check out http://addressupdate.bergnehr.se/sites.html for available site configurations.", @"Informative text when no site conf. were found.");
    NSString *openSitesPageButton = NSLocalizedString(@"Open website", @"Button when opening the sites website.");
    NSAlert *alert = [NSAlert alertWithMessageText:noDefaultFilesAlert defaultButton:nil alternateButton:openSitesPageButton otherButton:nil informativeTextWithFormat:noDefaultFilesdetailed];
    [alert beginSheetModalForWindow:mainWindow modalDelegate:self didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:noSitesFoundAlertContext];
    return;
  }
  
  NSString *alertText = NSLocalizedString(@"Do you want to add the site configurations that are default to your current system?", @"When pressing the load defaults sites button.");
  NSString *detailedText = NSLocalizedString(@"Note that reloading your default site configurations if you already have them among your current sites will result in duplicate sites.", @"Detailed text when reloading default configs.");
  NSString *cancelButton = NSLocalizedString(@"Cancel", @"Cancel button");
  NSAlert *alert = [NSAlert alertWithMessageText:alertText defaultButton:nil alternateButton:cancelButton otherButton:nil informativeTextWithFormat:detailedText];
  [alert beginSheetModalForWindow:mainWindow modalDelegate:self didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:reloadDefaultSitesAlertContext];
}

- (IBAction)helpButtonClick:(id)sender
{
  [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:homePageUrl]];
}

#pragma mark -
#pragma mark Notifications

- (void)addressBookChanged:(NSNotification *)note
{ 
  if (isUpdating) { return; }
  
  NSLog(@"Address book database changed");
  self.isUpdating = YES;
  
  // The concerned records.
  NSArray *insertedRecords = [[note userInfo] valueForKey:kABInsertedRecords];
  NSArray *updatedRecords = [[note userInfo] valueForKey:kABUpdatedRecords];
  NSArray *deletedRecords = [[note userInfo] valueForKey:kABDeletedRecords];
  
  if (!addressBookUpdater) {
    addressBookUpdater = [[AddressBookUpdater alloc] init];
    addressBookUpdater.delegate = self;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    BOOL shouldUpdateAddresses = [[defaults valueForKey:kUserDefaultsShoulUpdateAddresses] boolValue];
    BOOL shouldUpdateNames = [[defaults valueForKey:kUserDefaultsShouldUpdateNames] boolValue];
    BOOL shouldUpdateOtherPhoneNumbers = [[defaults valueForKey:kUserDefaultsShouldUpdatePhoneNumbers] boolValue];
    BOOL shouldUpdateCountryInAddress = [[defaults valueForKey:kUserDefaultsShouldUpdateCountryInAddress] boolValue];
    
    addressBookUpdater.shouldUpdateAddresses = shouldUpdateAddresses;
    addressBookUpdater.shouldUpdateNames = shouldUpdateNames;
    addressBookUpdater.shouldUpdateOtherPhoneNumbers = shouldUpdateOtherPhoneNumbers;
    addressBookUpdater.shouldUpdateCountryInAddress = shouldUpdateCountryInAddress;
  }
  
  // The site to use.
  NSArray *selectedObjects = [sites selectedObjects];
  NSManagedObject *site = [selectedObjects objectAtIndex:0];
  
  // If all records are nil, the entire db was changed.
  if (!insertedRecords && !updatedRecords && !deletedRecords) {
    // Update the entire address book.
    [self updateEntireAddressBookClick:self];
    return;
  }
  
  // Update the inserted and updated records.
  NSMutableArray *records = [NSMutableArray arrayWithArray:updatedRecords];
  [records addObjectsFromArray:insertedRecords];
  [addressBookUpdater updateRecords:[[records copy] autorelease] usingSite:site];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
  if (object == usedXpaths) {
    NSArray *usedXpathsArray = [object valueForKeyPath:keyPath];
    // Initially set all items to NSOffState. 
    [[pullDownButton itemArray] setValue:[NSNumber numberWithInteger:NSOffState] forKey:@"state"];
    
    // For every element in the used xpaths array.
    for (NSManagedObject *xpath in usedXpathsArray) {
      NSString *xpathName = [xpath valueForKey:kXPathNameAttribute];
      // For all elements in the drop down list.
      for (NSMenuItem *item in [pullDownButton itemArray]) {
        // Get the represented object.
        id representedObject = [item representedObject];
        if (representedObject) {
          NSString *name = [representedObject valueForKey:kXPathNameAttribute];
          // If the name is the same as the one in the list.
          if (name && [name isEqualToString:xpathName]) {
            // Set the state of the item to enabled.
            [item setState:NSOnState];
            break;
          }
        }
      }
    }
  } else if (context == arrangedObjectsObservingContext) {
    if ([[sites arrangedObjects] count] == 0) { return; }
    
    NSString *selectedObjectUri = [[NSUserDefaults standardUserDefaults] valueForKey:kUserDefaultsSelectedSiteURI];
    if (selectedObjectUri && [selectedObjectUri length] != 0) {
      // For all site objects.
      for (NSManagedObject *object in [sites arrangedObjects]) {
        NSManagedObjectID *identity = [object objectID];
        NSURL *uriRepresentation = [identity URIRepresentation];
        NSString *uri = [uriRepresentation absoluteString];
        if ([uri isEqualToString:selectedObjectUri]) {
          NSArray *site = [NSArray arrayWithObject:object];
          [sites setSelectedObjects:site];
        }
      }
      
      // Remove the observing since we've loaded the selected object.
      [sites removeObserver:self forKeyPath:@"arrangedObjects"];
      
    }
  } else if (context == selectedObjectsObservingContext) {
    [self rememberCurrentlySelectedSite];
  } else {
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
  }
}

#pragma mark -
#pragma mark Delegate Methods

- (void)updaterWillUpdateRecords:(NSArray *)recordIDs usingSite:(NSManagedObject *)site
{
  self.isUpdating = YES;
  NSLog(@"Will update %d records.", [recordIDs count]);
  [self performSelectorOnMainThread:@selector(initUpdateStatusWithItemsToUpdate:) withObject:[NSNumber numberWithUnsignedInteger:[recordIDs count]] waitUntilDone:YES];
}

- (void)updaterDidFinnishUpdatingRecords:(NSArray *)recordIDs usingSite:(NSManagedObject *)site
{
  NSLog(@"Updated %d records.", [recordIDs count]);
  [self performSelectorOnMainThread:@selector(finnishedUpdatingRecords) withObject:nil waitUntilDone:YES];
  self.isUpdating = NO;
}

- (void)application:(NSApplication *)sender openFiles:(NSArray *)filenames
{
  AddressUpdateSiteImporter *importer = [[AddressUpdateSiteImporter alloc] initWithManagedObjectContext:[[NSApp delegate] managedObjectContext]];
  importer.mainWindow = mainWindow;
  for (NSString *filePath in filenames) {
    [importer importSiteFromFile:filePath presentError:YES];
  }
  [importer release];
}

- (void) alertDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
  // Remove site alert.
  if (contextInfo == removeSiteAlertContext && returnCode == NSAlertAlternateReturn) {
      [sites remove:self];
    // Update entire address book alert.
  } else if (contextInfo == updateEntireAddressBookAlertContext && returnCode == NSAlertDefaultReturn) {
    [updateWindowController autorelease];
    updateWindowController = [[UpdateWindowController alloc] initWithWindowNibName:@"UpdateSheet"];

    updateWindowController.delegate = self;    
    updateWindowController.dockWindow = mainWindow;
    
    NSArray *selectedObjects = [sites selectedObjects];
    NSManagedObject *site = [selectedObjects objectAtIndex:0];
    
    // Remove the alert window before showing the other one.
    NSWindow *alertWindow = [alert window];
    [alertWindow orderOut:self];
    
    [updateWindowController updateAllRecordsWithSite:site statusView:statusItemView];
    // No default sites alert.
  } else if (contextInfo == noSitesFoundAlertContext && returnCode == NSAlertAlternateReturn) {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:homePageUrl]];
    // Reload sites alert.
  } else if (contextInfo == reloadDefaultSitesAlertContext && returnCode == NSAlertDefaultReturn) {
    [self loadDefaultSiteConfigurations];
  }
}

- (void)didFinnishUpdatingAllRecords:(UpdateWindowController *)controller
{
  NSLog(@"Finnished updating all records.");
  NSUInteger totalRecords = [[controller.updateInfomation valueForKey:kUpdateInformationProcessedRecords] unsignedIntegerValue];
  NSUInteger updatedRecords = [[controller.updateInfomation valueForKey:kUpdateInformationUpdatedRecords] unsignedIntegerValue];
  [updateWindowController release];
  updateWindowController = nil;
  
  // Show an alert that we got so many updated records.
  NSString *messageText = NSLocalizedString(@"Successfully updated %d contacts out of %d.", @"Message when having updated all records. First %d is for the successfully updated records, the second %d is for the total attempted.");
  NSString *informativeText = NSLocalizedString(@"Some contacts are not updated because they already contain the address information found on the search site, and some because no information could be found using the telephone number(s) for that contact.", @"Informative text for when all updates are complete.");
  NSAlert *alert = [NSAlert alertWithMessageText:[NSString stringWithFormat:messageText, updatedRecords, totalRecords] defaultButton:nil alternateButton:nil otherButton:nil informativeTextWithFormat:informativeText];
  [alert beginSheetModalForWindow:mainWindow modalDelegate:self didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:nil];
}

- (void)didStopBeforeUpdatingAllRecords:(UpdateWindowController *)controller
{
  NSLog(@"Stoped before updating all records.");
}

@end

#pragma mark -
#pragma mark Private Methods

@implementation AppController (PrivateMethods)

- (void)enableLoginItemWithLoginItemsReference:(LSSharedFileListRef)theLoginItemsRefs forPath:(CFURLRef)thePath
{
	// We call LSSharedFileListInsertItemURL to insert the item at the bottom of Login Items list.
	LSSharedFileListItemRef item = LSSharedFileListInsertItemURL(theLoginItemsRefs, kLSSharedFileListItemLast, NULL, NULL, thePath, NULL, NULL);		
	if (item)
		CFRelease(item);
}

- (void)disableLoginItemWithLoginItemsReference:(LSSharedFileListRef)theLoginItemsRefs forPath:(CFURLRef)thePath
{
	UInt32 seedValue;
  
	// We're going to grab the contents of the shared file list (LSSharedFileListItemRef objects)
	// and pop it in an array so we can iterate through it to find our item.
	NSArray  *loginItemsArray = (NSArray *)LSSharedFileListCopySnapshot(theLoginItemsRefs, &seedValue);
	for (id item in loginItemsArray) {		
		LSSharedFileListItemRef itemRef = (LSSharedFileListItemRef)item;
		if (LSSharedFileListItemResolve(itemRef, 0, (CFURLRef*) &thePath, NULL) == noErr) {
			if ([[(NSURL *)thePath path] hasPrefix:applicationPath])
				LSSharedFileListItemRemove(theLoginItemsRefs, itemRef); // Deleting the item
		}
	}
	
	[loginItemsArray release];
}

- (void)initUpdateStatusWithItemsToUpdate:(NSNumber *)count
{
  [statusItemView startRotationAnimation];
}

- (void)finnishedUpdatingRecords
{
  // Stop the animation.
  [statusItemView stopRotationAnimation];
}

- (NSArray *)siteConfigurationFilesForCountryCode:(NSString *)code
{
  NSArray *siteConfigurations = [[NSBundle mainBundle] pathsForResourcesOfType:@"ausite" inDirectory:[NSString stringWithFormat:@"Site Configurations/%@", code]];
  return siteConfigurations;
}
    
- (void)loadDefaultSiteConfigurations
{
  NSLocale *locale = [NSLocale currentLocale];
  NSString *countryCode = [locale objectForKey:NSLocaleCountryCode];
  NSArray *siteConfigurations = [self siteConfigurationFilesForCountryCode:countryCode];
  if ([siteConfigurations count] == 0) {
    NSLog(@"Could not find any site configurations in applications resource folder for country code %@.", countryCode);
    return;
  }
  
  AddressUpdateSiteImporter *importer = [[AddressUpdateSiteImporter alloc] initWithManagedObjectContext:[[NSApp delegate] managedObjectContext]];
  [importer importSitesFromFiles:siteConfigurations presentError:NO];
  [importer release];
}

- (void)rememberCurrentlySelectedSite
{
  NSArray *objects = [sites selectedObjects];
  if (!objects || [objects count] == 0) { return; }
  
  NSManagedObject *object = [objects objectAtIndex:0];
  NSManagedObjectID *objectId = [object objectID];
  NSURL *objectUri = [objectId URIRepresentation];
  NSString *objectUriString = [objectUri absoluteString];
  [[NSUserDefaults standardUserDefaults] setValue:objectUriString forKey:kUserDefaultsSelectedSiteURI];
  [[NSUserDefaults standardUserDefaults] synchronize];
}

@end
