//
//  UserAnnotation.h
//  CrimeMapper
//
//  Created by Mallikarjun Patil on 2/11/16.
//  Copyright © 2016 Mallikarjun. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@interface UserAnnotation : NSObject<MKAnnotation>

@property (nonatomic, assign)   CLLocationCoordinate2D  coordinate;
@property (nonatomic, copy)     NSString*               title;
@property (nonatomic, copy)     NSString*               subtitle;
@property NSInteger index;

@end
