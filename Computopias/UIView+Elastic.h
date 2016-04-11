//
//  UIView+Elastic.h
//  Elastic
//
//  Created by Nate Parrott on 6/29/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ElasticReuseQueue.h"

// TODO: make private
@class _ElasticMetadata;

@interface UIView (Elastic)

- (void)elasticSetup;
- (void)elasticRender;
- (void)elasticTick; // called before -elasticRender; useful for sending callbacks that should alter superviews' layout in the current frame

- (_Nonnull id)elasticGetChildWithKey:(NSString * _Nonnull)key creationBlock:(UIView*_Nonnull(^_Nonnull)())creationBlock;
- (_Nullable id)elasticGetChildWithKeyIfPresent:(NSString  * _Nonnull )key;
- (_Nullable id)elasticGetChildWithKey:(NSString * _Nonnull)key possiblyCreateWithCost:(double)cost block:(UIView*_Nonnull(^_Nonnull)())creationBlock;

- (ElasticReuseQueue *)elasticReuseQueueForIdentifier:(NSString *)reuseIdentifier;

#pragma mark Private
- (NSInteger)_elasticDepthInTree;
- (void)_elasticSetReuseQueue:(ElasticReuseQueue *)queue;
- (_ElasticMetadata *)_getElasticMetadata:(BOOL)create;

@end
