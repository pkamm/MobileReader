//
//  UpdateUtilities.m
//  DigitasPocketReader
//
//  Created by Peter Kamm on 1/21/14.
//  Copyright (c) 2014 Digitas. All rights reserved.
//

#import "UpdateUtilities.h"
#import <AFNetworkReachabilityManager.h>


@implementation UpdateUtilities

+(void)checkForUpdatedApp:(id)delegate{
    NSDate *lastUpdate = [[NSUserDefaults standardUserDefaults] objectForKey:@"lastUpdateDate"] ;
    
  //  if ([lastUpdate timeIntervalSinceNow] < UPDATE_DURATION ) {
    
        NSURLRequest *request = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/MobileReader.ipa", BASE_APP_URL]]];
        NSHTTPURLResponse *response;

    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[[NSOperationQueue alloc] init]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                               if( [response respondsToSelector:@selector( allHeaderFields )] )
                               {
                                   NSDictionary *metaData = [(NSHTTPURLResponse*)response allHeaderFields];
                                   NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                                   [formatter setDateFormat:@"EEE, dd MMM yyyy HH:mm:ss zzz"];
                                   NSString *lastModifiedString = [metaData objectForKey:@"Last-Modified"];
                                   
                                   NSDate *webAppUpdateDate = [formatter dateFromString:lastModifiedString];
                                   
                                   if ([webAppUpdateDate laterDate:lastUpdate] == webAppUpdateDate) {
                                       
                                       UIAlertView *updateAlert = [[UIAlertView alloc] initWithTitle:@"Update Available" message:@"Please download the new update in order to use this app" delegate:delegate cancelButtonTitle:@"Download Now" otherButtonTitles: nil];
                                       [updateAlert show];
                                       
                                   }else{
                                       [[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:@"lastUpdateDate"];
                                   }
                               }

                           }];
    
 //   [NSURLConnection sen
//    
//        [NSURLConnection sendSynchronousRequest:request
//                              returningResponse:&response
//                                          error:nil];
//        
//        if( [response respondsToSelector:@selector( allHeaderFields )] )
//        {
//            NSDictionary *metaData = [response allHeaderFields];
//            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
//            [formatter setDateFormat:@"EEE, dd MMM yyyy HH:mm:ss zzz"];
//            NSString *lastModifiedString = [metaData objectForKey:@"Last-Modified"];
//
//            NSDate *webAppUpdateDate = [formatter dateFromString:lastModifiedString];
//            
//            if ([webAppUpdateDate laterDate:lastUpdate] == webAppUpdateDate) {
//                
//                UIAlertView *updateAlert = [[UIAlertView alloc] initWithTitle:@"Update Available" message:@"Please download the new update in order to use this app" delegate:delegate cancelButtonTitle:@"Download Now" otherButtonTitles: nil];
//                [updateAlert show];
//                
//            }else{
//                [[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:@"lastUpdateDate"];
//            }
//        }

//    }
}

+(BOOL)isAlertViewShowing{
    for (UIWindow* window in [UIApplication sharedApplication].windows){
        for (UIView *subView in [window subviews]){
            if ([subView isKindOfClass:[UIAlertView class]]) {
                return YES;
            }
        }
    }
    return NO;
}


@end
