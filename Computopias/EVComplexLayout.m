//
//  ElasticComplexLayout.m
//  ProductHunt
//
//  Created by Nate Parrott on 7/22/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import "EVComplexLayout.h"

typedef NS_ENUM(NSInteger, EVLayoutAttributeType) {
    EVLayoutAttributeTypeDirectionIsHorizontal,
    EVLayoutAttributeTypePadding,
    EVLayoutAttributeTypeAlignment
};

typedef NS_ENUM(NSInteger, EVLayoutAlignment) {
    EVLayoutAlignmentLeading,
    EVLayoutAlignmentTrailing,
    EVLayoutAlignmentCenter,
    EVLayoutAlignmentSpread
};

@interface _EVLayoutAttribute : NSObject

@property (nonatomic) EVLayoutAttributeType type;
@property (nonatomic) id value;

@end

@implementation _EVLayoutAttribute

+ (instancetype)withType:(EVLayoutAttributeType)type value:(id)value {
    _EVLayoutAttribute *a = [_EVLayoutAttribute new];
    a.type = type;
    a.value = value;
    return a;
}

@end

@interface _EVLayoutInfoWrapper : NSObject

@property (nonatomic) NSArray *layoutables;
@property (nonatomic) CGFloat stretchFactor;
@property (nonatomic) UIEdgeInsets insets;

@end

@implementation _EVLayoutInfoWrapper

@end

#pragma mark Core layout algorithm

CGSize _EVMinSizeForLayoutable(id layoutable, CGSize maxSize, CGFloat *stretchFactor);

void _EVPositionLayoutable(id layoutable, CGRect frame) {
    if ([layoutable isKindOfClass:[NSArray class]]) {
        EVComplexLayout(NO, frame, layoutable);
    } else if ([layoutable isKindOfClass:[_EVLayoutInfoWrapper class]]) {
        _EVLayoutInfoWrapper *wrapper = layoutable;
        CGRect innerFrame = UIEdgeInsetsInsetRect(frame, wrapper.insets);
        for (id childLayoutable in wrapper.layoutables) {
            _EVPositionLayoutable(childLayoutable, innerFrame);
        }
    } else if ([layoutable isKindOfClass:[UIView class]]) {
        /*UIView *view = layoutable;
        CGRect windowFrame = [view.window convertRect:frame fromView:view.superview];
        windowFrame = CGRectIntegral(windowFrame);
        CGRect localFrame = [view.superview convertRect:windowFrame fromView:view.window];
        [layoutable setFrame:localFrame];*/
        [layoutable setFrame:frame];
    } else {
        NSCAssert(0, @"EVComplexLayout: can only lay out UIViews or NSArrays of views and attributes, but got: %@", layoutable);
    }
}

CGSize EVComplexLayout(BOOL sizingOnly, CGRect maxFrame, NSArray *layoutTree) {
    CGSize maxSize = maxFrame.size;
    NSMutableArray *layoutables = [NSMutableArray new];
    BOOL horizontal = NO;
    CGFloat padding = 0;
    EVLayoutAlignment alignment = EVLayoutAlignmentLeading;
    for (id item in layoutTree) {
        if ([item isKindOfClass:[_EVLayoutAttribute class]]) {
            _EVLayoutAttribute *attr = item;
            if (attr.type == EVLayoutAttributeTypePadding) {
                padding = [attr.value doubleValue];
            } else if (attr.type == EVLayoutAttributeTypeDirectionIsHorizontal) {
                horizontal = [attr.value boolValue];
            } else if (attr.type == EVLayoutAttributeTypeAlignment) {
                alignment = [attr.value integerValue];
            }
        } else {
            // assume this is layoutable:
            [layoutables addObject:item];
        }
    }
    NSMutableArray *overflow = [NSMutableArray new]; // TODO: expose this to clients
    CGSize minSize = CGSizeZero;
    NSMutableArray *minSizesAlongAxis = [NSMutableArray new];
    NSMutableArray *stretchFactorsAlongAxis = [NSMutableArray new];
    CGFloat totalStretch = 0;
    for (id layoutable in layoutables) {
        CGFloat stretch = 0;
        CGSize size = _EVMinSizeForLayoutable(layoutable, maxSize, &stretch);
        totalStretch += stretch;
        BOOL fits = NO;
        if (horizontal) {
            if (minSize.width + size.width <= maxSize.width) {
                fits = YES;
                minSize.width += size.width;
                minSize.height = MAX(minSize.height, size.height);
                [minSizesAlongAxis addObject:@(size.width)];
            }
        } else {
            if (minSize.height + size.height <= maxSize.height) {
                fits = YES;
                minSize.height += size.height;
                minSize.width = MAX(minSize.width, size.width);
                [minSizesAlongAxis addObject:@(size.height)];
            }
        }
        if (fits) {
            [stretchFactorsAlongAxis addObject:@(stretch)];
        } else {
            [overflow addObject:layoutable];
        }
    }
    
    if (!sizingOnly) {
        CGFloat axisPos = 0;
        CGFloat spacing = 0;
        CGFloat minAxisSize = horizontal ? minSize.width : minSize.height;
        CGFloat maxAxisSize = horizontal ? maxSize.width : maxSize.height;
        if (totalStretch == 0) {
            if (alignment == EVLayoutAlignmentTrailing) {
                axisPos = maxAxisSize - minAxisSize;
            } else if (alignment == EVLayoutAlignmentCenter) {
                axisPos = (maxAxisSize - minAxisSize) / 2;
            } else if (alignment == EVLayoutAlignmentSpread && layoutables.count >= 2) {
                spacing = (maxAxisSize - minAxisSize) / (layoutables.count - 1);
            }
        }
        NSInteger i = 0;
        for (id layoutable in [layoutables subarrayWithRange:NSMakeRange(0, layoutables.count - overflow.count)]) {
            CGRect frame;
            CGFloat sizeAlongAxis = [minSizesAlongAxis[i] doubleValue];
            if (totalStretch) {
                sizeAlongAxis += (maxAxisSize - minAxisSize) * [stretchFactorsAlongAxis[i] doubleValue] / totalStretch;
            }
            if (horizontal) {
                frame = CGRectMake(axisPos, 0, sizeAlongAxis, maxSize.height);
                axisPos = CGRectGetMaxX(frame);
            } else {
                frame = CGRectMake(0, axisPos, maxSize.width, sizeAlongAxis);
                axisPos = CGRectGetMaxY(frame);
            }
            frame.origin.x += maxFrame.origin.x;
            frame.origin.y += maxFrame.origin.y;
            axisPos += spacing;
            _EVPositionLayoutable(layoutable, frame);
            i++;
        }
    }
    
    return sizingOnly ? minSize : maxSize;
}

CGSize _EVMinSizeForLayoutable(id layoutable, CGSize maxSize, CGFloat *stretchFactor) {
    *stretchFactor = 0;
    if ([layoutable isKindOfClass:[NSArray class]]) {
        return EVComplexLayout(YES, CGRectMake(0, 0, maxSize.width, maxSize.height), layoutable);
    } else if ([layoutable isKindOfClass:[_EVLayoutInfoWrapper class]]) {
        _EVLayoutInfoWrapper *wrapper = layoutable;
        maxSize.width -= wrapper.insets.left + wrapper.insets.right;
        maxSize.height -= wrapper.insets.top + wrapper.insets.bottom;
        *stretchFactor = [wrapper stretchFactor];
        CGSize largestSize = CGSizeZero;
        for (id childLayoutable in wrapper.layoutables) {
            CGFloat _;
            CGSize size = _EVMinSizeForLayoutable(childLayoutable, maxSize, &_);
            largestSize.width = MAX(largestSize.width, size.width);
            largestSize.height = MAX(largestSize.height, size.height);
        }
        largestSize.width += wrapper.insets.left + wrapper.insets.right;
        largestSize.height += wrapper.insets.top + wrapper.insets.bottom;
        return largestSize;
    } else if ([layoutable isKindOfClass:[UIView class]]) {
        return [layoutable sizeThatFits:maxSize];
    } else {
        NSCAssert(0, @"EVComplexLayout: can only lay out UIViews or NSArrays of views and attributes, but got: %@", layoutable);
        return CGSizeZero;
    }
}

#pragma mark Wrapper constructors

id EVStretchable(CGFloat stretchFactor, id layoutable) {
    _EVLayoutInfoWrapper *w = [_EVLayoutInfoWrapper new];
    w.stretchFactor = stretchFactor;
    w.layoutables = @[layoutable];
    return w;
}

id EVOverlap(NSArray *layoutables) {
    _EVLayoutInfoWrapper *w = [_EVLayoutInfoWrapper new];
    w.layoutables = layoutables;
    return w;
}

id EVInset(id layoutable, UIEdgeInsets insets) {
    _EVLayoutInfoWrapper *w = [_EVLayoutInfoWrapper new];
    w.layoutables = @[layoutable];
    w.insets = insets;
    return w;
}

#pragma mark Attribute convenience constructors

id EVLayoutAlignLeading() {
    return [_EVLayoutAttribute withType:EVLayoutAttributeTypeAlignment value:@(EVLayoutAlignmentLeading)];
}

id EVLayoutAlignTrailing() {
    return [_EVLayoutAttribute withType:EVLayoutAttributeTypeAlignment value:@(EVLayoutAlignmentTrailing)];
}

id EVLayoutAlignCenter() {
    return [_EVLayoutAttribute withType:EVLayoutAttributeTypeAlignment value:@(EVLayoutAlignmentCenter)];
}

id EVLayoutAlignSpread() {
    return [_EVLayoutAttribute withType:EVLayoutAttributeTypeAlignment value:@(EVLayoutAlignmentSpread)];
}

id EVVertical() {
    return [_EVLayoutAttribute withType:EVLayoutAttributeTypeDirectionIsHorizontal value:@NO];
}

id EVHorizontal() {
    return [_EVLayoutAttribute withType:EVLayoutAttributeTypeDirectionIsHorizontal value:@YES];
}

id EVPadding(CGFloat padding) {
    return [_EVLayoutAttribute withType:EVLayoutAttributeTypePadding value:@(padding)];
}
