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
-(NSString *)openCVVersionString;
+(UIImage *)extractGroups:(UIImage *)image;
+(int)getDimension:(UIImage *)image;
@end

NS_ASSUME_NONNULL_END
