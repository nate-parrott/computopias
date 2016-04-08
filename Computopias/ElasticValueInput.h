//
//  ElasticValueInput.h
//  Elastic
//
//  Created by Nate Parrott on 7/15/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#ifndef ElasticValueInput_h
#define ElasticValueInput_h

#import <UIKit/UIKit.h>
@class ElasticValue;

typedef NS_ENUM(NSInteger, ElasticValueInputState) {
    ElasticValueInputStateBegan,
    ElasticValueInputStateMoving,
    ElasticValueInputStateEnded,
    ElasticValueInputStateCancelled
};

@protocol ElasticValueInput <NSObject>

- (void)addTarget:(id)target action:(SEL)action;
- (void)removeTarget:(id)target action:(SEL)action;
- (ElasticValueInputState)elasticState;

@optional
- (BOOL)isAbsolute;

@end

@interface ElasticValueInputGeneric : NSObject <ElasticValueInput>

@property (nonatomic) BOOL dragging;
@property (nonatomic) CGFloat position;
@property (nonatomic) BOOL isAbsolute;
@property (nonatomic,weak) id _proxySender;

@end

#endif /* ElasticValueInput_h */
