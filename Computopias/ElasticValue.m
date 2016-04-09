//
//  ElasticValue2.m
//  Elastic
//
//  Created by Nate Parrott on 7/2/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import "ElasticValue.h"

@interface _ElasticValueInputInfo : NSObject

@property (nonatomic,copy) CGFloat (^valueFunction)(id<ElasticValueInput>);
@property (nonatomic) CGFloat previousValue;
@property (nonatomic) BOOL hasPreviousValue;

@end

@implementation _ElasticValueInputInfo

@end



@interface ElasticValue () {
    void (^_snapCompletionBlock)(BOOL cancelled);
    long long _tick;
}

@property (nonatomic) NSMutableArray *dragPositionSamples, *dragTimeSamples, *dragTickSamples;
@property (nonatomic) CGFloat velocity;
@property (nonatomic) CGFloat position;
@property (nonatomic) CGFloat positionAtStartOfGesture;

@property (nonatomic) NSNumber *snapToPosition;
@property (nonatomic) NSNumber *tempMin, *tempMax;

@property (nonatomic) CGFloat epsilon;

@property (nonatomic) CGFloat positionChangeDuringLastFrame;
@property (nonatomic) CGFloat dragDistanceInPreviousFrame;

@property (nonatomic) NSMapTable *infoForInputValues;

@property (nonatomic) NSSet *draggingInputs;

@property (nonatomic) ElasticValueInputGeneric *selfInput;

@property (nonatomic) ElasticValueInputGeneric *inputProviderProxy;

@end

@implementation ElasticValue

#pragma mark Lifecycle


+ (ElasticValue *)screenValue {
    ElasticValue *v = [ElasticValue new];
    v->_isScreenValue = YES;
    v.epsilon = 1;
    return v;
}

+ (ElasticValue *)pageValue {
    ElasticValue *v = [ElasticValue new];
    return v;
}

- (instancetype)init {
    self = [super init];
    [[[self class] _all] setObject:@1 forKey:self];
    self.max = 1;
    self.epsilon = 0.01;
    self.speed = 1;
    self.extraBounce = 1;
    self.decelerationRate = 1;
    self.infoForInputValues = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsObjectPointerPersonality | NSPointerFunctionsWeakMemory valueOptions:NSPointerFunctionsStrongMemory | NSPointerFunctionsObjectPersonality];
    self.inputProviderProxy = [ElasticValueInputGeneric new];
    self.inputProviderProxy._proxySender = self;
    self.draggingInputs = [NSSet set];
    return self;
}

- (void)dealloc {
    [[[self class] _all] removeObjectForKey:self];
    for (id<ElasticValueInput> input in self.infoForInputValues.keyEnumerator) {
        [input removeTarget:self action:nil];
    }
}

#pragma mark Interface

- (void)_draggedToPosition:(CGFloat)position {
    self.dragDistanceInPreviousFrame = position - self.position;
    self.position = position;
    [self _addPositionSample:position];
    self.velocity = [self _computeDragVelocity];
}

- (CGFloat)estimatedStoppingPosition {
    if (self.snapToPosition) {
        return self.snapToPosition.floatValue;
    } else if (self.velocity == 0) {
        return self.position;
    } else {
        CGFloat direction = self.velocity / fabs(self.velocity);
        CGFloat d = self.position + [self _estimateDisplacementFromInitialSpeed:fabs(self.velocity)] * direction;
        return MAX(self.min, MIN(self.max, d));
    }
}

- (void)setDraggingInputs:(NSSet *)draggingInputs {
    BOOL wasDragging = self.dragging;
    _draggingInputs = draggingInputs;
    if (self.dragging != wasDragging) {
        if (self.dragging) {
            [self _resetSnap];
            [self _callCompletionBlockCancelled:YES];
            if (self.dragStartBlock) self.dragStartBlock();
        } else {
            self.velocity = [self _computeDragVelocity];
            [self log:[NSString stringWithFormat:@"samples: %@", self.dragPositionSamples]];
            [self log:[NSString stringWithFormat:@"velocity: %f", self.velocity]];
            if (self.dragEndBlock) self.dragEndBlock(self, [self estimatedStoppingPosition]);
        }
        [self _addPositionSample:self.position];
        self.inputProviderProxy.dragging = self.dragging;
    }
}

- (BOOL)dragging {
    return self.draggingInputs.count > 0;
}

- (void)snapToPosition:(CGFloat)position completionBlock:(void(^)(BOOL cancelled))completionBlock {
    [self snapToPosition:position spring:NO completionBlock:completionBlock];
}

- (void)snapToPosition:(CGFloat)position spring:(BOOL)spring completionBlock:(void(^)(BOOL cancelled))completionBlock {
    [self _resetSnap];
    [self _callCompletionBlockCancelled:YES];
    self.snapToPosition = @(position);
    if (!spring) {
        if (position > self.position) {
            self.tempMax = @(position);
        } else {
            self.tempMin = @(position);
        }
    }
    _snapCompletionBlock = completionBlock;
}

- (void)resetTo:(CGFloat)position {
    self.position = position;
    [self.dragPositionSamples removeAllObjects];
    [self.dragTimeSamples removeAllObjects];
    [self.dragTickSamples removeAllObjects];
    self.velocity = 0;
    [self _resetSnap];
}

- (CGFloat)position {
    if (_isScreenValue && self.isStopped) {
        return EVRoundToScreenCoordinates(_position);
    } else {
        return _position;
    }
}

- (CGFloat)rubberBandedPosition {
    CGFloat p = self.position;
    CGFloat dropOffDist = _isScreenValue ? 100 : 0.3;
    if (p > self.max) {
        return EVExponentialSlowdown(p - self.max, dropOffDist) + self.max;
    } else if (p < self.min) {
        return self.min - EVExponentialSlowdown(self.min - p, dropOffDist);
    } else {
        return p;
    }
}

#pragma mark Velocity

- (void)_addPositionSample:(CGFloat)position {
    if (!self.dragPositionSamples) {
        self.dragPositionSamples = [NSMutableArray new];
        self.dragTimeSamples = [NSMutableArray new];
        self.dragTickSamples = [NSMutableArray new];
    }
    [self.dragPositionSamples addObject:@(position)];
    [self.dragTimeSamples addObject:@(CFAbsoluteTimeGetCurrent())];
    [self.dragTickSamples addObject:@(_tick)];
    [self _trimDragSamples];
    [self log:[NSString stringWithFormat:@"adding sample %f", position]];
}

- (void)_trimDragSamples {
    /*while (self.dragTimeSamples.count && [self.dragTimeSamples.firstObject doubleValue] < CFAbsoluteTimeGetCurrent() - [self trailingVelocityCalculationTime]) {
        [self.dragTimeSamples removeObjectAtIndex:0];
        [self.dragPositionSamples removeObjectAtIndex:0];
    }*/
    while ([self _countUniqueTicksInDragSamples] > 3) {
        [self.dragTimeSamples removeObjectAtIndex:0];
        [self.dragPositionSamples removeObjectAtIndex:0];
        [self.dragTickSamples removeObjectAtIndex:0];
    }
}

- (NSInteger)_countUniqueTicksInDragSamples {
    long long lastTick = -1;
    NSInteger count = 0;
    for (NSNumber *n in self.dragTickSamples) {
        if (n.longLongValue != lastTick) {
            count++;
            lastTick = n.longLongValue;
        }
    }
    return count;
}

- (CGFloat)_computeDragVelocity {
    [self _trimDragSamples];
    if (self.dragPositionSamples.count == 0) return 0;
    NSTimeInterval dt = ([self.dragTimeSamples.lastObject doubleValue] - [self.dragTimeSamples.firstObject doubleValue]);
    if (dt == 0) return 0;
    return ([self.dragPositionSamples.lastObject doubleValue] - [self.dragPositionSamples.firstObject doubleValue]) / dt;
}

- (CGFloat)_estimateDisplacementFromInitialSpeed:(CGFloat)s {
    NSTimeInterval dt = 0.5 / 60.0;
    CGFloat friction = [self frictionConstant];
    CGFloat epsilon = [self epsilon];
    CGFloat d = 0;
    while (s > epsilon) {
        CGFloat force = -friction * s;
        s += force * dt;
        d += s * dt;
    }
    return d;
}

- (BOOL)isStopped {
    return fabs(self.positionChangeDuringLastFrame) <= [self epsilon];
}

#pragma mark Conf

- (CGFloat)friction {
    CGFloat f = [self frictionConstant];
    if ([self isOutOfBounds]) f *= 10;
    return f;
}

- (CGFloat)frictionConstant {
    return 2 / [self extraBounce] * self.decelerationRate;
}

- (CGFloat)snappingSpringConstant {
    return 10;
}

- (CGFloat)rubberBandCoefficient {
    return 80 / self.extraBounce * self.decelerationRate;
}

- (NSTimeInterval)trailingVelocityCalculationTime {
    return 2/60.0;
}

#pragma mark Physics

- (void)_tick:(NSTimeInterval)dt {
    _tick++;
    CGFloat lastPos = self.position;
    
    if (!self.dragging) {
        CGFloat force = -self.velocity * [self friction];
        if (self.snapToPosition) {
            force += (self.snapToPosition.floatValue - self.position) * [self snappingSpringConstant];
        }
        if (self.position < [self effectiveMin]) {
            force += [self rubberBandCoefficient] * ([self effectiveMin] - self.position);
        } else if (self.position > [self effectiveMax]) {
            force -= [self rubberBandCoefficient] * (self.position - [self effectiveMax]);
        }
        
        self.velocity += force * dt * self.speed;
        BOOL snappingToNewPosition = self.snapToPosition && fabs(self.position - self.snapToPosition.doubleValue) > [self epsilon];
        if (fabs(self.velocity) < [self epsilon] && !snappingToNewPosition) {
            self.velocity = 0;
        }
        self.position += self.velocity * dt;
        
        if (self.velocity == 0) {
            if (self.snapToPosition) {
                if (fabs(self.snapToPosition.doubleValue - self.position) < [self epsilon]
                    && fabs([self velocity]) < [self epsilon]) {
                    self.position = self.snapToPosition.doubleValue;
                    [self _resetSnap];
                    [self _callCompletionBlockCancelled:NO];
                }
            } else if (fabs(self.position - self.min) < [self epsilon]) {
                self.position = self.min;
            } else if (fabs(self.position - self.max) < [self epsilon]) {
                self.position = self.max;
            }
        }
    }
    self.positionChangeDuringLastFrame = self.position - lastPos + self.dragDistanceInPreviousFrame;
    self.dragDistanceInPreviousFrame = 0;
    // NSLog(@"%@: effectively dragging: %@; dragging: %@, dx: %f", self.name, self.effectivelyDragging ? @"YES" : @"NO", self.dragging ? @"YES" : @"NO", self.positionChangeDuringLastFrame);
    [self _addPositionSample:self.position];
    
    if (self.tickBlock) self.tickBlock();
    
    self.inputProviderProxy.position = self.position;
}

- (void)_callCompletionBlockCancelled:(BOOL)cancelled {
    if (_snapCompletionBlock) {
        void (^b)(BOOL cancelled) = _snapCompletionBlock;
        _snapCompletionBlock = nil;
        b(cancelled);
    }
}

- (BOOL)isOutOfBounds {
    return self.position < [self effectiveMin] || self.position > [self effectiveMax];
}

- (CGFloat)effectiveMin {
    if (self.tempMin) return MAX(self.tempMin.doubleValue, self.min);
    return self.min;
}

- (CGFloat)effectiveMax {
    if (self.tempMax) return MIN(self.tempMax.doubleValue, self.max);
    return self.max;
}

- (void)_resetSnap {
    self.tempMax = self.tempMin = self.snapToPosition = nil;
}

#pragma mark Global updating

+ (void)_updateAllWithDt:(NSTimeInterval)dt {
    NSMutableArray *vals = [[NSMutableArray alloc] initWithCapacity:[self _all].count];
    for (ElasticValue *v in [self _all]) [vals addObject:v];
    for (ElasticValue *v in vals) {
        [v _tick:dt];
    }
}

+ (NSMapTable *)_all {
    static NSMapTable *all;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        all = [[NSMapTable alloc] initWithKeyOptions:NSPointerFunctionsWeakMemory valueOptions:NSPointerFunctionsStrongMemory capacity:0];
    });
    return all;
}

#pragma mark Input receiver

- (void)addInput:(id<ElasticValueInput>)input valueFunction:(CGFloat (^)(id<ElasticValueInput> input))valueFunction {
    _ElasticValueInputInfo *info = [_ElasticValueInputInfo new];
    info.valueFunction = valueFunction;
    [self.infoForInputValues setObject:info forKey:input];
    [input addTarget:self action:@selector(receiveInput:)];
}

- (void)removeInput:(id<ElasticValueInput>)input {
    [self.infoForInputValues removeObjectForKey:input];
    [input removeTarget:self action:@selector(receiveInput:)];
    [self setInput:input isDragging:NO];
}

- (void)receiveInput:(id<ElasticValueInput>)input {
    _ElasticValueInputInfo *info = [self.infoForInputValues objectForKey:input];
    ElasticValueInputState state = [input elasticState];
    CGFloat value = info.valueFunction(input);
    if (state == ElasticValueInputStateBegan) {
        [self setInput:input isDragging:YES];
    } else if (state == ElasticValueInputStateMoving) {
        if ([input respondsToSelector:@selector(isAbsolute)] && [input isAbsolute]) {
            [self _draggedToPosition:value];
        } else {
            if (info.hasPreviousValue) {
                [self _draggedToPosition:self.position + value - info.previousValue];
            }
        }
    } else if (state == ElasticValueInputStateEnded) {
        [self setInput:input isDragging:NO];
    } else if (state == ElasticValueInputStateCancelled) {
        [self setInput:input isDragging:NO];
    }
    info.previousValue = value;
    info.hasPreviousValue = YES;
}

- (void)setInput:(id<ElasticValueInput>)input isDragging:(BOOL)dragging {
    NSMutableSet *inputs = self.draggingInputs.mutableCopy;
    if (dragging) {
        [inputs addObject:input];
    } else {
        [inputs removeObject:input];
    }
    self.draggingInputs = inputs;
}

#pragma mark Direct input
- (void)ensureSelfInput {
    if (!self.selfInput) {
        self.selfInput = [ElasticValueInputGeneric new];
        self.selfInput.isAbsolute = YES;
        [self addInput:self.selfInput valueFunction:^CGFloat(id<ElasticValueInput> input) {
            return [(ElasticValueInputGeneric *)input position];
        }];
    }
}

- (void)startDragging {
    [self ensureSelfInput];
    self.selfInput.dragging = YES;
}

- (void)draggedToPosition:(CGFloat)position {
    [self ensureSelfInput];
    self.selfInput.position = position;
}

- (void)stopDragging {
    self.selfInput.dragging = NO;
}

#pragma mark Input provider

- (void)addTarget:(id)target action:(SEL)action {
    [self.inputProviderProxy addTarget:target action:action];
}

- (void)removeTarget:(id)target action:(SEL)action {
    [self.inputProviderProxy removeTarget:target action:action];
}

- (ElasticValueInputState)elasticState {
    return self.inputProviderProxy.elasticState;
}

#pragma mark Debug

- (void)log:(id)value {
    if (_logName) NSLog(@"%@: %@", _logName, value);
}

@end
