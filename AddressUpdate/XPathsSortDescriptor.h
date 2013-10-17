
#import <Cocoa/Cocoa.h>


@interface XPathsSortDescriptor : NSSortDescriptor {

}

- (NSComparisonResult)compareCategories:(NSString *)category1 toCategory:(NSString *)category2;

@end
