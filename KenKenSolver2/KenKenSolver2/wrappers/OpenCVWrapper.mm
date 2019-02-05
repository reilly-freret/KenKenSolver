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


// MARK: experimental visualization shiet

bool comparePoints(cv::Point a, cv::Point b) {
    if (abs(a.y - b.y) <= 10) {
        if (a.x / 3 <= b.x / 3) {
            return true;
        }
    }
    return false;
}


+(UIImage *)testIntersectionDetection:(UIImage *)image; {
    
    Mat original;
    UIImageToMat(image, original);
    cvtColor(original, original, CV_BGR2GRAY);
    Mat adapted = Mat(original.size(), CV_8UC1);
    GaussianBlur(original, original, cv::Size(3,3), 0);
    adaptiveThreshold(original, adapted, 255, CV_ADAPTIVE_THRESH_MEAN_C, THRESH_BINARY_INV, 9, 10);
    
    Mat horiz, vert;
    adapted.copyTo(horiz);
    adapted.copyTo(vert);

    Mat horizStructure = getStructuringElement(MORPH_RECT, cv::Size(horiz.rows / 20, 2));
    morphologyEx(horiz, horiz, MORPH_OPEN, horizStructure);
    dilate(horiz, horiz, horizStructure);
    
    Mat vertStructure = getStructuringElement(MORPH_RECT, cv::Size(2, horiz.cols / 20));
    morphologyEx(vert, vert, MORPH_OPEN, vertStructure);
    dilate(vert, vert, vertStructure);
    
    Mat dest;
    bitwise_and(vert, horiz, dest);
    Mat colorTest;
    cvtColor(original, colorTest, CV_GRAY2BGR);
    
    Mat labels, stats, centroids;
    int nothing = connectedComponentsWithStats(dest, labels, stats, centroids);
    
    vector<cv::Point> points;
    
    for (int i = 1; i < centroids.rows; i++) {
        
        int x = int(centroids.row(i).at<double>(0));
        int y = int(centroids.row(i).at<double>(1));
        points.push_back(cv::Point(x, y));
        
    }
    
    
    stable_sort(points.begin(), points.end(), comparePoints);
    
    int count = 0;
    for (cv::Point p : points) {
        circle(colorTest, p, 4, Scalar(255, 0, 0), CV_FILLED);
        putText(colorTest, to_string(count++), cv::Point(p.x + 4, p.y + 4), FONT_HERSHEY_PLAIN, 3.0, Scalar(0, 0, 255));
    }
    
    vector<cv::Point> maps;
    int dim = [self getDimension:image];
    int inset = 80; // probably make this even
    int pixels = colorTest.cols - inset;
    
    for (int i = 0; i < dim + 1; i++) {
        for (int j = 0; j < dim + 1; j++) {
            int step = (pixels / dim);
            circle(colorTest, cv::Point(step * j + inset / 2, step * i + inset / 2), 4, Scalar(0, 0, 255), CV_FILLED);
            maps.push_back(cv::Point(step * j + inset / 2, step * i + inset / 2));
        }
    }
    
    Mat hom = findHomography(points, maps, CV_RANSAC);
    Mat result;
    warpPerspective(original, result, hom, original.size());

    cvtColor(result, result, CV_GRAY2BGR);
    return MatToUIImage(result);
//    return MatToUIImage(dest);
//    return MatToUIImage(adapted);
    
    
}

+(UIImage *)testGridExtraction:(UIImage *)image; {
    
    Mat i;
    UIImageToMat(image, i);
    cvtColor(i, i, CV_BGR2GRAY);
    Mat mat = Mat(i.size(), CV_8UC1);
    GaussianBlur(i, i, cv::Size(21,21), 0);
    adaptiveThreshold(i, mat, 255, ADAPTIVE_THRESH_MEAN_C, THRESH_BINARY_INV, 5, 2);
    morphologyEx(mat, mat, MORPH_OPEN, getStructuringElement(MORPH_ELLIPSE, cv::Size(3,3)));

    Mat labels;
    int asdf = connectedComponents(mat, labels);
    compare(labels, 1, mat, CMP_EQ);
    
    morphologyEx(mat, mat, MORPH_CLOSE, getStructuringElement(MORPH_ELLIPSE, cv::Size(7,7)));
    
    return MatToUIImage(mat);
    
}

//

//+(UIImage *)extractGroups:(UIImage *)image
+(void)extractGroups:(UIImage *)image :(NSMutableDictionary *)dict;
{
    
    // send image off for text processing (which happens to be magical, apparently, because I can't remember doing it)
    Mat underlay = [self preprocessText:image];
    cvtColor(underlay, underlay, CV_GRAY2RGB);
    
    // preprocess for lifting groups
    // TODO: flatten image using:
        // findHomography between theoretical "flat" grid vertices and actual grid vertices
        // map using either remap() or warpPerspective(), so whole thing is flat, occupying the same space
    
    // first, make greyscale and apply blur, threshold, and morphological open
    Mat i;
    UIImageToMat(image, i);
    cvtColor(i, i, CV_BGR2GRAY);
    Mat mat = Mat(i.size(), CV_8UC1);
    GaussianBlur(i, i, cv::Size(21,21), 0);
    adaptiveThreshold(i, mat, 255, ADAPTIVE_THRESH_MEAN_C, THRESH_BINARY_INV, 5, 2);
    morphologyEx(mat, mat, MORPH_OPEN, getStructuringElement(MORPH_ELLIPSE, cv::Size(3,3)));
    // then, cover up everything but the first (upper-leftmost) blob (which happens to be the grid)
    const int connectivity_8 = 8;
    Mat labels, stats, centroids;
    int nLabels = connectedComponentsWithStats(mat, labels, stats, centroids, connectivity_8, CV_32S);
    compare(labels, 1, mat, CMP_EQ);

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

+(bool)inRange:(unsigned)low :(unsigned)high :(unsigned)x {
    return ((x - low) <= (high - low));
}

+(vector<vector<cv::Point>>)getCoordinates:(vector<vector<cv::Point>>)contours :(vector<double>)areas :(vector<cv::Point>)topCorners :(vector<Point2f>)centers :(int)dim :(cv::Rect)bigBox {
    
    vector<vector<cv::Point>> allCords;
    
    // damn most of this could probably be optimized with a transposition
    for (int i = 0; i < contours.size(); i++) {
        
        int xcord = (topCorners[i].x - bigBox.x + (bigBox.width / (dim * 1.8))) / (bigBox.width / dim);
        int ycord = (topCorners[i].y - bigBox.y + (bigBox.height / (dim * 1.8))) / (bigBox.height / dim);
        int numCells = int(areas[i] * 1.3) / (bigBox.area() / (dim * dim));
        
        // if we're outside the bounds of the puzzle, quit like fuq
        if (numCells < 1 || xcord < 0 || xcord >= dim || ycord < 0 || ycord >= dim) {
            allCords.clear();
            cout << "broken" << endl;
            cout << numCells << " " << dim << " " << xcord << " " << ycord << endl;
            break;
        }
        
        cout << "cells: " << numCells << endl;
        
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
                cout << "\nHERHEERE\n" << endl;
                vector<cv::Point> morph;
                approxPolyDP(contours[i], morph, 0.03 * arcLength(contours[i], true), true);
                cout << morph << endl;
                if (morph.size() > 6) { // could probably simplify this with math but fuuuuck that
                    cout << "\n========\nhere!\n========\n" << endl;
                    if ([self inRange:boundsMid.x - 5 :boundsMid.x + 5 :centers[i].x] && [self inRange:boundsMid.y - 5 :boundsMid.y + 5 :centers[i].y]) {
                        if (double(bounds.width) / double(bounds.height) < 1) {
                            cords.push_back(cv::Point(xcord, ycord + 1));
                            if (topCorners[i].x > bounds.x + 15) {
                                cords.push_back(cv::Point(xcord - 1, ycord + 1));
                                cords.push_back(cv::Point(xcord - 1, ycord + 2));
                            } else {
                                cords.push_back(cv::Point(xcord + 1, ycord + 1));
                                cords.push_back(cv::Point(xcord + 1, ycord + 2));
                            }
                        } else {
                            cords.push_back(cv::Point(xcord + 1, ycord));
                            if (topCorners[i].x > bounds.x + 15) {
                                cords.push_back(cv::Point(xcord, ycord + 1));
                                cords.push_back(cv::Point(xcord - 1, ycord + 1));
                            } else {
                                cords.push_back(cv::Point(xcord + 1, ycord + 1));
                                cords.push_back(cv::Point(xcord + 2, ycord + 1));
                            }
                        }
                    } else {
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
                    }
                    cout << cords << endl;
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
    
    bitwise_not(mat, mat);
    
    image = MatToUIImage(mat);
    
    
    return mat;
}


@end
