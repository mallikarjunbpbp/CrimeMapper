//
//  ViewController.m
//  CrimeMapper
//
//  Created by Mallikarjun Patil on 2/11/16.
//  Copyright © 2016 Mallikarjun. All rights reserved.
//

#import "ViewController.h"
CGFloat const kMeterPerMile = 1609.344f ;

@interface ViewController (){
    int offset;
    NSDateFormatter *formatter;
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [_centerButton setEnabled:NO];
    UINavigationBar *navigationBar = self.navigationController.navigationBar;
    
    _session = [NSURLSession sharedSession];
    formatter = [self dateFormatter];
    offset=0;
    
    [navigationBar setBarTintColor:[UIColor colorWithRed:244.0/255.0 green:146.0/255.0 blue:10.0/255.0 alpha:1]];
    [navigationBar setTintColor:[UIColor whiteColor]];
    [navigationBar setTranslucent:NO];
    
    _colorArray= [NSMutableArray arrayWithObjects:[UIColor colorWithRed:1 green:0 blue:0 alpha:1],[UIColor colorWithRed:0.922 green:0.212 blue:0 alpha:1], [UIColor colorWithRed:0.898 green:0.282 blue:0 alpha:1.0], [UIColor colorWithRed:0.847 green:0.427 blue:0 alpha:1.0], [UIColor colorWithRed:0.824 green:0.498 blue:0 alpha:1.0], [UIColor colorWithRed:0.773 green:0.639 blue:0 alpha:1.0], [UIColor colorWithRed:0.725 green:0.784 blue:0 alpha:1.0], [UIColor colorWithRed:0.651 green:1 blue:0 alpha:1.0], nil];
    
    [_mapView setDelegate:self];
    [self getAnnotations];
    [self reloadToolBar];
}

- (NSDateFormatter *)dateFormatter {
    static NSDateFormatter *dateFormatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dateFormatter = [[NSDateFormatter alloc] init];
    });
    
    return dateFormatter;
}

-(void)viewWillAppear:(BOOL)animated{
    CLLocationCoordinate2D zoomLocation;
    zoomLocation.latitude = 37.765279;
    zoomLocation.longitude= -122.455111;
    MKCoordinateRegion viewRegion = MKCoordinateRegionMakeWithDistance(zoomLocation, 10*kMeterPerMile, 10*kMeterPerMile);
    [_mapView setRegion:viewRegion animated:YES];
}

-(void)getAnnotations{

    [formatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss"];
    
    NSDate *currentDate = [NSDate date];
    NSDateComponents *dateComponents = [[NSDateComponents alloc] init];
    [dateComponents setMonth:-3];
    NSDate *lastMonth = [[NSCalendar currentCalendar] dateByAddingComponents:dateComponents toDate:currentDate options:0];
    
    NSString* urlString = [NSString stringWithFormat:@"https://data.sfgov.org/resource/ritf-b9ki.json?$limit=25&$offset=%d&$where=date>\'%@\'",offset,[formatter stringFromDate:lastMonth]];
    
    [_loadingIndicator startAnimating];
    [_loadingIndicator setHidden:NO];
    _jsonArray=[NSMutableArray array];
    [_mapView removeAnnotations:_mapView.annotations];
    
    NSCharacterSet *set = [NSCharacterSet URLQueryAllowedCharacterSet];
    
    NSURLSessionDataTask *dataTask = [_session dataTaskWithURL:[NSURL URLWithString:[urlString stringByAddingPercentEncodingWithAllowedCharacters:set]]  completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        
        if (error!=nil) {
            [_loadingIndicator stopAnimating];
            [_loadingIndicator setHidden:YES];
            return ;
        }
        
        NSObject *jsonObject= [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        
        if ([jsonObject isKindOfClass:[NSArray class]]) {
            _jsonArray =(NSMutableArray*)jsonObject;
            
            if([_jsonArray count]==0){
                //disable the right button
                [_loadingIndicator stopAnimating];
                [_loadingIndicator setHidden:YES];
                return;
                
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                [self plotOnMapView];
            });
        }
        
    }];
    [dataTask resume];
    
}

-(void)reloadToolBar{
    
    NSString *title = (offset == 0) ? @"" : @"Prev";
    [_leftButton setTitle:title];
    
    [_centerButton setTitle:[NSString stringWithFormat:@"Page %d",offset+1]];
    [_rightButton setTitle:@"Next"];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)plotOnMapView{
    
    NSString *latitude;
    NSString *longitude;
    CLLocationDegrees lat;
    CLLocationDegrees longi;
    NSString* category;
    NSString* address;
    NSDictionary *dictionary;
    NSMutableDictionary *districtCountDict = [[NSMutableDictionary alloc] init];
    NSString*districtName;
    UserAnnotation *userAnnotation;
    NSNumber *districtCount;
    int count;
    NSArray *sortedArray;
    for(int i=0;i<[_jsonArray count];i++){
        
        dictionary = _jsonArray[i];
        latitude = dictionary[@"y"];
        lat = [latitude doubleValue];
        
        longitude = dictionary[@"x"];
        longi = [longitude doubleValue];
        
        address = dictionary[@"address"];
        category = dictionary[@"category"];
        
        userAnnotation = [[UserAnnotation alloc]init];
        userAnnotation.coordinate = CLLocationCoordinate2DMake(lat,longi);
        userAnnotation.title = category;
        userAnnotation.subtitle = address;
        userAnnotation.index=i;
        [self.mapView addAnnotation:userAnnotation];
        
        //Get the count of crimes ina district.
        districtName =dictionary[@"pddistrict"];
        
        if(districtCountDict[districtName] == nil){
            districtCountDict[districtName] = @1;
        }else {
            districtCount =districtCountDict[districtName];
            count =  [districtCount intValue];
            count++;
            districtCountDict[districtName] = [NSNumber numberWithInt:count];
        }
    }
    
    sortedArray = [districtCountDict keysSortedByValueUsingComparator: ^(id obj1, id obj2) {
        
        //Sort in descending order
        return [obj2 compare:obj1];
    }];
    
    _colorDictionary= [[NSMutableDictionary alloc] init];
    for (int i=0;i<[sortedArray count];i++) {
        if(i>=7){
            _colorDictionary[sortedArray[i]] =_colorArray[7];
        }else
            _colorDictionary[sortedArray[i]]=_colorArray[i];
        
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
        
        NSDictionary* dataObject=_jsonArray[userAnnotation.index];
        
        annView.canShowCallout = YES;
        NSString* districtName=dataObject[@"pddistrict"];
        annView.pinTintColor = _colorDictionary[districtName];
        
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
