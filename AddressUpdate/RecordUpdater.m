
#import "RecordUpdater.h"
#import <AddressUpdateKit/AddressUpdateKit.h>
#import "XPathMO.h"
#import "UserDefaultsKeys.h"
#import "SiteInformationMO.h"
#import "objpcre.h"
#import "pcre.h"


static NSDictionary const * countryCodesAndReplacements = nil;

@interface RecordUpdater (hidden)

- (UpdateReturnValue)updateRecord:(ABPerson *)record usingSite:(NSManagedObject *)entity;
- (UpdateReturnValue)updateRecord:(ABPerson *)person withAddressData:(NSDictionary *)data label:(NSString *)label;
- (UpdateReturnValue)updateAddressesForPerson:(ABPerson *)person withAddressData:(NSDictionary *)data withLabel:(NSString *)label;
- (UpdateReturnValue)updateNameForPerson:(ABPerson *)person withAddressData:(NSDictionary *)data;
- (UpdateReturnValue)updateOtherPhoneNumbersForPerson:(ABPerson *)person withAddressData:(NSDictionary *)data;
- (NSDictionary *)applyRegExpToData:(NSDictionary *)data fromXpaths:(NSArray *)xpaths;

@end

@implementation RecordUpdater
@synthesize theRecord, theEntity, delegate, shouldUpdateNames, shouldUpdateOtherPhoneNumbers, shouldUpdateAddresses, shouldUpdateCountryInAddress;

#pragma mark -
#pragma mark init/deallc

+ (void)initialize
{
  // Load all the country codes and their replacements from file.
  NSString *path = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"CountryCodes.plist"];
  countryCodesAndReplacements = [[NSDictionary dictionaryWithContentsOfFile:path] retain];
  
  // If nothing was found.
  if (!countryCodesAndReplacements) {
    countryCodesAndReplacements = [[NSDictionary alloc] init];
  }
}

- (id)init
{
  self = [super init];
  if (self) {
    theEntity = nil;
    theRecord = nil;
    isCancelled = NO;
  }
  
  return self;
}

- (void)dealloc
{
  [theEntity release];
  [theRecord release];
  [super dealloc];
}

#pragma mark -
#pragma mark Operation Methods

- (void)main
{
  if (isCancelled) { return; }
  
  if (theEntity && theRecord) {
    if ([delegate respondsToSelector:@selector(updater:willBeginUpdatingRecord:)]) {
      [delegate updater:self willBeginUpdatingRecord:theRecord];
    }
    @try {
      UpdateReturnValue changesMade = [self updateRecord:theRecord usingSite:theEntity];
      if ([delegate respondsToSelector:@selector(updater:didFinnishUpdatingRecord:withChanges:)]) {
        [delegate updater:self didFinnishUpdatingRecord:theRecord withChanges:changesMade];
      }
    } @catch (NSException *ex) {
      if ([delegate respondsToSelector:@selector(updater:didFailWithError:forRecord:)]) {
        NSDictionary *dict = [NSDictionary dictionaryWithObject:NSLocalizedString(@"Unknown error occurred.", @"When something crashed inside the updating method of the RecordUpdater's updateRecord:usingEntity:.")
                                                         forKey:NSLocalizedFailureReasonErrorKey];
        NSError *error = [NSError errorWithDomain:@"RecordUpdaterDomain" code:2 userInfo:dict];
        NSLog(@"Error when updating record. Exception: %@", ex);
        [delegate updater:self didFailWithError:error forRecord:theRecord];
      }
    }
  } else {
    if ([delegate respondsToSelector:@selector(updater:didFailWithError:forRecord:)]) {
      NSDictionary *dict = [NSDictionary dictionaryWithObject:NSLocalizedString(@"entityOrRecordWasNil", @"In the main method of the RecordUpdater, if the entity (site) of the record (person) is nil.")
                                                       forKey:NSLocalizedFailureReasonErrorKey];
      NSError *error = [NSError errorWithDomain:@"RecordUpdaterDomain" code:1 userInfo:dict];
      [delegate updater:self didFailWithError:error forRecord:theRecord];
    }
  }
  
  isFinnished = YES;
}

- (void)cancel
{
  isCancelled = YES;
}

- (BOOL)isCancelled
{
  return isCancelled;
}

- (BOOL)isFinnished
{
  return isFinnished;
}

@end

#pragma mark -
#pragma mark Private Update Methods

@implementation RecordUpdater (hidden)

NSString * countryCodeFormatNumber(NSString * number)
{
  if (!number ) { return nil; }
  
  NSMutableString *formattedNumber = [NSMutableString stringWithString:number];
  
  // For all keys in the dictionary.
  for (NSString *code in [countryCodesAndReplacements allKeys]) {
    // If the prefix of the number is the same as the key.
    if ([number hasPrefix:code]) {
      // Replace the code with the replacement string and return.
      NSString *replacementString = [countryCodesAndReplacements valueForKey:code];
      [formattedNumber replaceOccurrencesOfString:code withString:replacementString options:0 range:NSMakeRange(0, 5)];
      return [[formattedNumber copy] autorelease];
    }
  }
  
  return formattedNumber;
}

NSString * formatNumber(NSString *number)
{
  if (!number) { return nil; }
  
  number = [number stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
  NSMutableString *formattedNumber = [NSMutableString stringWithString:number];
  
  // Remove all white spaces and dashes.
  [formattedNumber replaceOccurrencesOfString:@" " withString:@"" options:0 range:NSMakeRange(0, [formattedNumber length])];
  [formattedNumber replaceOccurrencesOfString:@"-" withString:@"" options:0 range:NSMakeRange(0, [formattedNumber length])];
  
  // If the number has a country code prefix.
  if ([formattedNumber hasPrefix:@"+"] || [formattedNumber hasPrefix:@"00"]) {
    formattedNumber = [[countryCodeFormatNumber(formattedNumber) mutableCopy] autorelease];
  }
  
  return [[formattedNumber copy] autorelease];
}

BOOL abAddressIsEqualToFetchedAddress(NSDictionary *abAddress, NSDictionary *fetchedAddress)
{
  NSString *nilStr = @"";
  
  NSString *abStreet = [abAddress valueForKey:kABAddressStreetKey] ? [abAddress valueForKey:kABAddressStreetKey] : nilStr;
  NSString *abPostalCode = [abAddress valueForKey:kABAddressZIPKey] ? [abAddress valueForKey:kABAddressZIPKey] : nilStr;
  NSString *abLocality = [abAddress valueForKey:kABAddressCityKey] ? [abAddress valueForKey:kABAddressCityKey] : nilStr;
  NSString *abState = [abAddress valueForKey:kABAddressStateKey] ? [abAddress valueForKey:kABAddressStateKey] : nilStr;
  
  NSString *street = [fetchedAddress valueForKey:kXPathCommonKeyStreetAddress]
  ? [fetchedAddress valueForKey:kXPathCommonKeyStreetAddress] : nilStr;
  NSString *postalCode = [fetchedAddress valueForKey:kXPathCommonKeyPostalCode]
  ? [fetchedAddress valueForKey:kXPathCommonKeyPostalCode] : nilStr;
  NSString *locality = [fetchedAddress valueForKey:kXPathCommonKeyLocality]
  ? [fetchedAddress valueForKey:kXPathCommonKeyLocality] : nilStr;
  NSString *state = [fetchedAddress valueForKey:kXPathCommonKeyState]
  ? [fetchedAddress valueForKey:kXPathCommonKeyState] : nilStr;
  
  BOOL isEqual = ([abStreet isEqualToString:street]
                  && [abPostalCode isEqualToString:postalCode]
                  && [abLocality isEqualToString:locality]       
                  && [abState isEqualToString:state]);
  
  return isEqual;
}

- (UpdateReturnValue)updateRecord:(ABPerson *)person withAddressData:(NSDictionary *)data label:(NSString *)label
{
  if (isCancelled) { return updateAborted; }
  
  UpdateReturnValue addressReturnValue = nothingFoundAtSite;
  UpdateReturnValue phoneReturnValue = nothingFoundAtSite;
  UpdateReturnValue nameReturnValue = nothingFoundAtSite;
  
  if (shouldUpdateAddresses) {
    addressReturnValue = [self updateAddressesForPerson:person withAddressData:data withLabel:label];
  }
  if (shouldUpdateNames) {
    nameReturnValue = [self updateNameForPerson:person withAddressData:data];
  }
  if (shouldUpdateOtherPhoneNumbers) {
    phoneReturnValue = [self updateOtherPhoneNumbersForPerson:person withAddressData:data];
  }
  
  if (addressReturnValue == informationUpdated
      || nameReturnValue == informationUpdated
      || phoneReturnValue == informationUpdated) {
    return informationUpdated;
  } else if (addressReturnValue == nothingFoundAtSite
             && nameReturnValue == nothingFoundAtSite
             && phoneReturnValue == nothingFoundAtSite) {
    return nothingFoundAtSite;
  } else if (addressReturnValue == updateAborted
             || nameReturnValue == updateAborted
             || phoneReturnValue == updateAborted) {
    return updateAborted;
  } else {
    return informationAlreadyUpToDate;
  }
}

/* Updates a record using a specified site */
- (UpdateReturnValue)updateRecord:(ABPerson *)record usingSite:(NSManagedObject *)entity
{
  UpdateReturnValue returnValue = nothingFoundAtSite;
  if (isCancelled) { return updateAborted; }
  
  AUKAddressretriever *retriever = [AUKAddressretriever retriever];
  retriever.connectionTimeout = 30.0;
  retriever.stringDataEncoding = (NSStringEncoding)[[entity valueForKey:kSiteStringEncodingAttribute] integerValue];
  
  // Get the action of the form if it isn't defined.
  NSString *url = [entity valueForKey:kSiteURLAttribute];
  if (![url hasPrefix:@"http://"]) {
    url = [@"http://" stringByAppendingString:url];
  }
  if (![url hasSuffix:@"/"]) {
    url = [url stringByAppendingString:@"/"];
  }
  
  NSURL *theUrl = [NSURL URLWithString:url];
  
  // If the URL has the form of a base URL.
  if ([[theUrl relativePath] isEqualToString:@"/"] || [[theUrl relativePath] isEqualToString:@""]) {
    NSString *action = [retriever actionFromFormAtSiteUrl:theUrl];
    if (action) {
      NSString *newUrl = [url stringByAppendingString:action];
      [entity setValue:newUrl forKey:kSiteURLAttribute];
    }
  }
  
  // Get the XPaths for this site.
  NSSet *xpaths = [entity valueForKey:kSiteXpathsRelationship];
  NSMutableDictionary *xpathKeysAndValues = [NSMutableDictionary dictionaryWithCapacity:[xpaths count]];
  for (NSManagedObject *xpath in xpaths) {
    NSString *name = [xpath valueForKey:kXPathNameAttribute];
    NSString *path = [xpath valueForKey:kXPathPathAttribute];
    [xpathKeysAndValues setValue:path forKey:name];
  }
  
  // Set the properties of the site.
  AUKSearchSiteInformation *site = [AUKSearchSiteInformation searchSite];
  site.searchType = AUKHttpGetSearchType;
  site.url = [NSURL URLWithString:[entity valueForKey:kSiteURLAttribute]];
  site.xPaths = xpathKeysAndValues;
  NSString *searchAttribute = [entity valueForKey:kSiteSearchAttributeAttribute];
  
  // For all phone numbers in the record.
  ABMultiValue *numbers = [record valueForProperty:kABPhoneProperty];
  for (NSUInteger i = 0; i < [numbers count]; i++) {
    NSString *number = [numbers valueAtIndex:i];
    
    // Format the number.
    NSString *formattedNumber = formatNumber(number);
    
    // Add the search attribute.
    site.searchKeyValuePairs = [NSDictionary dictionaryWithObject:formattedNumber forKey:searchAttribute];
    
    // Get the data.
    NSDictionary *addressData = [retriever addressDataFromSite:site];
    
    // Check the availabilty.
    if (!addressData || [addressData count] == 0) {
      continue;
    }
    
    // Apply any eventual regular expressions to the found data.
    addressData = [self applyRegExpToData:addressData fromXpaths:[xpaths allObjects]];
    
    // Get the label.
    NSString *label = [numbers labelAtIndex:i];
    
    // Update the record.
    UpdateReturnValue tmpReturnValue = [self updateRecord:record withAddressData:addressData label:label];
    if (returnValue != informationUpdated) {
      if (tmpReturnValue == informationUpdated) {
        returnValue = tmpReturnValue;
      } else if (tmpReturnValue == informationAlreadyUpToDate) {
        returnValue = tmpReturnValue;
      }
    }
  }
  
  return returnValue;
}

- (NSDictionary *)applyRegExpToData:(NSDictionary *)data fromXpaths:(NSArray *)xpaths
{
  NSMutableDictionary *result = [NSMutableDictionary dictionaryWithDictionary:data];
  
  // For each data found.
  for (XPathMO *xpath in xpaths) {
    NSString *name = [xpath valueForKey:kXPathNameAttribute];
    NSString *foundValue = [data valueForKey:name];
    if (!foundValue) { continue; }
    
    // Get the pattern.
    NSString *pattern = [xpath valueForKey:kXPathRegExpAttribute];
    if (!pattern || [pattern length] == 0) { continue; }
    
    // Perform the regexp.
    ObjPCRE *regexp = [[[ObjPCRE alloc] initWithPattern:pattern andOptions:PCRE_UTF8] autorelease];
    if (![regexp isValid]) {
      NSLog(@"Regular expression pattern '%@' is not valid.", pattern);
      continue;
    }
    
    BOOL patternDidMatch = [regexp regexMatches:foundValue options:0 startOffset:0];
    if (!patternDidMatch) {
      NSLog(@"Regular expression pattern '%@' did not result in a match for string '%@'.", pattern, foundValue);
    }
    
    // Store the found value.
    NSString *modifiedValue = [regexp match:foundValue];
    if (modifiedValue) {
      [result setObject:modifiedValue forKey:name];
    }
  }
  
  return [NSDictionary dictionaryWithDictionary:result];
}

#pragma mark -
#pragma mark Update Helper Methods

- (UpdateReturnValue)updateAddressesForPerson:(ABPerson *)person withAddressData:(NSDictionary *)data withLabel:(NSString *)label
{
  UpdateReturnValue returnValue = nothingFoundAtSite;
  if (isCancelled) { return updateAborted; }
  
  data = [NSMutableDictionary dictionaryWithDictionary:data];
  
  NSString *streetAddress       = [data valueForKey:kXPathCommonKeyStreetAddress];
  NSString *streetNumber        = [data valueForKey:kXPathCommonKeyStreetNumber];
  NSString *streetNumberSuffix  = [data valueForKey:kXPathCommonKeyStreetNumberSuffix];
  NSString *postalCode          = [data valueForKey:kXPathCommonKeyPostalCode];
  NSString *locality            = [data valueForKey:kXPathCommonKeyLocality];
  NSString *state               = [data valueForKey:kXPathCommonKeyState];
  
  // If no address was found.
  if (!(streetAddress || streetNumber || streetNumberSuffix || postalCode || locality || state)) {
    return nothingFoundAtSite;
  }
  
  // If a street address was fetched.
  if (streetAddress) {
    NSMutableString *newStreetAddress = [NSMutableString stringWithString:streetAddress];
    
    // If there are street number and suffix, add them.
    if (streetNumber && [streetNumber length] != 0) {
      [newStreetAddress appendFormat:@" %@", streetNumber];
    }
    if (streetNumberSuffix && [streetNumberSuffix length] != 0) {
      [newStreetAddress appendFormat:@" %@", streetNumberSuffix];
    }
    
    // Set the new value.
    streetAddress = [[newStreetAddress copy] autorelease];
  }
  
  // Remove any spaces in the postal code.
  if (postalCode) {
    NSMutableString *newPostalCode = [NSMutableString stringWithString:postalCode];
    [newPostalCode replaceOccurrencesOfString:@" " withString:@"" options:0 range:NSMakeRange(0, [postalCode length])];
    postalCode = [[newPostalCode copy] autorelease];
  }
  
  // Reset the new values.
  [data setValue:streetAddress forKey:kXPathCommonKeyStreetAddress];
  [data setValue:postalCode forKey:kXPathCommonKeyPostalCode];
  
  // Get the old address data.
  ABMultiValue *existingAddresses = [person valueForProperty:kABAddressProperty];
	ABMutableMultiValue *updatedAddresses = [[existingAddresses mutableCopy] autorelease];
  
  // If some address exists in the address book.
  if (updatedAddresses) {
    // For all addresses.
    for (NSUInteger i = 0; i < [updatedAddresses count]; i++) {
      NSDictionary *address = [updatedAddresses valueAtIndex:i];
      
      // If the fetched address already exists in the AB.
      BOOL isEqual = abAddressIsEqualToFetchedAddress(address, data);
      if (isEqual) {
        return informationAlreadyUpToDate;
      } else {
        returnValue = informationUpdated;
      }
      
    }
  } else {
    updatedAddresses = [[[ABMutableMultiValue alloc] init] autorelease];
    returnValue = informationUpdated;
  }
  
  // The address wasn't there, so add it to the list of addresses.
  NSMutableDictionary *newAddress = [NSMutableDictionary dictionary];
  if (streetAddress) { [newAddress setValue:streetAddress forKey:kABAddressStreetKey]; }
  if (postalCode) { [newAddress setValue:postalCode forKey:kABAddressZIPKey]; }
  if (locality) { [newAddress setValue:locality forKey:kABAddressCityKey]; }
  if (state) { [newAddress setValue:state forKey:kABAddressStateKey]; }
  
  // If we should update the country.
  if (shouldUpdateCountryInAddress) {
    // Add the country of the system locale (this is the most probable).
    NSLocale *locale = [NSLocale currentLocale];
    NSString *countryCode = [locale objectForKey:NSLocaleCountryCode];
    NSString *country = [locale displayNameForKey:NSLocaleCountryCode value:countryCode];
    [newAddress setValue:country forKey:kABAddressCountryKey];
  }
  
  // If the label was the mobile label, change it to home.
  if ([label isEqualToString:kABPhoneMobileLabel]) {
    label = kABPhoneHomeLabel;
  }
  
  [updatedAddresses addValue:newAddress withLabel:label];
  
  // Update the value.
  BOOL success = [person setValue:updatedAddresses forProperty:kABAddressProperty];
  if (!success) {
    NSLog(@"Could not update address %@ for person %@", newAddress, person);
    return updateAborted;
  }
  
  return returnValue;
}

NSString * formatName(NSString *name) {
  if (!name) { return nil; }
  
  NSMutableString *tmp = [name mutableCopy];
  [tmp replaceOccurrencesOfString:@" " withString:@"" options:0 range:NSRangeFromString(tmp)];
  NSString *newName = [tmp stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];
  [tmp release];
  
  return newName;
}

- (UpdateReturnValue)updateNameForPerson:(ABPerson *)person withAddressData:(NSDictionary *)data
{
  UpdateReturnValue returnValue = nothingFoundAtSite;
  if (isCancelled) { return updateAborted; }
  
  NSString *firstName = [data valueForKey:kXPathCommonKeyFirstName];
  NSString *secondName = [data valueForKey:kXPathCommonKeySecondName];
  
  if (!firstName && !secondName) { return nothingFoundAtSite; }
  
  // If not both first and second name is defined.
  if (!firstName || !secondName
      || [firstName length] == 0 || [secondName length] == 0) {
    NSArray *names = [firstName componentsSeparatedByString:@" "];
    if (names && [names count] > 1) {
      firstName = formatName([[names subarrayWithRange:NSMakeRange(0, [names count] - 1)] componentsJoinedByString:@" "]);
      secondName = formatName([names objectAtIndex:[names count] - 1]);
    } else {
      secondName = @"";
    }
  }
  
  if (![firstName isEqualToString:[person valueForProperty:kABFirstNameProperty]]
      && [secondName isEqualToString:[person valueForProperty:kABLastNameProperty]]) {
    [person setValue:firstName forProperty:kABFirstNameProperty];
    [person setValue:secondName forProperty:kABLastNameProperty];
    returnValue = informationUpdated;
  }
  
  return returnValue;
}

BOOL numberExistsInAddressBook(NSString *number, ABMultiValue *abNumbers)
{
  for (int i = 0; i < [abNumbers count]; i++) {
    if ([number isEqualToString:[abNumbers valueAtIndex:i]]) {
      return YES;
    }
  }
  
  return NO;
}

- (UpdateReturnValue)updateOtherPhoneNumbersForPerson:(ABPerson *)person withAddressData:(NSDictionary *)data
{
  UpdateReturnValue returnValue = nothingFoundAtSite;
  if (isCancelled) { return updateAborted; }
  
  NSString *homePhone = formatNumber([data valueForKey:kXPathCommonKeyHomePhone]);
  NSString *mobilePhone = formatNumber([data valueForKey:kXPathCommonKeyMobilePhone]);
  NSString *workPhone = formatNumber([data valueForKey:kXPathCommonKeyWorkPhone]);
  
  if (!homePhone && !mobilePhone && !workPhone) { return nothingFoundAtSite; }
  returnValue = informationAlreadyUpToDate;
  
  ABMultiValue *phones = [person valueForProperty:kABPhoneProperty];
  ABMutableMultiValue *newPhones = [[phones mutableCopy] autorelease];
  
  BOOL didAddValue = NO;
  
  if (homePhone && !numberExistsInAddressBook(homePhone, phones)) {
    [newPhones addValue:homePhone withLabel:kABPhoneHomeLabel];
    didAddValue = YES;
  }
  if (mobilePhone && !numberExistsInAddressBook(mobilePhone, phones)) {
    [newPhones addValue:mobilePhone withLabel:kABPhoneMobileLabel];
    didAddValue = YES;
  }
  if (workPhone && !numberExistsInAddressBook(workPhone, phones)) {
    [newPhones addValue:workPhone withLabel:kABPhoneWorkLabel];
    didAddValue = YES;
  }
  
  if (didAddValue) {
    [person setValue:newPhones forProperty:kABPhoneProperty];
    returnValue = informationUpdated;
  }
  
  return returnValue;
}


@end
