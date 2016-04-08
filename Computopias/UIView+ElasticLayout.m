//
//  UIView+ElasticLayout.m
//  Elastic
//
//  Created by Nate Parrott on 7/7/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import "UIView+ElasticLayout.h"
#import "EVCommon.h"

@implementation UIView (ElasticLayout)

- (void)elasticRenderModels:(NSArray *)models positionBlock:(ElasticLayoutModelPosition (^)(id model, NSInteger index))positionBlock renderBlock:(void (^)(id model, NSInteger index))renderBlock {
    if (models.count == 0) return;
    
    NSInteger firstOnscreenIndex = EVBinarySearch(models.count, ^NSInteger(NSInteger index) {
        ElasticLayoutModelPosition position = positionBlock(models[index], index);
        if (position == ElasticLayoutModelPositionOnscreen) {
            if (index == 0 || positionBlock(models[index-1], index-1) == ElasticLayoutModelPositionBeforeScreen) {
                return 0;
            }
        }
        if (position == ElasticLayoutModelPositionBeforeScreen) {
            return -1;
        } else {
            return 1;
        }
    });
    NSInteger lastOnscreenIndex = EVBinarySearch(models.count, ^NSInteger(NSInteger index) {
        ElasticLayoutModelPosition position = positionBlock(models[index], index);
        if (position == ElasticLayoutModelPositionOnscreen) {
            if (index+1 == models.count || positionBlock(models[index+1], index+1) == ElasticLayoutModelPositionAfterScreen) {
                return 0;
            }
        }
        if (position == ElasticLayoutModelPositionAfterScreen) {
            return 1;
        } else {
            return -1;
        }
    });
    if (firstOnscreenIndex > -1 && lastOnscreenIndex > -1) {
        for (NSInteger i=firstOnscreenIndex; i<=lastOnscreenIndex; i++) {
            renderBlock(models[i], i);
        }
    }
}

@end
