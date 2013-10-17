
#import "XPathsSortDescriptor.h"
#import "XPathMO.h"

static const NSDictionary * xpathCategories = nil;

static const NSString * nameCategory = @"nameCategory";
static const NSString *addressCategory = @"addressCategory";
static const NSString *phoneCategory = @"phoneCategory";

@implementation XPathsSortDescriptor

+ (void)initialize
{ 
  xpathCategories = [NSDictionary dictionaryWithObjectsAndKeys:
                     nameCategory, kXPathCommonKeyFirstName,
                     nameCategory, kXPathCommonKeySecondName,
                     
                     addressCategory, kXPathCommonKeyStreetAddress,
                     addressCategory, kXPathCommonKeyStreetNumber,
                     addressCategory, kXPathCommonKeyStreetNumberSuffix,
                     addressCategory, kXPathCommonKeyPostalCode,
                     addressCategory, kXPathCommonKeyLocality,
                     addressCategory, kXPathCommonKeyState,
                     
                     phoneCategory, kXPathCommonKeyHomePhone,
                     phoneCategory, kXPathCommonKeyWorkPhone,
                     phoneCategory, kXPathCommonKeyMobilePhone, nil];
  [xpathCategories retain];
}

- (NSComparisonResult)compareObject:(XPathMO *)object1 toObject:(XPathMO *)object2
{
  NSString *category1 = [xpathCategories valueForKey:[object1 valueForKey:kXPathNameAttribute]];
  NSString *category2 = [xpathCategories valueForKey:[object2 valueForKey:kXPathNameAttribute]];
  
  NSComparisonResult result = [self compareCategories:(NSString *)category1 toCategory:(NSString *)category2];
  return result;
}

- (NSComparisonResult)compareCategories:(NSString *)category1 toCategory:(NSString *)category2
{
  if (category1 == nameCategory) {
    if (category2 == nameCategory) {
      return NSOrderedSame;
    } else {
      return NSOrderedAscending;
    }
  } else if (category1 == addressCategory) {
    if (category2 == nameCategory) {
      return NSOrderedDescending;
    } else if (category2 == phoneCategory) {
      return NSOrderedAscending;
    } else {
      return NSOrderedSame;
    }
  } else if (category1 == phoneCategory) {
    if (category2 == phoneCategory) {
      return NSOrderedSame;
    } else {
      return NSOrderedDescending;
    }
  } else {
    NSLog(@"Unknown category: %@.", category1);
    return NSOrderedSame;
  }
}

@end
