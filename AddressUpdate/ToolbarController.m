
#import "ToolbarController.h"

static const CGFloat windowResizeOffset     = 150.0;
static const CGFloat xPathViewOffset        = 27.0;
static const CGFloat initialXpathViewOffset = 70.0;

@implementation ToolbarController

- (void)awakeFromNib
{
  currentPreferencesView = nil;
  identifiers = nil;
  lastNumberOfXpathViews = 0;
  
  NSString *selectedIdentifier = [firstClickButton itemIdentifier];
  [[firstClickButton toolbar] setSelectedItemIdentifier:selectedIdentifier];
  [self switchToWiew:generalView];
  
  // Observe the changes in the XPath collection.
  NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
  [center addObserver:self selector:@selector(xPathsChanged:) name:@"XPathCollectionChanged" object:nil];
}

- (void)dealloc
{
  [identifiers release];
  [super dealloc];
}

- (void)xPathsChanged:(NSNotification *)note
{ 
  [self switchToWiew:nil];
}

- (IBAction)generalClick:(id)sender
{
  [self switchToWiew:generalView];
}

- (IBAction)siteClick:(id)sender
{
  [self switchToWiew:siteView];
}

- (IBAction)advancedClick:(id)sender
{
  [self switchToWiew:advancedView];
}

- (void)switchToWiew:(NSView *)newView
{
  NSRect frame;
  int height;
  
  NSUInteger numberOfXpathViews = [[usedXpaths arrangedObjects] count];
  if (newView && newView != siteView) {
    height = [newView bounds].size.height + windowResizeOffset;
  } else {
    height = windowResizeOffset + (numberOfXpathViews * xPathViewOffset) + initialXpathViewOffset;
    [siteView setFrame:NSMakeRect(0, 0, [siteView bounds].size.width, numberOfXpathViews * xPathViewOffset + initialXpathViewOffset)];
  }
  
  frame = [mainWindow frame];
  int winHeight = frame.size.height;
  
  frame.size.height = height;
  frame.origin.y += (winHeight - height);
  
  // Now set the new window frame and animate it.
  [mainWindow setFrame:frame display:YES animate:YES];
  
  if (newView) {
    if (currentPreferencesView) {
      [[mainContentView animator] replaceSubview:[currentPreferencesView retain] with:newView];
      [newView setFrameOrigin:NSZeroPoint];
    } else {
      [[mainContentView animator] addSubview:newView];
      [newView setFrameOrigin:NSZeroPoint];
    }
    
    currentPreferencesView = newView;
  } else {
    [siteView setFrameOrigin:NSZeroPoint];
  }
  
  lastNumberOfXpathViews = numberOfXpathViews;
}

- (NSArray *)toolbarSelectableItemIdentifiers:(NSToolbar *)toolbar
{
  if (!identifiers) {
    NSArray *items = [toolbar items];
    identifiers = [[items valueForKey:@"itemIdentifier"] retain];
  }
  
  return identifiers;
}

@end
