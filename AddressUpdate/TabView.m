
#import "TabView.h"

@implementation TabView

- (void)awakeFromNib
{
  [self setDelegate:self];
}

- (void)tabView:(NSTabView *)tabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem
{
  NSRect  frame;
  int    height;
  
  // Determine the height of the window based upon the selected tab
  // The identifier is a usually a string defined for each
  // tab through the Interface Builder info panel
  if ([[tabViewItem identifier] isEqualTo:@"sitePreferences"]) {
    height = 282;
    
  } else if ([[tabViewItem identifier] isEqualTo:@"addressDataDefinitions"]) {
    height = 440; 
  } else if ([[tabViewItem identifier] isEqualTo:@"generalPreferences"]) {
    height = 277;
  }
  
  // We now need to establish the new window frame.
  // First grab the current window frame and we will
  // adjust that.
  frame = [mainWindow frame];
  int winHeight = frame.size.height;
  
  // The "origin" of the frame is the bottom left corner
  // So we will need to change that along with the height
  // If we did not change the origin the window would
  // animate up rather than down. Try both ways.
  frame.size.height = height;
  frame.origin.y += (winHeight - height);
  
  // Now set the new window frame and animate it.
  [[tabView window] setFrame:frame display:YES animate:YES];
}

@end
