
#import "AddressUpdate_Address_Book_Plug_In.h"
#import "SiteInformationMO.h"
#import "XPathMO.h"
#import "UserDefaultsKeys.h"


@interface AddressUpdate_Address_Book_Plug_In ()
- (SiteInformationMO *)selectedSiteInAddressUpdate;
@end

@implementation AddressUpdate_Address_Book_Plug_In

#pragma mark -
#pragma mark init/dealloc

- (void)dealloc
{
  [auDelegate release];
  [updater release];
  [super dealloc];
}

#pragma mark -
#pragma mark Address Book Plug-In Methods

- (NSString *)actionProperty
{
  return kABPhoneProperty;
}

- (NSString *)titleForPerson:(ABPerson *)person identifier:(NSString *)identifier
{
  ABMultiValue* values = [person valueForProperty:[self actionProperty]];
  NSString* number = [values valueForIdentifier:identifier];
  
  NSString *preString = NSLocalizedString(@"Update address for: ", @"Prefix for title in context menu.");
  return [preString stringByAppendingString:number];
}

- (void)performActionForPerson:(ABPerson *)person identifier:(NSString *)identifier
{
  ABMultiValue* values = [person valueForProperty:[self actionProperty]];
  NSString* number = [values valueForIdentifier:identifier];
  number = nil;
  
  // Get the currently selected item from AddressUpdate.
  SiteInformationMO *site = nil;
  @try {
    site = [self selectedSiteInAddressUpdate];
  } @catch (NSException *exception) {
    NSLog(@"Could not retrieve the currently used AU-site in AddressUpdate due to: %@", exception);
    return;
  }
  
  if (!site) { return; }
  
  if (!updater) {
    updater = [[AddressBookUpdater updater] retain];
    
    // Get the app defaults first. 
    NSString *appDefaultsPath = [[[NSBundle bundleForClass:[self class]] resourcePath]
                                 stringByAppendingPathComponent:@"AppDefaults.plist"];
    NSDictionary *appDefaults = [NSDictionary dictionaryWithContentsOfFile:appDefaultsPath];
    NSMutableDictionary *defaults = [NSMutableDictionary dictionaryWithDictionary:appDefaults];
    NSDictionary *auDefaults = [[[[NSUserDefaults alloc] init] autorelease] persistentDomainForName:kUserDefaultsIdentifier];
    [defaults setValuesForKeysWithDictionary:auDefaults];
    BOOL shouldUpdateAddresses = [[defaults valueForKey:kUserDefaultsShoulUpdateAddresses] boolValue];
    BOOL shouldUpdateNames = [[defaults valueForKey:kUserDefaultsShouldUpdateNames] boolValue];
    BOOL shouldUpdateOtherPhoneNumbers = [[defaults valueForKey:kUserDefaultsShouldUpdatePhoneNumbers] boolValue];
    BOOL shouldUpdateCountryInAddress = [[defaults valueForKey:kUserDefaultsShouldUpdateCountryInAddress] boolValue];
    
    updater.shouldUpdateAddresses = shouldUpdateAddresses;
    updater.shouldUpdateNames = shouldUpdateNames;
    updater.shouldUpdateOtherPhoneNumbers = shouldUpdateOtherPhoneNumbers;
    updater.shouldUpdateCountryInAddress = shouldUpdateCountryInAddress;
  }
  
  [updater updateRecords:[NSArray arrayWithObject:[person uniqueId]] usingSite:site];
}

- (BOOL)shouldEnableActionForPerson:(ABPerson *)person identifier:(NSString *)identifier
{
  return YES;
}

#pragma mark -
#pragma mark Private Methods

- (SiteInformationMO *)selectedSiteInAddressUpdate
{
  SiteInformationMO *site = nil;
  
  // First, get the selected site URI from the user defaults db.
  NSDictionary *defaults = [[[[NSUserDefaults alloc] init] autorelease] persistentDomainForName:kUserDefaultsIdentifier];
  if (defaults) {
    NSString *siteUriString = [defaults valueForKey:kUserDefaultsSelectedSiteURI];
    NSURL *siteUri = [[NSURL alloc] initWithString:siteUriString];
    
    if (!auDelegate) {
      auDelegate = [[AddressUpdate_AppDelegate alloc] init];
    }
    
    NSPersistentStoreCoordinator *coordinator = [auDelegate persistentStoreCoordinator];
    NSManagedObjectContext *context = [auDelegate managedObjectContext];
    
    NSManagedObjectID *objectId = [coordinator managedObjectIDForURIRepresentation:siteUri];
    site = (SiteInformationMO *)[context objectWithID:objectId];
    
    [siteUri release];
  } else {
    NSString *message = NSLocalizedString(@"Could not load AddressUpdate preferences.", @"When loading preferences from AddressUpdate.");
    NSString *infoText = NSLocalizedString(@"Make sure that you have launched and configured AddressUpdate before you use the AddressUpdate Address Book Plu-In", @"Informative text when loading preferences from AddressUpdate.");
    [NSAlert alertWithMessageText:message defaultButton:nil alternateButton:nil otherButton:nil informativeTextWithFormat:infoText];
  }
  
  return site;
}

@end