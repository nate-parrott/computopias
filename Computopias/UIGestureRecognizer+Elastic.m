//
//  UIGestureRecognizer+Elastic.m
//  Elastic
//
//  Created by Nate Parrott on 6/30/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import "UIGestureRecognizer+Elastic.h"
#import "EVInterpolation.h"
#import "EVCommon.h"
#import <UIKit/UIGestureRecognizerSubclass.h>

@implementation UIGestureRecognizer (Elastic)

- (ElasticValueInputState)elasticState {
    if (self.state == UIGestureRecognizerStateBegan) {
        return ElasticValueInputStateBegan;
    } else if (self.state == UIGestureRecognizerStateChanged) {
        return ElasticValueInputStateMoving;
    } else if (self.state == UIGestureRecognizerStateEnded) {
        return ElasticValueInputStateEnded;
    } else if (self.state == UIGestureRecognizerStateCancelled) {
        return ElasticValueInputStateCancelled;
    }
    return ElasticValueInputStateEnded;
}

@end

#define VERTICAL 1
#define HORIZONTAL 2

@implementation UIPanGestureRecognizer (Elastic)

+ (NSMapTable *)gestureRecognizersThatAreDirectionLocked {
    static NSMapTable *a;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        a = [[NSMapTable alloc] initWithKeyOptions:NSPointerFunctionsWeakMemory|NSPointerFunctionsOpaquePersonality valueOptions:NSPointerFunctionsStrongMemory capacity:0];
    });
    return a;
}

- (void)setState:(UIGestureRecognizerState)state {
    [super setState:state];
    if (state != UIGestureRecognizerStateChanged && state != UIGestureRecognizerStateRecognized) {
        [[[self class] gestureRecognizersThatAreDirectionLocked] removeObjectForKey:self];
    }
}

- (CGFloat)horizontalTranslationInView:(UIView *)view {
    CGPoint t = [self translationInView:view];
    return [self translationWithMainDimension:t.x otherDimension:t.y direction:HORIZONTAL];
}

- (CGFloat)verticalTranslationInView:(UIView *)view {
    CGPoint t = [self translationInView:view];
    return [self translationWithMainDimension:t.y otherDimension:t.x direction:VERTICAL];
}

- (CGFloat)translationWithMainDimension:(CGFloat)main otherDimension:(CGFloat)other direction:(NSInteger)dir {
    NSInteger lock = [[[[self class] gestureRecognizersThatAreDirectionLocked] objectForKey:self] integerValue];
    if (lock) {
        return lock == dir ? main : 0;
    }
    if (other == 0) return main;
    
    CGFloat distance = sqrt(pow(main, 2) + pow(other, 2));
    CGFloat distanceProgress = MIN(1, distance / 10);
    
    CGFloat ratio = fabs(main / other);
    CGFloat directionCorrectness = EVPositionOfValueInBounds(ratio, 0.5, 1);
    
    if (directionCorrectness == 1 && distance > 10) {
        [[[self class] gestureRecognizersThatAreDirectionLocked] setObject:@(dir) forKey:self];
    }
    
    return main * directionCorrectness * distanceProgress + main * (1 - distanceProgress);
}

@end
