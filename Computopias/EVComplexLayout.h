//
//  ElasticComplexLayout.h
//  ProductHunt
//
//  Created by Nate Parrott on 7/22/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import <UIKit/UIKit.h>

id EVVertical();
id EVHorizontal();

id EVLayoutAlignLeading();
id EVLayoutAlignTrailing();
id EVLayoutAlignCenter();
id EVLayoutAlignSpread();

id EVOverlap(NSArray *layoutables);

// id EVPadding(CGFloat padding); // TODO

id EVStretchable(CGFloat stretchFactor, id layoutable);

id EVInset(id layoutable, UIEdgeInsets insets);

CGSize EVComplexLayout(BOOL sizingOnly, CGRect maxFrame, NSArray *layoutTree);
