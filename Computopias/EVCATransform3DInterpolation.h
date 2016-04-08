//
//  EVCATransform3DInterpolation.h
//  Elastic
//
//  Created by Nate Parrott on 7/8/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#ifndef EVCATransform3DInterpolation_h
#define EVCATransform3DInterpolation_h

#import <UIKit/UIKit.h>

CATransform3D EVInterpolateTransform(CATransform3D t1, CATransform3D t2, CGFloat progress);

#endif /* EVCATransform3DInterpolation_h */
