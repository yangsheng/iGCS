//
//  GCSImageUtils.h
//  iGCS
//
//  Created by Andrew Brown on 5/6/13.
//
//

#import <Foundation/Foundation.h>

@interface GCSImageUtils : NSObject

+ (UIImage*)imageWithImage:(UIImage*)image
              scaledToSize:(CGSize)newSize
                  rotation:(double)ang;

+ (UIImage *)image:(UIImage*)img
         withColor:(UIColor*)color;

@end
