//
//  MasterViewController.m
//  DigitasPocketReader
//
//  Created by Peter Kamm on 10/18/13.
//  Copyright (c) 2013 Digitas. All rights reserved.
//

#import "MasterViewController.h"
#import "DetailViewController.h"
#import "AppDelegate.h"
#import "UpdateUtilities.h"
#import "AFNetworking.h"
#import <AFImageDownloader.h>
#import <UIImageView+AFNetworking.h>
#import "ArticleTableViewCell.h"
#import <QuartzCore/CALayer.h>
#import <QuartzCore/QuartzCore.h>
#import <DLAVAlertView.h>

@interface MasterViewController ()
- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath;
@end

#define HEADER_HT 0

#define ALERT_VIEW_CODE_INPUT 1001
#define ALERT_VIEW_CODE_ERROR 1002

@implementation MasterViewController

- (void)awakeFromNib
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        self.clearsSelectionOnViewWillAppear = NO;
        self.preferredContentSize = CGSizeMake(320.0, 600.0);
    }
    [super awakeFromNib];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName : [UIColor redColor]};
	// Do any additional setup after loading the view, typically from a nib.

    self.detailViewController = (DetailViewController *)[[self.splitViewController.viewControllers lastObject] topViewController];
    
    UIButton *digiLogo = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 35, 38)];
    [digiLogo setImage:[UIImage imageNamed:@"logo2-new.png"] forState:UIControlStateNormal];
    [digiLogo addTarget:self action:@selector(showEnterCodeView:) forControlEvents:UIControlEventTouchUpInside];
    
    UIBarButtonItem * leftItem = [[UIBarButtonItem alloc] initWithCustomView:digiLogo];
    self.navigationItem.leftBarButtonItem = leftItem;
    
    self.brandLogo = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 48, 40)];
    [self.brandLogo setContentMode:UIViewContentModeScaleAspectFit];
    [self.brandLogo.layer setCornerRadius:3.0f];
    [self.brandLogo.layer setMasksToBounds:YES];
    [self loadBrandImage];

    UIBarButtonItem * rightItem = [[UIBarButtonItem alloc] initWithCustomView:self.brandLogo];
    self.navigationItem.rightBarButtonItem = rightItem;
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(dropViewDidBeginRefreshing:) forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:self.refreshControl];
}

-(void)dropViewDidBeginRefreshing:(UIRefreshControl*)refreshControl{
    [self refreshArticlesWithCode:[[NSUserDefaults standardUserDefaults] objectForKey:@"url"] showWelcome:NO];
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    id tracker = [[GAI sharedInstance] defaultTracker];
    
    // This screen name value will remain set on the tracker and sent with
    // hits until it is set to a new value or to nil.
    [tracker set:kGAIScreenName value:@"Home Screen"];
    [tracker send:[[GAIDictionaryBuilder createAppView] build]];
    
    if (![[NSUserDefaults standardUserDefaults] objectForKey:@"url"] && ![UpdateUtilities isAlertViewShowing]) {
        [self showEnterCodeView:nil];
    }
}

-(void)showEnterCodeView:(id)sender{
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Welcome to the DigitasLBi Pocket Reader" message:@"Please enter your company code" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Enter", nil];
    [alert setAlertViewStyle:UIAlertViewStylePlainTextInput];
    [alert setTag:ALERT_VIEW_CODE_INPUT];
    [alert show];
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    
    switch (alertView.tag) {
        case ALERT_VIEW_CODE_INPUT:
            if (buttonIndex == 1) {
                [self.refreshControl beginRefreshing];
                [self.tableView setContentOffset:CGPointMake(0, -self.refreshControl.frame.size.height) animated:YES];
                [self refreshArticlesWithCode:[[[alertView textFieldAtIndex:0] text] lowercaseString] showWelcome:YES];
            }else if (![[NSUserDefaults standardUserDefaults] objectForKey:@"url"] && ![UpdateUtilities isAlertViewShowing]) {
                [self showEnterCodeView:nil];
            }
            break;
            
        case ALERT_VIEW_CODE_ERROR:
            if(![[NSUserDefaults standardUserDefaults] objectForKey:@"url"]) {
                [self showEnterCodeView:nil];
            }
            break;
            
        default:
            break;
    }
}


-(void)refreshArticlesWithCode:(NSString*)codeString showWelcome:(BOOL)showWelcome{
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/%@:urls.txt", BASE_APP_URL, codeString]]];
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *path = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"urls.txt"];
    operation.outputStream = [NSOutputStream outputStreamToFileAtPath:path append:NO];
    
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        if ([[NSUserDefaults standardUserDefaults] objectForKey:codeString]) { //Adding new code
            [self clearAllData];
        }
        [[NSUserDefaults standardUserDefaults] setObject:codeString forKey:@"url"];
        if (showWelcome) {
            [self showWelcomeSplash:codeString];
        }
        [self updateArticles:path];
        [self.refreshControl endRefreshing];
        id tracker = [[GAI sharedInstance] defaultTracker];
        
        [tracker set:kGAIScreenName value:[NSString stringWithFormat:@"Enter Code: %@", codeString]];
        [tracker send:[[GAIDictionaryBuilder createAppView] build]];

    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Sorry!" message:@"The code you entered is not valid.  Please double check it and try again." delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
        [alert setTag:ALERT_VIEW_CODE_ERROR];
        [alert show];
        [self.refreshControl endRefreshing];
    }];
    
    [operation start];
}

-(void)showWelcomeSplash:(NSString*)codeString{

    NSURLRequest *urlRequest = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/%@:logo_square.png", BASE_APP_URL, codeString]]];
    AFHTTPRequestOperation *postOperation = [[AFHTTPRequestOperation alloc] initWithRequest:urlRequest];
    postOperation.responseSerializer = [AFImageResponseSerializer serializer];
    
    [postOperation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"Response: %@", responseObject);
        [self saveBrandImageLocally:responseObject];
        UIImageView *welcomeImageView = [[UIImageView alloc] initWithImage:responseObject];
        [welcomeImageView setFrame:CGRectMake(0, 0, 160, 160)];
        [welcomeImageView setContentMode:UIViewContentModeScaleAspectFit];
        [welcomeImageView.layer setCornerRadius:5.0f];
        [welcomeImageView.layer setMasksToBounds:YES];
        
        DLAVAlertView *welcomeAlert = [[DLAVAlertView alloc] initWithTitle:@"Welcome!" message:@"Your articles are downloading now" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [welcomeAlert setContentView:welcomeImageView];
        [welcomeAlert showWithCompletion:^(DLAVAlertView *alertView, NSInteger buttonIndex) {

            [self.brandLogo setImage:responseObject];
        }];
    }
                failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                       NSLog(@"Image error: %@", error);
                }];

    [postOperation start];
}

-(BOOL)loadBrandImage{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *filePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"logo_square.png"];
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    if ([fileManager fileExistsAtPath:filePath]) {
        NSData *imageData = [NSData dataWithContentsOfFile:filePath];
        [self.brandLogo setImage:[UIImage imageWithData:imageData]];
        return YES;
    }else
        return NO;
}

-(void)saveBrandImageLocally:(UIImage*)image{
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *filePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"logo_square.png"];
    
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    if ([fileManager fileExistsAtPath:filePath]) {
        NSError *error;
        [fileManager removeItemAtPath:filePath error:&error];
        if (error) {
            NSLog(@"Error erasing: %@",[error userInfo]);
        }
    }
    [UIImagePNGRepresentation(image) writeToFile:filePath atomically:YES];
}

- (void)updateArticles:(NSString*)filePath{

    NSError *error;
    NSString *fileContents = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:&error];
    
    if (error)
        NSLog(@"Error reading file: %@", error.localizedDescription);
    
    NSLog(@"contents: %@", fileContents);
    NSArray *listArray = [fileContents componentsSeparatedByString:@"\n"];
    NSLog(@"items = %lu", (unsigned long)[listArray count]);
    
    [self downloadNewArticles:listArray];
}

- (void)downloadNewArticles:(NSArray*)articleArray{
    
    NSManagedObjectContext *context = [self.fetchedResultsController managedObjectContext];
    
    for (NSString *articleURLString in articleArray){

        NSFetchRequest *fetch = [[NSFetchRequest alloc] initWithEntityName:@"Article"];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"url == %@",articleURLString];
        [fetch setPredicate:predicate];
        
        NSArray *array = [context executeFetchRequest:fetch error:nil];
        if (array && [array count] == 0){

            AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
            [manager GET:[NSString stringWithFormat:@"http://www.diffbot.com/api/article?token=d8b0b3fcbe5040c018e3a4137cbe2d0f&url=%@",articleURLString] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
                NSLog(@"JSON: %@", responseObject);
                [self addArticle:responseObject withURL:articleURLString];
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                NSLog(@"Error: %@", error);
            }];
        }
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)addArticle:(NSDictionary*)articleDictionary withURL:(NSString*)urlString
{
    NSManagedObjectContext *context = [self.fetchedResultsController managedObjectContext];
    
    NSFetchRequest *fetch = [[NSFetchRequest alloc] initWithEntityName:@"Article"];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"url == %@",urlString];
    [fetch setPredicate:predicate];
    
    NSError *error1;
    NSArray *array = [context executeFetchRequest:fetch error:&error1];
    if (array && [array count] == 0 && [articleDictionary valueForKey:@"text"]){
        
        NSEntityDescription *entity = [[self.fetchedResultsController fetchRequest] entity];
        NSManagedObject *newManagedObject = [NSEntityDescription insertNewObjectForEntityForName:[entity name] inManagedObjectContext:context];
        
        [newManagedObject setValue:[articleDictionary objectForKey:@"text"] forKey:@"text"];
        [newManagedObject setValue:[articleDictionary objectForKey:@"title"] forKey:@"title"];
        [newManagedObject setValue:[articleDictionary objectForKey:@"author"] forKey:@"author"];
        [newManagedObject setValue:urlString forKey:@"url"];
        [newManagedObject setValue:[NSNumber numberWithBool:NO] forKey:@"beenRead"];
        [newManagedObject setValue:[NSNumber numberWithBool:NO] forKey:@"beenDeleted"];
        
        // Save the context.
        NSError *error = nil;
        if (![context save:&error]) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }else{
            [self downloadImagesForArticle:[[articleDictionary objectForKey:@"media"] objectAtIndex:0] andURL:urlString];
        }
    }
}

- (void)downloadImagesForArticle:(NSDictionary*)mediaDictionary andURL:(NSString*)urlString{
    
    AFImageDownloader *downloader = [AFImageDownloader imageDownloaderWithURLString:[mediaDictionary objectForKey:@"link"] completion:^(UIImage *decompressedImage) {
        
        NSManagedObjectContext *context = [self.fetchedResultsController managedObjectContext];
        NSFetchRequest *fetch = [[NSFetchRequest alloc] initWithEntityName:@"Article"];
        
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"url == %@",urlString];
        [fetch setPredicate:predicate];
        
        NSError *error;
        NSArray *array = [context executeFetchRequest:fetch error:&error];
        
        if (!error && array && [array count] > 0) {
            NSManagedObject *article = [array objectAtIndex:0];
            [article setValue:UIImagePNGRepresentation(decompressedImage) forKey:@"primaryImage"];
            [self.tableView reloadData];
            NSError *error = nil;
            if (![context save:&error]) {
                // Replace this implementation with code to handle the error appropriately.
                // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
                abort();
            }
        }
    }];
    [downloader start];
}


- (void)insertNewObject:(id)sender
{
//    NSManagedObjectContext *context = [self.fetchedResultsController managedObjectContext];
//    NSEntityDescription *entity = [[self.fetchedResultsController fetchRequest] entity];
//    NSManagedObject *newManagedObject = [NSEntityDescription insertNewObjectForEntityForName:[entity name] inManagedObjectContext:context];
//    
//    // If appropriate, configure the new managed object.
//    // Normally you should use accessor methods, but using KVC here avoids the need to add a custom class to the template.
//  //  [newManagedObject setValue:[NSDate date] forKey:@"timeStamp"];
//    
//    // Save the context.
//    NSError *error = nil;
//    if (![context save:&error]) {
//         // Replace this implementation with code to handle the error appropriately.
//         // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
//        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
//        abort();
//    }
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [[self.fetchedResultsController sections] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    id <NSFetchedResultsSectionInfo> sectionInfo = [self.fetchedResultsController sections][section];
    return [sectionInfo numberOfObjects];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    [self configureCell:cell atIndexPath:indexPath];
    return cell;
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    return (float)HEADER_HT;
}

-(UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    
    return nil;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSManagedObjectContext *context = [self.fetchedResultsController managedObjectContext];
        
        NSManagedObject *object = [[self fetchedResultsController] objectAtIndexPath:indexPath];
        
        if (![[object valueForKey:@"beenDeleted"] boolValue]) {
            [object setValue:[NSNumber numberWithBool:YES] forKey:@"beenDeleted"];
            [[self.fetchedResultsController managedObjectContext] processPendingChanges];
        }
        
        NSError *error = nil;
        if (![context save:&error]) {
             // Replace this implementation with code to handle the error appropriately.
             // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }   
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // The table view should not be re-orderable.
    return NO;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSManagedObject *object = [[self fetchedResultsController] objectAtIndexPath:indexPath];
    
    if (![[object valueForKey:@"beenRead"] boolValue]) {
        [object setValue:[NSNumber numberWithBool:YES] forKey:@"beenRead"];
        [[self.fetchedResultsController managedObjectContext] processPendingChanges];
    }
        
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        self.detailViewController.detailItem = object;
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"showDetail"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        NSManagedObject *object = [[self fetchedResultsController] objectAtIndexPath:indexPath];
        [[segue destinationViewController] setDetailItem:object];
    }
}

#pragma mark - Fetched results controller


- (NSFetchedResultsController *)fetchedResultsController
{
    if (_fetchedResultsController != nil) {
        return _fetchedResultsController;
    }
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"beenDeleted == FALSE"]];

    // Edit the entity name as appropriate.
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Article" inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    
    // Set the batch size to a suitable number.
    [fetchRequest setFetchBatchSize:20];
    
    // Edit the sort key as appropriate.
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"date" ascending:NO];
    NSArray *sortDescriptors = @[sortDescriptor];
    
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    // Edit the section name key path and cache name if appropriate.
    // nil for section name key path means "no sections".
    NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName:@"Master"];
    aFetchedResultsController.delegate = self;
    self.fetchedResultsController = aFetchedResultsController;
    
	NSError *error = nil;
	if (![self.fetchedResultsController performFetch:&error]) {
	     // Replace this implementation with code to handle the error appropriately.
	     // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
	    NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
	    abort();
	}
    
    return _fetchedResultsController;
}


- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type
{
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath
{
    UITableView *tableView = self.tableView;
    
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeUpdate:
            [self configureCell:[tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
            break;
            
        case NSFetchedResultsChangeMove:
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView endUpdates];
}

/*
// Implementing the above methods to update the table view in response to individual changes may have performance implications if a large number of changes are made simultaneously. If this proves to be an issue, you can instead just implement controllerDidChangeContent: which notifies the delegate that all section and object changes have been processed. 
 
 - (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    // In the simplest, most efficient, case, reload the table view.
    [self.tableView reloadData];
}
 */

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    ArticleTableViewCell *artCell = (ArticleTableViewCell*)cell;
    NSManagedObject *object = [self.fetchedResultsController objectAtIndexPath:indexPath];
    [artCell.title setText:[object valueForKey:@"title"]];
    if ([object valueForKey:@"author"]) {
        [artCell.detailLabel setText:[object valueForKey:@"author"]];
    }else{
        [artCell.detailLabel setText:nil];
    }
    if ([object valueForKey:@"primaryImage"]) {
        [artCell.articleImage setImage:[UIImage imageWithData:[object valueForKey:@"primaryImage"]]];

    }else{
        [artCell.articleImage setImage:nil];
        [artCell.articleImage setImage:[UIImage imageNamed:@"placeholder-for-no-image"]];
    }
    
    if ([[object valueForKey:@"beenRead"] boolValue]) {
        [artCell setBackgroundColor:[UIColor colorWithRed:.9 green:.9 blue:.9 alpha:1]];
         }else{
        [artCell setBackgroundColor:[UIColor whiteColor]];
    }
}

-(void)clearAllData{
    NSManagedObjectContext *context = [self.fetchedResultsController managedObjectContext];
    for (id object in [self.fetchedResultsController fetchedObjects]) {
        [context deleteObject:object];
    }
    
    NSError *error = nil;
    if (![context save:&error]) {
        // Replace this implementation with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
}

@end
