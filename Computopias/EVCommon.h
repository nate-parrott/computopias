//
//  EVCommon.h
//  Elastic
//
//  Created by Nate Parrott on 7/7/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import <UIKit/UIKit.h>

#ifndef weakify

#define metamacro_concat(A, B) A ## B
#define weakify(VAR) \
autoreleasepool {} \
__weak __typeof__(VAR) metamacro_concat(VAR, _weak_) = (VAR)
#define strongify(VAR) \
autoreleasepool {} \
_Pragma("clang diagnostic push") \
_Pragma("clang diagnostic ignored \"-Wshadow\"") \
__strong __typeof__(VAR) VAR = metamacro_concat(VAR, _weak_)\
_Pragma("clang diagnostic pop")

#endif

#define EV1Pixel (1 / [[UIScreen mainScreen] scale])

CGFloat EVPositionOfValueInBounds(CGFloat val, CGFloat low, CGFloat high);

/*
 block should return either:
 -1: too low
 0: correct
 1: too high
 */
NSInteger EVBinarySearch(NSInteger count, NSInteger (^block)(NSInteger index));

CATransform3D EVPerspectiveTransform(CGFloat perspective); // perspective=1 is a reasonable value

CGFloat EVRoundToScreenCoordinates(CGFloat val);

typedef void (^EVCallback)();


CGFloat EVQuadraticEaseIn(CGFloat p);
CGFloat EVQuadraticEaseOut(CGFloat p);
CGFloat EVQuadraticEaseInOut(CGFloat p);

@interface NSObject (Elastic)

- (NSString *)EVPointerKey;

@end
