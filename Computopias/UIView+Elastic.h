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

- (id)elasticGetChildWithKey:(NSString *)key creationBlock:(UIView*(^)())creationBlock;
- (id)elasticGetChildWithKeyIfPresent:(NSString *)key;

- (ElasticReuseQueue *)elasticReuseQueueForIdentifier:(NSString *)reuseIdentifier;

#pragma mark Private
- (NSInteger)_elasticDepthInTree;
- (void)_elasticSetReuseQueue:(ElasticReuseQueue *)queue;
- (_ElasticMetadata *)_getElasticMetadata:(BOOL)create;

@end
