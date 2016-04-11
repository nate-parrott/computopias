//
//  ElasticValue2.h
//  Elastic
//
//  Created by Nate Parrott on 7/2/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EVCommon.h"
#import "ElasticValueInput.h"
#import "UIGestureRecognizer+Elastic.h"

@class ElasticValue;

typedef void (^ElasticValueDragEndBlock)(ElasticValue *val, CGFloat suggestedLandingPos);

@interface ElasticValue : NSObject <ElasticValueInput>

+ (ElasticValue *)screenValue;
+ (ElasticValue *)pageValue;

@property (nonatomic,readonly) CGFloat position;
@property (nonatomic,readonly) CGFloat rubberBandedPosition;

- (CGFloat)velocity;

@property (nonatomic,readonly) BOOL dragging;

@property (nonatomic) NSString *logName;

- (void)startDragging;
- (void)draggedToPosition:(CGFloat)position;
- (void)stopDragging;

- (void)snapToPosition:(CGFloat)position completionBlock:(void(^)(BOOL cancelled))completionBlock;
- (void)snapToPosition:(CGFloat)position spring:(BOOL)spring completionBlock:(void(^)(BOOL cancelled))completionBlock;

- (CGFloat)estimatedStoppingPosition;

@property (nonatomic) CGFloat min, max;

- (void)resetTo:(CGFloat)position;

- (BOOL)isStopped;

@property (nonatomic, copy) EVCallback dragStartBlock, tickBlock;
@property (nonatomic, copy) ElasticValueDragEndBlock dragEndBlock; // defaults to normal deceleration

#pragma mark Options

@property (nonatomic) CGFloat speed; // default 1
@property (nonatomic) CGFloat extraBounce; // default 1
@property (nonatomic) CGFloat decelerationRate; // default 1
@property (nonatomic,readonly) BOOL isScreenValue;

#pragma mark Gesture recognizers

- (void)addInput:(id<ElasticValueInput>)input valueFunction:(CGFloat (^)(id<ElasticValueInput> input))valueFunction;
- (void)removeInput:(id<ElasticValueInput>)input;

#pragma mark Implementation details

+ (void)_updateAllWithDt:(NSTimeInterval)dt;
- (void)_tick:(NSTimeInterval)dt;
- (CGFloat)positionChangeDuringLastFrame;
- (CGFloat)epsilon;
@property (nonatomic) NSString *name; // for debugging

@end
