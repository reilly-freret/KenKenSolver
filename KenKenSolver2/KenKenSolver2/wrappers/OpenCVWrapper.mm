//
//  OpenCVWrapper.m
//  kenken-solver
//
//  Created by Reilly Freret on 11/18/18.
//  Copyright © 2018 Reilly Freret. All rights reserved.
//

#import <opencv2/opencv.hpp>
#import <opencv2/imgcodecs/ios.h>
#import "OpenCVWrapper.h"

using namespace cv;
using namespace std;

@implementation OpenCVWrapper

//+(UIImage *)extractGroups:(UIImage *)image
+(void)extractGroups:(UIImage *)image :(NSMutableDictionary *)dict;
{
    Mat underlay = [self preprocessText:image];
    cvtColor(underlay, underlay, CV_GRAY2RGB);
    
    Mat i;
    UIImageToMat(image, i);
    
    cvtColor(i, i, CV_BGR2GRAY);
    
    Mat mat = Mat(i.size(), CV_8UC1);
    
    GaussianBlur(i, i, cv::Size(7,7), 0);
    
//    adaptiveThreshold(i, mat, 255, ADAPTIVE_THRESH_MEAN_C, THRESH_BINARY, 5, 5);
//    image = MatToUIImage(mat);
    
    threshold(i, mat, 0, 255, CV_THRESH_BINARY_INV | CV_THRESH_OTSU);
    
    Mat threeKernel = getStructuringElement(MORPH_CROSS, cv::Size(3,3));
    Mat fiveKernel = getStructuringElement(MORPH_CROSS, cv::Size(5,5));
    morphologyEx(mat, mat, MORPH_OPEN, fiveKernel);
    
    int count = 0;
    int max = -1;
    
    cv::Point maxPt;
    
    for(int y=0;y<mat.size().height;y++)
    {
        uchar *row = mat.ptr(y);
        for(int x=0;x<mat.size().width;x++)
        {
            if(row[x]>=128)
            {
                int area = floodFill(mat, cv::Point(x,y), CV_RGB(0,0,64));
                
                if(area>max)
                {
                    maxPt = cv::Point(x,y);
                    max = area;
                }
            }
        }
        
    }
    
    floodFill(mat, maxPt, CV_RGB(255,255,255));
    
    for(int y=0;y<mat.size().height;y++)
    {
        uchar *row = mat.ptr(y);
        for(int x=0;x<mat.size().width;x++)
        {
            if(row[x]==64 && x!=maxPt.x && y!=maxPt.y)
            {
                int area = floodFill(mat, cv::Point(x,y), CV_RGB(0,0,0));
            }
        }
    }
    
    morphologyEx(mat, mat, MORPH_CLOSE, fiveKernel);
    erode(mat, mat, threeKernel);
    
    vector<vector<cv::Point>> contours;
    vector<Vec4i> hierarchy;
    findContours(mat, contours, hierarchy, CV_RETR_CCOMP, CV_CHAIN_APPROX_SIMPLE);
    RNG rng(12345);
    
    vector<vector<cv::Point>> filteredContours;
    vector<double> areas;
    vector<cv::Point> topCorners;
    vector<Moments> contourMoments;
    Moments m = {};
    vector<Point2f> contourCenters;
    cv::Rect bigBox;
    int dimension = [self getDimension:image];
    
    for (int i = 0; i < contours.size(); i++) {
        
        if (contourArea(contours[i]) < 500) continue;
        if (contourArea(contours[i]) > 200000) {
            bigBox = boundingRect(contours[i]);
            rectangle(underlay, bigBox.tl(), bigBox.br(), CV_RGB(0, 0, 0));
            continue;
        }
        filteredContours.push_back(contours[i]);
        areas.push_back(contourArea(contours[i]));
        m = moments(contours[i], false);
        contourCenters.push_back(Point2f(m.m10 / m.m00, m.m01 / m.m00));
        topCorners.push_back([self getTopCorner:contours[i]]);
        
    }
    
    vector<vector<cv::Point>> k = [self getCoordinates:filteredContours :areas :topCorners :contourCenters :dimension :bigBox];
    
    for (int i = 0; i < k.size(); i++) {
        NSMutableArray *currCords = [[NSMutableArray alloc] init];
        cv::Rect r(topCorners[i].x - 5, topCorners[i].y - 5, bigBox.width / dimension, (bigBox.height / dimension) / 2);
        cv::Mat cropped = underlay(r);
        [currCords addObject:MatToUIImage(cropped)];
        for (int j = 0; j < k[i].size(); j++) {
            NSMutableArray *thisCord = [[NSMutableArray alloc] init];
            NSNumber *thisX = [NSNumber numberWithInteger:k[i][j].x];
            NSNumber *thisY = [NSNumber numberWithInteger:k[i][j].y];
            [thisCord addObject:thisX];
            [thisCord addObject:thisY];
            [currCords addObject:thisCord];
        }
        [dict setObject:currCords forKey:[NSNumber numberWithInt:i]];
    }
    
    return;
}

+(vector<vector<cv::Point>>)getCoordinates:(vector<vector<cv::Point>>)contours :(vector<double>)areas :(vector<cv::Point>)topCorners :(vector<Point2f>)centers :(int)dim :(cv::Rect)bigBox {
    
    vector<vector<cv::Point>> allCords;
    
    // damn most of this could probably be optimized with a transposition
    for (int i = 0; i < contours.size(); i++) {
        
        int xcord = (topCorners[i].x - bigBox.x + (bigBox.width / (dim * 2))) / (bigBox.width / dim);
        int ycord = (topCorners[i].y - bigBox.y + (bigBox.height / (dim * 2))) / (bigBox.height / dim);
        int numCells = int(areas[i] * 1.2) / (bigBox.area() / (dim * dim));
        
        cout << xcord << "," << ycord << " - " << numCells << " cells" << endl;
        
        // if we're outside the bounds of the puzzle, quit like fuq
        if (numCells < 1 || xcord < 0 || xcord >= dim || ycord < 0 || ycord >= dim) {
            allCords.clear();
            break;
        }
        
        vector<cv::Point> cords; // current group coordinates
        cv::Rect bounds = boundingRect(contours[i]); // current group bounding rectangle
        double ratio = double(areas[i]) / double(bounds.area()); // ratio between area of group and area of bounding rectangle
        cv::Point boundsMid = cv::Point(bounds.x + bounds.width / 2, bounds.y + bounds.height / 2);
        
        // push back the first cell
        cords.push_back(cv::Point(xcord, ycord));
        
        // if the group represents a rectangle
        // goooood that's clean code.
        if (ratio > 0.8) {
            // if the y distance between the corner and the center is longer than the corresponding x distance, it's a vertical rectangle of length numCells
            // unless it's a 2x2 group, so we'll check for that
            if (numCells == 4 && (double(bounds.width) / double(bounds.height) < 2 || double(bounds.width) / double(bounds.height) > 0.5)) {
                cords.push_back(cv::Point(xcord, ycord + 1));
                cords.push_back(cv::Point(xcord + 1, ycord));
                cords.push_back(cv::Point(xcord + 1, ycord + 1));
            } else {
                bool t = abs(topCorners[i].y - centers[i].y) > abs(topCorners[i].x - centers[i].x);
                [self pushStack:(numCells - 1) :t :cords];
            }
            // unfortunately, need special cases for the rest, I think
        } else {
            if (numCells == 3) {
                // trust me
                bool a = topCorners[i].y < centers[i].y && centers[i].y < boundsMid.y;
                cords.push_back(cv::Point(xcord + int(a), ycord + int(!a)));
                
                // trust me again
                bool b = centers[i].x > boundsMid.x && centers[i].y < boundsMid.y;
                bool c = centers[i].x > boundsMid.x && centers[i].y > boundsMid.y;
                bool d = centers[i].x < boundsMid.x && centers[i].y > boundsMid.y;
                cords.push_back(cv::Point(xcord + int(b) - int(c) + int(d), ycord + 1));
            } else if (numCells == 4) {
                vector<cv::Point> morph;
                approxPolyDP(contours[i], morph, 0.05 * arcLength(contours[i], true), true);
                if (morph.size() > 6) { // could probably simplify this with math but fuuuuck that
                    if (double(bounds.width) / double(bounds.height) > 1) {
                        cords.push_back(cv::Point(xcord + 1, ycord + 1));
                        if (topCorners[i].x > bounds.x + 20) {
                            cords.push_back(cv::Point(xcord, ycord + 1));
                            cords.push_back(cv::Point(xcord - 1, ycord + 1));
                        } else {
                            cords.push_back(cv::Point(xcord + 1, ycord));
                            cords.push_back(cv::Point(xcord + 2, ycord));
                        }
                    } else {
                        cords.push_back(cv::Point(xcord, ycord + 1));
                        cords.push_back(cv::Point(xcord, ycord + 2));
                        if (topCorners[i].x > bounds.x + 20) {
                            cords.push_back(cv::Point(xcord - 1, ycord + 1));
                        } else {
                            cords.push_back(cv::Point(xcord + 1, ycord + 1));
                        }
                    }
                } else {
                    bool a = centers[i].x < boundsMid.x;
                    int b = 2 * int(a) - 1;
                    if (double(bounds.width) / double(bounds.height) > 1) {
                        if (centers[i].y > boundsMid.y) {
                            for (int i = 0; i < 3; i++) {
                                cords.push_back(cv::Point(xcord + b * i, ycord + 1));
                            }
                        } else {
                            cords.push_back(cv::Point(xcord + 1, ycord));
                            cords.push_back(cv::Point(xcord + 2, ycord));
                            cords.push_back(cv::Point(xcord + 2 * int(!a), ycord + 1));
                        }
                    } else {
                        if (centers[i].y < boundsMid.y) {
                            cords.push_back(cv::Point(xcord + 1, ycord));
                            cords.push_back(cv::Point(xcord + int(!a), ycord + 1));
                            cords.push_back(cv::Point(xcord + int(!a), ycord + 2));
                        } else {
                            cords.push_back(cv::Point(xcord, ycord + 1));
                            cords.push_back(cv::Point(xcord, ycord + 2));
                            cords.push_back(cv::Point(xcord + b, ycord + 2));
                        }
                    }
                }
            }
        }
        allCords.push_back(cords);
    }
    return allCords;
}

+(void)pushStack :(int)numToPush :(bool)isVertical :(vector<cv::Point>&)cordVector {
    for (int i = 1; i <= numToPush; i++) {
        cordVector.push_back(cv::Point(cordVector[0].x + int(!(isVertical)) * i, cordVector[0].y + int(isVertical) * i));
    }
}

+(cv::Point)getTopCorner:(vector<cv::Point>)contour {
    cv::Point extTop = *min_element(contour.begin(), contour.end(), [](const cv::Point& lhs, const cv::Point& rhs) { return lhs.y < rhs.y;});
    vector<cv::Point> temp;
    for (int i = 0; i < contour.size(); i++) {
        if (contour[i].y <= (extTop.y + 3)) {
            temp.push_back(contour[i]);
        }
    }
    return *min_element(temp.begin(), temp.end(), [](const cv::Point& lhs, const cv::Point& rhs) { return lhs.x < rhs.x; });
}

+(int)getDimension:(UIImage *)image {
    Mat i;
    UIImageToMat(image, i);
    
    cvtColor(i, i, CV_BGR2GRAY);
    
    Mat mat = Mat(i.size(), CV_8UC1);
    
    adaptiveThreshold(i, mat, 255, CV_ADAPTIVE_THRESH_MEAN_C, CV_THRESH_BINARY_INV, 101, 1);
    
    Mat horiz = Mat::zeros(1, 50, CV_32F);
    bitwise_not(horiz, horiz);
    erode(mat, mat, horiz);
    
    vector<vector<cv::Point>> contours;
    vector<Vec4i> hierarchy;
    findContours(mat, contours, hierarchy, CV_RETR_CCOMP, CV_CHAIN_APPROX_SIMPLE);
    
    int count = 0;
    for (int i = 0; i < contours.size(); i++) {
        if (arcLength(contours[i], true) > 400) {
            count++;
        }
    }
    
    return (count - 1);
}

+(UIImage *)debugProcessing:(UIImage *)image {
    
    Mat lol = [self preprocessText:image];
    
    return MatToUIImage(lol);
}

+(Mat)preprocessText:(UIImage *)image {
    Mat i;
    UIImageToMat(image, i);
    
    cvtColor(i, i, CV_BGR2GRAY);
    
    Mat mat = Mat(i.size(), CV_8UC1);
    
    adaptiveThreshold(i, mat, 255, CV_ADAPTIVE_THRESH_GAUSSIAN_C, CV_THRESH_BINARY_INV, 11, 11);
    
    Mat kernel = (Mat_<uchar>(3,3) << 0,1,0,1,1,1,0,1,0);
    
    vector<vector<cv::Point>> contours;
    vector<Vec4i> hierarchy;
    findContours(mat, contours, hierarchy, CV_RETR_CCOMP, CV_CHAIN_APPROX_SIMPLE);
    
    for (int i = 0; i < contours.size(); i++) {
        cv::Point& p = contours[i][0];
        if (arcLength(contours[i], true) > 200 && mat.ptr(p.y)[p.x] >= 128) {
            floodFill(mat, p, CV_RGB(0, 0, 0));
        }
    }

    for (int y = 0; y < mat.size().height; y++) {
        uchar *row = mat.ptr(y);
        for (int x = 0; x < mat.size().width; x++) {
            if (y < 4 || y > mat.size().height - 4) {
                if (row[x] >= 128) {
                    floodFill(mat, cv::Point(x,y), CV_RGB(0, 0, 0));
                }
            } else {
                if (x < 4 || x > mat.size().width - 4) {
                    if (row[x] >= 128) {
                        floodFill(mat, cv::Point(x,y), CV_RGB(0, 0, 0));
                    }
                }
            }
        }
    }
    
//    erode(mat, mat, kernel);
//    dilate(mat, mat, kernel);

    bitwise_not(mat, mat);
    
    return mat;
}


@end
