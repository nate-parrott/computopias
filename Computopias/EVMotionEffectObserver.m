//
//  EVMotionEffectObserver.m
//  Elastic
//
//  Created by Nate Parrott on 7/18/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import "EVMotionEffectObserver.h"

@interface _EVMotionObserverEffect : UIMotionEffect

@property (nonatomic,readonly) UIOffset viewerOffset;

@end

@implementation _EVMotionObserverEffect

- (NSDictionary *)keyPathsAndRelativeValuesForViewerOffset:(UIOffset)viewerOffset {
    _viewerOffset = viewerOffset;
    return @{};
}

@end

NSInteger _EVMotionEffectObserverLiveObserverCount = 0;
_EVMotionObserverEffect *_EVMotionObserverEffectShared = nil;

@implementation EVMotionEffectObserver

- (instancetype)init {
    self = [super init];
    [[self class] updateObserverCount:1];
    return self;
}

- (void)dealloc {
    [[self class] updateObserverCount:-1];
}

- (UIOffset)viewerOffset {
    return _EVMotionObserverEffectShared.viewerOffset;
}

+ (void)updateObserverCount:(NSInteger)add {
    BOOL hadObservers = _EVMotionEffectObserverLiveObserverCount > 0;
    _EVMotionEffectObserverLiveObserverCount += add;
    BOOL hasObservers = _EVMotionEffectObserverLiveObserverCount > 0;
    if (hadObservers != hasObservers) {
        if (hasObservers) {
            _EVMotionObserverEffectShared = [_EVMotionObserverEffect new];
            [[[[UIApplication sharedApplication] windows] firstObject] addMotionEffect:_EVMotionObserverEffectShared];
        } else {
            // we no longer have observers
            [[[[UIApplication sharedApplication] windows] firstObject] removeMotionEffect:_EVMotionObserverEffectShared];
            _EVMotionObserverEffectShared = nil;
        }
    }
}

@end
