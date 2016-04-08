//
//  EVCATransform3DInterpolation.m
//  Elastic
//
//  Created by Nate Parrott on 7/8/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import "EVCATransform3DInterpolation.h"

// via http://svn.gna.org/svn/gnustep/libs/quartzcore/trunk/Source/CAAnimation.m

typedef struct _GSQuartzCoreQuaternion
{
    CGFloat x, y, z, w;
} GSQuartzCoreQuaternion;

/* Following two functions based on paper: */
/*   J.M.P. Warren: From Quaternion to Matrix and Back
 id Software, 2005 */
/* We use them to interpolate CATransform3Ds. Quaternions are
 easier to interpolate. */
static CATransform3D quaternionToMatrix(GSQuartzCoreQuaternion q)
{
    CATransform3D m;
    CGFloat x=q.x, y=q.y, z=q.z, w=q.w;
    
    m.m11 = 1 - 2*y*y - 2*z*z;
    m.m12 = 2*x*y + 2*w*z;
    m.m13 = 2*x*z - 2*w*y;
    m.m14 = 0;
    
    m.m21 = 2*x*y - 2*w*z;
    m.m22 = 1 - 2*x*x - 2*z*z;
    m.m23 = 2*y*z + 2*w*x;
    m.m24 = 0;
    
    m.m31 = 2*x*z + 2*w*y;
    m.m32 = 2*y*z - 2*w*x;
    m.m33 = 1 - 2*x*x - 2*y*y;
    m.m34 = 0;
    
    m.m41 = 0;
    m.m42 = 0;
    m.m43 = 0;
    m.m44 = 1;
    
    return m;
}

static GSQuartzCoreQuaternion matrixToQuaternion(CATransform3D m)
{
    /* note: how about we use reciprocal square root, too? */
    /* see:
     http://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Reciprocal_of_the_square_root
     http://en.wikipedia.org/wiki/Fast_inverse_square_root
     */
    
    GSQuartzCoreQuaternion q;
    
    m = m;
    if (m.m11 + m.m22 + m.m33 > 0)
    {
        CGFloat t = m.m11 + m.m22 + m.m33 + 1.;
        CGFloat s = 0.5/sqrt(t);
        
        q.w = s*t;
        q.z = (m.m12 - m.m21)*s;
        q.y = (m.m31 - m.m13)*s;
        q.x = (m.m23 - m.m32)*s;
    }
    else if (m.m11 > m.m22 && m.m11 > m.m33)
    {
        CGFloat t = m.m11 - m.m22 - m.m33 + 1;
        CGFloat s = 0.5/sqrt(t);
        
        q.x = s*t;
        q.y = (m.m12 + m.m21)*s;
        q.z = (m.m31 + m.m13)*s;
        q.w = (m.m23 - m.m32)*s;
    }
    else if (m.m22 > m.m33)
    {
        CGFloat t = -m.m11 + m.m22 - m.m33 + 1;
        CGFloat s = 0.5/sqrt(t);
        
        q.y = s*t;
        q.x = (m.m12 + m.m21)*s;
        q.w = (m.m31 - m.m13)*s;
        q.z = (m.m23 + m.m32)*s;
    }
    else
    {
        CGFloat t = -m.m11 - m.m22 + m.m33 + 1;
        CGFloat s = 0.5/sqrt(t);
        
        q.z = s*t;
        q.w = (m.m12 - m.m21)*s;
        q.x = (m.m31 + m.m13)*s;
        q.y = (m.m23 + m.m32)*s;
    }
    
    return q;
}

static GSQuartzCoreQuaternion linearInterpolationQuaternion(GSQuartzCoreQuaternion a, GSQuartzCoreQuaternion b, CGFloat fraction)
{
    // slerp
    GSQuartzCoreQuaternion qr;
    
    /* reduction of calculations */
    if (!memcmp(&a, &b, sizeof(a)))
    {
        /* aside from making less calculations, this will also
         fix NaNs that would be returned if quaternions are equal */
        return a;
    }
    if (fraction == 0.)
    {
        return a;
    }
    if (fraction == 1.)
    {
        return b;
    }
    
    CGFloat dotproduct = a.x * b.x + a.y * b.y + a.z * b.z + a.w * b.w;
    CGFloat theta, st, sut, sout, coeff1, coeff2;
    
    theta = acos(dotproduct);
    if (theta == 0.0)
    {
        /* shouldn't happen, since we already checked for equality of
         inbound quaternions */
        /* if we didn't make this check, we'd get a lot of NaNs. */
        return a;
    }
    
    if (theta<0.0)
        theta=-theta;
    
    st = sin(theta);
    sut = sin(fraction*theta);
    sout = sin((1-fraction)*theta);
    coeff1 = sout/st;
    coeff2 = sut/st;
    
    qr.x = coeff1*a.x + coeff2*b.x;
    qr.y = coeff1*a.y + coeff2*b.y;
    qr.z = coeff1*a.z + coeff2*b.z;
    qr.w = coeff1*a.w + coeff2*b.w;
    
    // normalize
    CGFloat qrLen = sqrt(qr.x*qr.x + qr.y*qr.y + qr.z*qr.z + qr.w*qr.w);
    qr.x /= qrLen;
    qr.y /= qrLen;
    qr.z /= qrLen;
    qr.w /= qrLen;
    
    return qr;
    
}

CATransform3D EVInterpolateTransform(CATransform3D t1, CATransform3D t2, CGFloat progress) {
    return quaternionToMatrix(linearInterpolationQuaternion(matrixToQuaternion(t1), matrixToQuaternion(t2), progress));
}
