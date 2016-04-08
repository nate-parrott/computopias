//
//  ElasticValueInput.m
//  Elastic
//
//  Created by Nate Parrott on 7/15/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import "ElasticValueInput.h"

@interface ElasticValueInputGeneric ()

@property (nonatomic) NSMutableArray *targets, *actions;
@property (nonatomic) ElasticValueInputState elasticState;

@end

@implementation ElasticValueInputGeneric

- (void)addTarget:(id)target action:(SEL)action {
    if (!_targets) {
        _targets = [NSMutableArray new];
        _actions = [NSMutableArray new];
    }
    [_targets addObject:target];
    [_actions addObject:NSStringFromSelector(action)];
}

- (void)removeTarget:(id)target action:(SEL)action {
    NSInteger i = [_targets indexOfObject:target];
    [_targets removeObject:target];
    [_actions removeObjectAtIndex:i];
}

- (void)setDragging:(BOOL)dragging {
    if (dragging != _dragging) {
        _dragging = dragging;
        self.elasticState = dragging ? ElasticValueInputStateBegan : ElasticValueInputStateEnded;
        [self deliverEvents];
    }
}

- (void)setPosition:(CGFloat)position {
    _position = position;
    if (self.dragging) {
        self.elasticState = ElasticValueInputStateMoving;
        [self deliverEvents];
    }
}

- (void)deliverEvents {
    for (NSInteger i=0; i<_targets.count; i++) {
        id target = _targets[i];
        SEL sel = NSSelectorFromString(_actions[i]);
        [target performSelector:sel withObject:self._proxySender ? : self];
    }
}

@end