//
//  ElasticReuseQueue.h
//  Elastic
//
//  Created by Nate Parrott on 7/14/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ElasticReuseQueue : NSObject

@property (nonatomic,copy) UIView*(^viewBlock)();
@property (nonatomic) NSInteger maxSize, minSize;
- (id)dequeueView;
- (void)addView:(UIView *)view;

@end
