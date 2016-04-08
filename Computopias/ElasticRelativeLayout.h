//
//  ElasticRelativeLayout.h
//  Elastic
//
//  Created by Nate Parrott on 7/12/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, ElasticDirection) {
    ElasticDirectionBefore,
    ElasticDirectionAfter
};

@interface UIView (ElasticRelativeLayout)

- (UIView *)elasticRenderRelativelyWithAnchorView:(UIView *)anchor previousViewBlock:(UIView*(^)(UIView *following))prev nextViewBlock:(UIView*(^)(UIView *preceding))next nextAnchorViewSelectionFunction:(CGFloat(^)(UIView *view))nextAnchor;

/*
 A simpler wrapper around the above function.
 The block is first called with (prevView=nil, offset=0), and should return the anchor view;
 it's then called with the either 
 (prevView=previousView, offset=1) or (prevView=nextView, offset=-1)
 */
- (UIView *)elasticRenderRelativelyWithNextViewBlock:(UIView*(^)(UIView *prevView, NSInteger offset))nextViewBlock;

@end
