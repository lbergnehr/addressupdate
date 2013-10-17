
#import "UpdateWindowController.h"
#import "UserDefaultsKeys.h"
#import <QuartzCore/QuartzCore.h>
#import "NSImage-Extras.h"

NSString * const kUpdateInformationProcessedRecords = @"updateInformationProcessedRecords";
NSString * const kUpdateInformationUpdatedRecords = @"updateInformationUpdatedRecords";

@interface UpdateWindowController ()
- (void)initiateProgressBarWithMaxValue:(NSNumber *)value;
- (void)updateProgressForRecordID:(NSString *)recordID;
- (void)switchToImage:(NSImage *)image;
@end

@implementation UpdateWindowController
@synthesize updater, dockWindow, site, statusView, personNameBeingUpdated, delegate, filters, updateInfomation;

- (void)dealloc
{
  self.site                   = nil;
  self.updater                = nil;
  self.dockWindow             = nil;
  self.statusView             = nil;
  self.filters                = nil;
  self.personNameBeingUpdated = nil;
  [updateInfomation release];
  
  [super dealloc];
}

- (void)updateAllRecordsWithSite:(NSManagedObject *)theSite statusView:(StatusItemView *)view
{
  self.site       = theSite;
  self.statusView = view;
  
  if (!updater) {
    updater = [[AddressBookUpdater alloc] init];
    updater.delegate = self;
    
    NSUserDefaults *defaults            = [NSUserDefaults standardUserDefaults];
    BOOL shouldUpdateAddresses          = [[defaults valueForKey:kUserDefaultsShoulUpdateAddresses] boolValue];
    BOOL shouldUpdateNames              = [[defaults valueForKey:kUserDefaultsShouldUpdateNames] boolValue];
    BOOL shouldUpdateOtherPhoneNumbers  = [[defaults valueForKey:kUserDefaultsShouldUpdatePhoneNumbers] boolValue];
    BOOL shouldUpdateCountryInAddress   = [[defaults valueForKey:kUserDefaultsShouldUpdateCountryInAddress] boolValue];
    
    updater.shouldUpdateAddresses         = shouldUpdateAddresses;
    updater.shouldUpdateNames             = shouldUpdateNames;
    updater.shouldUpdateOtherPhoneNumbers = shouldUpdateOtherPhoneNumbers;
    updater.shouldUpdateCountryInAddress  = shouldUpdateCountryInAddress;
  }
  
  // Show the sheet.
  NSWindow *updateWindow = [self window];
  [NSApp beginSheet:updateWindow modalForWindow:dockWindow modalDelegate:self didEndSelector:nil contextInfo:NULL];
  [updateWindow makeKeyAndOrderFront:self];
  
  // Start the animation.
  [statusView startRotationAnimation];
  
  // Start updating.
  [updater updateAllRecordsWithSite:site];
}

- (IBAction)stopButtonClick:(id)sender
{
  // Stop the animation.
  [statusView stopRotationAnimation];
  
  [updater stopUpdatingRecords];
  
  // Set the image to the default image.
  NSImage *image = [NSImage imageNamed:NSImageNameUser];
  [addressBookImages setImage:image];
  
  // Close the sheet.
  NSWindow *window = [self window];
  [NSApp endSheet:window];
  [window close];
  
  // Inform the delegate.
  if ([delegate respondsToSelector:@selector(didStopBeforeUpdatingAllRecords:)]) {
    [delegate didStopBeforeUpdatingAllRecords:self];
  }
}

#pragma mark -
#pragma mark Delegate Methods

- (void)updaterWillUpdateRecords:(NSArray *)recordIDs usingSite:(NSManagedObject *)site
{
  [internalUpdateInformation release];
  internalUpdateInformation = [[NSMutableDictionary alloc] initWithCapacity:2];
  NSNumber *count = [NSNumber numberWithInteger:[recordIDs count]];
  [internalUpdateInformation setValue:count forKey:kUpdateInformationProcessedRecords];
  [self performSelectorOnMainThread:@selector(initiateProgressBarWithMaxValue:) withObject:count waitUntilDone:YES];
}

- (void)updaterDidFinnishProcessingRecord:(NSString *)recordID
{
  [self performSelectorOnMainThread:@selector(updateProgressForRecordID:) withObject:recordID waitUntilDone:YES];
}

- (void)updaterDidFinnishUpdatingRecords:(NSArray *)recordIDs usingSite:(NSManagedObject *)site
{
  // Stop the animation.
  [statusView stopRotationAnimation];
  
  NSWindow *window = [self window];
  [NSApp endSheet:window];
  [window close];
  
  // Set the update informaiton dictionary.
  [internalUpdateInformation setValue:[NSNumber numberWithUnsignedInteger:[recordIDs count]] forKey:kUpdateInformationUpdatedRecords];
  [updateInfomation autorelease];
  updateInfomation = [internalUpdateInformation copy];
  [internalUpdateInformation release];
  internalUpdateInformation = nil;
  
  // Inform the delegate.
  if ([delegate respondsToSelector:@selector(didFinnishUpdatingAllRecords:)]) {
    [delegate didFinnishUpdatingAllRecords:self];
  }
}

#pragma mark -
#pragma mark Updating View Methods

- (void)initiateProgressBarWithMaxValue:(NSNumber *)value
{
  [progressBar setMaxValue:[value doubleValue]];
  [progressBar setDoubleValue:0];
}

- (void)updateProgressForRecordID:(NSString *)recordID
{
  // Progress bar.
  [progressBar incrementBy:1];
  
  // User image.
  ABPerson *person = (ABPerson *)[[ABAddressBook sharedAddressBook] recordForUniqueId:recordID];
  
  // Set the image of the contact if any.
  NSData *imageData = [person imageData];
  NSImage *image = [[NSImage alloc] initWithData:imageData];
  if (image) {
    [self switchToImage:image];
    [image release];
  } else {
    // Put a filter on the image so that the user will understand that the image is not for that name.
    if (!filters) {
      filters = [[self filtersForImageView] retain];
    }
    
    [[addressBookImages animator] setContentFilters:filters];
  }
  
  
  // Change the name label to the new name.
  NSString *firstName = [person valueForProperty:kABFirstNameProperty];
  NSString *lastName  = [person valueForProperty:kABLastNameProperty];
  self.personNameBeingUpdated = [NSString stringWithFormat:@"%@ %@", firstName ?: @"", lastName ?: @""];
}

- (NSArray *)filtersForImageView
{
  CIFilter *blurFilter = [CIFilter filterWithName:@"CIGaussianBlur"];
  [blurFilter setDefaults];
  [blurFilter setValue:[NSNumber numberWithFloat:5.0] forKey:kCIInputRadiusKey];
  
  CIFilter *monochromeFilter = [CIFilter filterWithName:@"CIColorMonochrome"];
  [monochromeFilter setDefaults];
  CIColor *color = [CIColor colorWithRed:1 green:1 blue:1];
  [monochromeFilter setValue:color forKey:@"inputColor"];
  [monochromeFilter setValue:[NSNumber numberWithFloat:1.0] forKey:@"inputIntensity"];
  
  return [NSArray arrayWithObjects:blurFilter, monochromeFilter, nil];
}

- (void)switchToImage:(NSImage *)image
{
  // Switch the pointers.
  NSImageView *oldImageView = addressBookImages;
  NSImageView *newImageView = [[NSImageView alloc] initWithFrame:[oldImageView frame]];
  addressBookImages = newImageView;
  
  // Set the properties of the new view.
  [newImageView setWantsLayer:YES];
  [newImageView setImageScaling:[oldImageView imageScaling]];
  [newImageView setImageFrameStyle:[oldImageView imageFrameStyle]];
  [newImageView setContentFilters:[oldImageView contentFilters]];
  [newImageView setAutoresizingMask:[oldImageView autoresizingMask]];
  [newImageView setImage:image];
  [newImageView setContentFilters:nil];
  
  // Replace the old view with the new one.
  [CATransaction begin];
  [CATransaction setValue:[NSNumber numberWithFloat:1.0] forKey:kCATransactionAnimationDuration];
  [[imageViewWrapper animator] replaceSubview:oldImageView with:[newImageView autorelease]];
  [CATransaction commit];
}

@end