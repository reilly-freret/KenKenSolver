//
//  OpenCVWrapper.h
//  KenKenSolver2
//
//  Created by Reilly Freret on 11/23/18.
//  Copyright © 2018 Reilly Freret. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface OpenCVWrapper : NSObject

+(UIImage *)testIntersectionDetection:(UIImage *)image;
+(UIImage *)testGridExtraction:(UIImage *)image;

+(void)extractGroups:(UIImage *)image:(NSMutableDictionary *)dict;
+(int)getDimension:(UIImage *)image;
+(UIImage *)debugProcessing:(UIImage *)image;
@end

NS_ASSUME_NONNULL_END
