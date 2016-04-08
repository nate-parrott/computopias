//
//  UIView+ElasticLayout.h
//  Elastic
//
//  Created by Nate Parrott on 7/7/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, ElasticLayoutModelPosition) {
    ElasticLayoutModelPositionOnscreen,
    ElasticLayoutModelPositionBeforeScreen,
    ElasticLayoutModelPositionAfterScreen
};

@interface UIView (ElasticLayout)

- (void)elasticRenderModels:(NSArray *)models positionBlock:(ElasticLayoutModelPosition (^)(id model, NSInteger index))positionBlock renderBlock:(void (^)(id model, NSInteger index))renderBlock;

@end
