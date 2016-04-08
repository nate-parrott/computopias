//
//  EVInterpolation.h
//  Elastic
//
//  Created by Nate Parrott on 6/29/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EVCATransform3DInterpolation.h"

CGRect EVInterpolateRect(CGRect r1, CGRect r2, CGFloat progress);
CGPoint EVInterpolatePoint(CGPoint p1, CGPoint p2, CGFloat progress);
CGSize EVInterpolateSize(CGSize s1, CGSize s2, CGFloat progress);
CGFloat EVInterpolate(CGFloat a1, CGFloat a2, CGFloat progress);

@protocol EVInterpolation <NSObject>

- (instancetype)interpolatedWith:(id)other progress:(CGFloat)progress; // [0..1]

@end

@interface NSNumber (EVInterpolation) <EVInterpolation>

@end

@interface NSValue (EVInterpolation) <EVInterpolation>

@end

