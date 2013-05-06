//
//  GCSVideoAnnotationView.h
//  iGCS
//
//  Created by Andrew Brown on 5/6/13.
//
//

#import <MapKit/MapKit.h>
#import "KxMovieViewController.h"

@interface GCSVideoAnnotationView : MKAnnotationView {
    KxMovieViewController *_movieController;
}

@end
