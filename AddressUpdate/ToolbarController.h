
#import <Cocoa/Cocoa.h>


@interface ToolbarController : NSToolbar {

  @private
  IBOutlet NSArrayController *usedXpaths;
  
  IBOutlet NSView *generalView;
  IBOutlet NSView *siteView;
  IBOutlet NSView *advancedView;
  IBOutlet NSToolbarItem *firstClickButton;
  
  IBOutlet NSWindow *mainWindow;
  IBOutlet NSView  *mainContentView;
  
  NSView *currentPreferencesView;
  NSArray *identifiers;
  
  NSUInteger lastNumberOfXpathViews;
}

- (IBAction)generalClick:(id)sender;
- (IBAction)siteClick:(id)sender;
- (IBAction)advancedClick:(id)sender;

- (void)xPathsChanged:(NSNotification *)note;
- (void)switchToWiew:(NSView *)newView;

@end
