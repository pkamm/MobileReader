//
//  MasterViewController.h
//  DigitasPocketReader
//
//  Created by Peter Kamm on 10/18/13.
//  Copyright (c) 2013 Digitas. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import <QuartzCore/QuartzCore.h>

@class DetailViewController;


@interface MasterViewController : UITableViewController <NSFetchedResultsControllerDelegate, UIAlertViewDelegate>

@property (strong, nonatomic) DetailViewController *detailViewController;

@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;

@property (strong, nonatomic) UIImageView *brandLogo;
//@property (strong, nonatomic) ODRefreshControl *refreshControl;

//- (NSFetchedResultsController *)allFetchedResultsController;

@end
