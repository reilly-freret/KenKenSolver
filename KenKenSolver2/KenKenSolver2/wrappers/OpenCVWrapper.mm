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

-(NSString *) openCVVersionString
{
    return [NSString stringWithFormat:@"OpenCV Version %s", CV_VERSION];
}

+(UIImage *)extractGroups:(UIImage *)image
{
    Mat underlay = [self preprocessText:image];
    cvtColor(underlay, underlay, CV_GRAY2RGB);
    
    Mat i;
    UIImageToMat(image, i);
    
    cvtColor(i, i, CV_BGR2GRAY);
    
    Mat mat = Mat(i.size(), CV_8UC1);
    
    GaussianBlur(i, i, cv::Size(5,5), 0);
    
    adaptiveThreshold(i, mat, 255, ADAPTIVE_THRESH_MEAN_C, THRESH_BINARY, 5, 2);
    
    bitwise_not(mat, mat);
    
    Mat kernel = (Mat_<uchar>(3,3) << 0,1,0,1,1,1,0,1,0);
    
    dilate(mat, mat, kernel);
    
    
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
    
    Mat erosionKernel = (Mat_<uchar>(7,7) << 0,0,0,1,0,0,0,0,0,0,1,0,0,0,0,0,0,1,0,0,0,1,1,1,1,1,1,1,0,0,0,1,0,0,0,0,0,0,1,0,0,0,0,0,0,1,0,0,0);
    
    erode(mat, mat, erosionKernel);
    dilate(mat, mat, kernel);
    
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
        if (contourArea(contours[i]) > 250000) {
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
    
    for (int i = 0; i < filteredContours.size(); i++) {
        Scalar color = CV_RGB(rng.uniform(10, 200), rng.uniform(10, 200), rng.uniform(10, 200));
        drawContours(underlay, filteredContours, i, color);
        circle(underlay, contourCenters[i], 4, CV_RGB(255, 0, 0), -1);
        circle(underlay, topCorners[i], 4, CV_RGB(0, 0, 255), -1);
    }
    
    vector<vector<cv::Point>> k = [self getCoordinates:filteredContours :areas :topCorners :contourCenters :dimension :bigBox];
    
    //return k;
    
    UIImage *newImg = MatToUIImage(underlay);
    
    return newImg;
}

+(vector<vector<cv::Point>>)getCoordinates:(vector<vector<cv::Point>>)contours :(vector<double>)areas :(vector<cv::Point>)topCorners :(vector<Point2f>)centers :(int)dim :(cv::Rect)bigBox {
    cout << "big box area: " << bigBox.area() << " width: " << bigBox.width << endl;
    cout << "dim: " << dim << endl;
    
    vector<vector<cv::Point>> allCords;
    
    // damn most of this could probably be optimized with a transposition
    for (int i = 0; i < contours.size(); i++) {
        
        int xcord = (topCorners[i].x - bigBox.x + (bigBox.width / (dim * 2))) / (bigBox.width / dim);
        int ycord = (topCorners[i].y - bigBox.y + (bigBox.height / (dim * 2))) / (bigBox.height / dim);
        int numCells = int(areas[i] * 1.3) / (bigBox.area() / (dim * dim));
        
        // if we're outside the bounds of the puzzle, quit like fuq
        if (numCells < 1 || xcord < 0 || xcord >= dim || ycord < 0 || ycord >= dim) {
            allCords.clear();
            cout << "fuck" << endl;
            break;
        }
        
        vector<cv::Point> cords; // current group coordinates
        cv::Rect bounds = boundingRect(contours[i]); // current group bounding rectangle
        double ratio = double(areas[i]) / double(bounds.area()); // ratio between area of group and area of bounding rectangle
        cv::Point boundsMid = cv::Point(bounds.x + bounds.width / 2, bounds.y + bounds.height / 2);
        
        cout << "x: " << xcord << " y: " << ycord << endl;
        cout << "cells: " << numCells << endl;
        cout << "b.x: " << bounds.x << " b.y: " << bounds.y << endl;
        cout << "ratio: " << ratio << "\n" << endl;
        
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
                cout << "rectangle, t = " << t << "\n" << endl;
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
                cout << "case 2, 3 cells" << endl;
                cout << centers[i].x << " " << centers[i].y << " " << boundsMid.x << " " << boundsMid.y << " " << endl;
                cout << a << " " << b << " " << c << " " << d << "\n" << endl;
                cords.push_back(cv::Point(xcord + int(b) - int(c) + int(d), ycord + 1));
            } else if (numCells == 4) {
                vector<cv::Point> morph;
                approxPolyDP(contours[i], morph, 0.05 * arcLength(contours[i], true), true);
                cout << "morph size: " << morph.size() << endl;
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
                    cout << "a: " << a << endl;
                    cout << "width/height: " << bounds.width / bounds.height << endl;
                    bool b = 2 * int(a) - 1;
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
    cout << "\n" << allCords.size() << "\n" << endl;
    for (int i = 0; i < allCords.size(); i++) {
        cout << "cell " << i << ": ";
        for (int j = 0; j < allCords[i].size(); j ++) {
            cout << "(" << allCords[i][j].x << "," << allCords[i][j].y << ") ";
        }
        cout << endl;
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

+(Mat)preprocessText:(UIImage *)image {
    Mat i;
    UIImageToMat(image, i);
    
    cvtColor(i, i, CV_BGR2GRAY);
    
    Mat mat = Mat(i.size(), CV_8UC1);
    
    adaptiveThreshold(i, mat, 255, CV_ADAPTIVE_THRESH_MEAN_C, CV_THRESH_BINARY_INV, 5, 7);
    
    vector<vector<cv::Point>> contours;
    vector<Vec4i> hierarchy;
    findContours(mat, contours, hierarchy, CV_RETR_CCOMP, CV_CHAIN_APPROX_SIMPLE);
    
    for (int i = 0; i < contours.size(); i++) {
        cv::Point& p = contours[i][0];
        if (arcLength(contours[i], true) > 120 && mat.ptr(p.y)[p.x] >= 128) {
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
    
    bitwise_not(mat, mat);
    
    return mat;
}


@end
