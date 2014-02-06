//
//  UpdateUtilities.h
//  DigitasPocketReader
//
//  Created by Peter Kamm on 1/21/14.
//  Copyright (c) 2014 Digitas. All rights reserved.
//

#import <Foundation/Foundation.h>

#define UPDATE_DURATION 60*60*24*7

@interface UpdateUtilities : NSObject

+(void)checkForUpdatedApp:(id)delegate;
+(BOOL)isAlertViewShowing;



@end
