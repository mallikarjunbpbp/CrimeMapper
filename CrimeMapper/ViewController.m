//
//  ViewController.m
//  CrimeMapper
//
//  Created by Mallikarjun Patil on 2/11/16.
//  Copyright © 2016 Mallikarjun. All rights reserved.
//

#import "ViewController.h"
#define METERS_PER_MILE 1609.344


@interface ViewController ()

@end

@implementation ViewController

int offset=0;

- (void)viewDidLoad {
    [super viewDidLoad];
    [_centerButton setEnabled:NO];
    UINavigationBar *navigationBar = self.navigationController.navigationBar;
    
    [navigationBar setBarTintColor:[UIColor colorWithRed:244.0/255.0 green:146.0/255.0 blue:10.0/255.0 alpha:1]];
    [navigationBar setTintColor:[UIColor whiteColor]];
    [navigationBar setTranslucent:NO];
    //ff0000,
    _colorArray= [NSMutableArray arrayWithObjects:[UIColor colorWithRed:1 green:0 blue:0 alpha:1],[UIColor colorWithRed:0.922 green:0.212 blue:0 alpha:1], [UIColor colorWithRed:0.898 green:0.282 blue:0 alpha:1.0], [UIColor colorWithRed:0.847 green:0.427 blue:0 alpha:1.0], [UIColor colorWithRed:0.824 green:0.498 blue:0 alpha:1.0], [UIColor colorWithRed:0.773 green:0.639 blue:0 alpha:1.0], [UIColor colorWithRed:0.725 green:0.784 blue:0 alpha:1.0], [UIColor colorWithRed:0.651 green:1 blue:0 alpha:1.0], nil];
    [_mapView setDelegate:self];
    [self getAnnotations];
    [self reloadToolBar];
}

-(void)viewWillAppear:(BOOL)animated{
    CLLocationCoordinate2D zoomLocation;
    zoomLocation.latitude = 37.765279;
    zoomLocation.longitude= -122.455111;
    MKCoordinateRegion viewRegion = MKCoordinateRegionMakeWithDistance(zoomLocation, 10*METERS_PER_MILE, 10*METERS_PER_MILE);
    [_mapView setRegion:viewRegion animated:YES];
}
-(void)getAnnotations{
    
    NSURLSession *session = [NSURLSession sharedSession];
    NSLog(@"Offset is %d", offset);
    //, offset
    NSString* urlString = [NSString stringWithFormat:@"https://data.sfgov.org/resource/ritf-b9ki.json?$limit=25&$offset=%d",offset];
    [_loadingIndicator startAnimating];
    [_loadingIndicator setHidden:NO];
    _jsonArray=[NSMutableArray array];
    [_mapView removeAnnotations:_mapView.annotations];
    NSURLSessionDataTask *dataTask = [session dataTaskWithURL:[NSURL URLWithString:urlString] completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        
        if (error!=nil) {
            NSLog(@"error %@", error);
            [_loadingIndicator stopAnimating];
            [_loadingIndicator setHidden:YES];
            return ;
        }
        
        NSObject *jsonObject= [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        
        if ([jsonObject isKindOfClass:[NSArray class]]) {
            _jsonArray =(NSMutableArray*)jsonObject;
            
            //check this code
            if([_jsonArray count]==0){
                //disable the right button
                [_loadingIndicator stopAnimating];
                [_loadingIndicator setHidden:YES];
                return;
                
            }
            NSLog(@" jsonData - %@", _jsonArray);
            dispatch_async(dispatch_get_main_queue(), ^{
                [self plotOnMapView];
            });
        }
        
    }];
    [dataTask resume];
    
}

-(void)reloadToolBar{
    if(offset==0){
        [_leftButton setTitle:@""];
    }else {
        [_leftButton setTitle:@"Prev"];
    }
    
    [_centerButton setTitle:[NSString stringWithFormat:@"Page %d",offset+1]];
    [_rightButton setTitle:@"Next"];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)plotOnMapView{
    
    CLLocationDegrees lat;
    CLLocationDegrees longi;
    NSString* category;
    NSString* address;
    NSMutableDictionary *districtCountDict = [[NSMutableDictionary alloc] init];
    NSString*districtName;
    int count;
    for(int i=0;i<[_jsonArray count];i++){
        
        lat = [[[_jsonArray objectAtIndex:i] objectForKey:@"y"] doubleValue];
        longi = [[[_jsonArray objectAtIndex:i] objectForKey:@"x"] doubleValue];
        address = [[_jsonArray objectAtIndex:i] objectForKey:@"address"];
        category = [[_jsonArray objectAtIndex:i] objectForKey:@"category"];
        UserAnnotation *userAnnotation = [[UserAnnotation alloc]init];
        userAnnotation.coordinate = CLLocationCoordinate2DMake(lat,longi);
        userAnnotation.title = category;
        userAnnotation.subtitle = address;
        userAnnotation.index=i;
        [self.mapView addAnnotation:userAnnotation];
        
        //Get the count of crimes ina district.
        districtName = [[_jsonArray objectAtIndex:i] objectForKey:@"pddistrict"];
        if([districtCountDict objectForKey:districtName] == nil){
            [districtCountDict setObject:@1 forKey:districtName];
        }else {
            count = [[districtCountDict objectForKey:districtName] intValue];
            count++;
            [districtCountDict setObject:[NSNumber numberWithInt:count] forKey:districtName];
        }
    }
    
    NSLog(@" districtName %@", districtCountDict);
    NSArray *sortedArray;
    
    sortedArray = [districtCountDict keysSortedByValueUsingComparator: ^(id obj1, id obj2) {
        
        if ([obj1 integerValue] < [obj2 integerValue]) {
            
            return (NSComparisonResult)NSOrderedDescending;
        }
        if ([obj1 integerValue] >[obj2 integerValue]) {
            
            return (NSComparisonResult)NSOrderedAscending;
        }
        
        return (NSComparisonResult)NSOrderedSame;
    }];
    
    NSLog(@" sortedArray %@", sortedArray);
    
    _colorDictionary= [[NSMutableDictionary alloc] init];
    for (int i=0;i<[sortedArray count];i++) {
        if(i>=7){
            [_colorDictionary setObject:[_colorArray objectAtIndex:7] forKey:[sortedArray objectAtIndex:i]];
        }else
            [_colorDictionary setObject:[_colorArray objectAtIndex:i] forKey:[sortedArray objectAtIndex:i]];
        
    }
    
    
    [_loadingIndicator stopAnimating];
    [_loadingIndicator setHidden:YES];
    
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation
{
    // If it's the user location, just return nil.
    if ([annotation isKindOfClass:[MKUserLocation class]])
        return nil;
    
    if ([annotation isKindOfClass:[UserAnnotation class]]) {
        MKPinAnnotationView *annView=[[MKPinAnnotationView alloc]initWithAnnotation:annotation reuseIdentifier:@"pin"];
        UserAnnotation *userAnnotation = (UserAnnotation *)annotation;
        
        NSDictionary* dataObject=[_jsonArray objectAtIndex:userAnnotation.index];
        
        annView.canShowCallout = YES;
        annView.pinTintColor = [_colorDictionary objectForKey:[dataObject objectForKey:@"pddistrict"]];
        //        annView.pinTintColor = [UIColor colorWithRed:red green:green blue:blue alpha:1];
        
        return annView;
    }
    
    return nil;
}


- (IBAction)leftButtonPressed:(id)sender {
    
    if(offset==0){
        return;
    }
    offset--;
    [self getAnnotations];
    [self reloadToolBar];
    
}

- (IBAction)rightButtonPressed:(id)sender {
    
    offset++;
    [self getAnnotations];
    [self reloadToolBar];
    
}
@end
