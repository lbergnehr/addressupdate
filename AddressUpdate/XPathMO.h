
#import <Cocoa/Cocoa.h>

// Core Data keys.
extern NSString * const kXPathNameAttribute;
extern NSString * const kXPathPathAttribute;
extern NSString * const kXPathSiteRelationship;
extern NSString * const kXPathRegExpAttribute;

// Common XPath keys.
extern NSString * const kXPathCommonKeyStreetAddress;
extern NSString * const kXPathCommonKeyStreetNumber;
extern NSString * const kXPathCommonKeyStreetNumberSuffix;
extern NSString * const kXPathCommonKeyLocality;
extern NSString * const kXPathCommonKeyPostalCode;
extern NSString * const kXPathCommonKeyState;
extern NSString * const kXPathCommonKeyFirstName;
extern NSString * const kXPathCommonKeySecondName;
extern NSString * const kXPathCommonKeyHomePhone;
extern NSString * const kXPathCommonKeyMobilePhone;
extern NSString * const kXPathCommonKeyWorkPhone;

extern NSString * const kXPathAddedAttributeDisplayName;

@interface XPathMO : NSManagedObject
{
  
}

@property (assign, readonly, nonatomic) NSString *displayName;

+ (NSString *)displayNameForAttribute:(NSString *)attribute;

@end
