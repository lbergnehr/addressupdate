//
//  StatusItemView.h
//  AddressUpdate
//
//  Created by Leo Bergnéhr on 2009-07-23.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class AdressBookStatusItemView;

@interface StatusItemView : NSView <NSMenuDelegate> {
  
  NSStatusItem *statusItem;
  BOOL isMenuVisible;
  AdressBookStatusItemView *imageView;
  
}

@property (retain, nonatomic) NSStatusItem *statusItem;

- (void)startRotationAnimation;
- (void)stopRotationAnimation;

@end