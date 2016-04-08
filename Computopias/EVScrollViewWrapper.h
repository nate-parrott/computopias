//
//  EVScrollViewWrapper.h
//  Elastic
//
//  Created by Nate Parrott on 7/8/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EVCommon.h"
#import "ElasticValue.h"

@interface EVScrollViewWrapper : UIView

@property (nonatomic) ElasticValue *elasticValue;
@property (nonatomic) CGFloat elasticValueMin, screenPointToElasticValueScale;
@property (nonatomic,readonly) CGFloat elasticValueMax;

@property (nonatomic) UIView *subview;
@property (nonatomic) UIScrollView *scrollView;

@end
