//
//  EVScrollViewWrapper.m
//  Elastic
//
//  Created by Nate Parrott on 7/8/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import "EVScrollViewWrapper.h"
#import "UIView+Elastic.h"
#import "ElasticValue.h"

@interface EVScrollViewWrapper () <UIGestureRecognizerDelegate>

@property (nonatomic) ElasticValue *y;
@property (nonatomic) UIPanGestureRecognizer *panRec;
@property (nonatomic) CGPoint previousTranslation;
@property (nonatomic) CGFloat elasticValueMax;
@property (nonatomic) BOOL dragging;
@property (nonatomic) CGFloat translationThisFrame;

@end

@implementation EVScrollViewWrapper

- (void)elasticSetup {
    [super elasticSetup];
    self.panRec = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panned)];
    self.panRec.delegate = self;
    self.panRec.delaysTouchesBegan = NO;
    [self addGestureRecognizer:self.panRec];
}

- (void)elasticTick {
    [super elasticTick];
    
    // sync with scroll view:
    CGFloat scrollableDistance = MAX(0, self.scrollView.contentSize.height - self.scrollView.bounds.size.height);
    self.elasticValueMax = self.elasticValueMin + scrollableDistance * self.screenPointToElasticValueScale;
    BOOL touchIsDown = self.panRec.numberOfTouches > 0 || self.scrollView.dragging;
    self.dragging = touchIsDown || self.scrollView.decelerating;
    if (self.dragging) {
        if ([self scrollViewIsAtVerticalEdge] && touchIsDown) {
            if (self.scrollView.contentOffset.y == 0) {
                [self.elasticValue draggedToPosition:self.elasticValue.position - self.translationThisFrame * self.screenPointToElasticValueScale];
            } else {
                [self.elasticValue draggedToPosition:self.elasticValue.position - self.translationThisFrame * self.screenPointToElasticValueScale];
            }
        } else {
            [self.elasticValue draggedToPosition:self.scrollView.contentOffset.y * self.screenPointToElasticValueScale + self.elasticValueMin];
        }
    }
    self.scrollView.scrollEnabled = self.elasticValue.position >= self.elasticValueMin && self.elasticValue.position <= self.elasticValueMax;
    if (!self.dragging) {
        self.scrollView.contentOffset = CGPointMake(self.scrollView.contentOffset.x, EVPositionOfValueInBounds(self.elasticValue.position, self.elasticValueMin, self.elasticValueMax) * scrollableDistance);
    }
    self.translationThisFrame = 0;
}

- (void)setDragging:(BOOL)dragging {
    if (_dragging != dragging) {
        _dragging = dragging;
        if (dragging) [self.elasticValue startDragging];
        else [self.elasticValue stopDragging];
    }
}

- (BOOL)scrollViewIsAtVerticalEdge {
    return self.scrollView.contentOffset.y == 0 || self.scrollView.contentOffset.y + self.scrollView.bounds.size.height >= self.scrollView.contentSize.height;
}

- (void)panned {
    if (self.panRec.state == UIGestureRecognizerStateBegan) {
        self.previousTranslation = [self.panRec translationInView:self.window];
    } else if (self.panRec.state == UIGestureRecognizerStateChanged) {
        self.translationThisFrame += [self.panRec translationInView:self.window].y - self.previousTranslation.y;
        self.previousTranslation = [self.panRec translationInView:self.window];
    } else if (self.panRec.state == UIGestureRecognizerStateEnded || self.panRec.state == UIGestureRecognizerStateCancelled) {
        // pass
    }
}

- (BOOL)gestureRecognizer:(nonnull UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(nonnull UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

#pragma mark Child views

- (void)setScrollView:(UIScrollView *)scrollView {
    _scrollView = scrollView;
    scrollView.bounces = NO;
}

- (void)setSubview:(UIView *)subview {
    [_subview removeFromSuperview];
    _subview = subview;
    if (subview) {
        [self addSubview:subview];
        self.subview.frame = self.bounds;
        self.subview.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    }
}

@end
