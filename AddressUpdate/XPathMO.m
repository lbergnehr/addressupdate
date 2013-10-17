
#import "XPathMO.h"

#pragma mark -
#pragma mark Key Constants

// Core Data keys.
NSString * const kXPathNameAttribute = @"name";
NSString * const kXPathPathAttribute = @"path";
NSString * const kXPathSiteRelationship = @"siteInformaion";
NSString * const kXPathRegExpAttribute = @"regExp";

// Common XPath keys.
NSString * const kXPathCommonKeyStreetAddress = @"streetAddress";
NSString * const kXPathCommonKeyStreetNumber = @"streetNumber";
NSString * const kXPathCommonKeyStreetNumberSuffix = @"streetNumberSuffix";
NSString * const kXPathCommonKeyLocality = @"locality";
NSString * const kXPathCommonKeyPostalCode = @"postalCode";
NSString * const kXPathCommonKeyState = @"state";
NSString * const kXPathCommonKeyFirstName = @"firstName";
NSString * const kXPathCommonKeySecondName = @"lastName";
NSString * const kXPathCommonKeyHomePhone = @"homePhone";
NSString * const kXPathCommonKeyMobilePhone = @"mobilePhone";
NSString * const kXPathCommonKeyWorkPhone = @"workPhone";

NSString * const kXPathAddedAttributeDisplayName = @"displayName";

static NSDictionary *displayNames = nil;

@implementation XPathMO

+ (NSString *)displayNameForAttribute:(NSString *)attribute
{
  if (!displayNames) {
    displayNames = [NSDictionary dictionaryWithObjectsAndKeys:
                    NSLocalizedString(@"First name", @"Collection view"), kXPathCommonKeyFirstName,
                    NSLocalizedString(@"Last name", @"Collection view"), kXPathCommonKeySecondName,
                    NSLocalizedString(@"Street address", @"Collection view"), kXPathCommonKeyStreetAddress,
                    NSLocalizedString(@"Street number", @"Collection view"), kXPathCommonKeyStreetNumber,
                    NSLocalizedString(@"Street number suffix", @"Collection view"), kXPathCommonKeyStreetNumberSuffix,
                    NSLocalizedString(@"Postal code", @"Collection view"), kXPathCommonKeyPostalCode,
                    NSLocalizedString(@"City", @"Collection view"), kXPathCommonKeyLocality,
                    NSLocalizedString(@"State", @"Collection view"), kXPathCommonKeyState,
                    NSLocalizedString(@"Home phone", @"Collection view"), kXPathCommonKeyHomePhone,
                    NSLocalizedString(@"Work phone", @"Collection view"), kXPathCommonKeyWorkPhone,
                    NSLocalizedString(@"Mobile phone", @"Collection view"), kXPathCommonKeyMobilePhone, nil];
    [displayNames retain];
  }
  
  NSString *displayName = [displayNames objectForKey:attribute];
  return displayName;
}

- (NSString *)displayName
{
  NSString *name = [self valueForKey:kXPathNameAttribute];
  NSString *displayName = [XPathMO displayNameForAttribute:name];
  return displayName;
}

@end
