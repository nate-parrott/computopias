//
//  ElasticReuseQueue.m
//  Elastic
//
//  Created by Nate Parrott on 7/14/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import "ElasticReuseQueue.h"
#import "UIView+Elastic.h"

@interface ElasticReuseQueue ()

@property (nonatomic) NSMutableArray *q;

@end

@implementation ElasticReuseQueue

- (instancetype)init {
    self = [super init];
    self.q = [NSMutableArray new];
    return self;
}

- (id)dequeueView {
    NSAssert(self.viewBlock, @"All ElasticReuseQueue instances need their viewBlock property set.");
    while (_q.count <= _minSize) {
        UIView *view = _viewBlock();
        [view _elasticSetReuseQueue:self];
        [_q addObject:view];
    }
    id view = _q.lastObject;
    [_q removeLastObject];
    return view;
}

- (void)addView:(UIView *)view {
    if (_q.count < _maxSize) {
        [_q addObject:view];
    }
}

@end
