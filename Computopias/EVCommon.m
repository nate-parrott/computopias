//
//  EVCommon.m
//  Elastic
//
//  Created by Nate Parrott on 7/7/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import "EVCommon.h"

CGFloat EVPositionOfValueInBounds(CGFloat val, CGFloat low, CGFloat high) {
    return MAX(0, MIN(1, (val - low) / (high - low)));
}

NSInteger EVBinarySearch(NSInteger count, NSInteger (^block)(NSInteger index)) {
    NSInteger low = 0;
    NSInteger high = count;
    do {
        NSInteger oldLow = low;
        NSInteger oldHigh = high;
        
        NSInteger mid = (low + high)/2;
        NSInteger direction = block(mid);
        if (direction == -1) { // too low
            low = mid;
        } else if (direction == 1) { // too high
            high = mid;
        } else { // correct
            return mid;
        }
        if (low == oldLow && high == oldHigh) {
            return -1;
        }
    } while (low < high);
    return -1;
}

CATransform3D EVPerspectiveTransform(CGFloat perspective) {
    CATransform3D transform = CATransform3DIdentity;
    transform.m34 = 1.0 / (-2000 * perspective);
    return transform;
}

CGFloat EVRoundToScreenCoordinates(CGFloat val) {
    return round(val * [UIScreen mainScreen].scale) / [UIScreen mainScreen].scale;
}

#pragma mark Easing

// ported from https://github.com/warrenm/AHEasing/blob/master/AHEasing/easing.c

CGFloat EVQuadraticEaseIn(CGFloat p)
{
    return p * p;
}

// Modeled after the parabola y = -x^2 + 2x
CGFloat EVQuadraticEaseOut(CGFloat p)
{
    return -(p * (p - 2));
}

CGFloat EVQuadraticEaseInOut(CGFloat p)
{
    if(p < 0.5)
    {
        return 2 * p * p;
    }
    else
    {
        return (-2 * p * p) + (4 * p) - 1;
    }
}

@implementation NSObject (Elastic)

- (NSString *)EVPointerKey {
    return [NSValue valueWithNonretainedObject:self].description;
}

@end
