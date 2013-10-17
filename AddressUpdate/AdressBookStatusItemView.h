
#import <Cocoa/Cocoa.h>

@class CALayer, CAAnimation;

@interface AdressBookStatusItemView : NSImageView {

  CALayer       *backgroundLayer;
  CALayer       *sweeperLayer;
  CALayer       *traceLayer;
  CALayer       *spotLayer;
  CAAnimation   *rotationAnimation;
  CAAnimation   *pulseAnimation;
  
}

- (void)initLayers;
- (void)startRotationAnimation;
- (void)stopRotationAnimation;

@end
