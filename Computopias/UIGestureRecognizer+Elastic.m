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

@implementation UIPanGestureRecognizer (Elastic)

- (CGFloat)horizontalTranslationInView:(UIView *)view {
    CGPoint t = [self translationInView:view];
    return [self translationWithMainDimension:t.x otherDimension:t.y];
}

- (CGFloat)verticalTranslationInView:(UIView *)view {
    CGPoint t = [self translationInView:view];
    return [self translationWithMainDimension:t.y otherDimension:t.x];
}

- (CGFloat)translationWithMainDimension:(CGFloat)main otherDimension:(CGFloat)other {
    if (other == 0) return main;
    
    CGFloat distance = sqrt(pow(main, 2) + pow(other, 2));
    CGFloat distanceProgress = MIN(1, distance / 5);
    
    CGFloat ratio = fabs(main / other);
    CGFloat directionCorrectness = EVPositionOfValueInBounds(ratio, 0.5, 1);
    
    return main * directionCorrectness * distanceProgress + main * (1 - distanceProgress);
}

@end
