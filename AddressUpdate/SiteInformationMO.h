
#import <Cocoa/Cocoa.h>

// Core Data keys.
extern NSString * const kSiteURLAttribute;
extern NSString * const kSiteNameAttribute;
extern NSString * const kSiteXpathsRelationship;
extern NSString * const kSiteSearchAttributeAttribute;
extern NSString * const kSiteStringEncodingAttribute;

@interface SiteInformationMO : NSManagedObject {

}

- (BOOL)loadSiteFromFile:(NSString *)filePath error:(NSError **)error;

@end
