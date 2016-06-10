//
//  CGMath.swift
//  ptrptr
//
//  Created by Nate Parrott on 1/15/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import UIKit

func +(lhs: CGPoint, rhs: CGPoint) -> CGPoint {
    return CGPointMake(lhs.x + rhs.x, lhs.y + rhs.y)
}

func *(lhs: CGPoint, rhs: CGFloat) -> CGPoint {
    return CGPointMake(lhs.x * rhs, lhs.y * rhs)
}

func *(lhs: CGFloat, rhs: CGPoint) -> CGPoint {
    return CGPointMake(rhs.x * lhs, rhs.y * lhs)
}

func -(lhs: CGPoint, rhs: CGPoint) -> CGPoint {
    return lhs + rhs * -1
}

func +(lhs: CGSize, rhs: CGSize) -> CGSize {
    return CGSizeMake(lhs.width + rhs.width, lhs.height + rhs.height)
}

func -(lhs: CGSize, rhs: CGSize) -> CGSize {
    return lhs + -1 * rhs
}

func /(lhs: CGPoint, rhs: CGFloat) -> CGPoint {
    return CGPointMake(lhs.x / rhs, lhs.y / rhs)
}

func +(lhs: CGRect, rhs: CGSize) -> CGRect {
    return CGRectMake(lhs.origin.x, lhs.origin.y, lhs.size.width + rhs.width, lhs.size.height + rhs.height)
}

extension CGRect {
    var center: CGPoint {
        get {
            return CGPoint(x: CGRectGetMidX(self), y: CGRectGetMidY(self))
        }
        set {
            origin.x = newValue.x - size.width/2
            origin.y = newValue.y - size.height/2
        }
    }
    var bottom: CGFloat {
        get {
            return CGRectGetMaxY(self)
        }
    }
    var right: CGFloat {
        get {
            return CGRectGetMaxX(self)
        }
    }
    var left: CGFloat {
        get {
            return CGRectGetMinX(self)
        }
    }
    var top: CGFloat {
        get {
            return CGRectGetMinY(self)
        }
    }
    func distanceFromPoint(pt: CGPoint) -> CGFloat {
        if CGRectContainsPoint(self, pt) {
            return 0
        } else if pt.x < origin.x && pt.y < origin.y {
            return (pt - origin).magnitude // pt is top-left of the rect
        } else if pt.x < origin.x && pt.y > right {
            return (pt - CGPointMake(origin.x, bottom)).magnitude // // pt is bottom-left of the rect
        } else if pt.x > origin.x && pt.y < origin.y {
            return (pt - CGPointMake(right, origin.y)).magnitude // pt is top-right
        } else if pt.x > origin.x && pt.y > bottom {
            return (pt - CGPointMake(right, bottom)).magnitude // pt is bottom-right
        } else if pt.x < origin.x {
            return origin.x - pt.x // pt is to the left
        } else if pt.x > right {
            return pt.x - right // pt is to the right
        } else if pt.y < origin.y {
            return origin.y - pt.y // pt is to the top
        } else {
            return pt.y - bottom // pt is below
        }
    }
}

func ==(lhs: CGSize, rhs: CGSize) -> Bool {
    return lhs.width == rhs.width && lhs.height == rhs.height
}

func ==(lhs: CGPoint, rhs: CGPoint) -> Bool {
    return lhs.x == rhs.x && lhs.y == rhs.y
}

func +(lhs: CGRect, rhs: CGPoint) -> CGRect {
    return CGRectMake(lhs.origin.x + rhs.x, lhs.origin.y + rhs.y, lhs.size.width, lhs.size.height)
}

extension CGPoint {
    var magnitude: CGFloat {
        get {
            return sqrt(pow(x, 2) + pow(y, 2))
        }
    }
    var angle: CGFloat {
        get {
            return atan2(y, x)
        }
    }
    func distanceFrom(other: CGPoint) -> CGFloat {
        return (self - other).magnitude
    }
}

func *(lhs: CGSize, rhs: CGFloat) -> CGSize {
    return CGSizeMake(lhs.width * rhs, lhs.height * rhs)
}

func *(lhs: CGFloat, rhs: CGSize) -> CGSize {
    return rhs * lhs
}

func ==(lhs: CGRect, rhs: CGRect) -> Bool {
    return lhs.origin == rhs.origin && lhs.size == rhs.size
}

extension CGSize {
    func centeredInsideRect(rect: CGRect) -> CGRect {
        return CGRectMake(rect.origin.x + (rect.size.width - width)/2, rect.origin.y + (rect.size.height - height)/2, width, height)
    }
    func padded(padding: CGFloat) -> CGSize {
        return CGSizeMake(width + padding * 2, height + padding * 2)
    }
}
