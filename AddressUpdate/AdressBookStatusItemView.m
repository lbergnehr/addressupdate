//
//  ImageViewIgnoringClicks.m
//  AddressUpdate
//
//  Created by Leo Bergnéhr on 2009-07-24.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "AdressBookStatusItemView.h"
#import <QuartzCore/CoreAnimation.h>
#import "NSImage-Extras.h"


@implementation AdressBookStatusItemView

CAAnimation * createRotationAnimation(NSTimeInterval duration)
{
  CABasicAnimation *animation = [[CABasicAnimation animation] retain];
  CATransform3D t = CATransform3DMakeRotation(pi, 0, 0, 1);
  
  animation.keyPath = @"transform";
  animation.fromValue = nil;
  animation.toValue = [NSValue valueWithCATransform3D:t];
  animation.duration = duration / 2.0;
  animation.repeatCount = 1e100f;
  animation.cumulative = YES;
  animation.removedOnCompletion = YES;
  
  return animation;
}

CAAnimation * createPulseAnimation(NSTimeInterval duration, NSTimeInterval interval, NSTimeInterval offset)
{
  CABasicAnimation *animation = [CABasicAnimation animation];
  
  animation.keyPath = @"opacity";
  animation.fromValue = [NSNumber numberWithFloat:0.0];
  animation.toValue = [NSNumber numberWithFloat:1.0];
  animation.duration = duration / 2.0;
  animation.removedOnCompletion = YES;
  animation.autoreverses = YES;
  animation.beginTime = offset;
  
  CAAnimationGroup *group = [[CAAnimationGroup animation] retain];
  
  group.duration = interval;
  group.removedOnCompletion = YES;
  group.repeatCount = 1e100f;
  
  [group setAnimations:[NSArray arrayWithObject:animation]];
  
  return group;
}

- (id)initWithFrame:(NSRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    
    rotationAnimation = nil;
    pulseAnimation = nil;
    
    [self initLayers];
    [self setWantsLayer:YES];
    
    //[self startRotationAnimation];
  }
  return self;
}

- (void)dealloc
{
  [rotationAnimation release];
  [pulseAnimation release];
  [super dealloc];
}

- (NSView *)hitTest:(NSPoint)point
{
  return nil;
}

- (void)initLayers
{
  CGRect bounds = CGRectMake(0, 0, 16, 16);
  
  CALayer *viewLayer = [CALayer layer];
  viewLayer.bounds = NSRectToCGRect([self bounds]);
  viewLayer.layoutManager = [CAConstraintLayoutManager layoutManager];
  viewLayer.frame = NSRectToCGRect([self frame]);
  
  NSImage *backgroundImage = [NSImage imageNamed:@"AddresUpdateStatusBarBackground"];
  CGImageRef backgroundImageRef = [backgroundImage copyAsCgImage];
  backgroundLayer = [CALayer layer];
  backgroundLayer.bounds = bounds;
  backgroundLayer.contents = (id)backgroundImageRef;
  backgroundLayer.contentsGravity = kCAGravityResizeAspect;
  backgroundLayer.name = @"backgroundLayer";
  [viewLayer addSublayer:backgroundLayer];
  [backgroundLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMidX relativeTo:@"superlayer" attribute:kCAConstraintMidX offset:0.0]];
  [backgroundLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMaxY relativeTo:@"superlayer" attribute:kCAConstraintMaxY offset:0.0]];
  
  NSImage *sweeperImage = [NSImage imageNamed:@"AddresUpdateStatusBarSweeper"];
  CGImageRef sweeperImageRef = [sweeperImage copyAsCgImage];
  sweeperLayer = [CALayer layer];
  sweeperLayer.bounds = bounds;
  sweeperLayer.zPosition = -1;
  sweeperLayer.contents = (id)sweeperImageRef;
  sweeperLayer.contentsGravity = kCAGravityResizeAspect;
  sweeperLayer.name = @"sweeperLayer";
  [viewLayer addSublayer:sweeperLayer];
  [sweeperLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMidX relativeTo:@"superlayer" attribute:kCAConstraintMidX offset:0.0]];
  [sweeperLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMaxY relativeTo:@"superlayer" attribute:kCAConstraintMaxY offset:0.0]];
  
  NSImage *traceImage = [NSImage imageNamed:@"AddresUpdateStatusBarTrace"];
  CGImageRef traceImageRef = [traceImage copyAsCgImage];
  traceLayer = [CALayer layer];
  traceLayer.bounds = bounds;
  traceLayer.opacity = 0.0;
  traceLayer.zPosition = -2;
  traceLayer.contents = (id)traceImageRef;
  traceLayer.contentsGravity = kCAGravityResizeAspect;
  traceLayer.name = @"traceLayer";
  [viewLayer addSublayer:traceLayer];
  [traceLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMidX relativeTo:@"superlayer" attribute:kCAConstraintMidX offset:0.0]];
  [traceLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMaxY relativeTo:@"superlayer" attribute:kCAConstraintMaxY offset:0.0]];  
  
  NSImage *spotImage = [NSImage imageNamed:@"AddresUpdateStatusBarSpot"];
  CGImageRef spotImageRef = [spotImage copyAsCgImage];
  spotLayer = [CALayer layer];
  spotLayer.bounds = bounds;
  spotLayer.opacity = 0.0;
  spotLayer.zPosition = 5;
  spotLayer.contents = (id)spotImageRef;
  spotLayer.contentsGravity = kCAGravityResizeAspect;
  spotLayer.name = @"spotLayer";
  [viewLayer addSublayer:spotLayer];
  [spotLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMidX relativeTo:@"superlayer" attribute:kCAConstraintMidX offset:0.0]];
    [spotLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMaxY relativeTo:@"superlayer" attribute:kCAConstraintMaxY offset:0.0]];
  
  [self setLayer:viewLayer];
}

- (void)startRotationAnimation
{
  if (!rotationAnimation) {
    rotationAnimation = createRotationAnimation(2.6);
  }
  if (!pulseAnimation) {
    pulseAnimation = createPulseAnimation(0.8, 2.6, 1.8);
  }
  
  if (![sweeperLayer animationForKey:@"rotationAnimation"]) {
    traceLayer.opacity = 1.0;
    [sweeperLayer addAnimation:rotationAnimation forKey:@"rotationAnimation"];
    [traceLayer addAnimation:rotationAnimation forKey:@"rotationAnimation"];
  }
  if (![spotLayer animationForKey:@"pulseAnimation"]) {
    [spotLayer addAnimation:pulseAnimation forKey:@"pulseAnimation"];
  }
}

- (void)stopRotationAnimation
{
  traceLayer.opacity = 0.0;
  [sweeperLayer removeAllAnimations];
  [traceLayer removeAllAnimations];
  [spotLayer removeAllAnimations];
}

@end
