//
//  UIView+Elastic.m
//  Elastic
//
//  Created by Nate Parrott on 6/29/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import "UIView+Elastic.h"
#import <objc/runtime.h>
#import "ElasticValue.h"
#import "EVCommon.h"

@interface _ElasticInfo : NSObject
// information about views that are IN THE ELASTIC RENDER LOOP

@property (nonatomic) NSMutableDictionary *childViewsForKey;
@property (nonatomic) NSMutableSet *keysAccessedThisFrame;

@end

@implementation _ElasticInfo

- (instancetype)init {
    self = [super init];
    return self;
}

- (NSMutableDictionary *)childViewsForKey {
    if (!_childViewsForKey) _childViewsForKey = [NSMutableDictionary new];
    return _childViewsForKey;
}

@end


@interface _ElasticMetadata : NSObject
// metadata elastic holds about views

@property (nonatomic) NSMutableDictionary *reuseQueues;
@property (nonatomic) ElasticReuseQueue *belongsToReuseQueue;

@end

@implementation _ElasticMetadata

@end


@interface _ElasticManager : NSObject {
    NSMutableArray *_viewsToRender;
}

@property (nonatomic) BOOL running;
@property (nonatomic) NSMapTable *elasticViewInfo;
@property (nonatomic) CADisplayLink *displayLink;
@property (nonatomic) BOOL midRender;

@end

@implementation _ElasticManager

+ (instancetype)shared {
    static _ElasticManager *shared;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [_ElasticManager new];
    });
    return shared;
}

- (void)addElasticView:(UIView *)view {
    if (!self.elasticViewInfo) {
        self.elasticViewInfo = [[NSMapTable alloc] initWithKeyOptions:NSPointerFunctionsOpaquePersonality|NSPointerFunctionsWeakMemory valueOptions:NSPointerFunctionsStrongMemory capacity:1];
    }
    [self.elasticViewInfo setObject:[_ElasticInfo new] forKey:view];
    self.running = self.elasticViewInfo.count > 0;
    if (self.midRender) {
        [_viewsToRender addObject:view];
    }
}

- (void)removeElasticView:(UIView *)view {
    [self.elasticViewInfo removeObjectForKey:view];
    self.running = self.elasticViewInfo.count > 0;
}

- (void)setRunning:(BOOL)running {
    if (running != _running) {
        _running = running;
        if (running) {
            _displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(render)];
            [_displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
        } else {
            [_displayLink invalidate];
            _displayLink = nil;
        }
    }
}

- (void)render {
    // TODO: optimize this
    [self _performBlockOnParticipatingViews:^(UIView *view) {
        _ElasticInfo *info = [_elasticViewInfo objectForKey:view];
        info.keysAccessedThisFrame = [NSMutableSet new]; // reset keys before render()
        [view elasticTick];
    }];
    [self _performBlockOnParticipatingViews:^(UIView *view) {
        [self render:view];
    }];
}

- (void)_performBlockOnParticipatingViews:(void (^)(UIView *))block {
    [ElasticValue _updateAllWithDt:self.displayLink.duration];
    self.midRender = YES;
    _viewsToRender = [NSMutableArray new];
    for (UIView *v in _elasticViewInfo.keyEnumerator) {
        [_viewsToRender addObject:v];
    }
    [_viewsToRender sortUsingComparator:^NSComparisonResult(id  __nonnull obj1, id  __nonnull obj2) {
        NSInteger diff = [obj1 _elasticDepthInTree] - [obj2 _elasticDepthInTree];
        return diff < 0 ? NSOrderedAscending : (diff == 0 ? NSOrderedSame : NSOrderedDescending);
    }];
    
    while (_viewsToRender.firstObject) {
        UIView *view = _viewsToRender.firstObject;
        block(view);
        if (_viewsToRender.firstObject == view) {
            [_viewsToRender removeObjectAtIndex:0];
        }
    }
    self.midRender = NO;
}

- (void)render:(UIView *)view {
    _ElasticInfo *info = [_elasticViewInfo objectForKey:view];
    [view layoutIfNeeded];
    [view elasticRender];
    for (NSString *key in info.childViewsForKey.allKeys) {
        if (![info.keysAccessedThisFrame containsObject:key]) {
            // remove this child:
            UIView *childView = info.childViewsForKey[key];
            [childView removeFromSuperview];
            [info.childViewsForKey removeObjectForKey:key];
            [_viewsToRender removeObject:childView]; // TODO: improve time complexity of this operation
            [[[childView _getElasticMetadata:NO] belongsToReuseQueue] addView:childView];
        }
    }
}

@end



@implementation UIView (Elastic)

- (BOOL)_elasticHasCustomImplementation {
    return [self _elasticHasCustomImplementationForSelector:@selector(elasticRender)] || [self _elasticHasCustomImplementationForSelector:@selector(elasticSetup)] || [self _elasticHasCustomImplementationForSelector:@selector(elasticTick)];
}

- (BOOL)_elasticHasCustomImplementationForSelector:(SEL)selector {
    return class_getInstanceMethod([self class], selector) != class_getInstanceMethod([UIView class], selector);
}

- (void)willMoveToWindow:(nullable UIWindow *)newWindow {
    // API docs say the default imp. of -willMoveToWindow: does nothing,
    // so it's safe to override
    if ([self _elasticHasCustomImplementation]) {
        if (!!newWindow != !!self.window) {
            if (newWindow) {
                [[_ElasticManager shared] addElasticView:self];
                if (!objc_getAssociatedObject(self, @selector(elasticSetup))) {
                    objc_setAssociatedObject(self, @selector(elasticSetup), @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
                    [self elasticSetup];
                }
            } else {
                [[_ElasticManager shared] removeElasticView:self];
            }
        }
    }
}

- (_ElasticInfo *)_getElasticInfoIfExists {
    _ElasticManager *manager = [_ElasticManager shared];
    return [[manager elasticViewInfo] objectForKey:self];
}

- (_ElasticInfo *)_getElasticInfo {
    _ElasticManager *manager = [_ElasticManager shared];
    _ElasticInfo *info = [[manager elasticViewInfo] objectForKey:self];
    if (!info) {
        info = [_ElasticInfo new];
        [[manager elasticViewInfo] setObject:info forKey:self];
    }
    return info;
}

- (id)elasticGetChildWithKey:(NSString *)key creationBlock:(UIView*(^)())creationBlock {
    [self _elasticAssertMidRender];
    _ElasticInfo *info = [self _getElasticInfo];
    // create/keep this view:
    if (!info.childViewsForKey[key]) {
        info.childViewsForKey[key] = creationBlock();
        [self addSubview:info.childViewsForKey[key]];
    } else {
        [self bringSubviewToFront:info.childViewsForKey[key]];
    }
    [info.keysAccessedThisFrame addObject:key];
    return info.childViewsForKey[key];
}

- (id)elasticGetChildWithKeyIfPresent:(NSString *)key {
    _ElasticInfo *info = [self _getElasticInfo];
    return info.childViewsForKey[key];
}

- (void)_elasticAssertMidRender {
    // TODO
}

- (NSInteger)_elasticDepthInTree {
    NSInteger depth = 0;
    UIView *superview = self.superview;
    while (superview) {
        depth++;
        superview = superview.superview;
    }
    return depth;
}

#pragma mark Subclass hooks

- (void)elasticRender {
    
}

- (void)elasticTick {
    
}

- (void)elasticSetup {
    
}

#pragma mark Metadata

- (_ElasticMetadata *)_getElasticMetadata:(BOOL)create {
    _ElasticMetadata *md = objc_getAssociatedObject(self, @selector(_getElasticMetadata:));
    if (!md && create) {
        md = [_ElasticMetadata new];
        objc_setAssociatedObject(self, @selector(_getElasticMetadata:), md, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return md;
}

#pragma mark View reuse

- (ElasticReuseQueue *)elasticReuseQueueForIdentifier:(NSString *)reuseIdentifier {
    _ElasticMetadata *info = [self _getElasticMetadata:YES];
    NSMutableDictionary *queues = info.reuseQueues;
    if (!queues) {
        queues = [NSMutableDictionary new];
        info.reuseQueues = queues;
    }
    ElasticReuseQueue *queue = queues[reuseIdentifier];
    if (!queue) {
        queue = [ElasticReuseQueue new];
        queue.minSize = 1;
        queue.maxSize = 3;
        queues[reuseIdentifier] = queue;
    }
    return queue;
}

- (void)_elasticSetReuseQueue:(ElasticReuseQueue *)queue {
    [self _getElasticMetadata:YES].belongsToReuseQueue = queue;
}

@end
