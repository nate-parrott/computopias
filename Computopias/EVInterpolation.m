//
//  EVInterpolation.m
//  Elastic
//
//  Created by Nate Parrott on 6/29/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import "EVInterpolation.h"

CGRect EVInterpolateRect(CGRect r1, CGRect r2, CGFloat progress) {
    return (CGRect){EVInterpolatePoint(r1.origin, r2.origin, progress), EVInterpolateSize(r1.size, r2.size, progress)};
}

CGPoint EVInterpolatePoint(CGPoint sourceValue, CGPoint targetValue, CGFloat progress) {
    return CGPointMake(EVInterpolate(sourceValue.x, targetValue.x, progress), EVInterpolate(sourceValue.y, targetValue.y, progress));
}

CGSize EVInterpolateSize(CGSize s1, CGSize s2, CGFloat progress) {
    return CGSizeMake(EVInterpolate(s1.width, s2.width, progress), EVInterpolate(s1.height, s2.height, progress));
}

CGFloat EVInterpolate(CGFloat a1, CGFloat a2, CGFloat progress) {
    return a1 * (1-progress) + a2 * progress;
}

@implementation NSNumber (EVInterpolation)

- (instancetype)interpolatedWith:(id)other progress:(CGFloat)progress {
    return @([self doubleValue] * (1 - progress) + [other doubleValue]);
}

@end

@implementation NSValue (EVInterpolation)

- (instancetype)interpolatedWith:(id)target progress:(CGFloat)progress {
    // via https://github.com/rpetrich/CAKeyframeAnimation-Generation/blob/master/NSValue%2BInterpolation.m
    const char *sourceType = [self objCType];
    const char *targetType = [target objCType];
    if (strcmp(sourceType, targetType) != 0) {
        // Types don't match!
        return nil;
    }
    CGFloat remainingProgress = 1.0 - progress;
    if (strcmp(targetType, @encode(CGPoint)) == 0) {
        CGPoint sourceValue = [self CGPointValue];
        CGPoint targetValue = [target CGPointValue];
        CGPoint finalValue;
        finalValue.x = sourceValue.x * remainingProgress + targetValue.x * progress;
        finalValue.y = sourceValue.y * remainingProgress + targetValue.y * progress;
        return [NSValue valueWithCGPoint:finalValue];
    }
    if (strcmp(targetType, @encode(CGSize)) == 0) {
        CGSize sourceValue = [self CGSizeValue];
        CGSize targetValue = [target CGSizeValue];
        CGSize finalValue;
        finalValue.width = sourceValue.width * remainingProgress + targetValue.width * progress;
        finalValue.height = sourceValue.height * remainingProgress + targetValue.height * progress;
        return [NSValue valueWithCGSize:finalValue];
    }
    if (strcmp(targetType, @encode(CGRect)) == 0) {
        CGRect sourceValue = [self CGRectValue];
        CGRect targetValue = [target CGRectValue];
        CGRect finalValue;
        finalValue.origin.x = sourceValue.origin.x * remainingProgress + targetValue.origin.x * progress;
        finalValue.origin.y = sourceValue.origin.y * remainingProgress + targetValue.origin.y * progress;
        finalValue.size.width = sourceValue.size.width * remainingProgress + targetValue.size.width * progress;
        finalValue.size.height = sourceValue.size.height * remainingProgress + targetValue.size.height * progress;
        return [NSValue valueWithCGRect:finalValue];
    }
    return nil;
}

@end
