//
//  EVFakeData.h
//  Elastic
//
//  Created by Nate Parrott on 7/13/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface EVFakeData : NSObject

@property (nonatomic) NSString *shortText, *longText;
@property (nonatomic) UIColor *color;
@property (nonatomic) NSURL *url;
@property (nonatomic) NSString *identifier;
@property (nonatomic) NSString *word;
@property (nonatomic) id data;

+ (NSArray<EVFakeData *>*)getFakeData:(NSInteger)n;

@end
