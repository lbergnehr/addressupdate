
#import "SiteInformationMO.h"
#import "XPathMO.h"

#pragma mark -
#pragma mark Key Constants

// Core Data keys.
NSString * const kSiteURLAttribute = @"url";
NSString * const kSiteNameAttribute = @"name";
NSString * const kSiteXpathsRelationship = @"xpaths";
NSString * const kSiteSearchAttributeAttribute = @"searchAttribute";
NSString * const kSiteStringEncodingAttribute = @"stringEncoding";

@implementation SiteInformationMO

- (BOOL)loadSiteFromFile:(NSString *)filePath error:(NSError **)error;
{
	if (!filePath) { [NSException raise:@"ArgumentNilException" format:@"File path was nil when loading site configuration."]; }
	
	//NSString *errorInfo = NSLocalizedString(@"Could not load site configuration.", @"Main description when loading ausites.");
	NSDictionary *ausite = [NSDictionary dictionaryWithContentsOfFile:filePath];
	if (!ausite) {
		NSString *errorReason = NSLocalizedString(@"Could not load the site configuration file from \"%@\". Make sure the file has the right format.", @"When loading an ausite file which cannot be loaded into a dictionary.");
		NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:errorReason, NSLocalizedFailureReasonErrorKey, nil];
		if (error != NULL) {
			*error = [NSError errorWithDomain:@"AUSite" code:1 userInfo:userInfo];
		}
		return NO;
	}
	
	NSArray *siteKeys = [NSArray arrayWithObjects:kSiteNameAttribute, kSiteURLAttribute, kSiteSearchAttributeAttribute, kSiteStringEncodingAttribute, nil];
	NSDictionary  *siteValues   = [ausite dictionaryWithValuesForKeys:siteKeys];
	NSArray       *xpaths       = [ausite valueForKey:kSiteXpathsRelationship];
	
	if ([[siteValues allValues] containsObject:[NSNull null]]) {
		NSString *errorReason = NSLocalizedString(@"One ore more of the keys: \"name\", \"url\", \"searchAttribute\", \"stringEncoding\" or \"xpaths\" were not specified.", @"When loading an ausite configuration.");
		NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:errorReason, NSLocalizedFailureReasonErrorKey, nil];
		if (error != NULL) {
			*error = [NSError errorWithDomain:@"AUSite" code:2 userInfo:userInfo];
		}
		return NO;
	}
	
	// Create a XPathMO for each xpath entry.
	NSMutableSet *xpathSet = [NSMutableSet setWithCapacity:[xpaths count]];
	for (NSDictionary *xpathInfo in xpaths) {
		NSArray *keys = [NSArray arrayWithObjects:kXPathNameAttribute, kXPathPathAttribute, kXPathRegExpAttribute, nil];
		NSDictionary *values = [xpathInfo dictionaryWithValuesForKeys:keys];
		
		if ([values valueForKey:kXPathNameAttribute] == [NSNull null]) {
			NSString *errorReason = NSLocalizedString(@"A value for the name key must be provided for all XPath definitions.", @"Error when no name is given for the xpath key name when loading an ausite.");
			NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:errorReason, NSLocalizedFailureReasonErrorKey, nil];
			if (error != NULL) {
				*error = [NSError errorWithDomain:@"AUSite" code:3 userInfo:userInfo];
			}
			return NO;
		}
		
		NSEntityDescription *entity = [NSEntityDescription entityForName:@"XPath" inManagedObjectContext:[self managedObjectContext]];
		XPathMO *xpath = [[[XPathMO alloc] initWithEntity:entity insertIntoManagedObjectContext:[self managedObjectContext]] autorelease];
		[xpath setValuesForKeysWithDictionary:values];
		[xpathSet addObject:xpath];
	}
	
	// Set the content.
	[self setValuesForKeysWithDictionary:siteValues];
	[self setValue:[[xpathSet copy] autorelease] forKey:kSiteXpathsRelationship];
	
	return YES;
}

@end
