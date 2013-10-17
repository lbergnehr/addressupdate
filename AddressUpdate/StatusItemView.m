//
//  StatusItemView.m
//  AddressUpdate
//
//  Created by Leo Bergnéhr on 2009-07-23.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "StatusItemView.h"
#import "AdressBookStatusItemView.h"


@implementation StatusItemView

@synthesize statusItem;

- (id)initWithFrame:(NSRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    statusItem = nil;
    isMenuVisible = NO;
    imageView = [[[AdressBookStatusItemView alloc] initWithFrame:frame] autorelease];
    [self addSubview:imageView];
  }
  return self;
}

- (void)dealloc {
  [statusItem release];
  [super dealloc];
}

- (void)mouseDown:(NSEvent *)event {
  [[self menu] setDelegate:self];
  [statusItem popUpStatusItemMenu:[self menu]];
  [self setNeedsDisplay:YES];
}

- (void)rightMouseDown:(NSEvent *)event {
  // Treat right-click just like left-click
  [self mouseDown:event];
}

- (void)menuWillOpen:(NSMenu *)menu {
  isMenuVisible = YES;
  [self setNeedsDisplay:YES];
}

- (void)menuDidClose:(NSMenu *)menu {
  isMenuVisible = NO;
  [menu setDelegate:nil];    
  [self setNeedsDisplay:YES];
}

- (void)drawRect:(NSRect)rect {
  // Draw status bar background, highlighted if menu is showing
  [statusItem drawStatusBarBackgroundInRect:[self bounds]
                              withHighlight:isMenuVisible];
}

- (void)startRotationAnimation
{
  [imageView startRotationAnimation];
}

- (void)stopRotationAnimation
{
  [imageView stopRotationAnimation];
}

@end
