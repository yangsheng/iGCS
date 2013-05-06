//
//  GCSImageUtils.m
//  iGCS
//
//  Created by Andrew Brown on 5/6/13.
//
//

#import "GCSImageUtils.h"

@implementation GCSImageUtils

+ (UIImage*)imageWithImage:(UIImage*)image
              scaledToSize:(CGSize)newSize
                  rotation:(double)ang {
    
    UIGraphicsBeginImageContext( newSize );
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGAffineTransform transform = CGAffineTransformIdentity;
    transform = CGAffineTransformTranslate(transform, newSize.width/2, newSize.height/2);
    transform = CGAffineTransformRotate(transform, ang);
    CGContextConcatCTM(context, transform);
    
    [image drawInRect:CGRectMake(-newSize.width/2,-newSize.width/2,newSize.width,newSize.height)];
    
    UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}


// ref: http://coffeeshopped.com/2010/09/iphone-how-to-dynamically-color-a-uiimage
+ (UIImage *)image:(UIImage*)img
         withColor:(UIColor*)color {
    
    
    // begin a new image context, to draw our colored image onto
    UIGraphicsBeginImageContext(img.size);
    
    // get a reference to that context we created
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // translate/flip the graphics context (for transforming from CG* coords to UI* coords
    CGContextTranslateCTM(context, 0, img.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);
    CGRect rect = CGRectMake(0, 0, img.size.width, img.size.height);
    CGContextDrawImage(context, rect, img.CGImage);
    
    // Set a mask that matches the shape of the image, then draw as black
    [[UIColor blackColor] setFill];
    CGContextSetBlendMode(context, kCGBlendModeDarken);
    CGContextClipToMask(context, rect, img.CGImage);
    CGContextAddRect(context, rect);
    CGContextDrawPath(context,kCGPathFill);
    
    // Now replace with the desired color
    [color setFill];
    CGContextSetBlendMode(context, kCGBlendModeLighten);
    CGContextClipToMask(context, rect, img.CGImage);
    CGContextAddRect(context, rect);
    CGContextDrawPath(context,kCGPathFill);
    
    // generate a new UIImage from the graphics context we drew onto
    UIImage *coloredImg = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    //return the color-burned image
    return coloredImg;
}


@end
