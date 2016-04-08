//
//  ElasticRelativeLayout.m
//  Elastic
//
//  Created by Nate Parrott on 7/12/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import "ElasticRelativeLayout.h"
#import "UIView+Elastic.h"

@implementation UIView (ElasticRelativeLayout)

- (UIView *)elasticRenderRelativelyWithAnchorView:(UIView *)anchor previousViewBlock:(UIView*(^)(UIView *following))prev nextViewBlock:(UIView*(^)(UIView *preceding))next nextAnchorViewSelectionFunction:(CGFloat(^)(UIView *view))nextAnchorFunc {
    if (!anchor) return nil;
    NSMutableArray *views = [NSMutableArray arrayWithObject:anchor];
    UIView *prevView = anchor;
    while ((prevView = prev(prevView))) [views addObject:prevView];
    UIView *nextView = anchor;
    while ((nextView = next(nextView))) [views addObject:nextView];
    
    UIView *nextAnchor = anchor;
    CGFloat nextAnchorScore = nextAnchorFunc(nextAnchor);
    for (UIView *view in views) {
        CGFloat score = nextAnchorFunc(view);
        if (score > nextAnchorScore) {
            nextAnchor = view;
            nextAnchorScore = score;
        }
    }
    return nextAnchor;
}

- (UIView *)elasticRenderRelativelyWithNextViewBlock:(UIView*(^)(UIView *prevView, NSInteger offset))nextViewBlock {
    return [self elasticRenderRelativelyWithAnchorView:nextViewBlock(nil, 0) previousViewBlock:^UIView *(UIView *following) {
        return nextViewBlock(following, -1);
    } nextViewBlock:^UIView *(UIView *preceding) {
        return nextViewBlock(preceding, 1);
    } nextAnchorViewSelectionFunction:^CGFloat(UIView *view) {
        return -sqrt(pow(view.frame.origin.x, 2) + pow(view.frame.origin.y, 2));
    }];
}

@end
