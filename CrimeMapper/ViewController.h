
//
//  ViewController.h
//  CrimeMapper
//
//  Created by Mallikarjun Patil on 2/11/16.
//  Copyright © 2016 Mallikarjun. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "UserAnnotation.h"

@interface ViewController : UIViewController<MKMapViewDelegate,  CLLocationManagerDelegate>

@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property(strong, nonatomic) NSMutableArray*jsonArray;
@property(strong, nonatomic) NSMutableArray*colorArray;
@property(strong, nonatomic) NSMutableDictionary*colorDictionary;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *loadingIndicator;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *leftButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *centerButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *rightButton;
- (IBAction)leftButtonPressed:(id)sender;

- (IBAction)rightButtonPressed:(id)sender;

@end

