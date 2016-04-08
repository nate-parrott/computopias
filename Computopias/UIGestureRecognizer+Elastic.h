//
//  UIGestureRecognizer+Elastic.h
//  Elastic
//
//  Created by Nate Parrott on 6/30/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ElasticValue.h"

@interface UIGestureRecognizer (Elastic) <ElasticValueInput>

@end

@interface UIPanGestureRecognizer (Elastic)

- (CGFloat)horizontalTranslationInView:(UIView *)view;
- (CGFloat)verticalTranslationInView:(UIView *)view;

@end
