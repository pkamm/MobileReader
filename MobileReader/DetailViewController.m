//
//  DetailViewController.m
//  DigitasPocketReader
//
//  Created by Peter Kamm on 10/18/13.
//  Copyright (c) 2013 Digitas. All rights reserved.
//

#import "DetailViewController.h"

#define TEXT_MARGIN 20

@interface DetailViewController ()
@property (strong, nonatomic) UIPopoverController *masterPopoverController;
- (void)configureView;
@end

@implementation DetailViewController

#pragma mark - Managing the detail item

- (void)setDetailItem:(id)newDetailItem
{
    if (_detailItem != newDetailItem) {
        _detailItem = newDetailItem;
    }

    if (self.masterPopoverController != nil) {
        [self.masterPopoverController dismissPopoverAnimated:YES];
    }        
}

- (void)configureView
{
    // Update the user interface for the detail item.

    if (self.detailItem) {

        self.navigationItem.title = [self.detailItem valueForKey:@"title"];
        
        [self.titleLabel setText:[self.detailItem valueForKey:@"title"]];
        [self.authorLabel setText:[self.detailItem valueForKey:@"author"]];
        [self.dateLabel setText:[self.detailItem valueForKey:@"date"]];
        [self.websiteButton setTitle:[[NSURL URLWithString:[self.detailItem valueForKey:@"url"]] host] forState:UIControlStateNormal];
        
        self.articleTextView = [[UILabel alloc] init];
        self.articleTextView.text = [[[self.detailItem valueForKey:@"text"] description] stringByReplacingOccurrencesOfString:@"\n" withString:@"\n\n"];

        NSAttributedString *attributedText =
        [[NSAttributedString alloc] initWithString:self.articleTextView.text
                                        attributes:@ { NSFontAttributeName: _articleTextView.font }];
        CGRect rect = [attributedText boundingRectWithSize:(CGSize){_scrollView.frame.size.width-(2*TEXT_MARGIN), CGFLOAT_MAX}
                                                   options:NSStringDrawingUsesLineFragmentOrigin
                                                   context:nil];
        _articleTextView.frame = CGRectMake(rect.origin.x+TEXT_MARGIN, rect.origin.y+300, rect.size.width, rect.size.height);
        [_articleTextView setNumberOfLines:0];
        [_scrollView addSubview:_articleTextView];
        [_scrollView setContentSize:CGSizeMake(_scrollView.frame.size.width, _articleTextView.frame.size.height+300)];
        if ([self.detailItem valueForKey:@"primaryImage"]) {
            [self.primaryImageView setImage:[UIImage imageWithData:[self.detailItem valueForKey:@"primaryImage"]]];
            
        }else{
            [self.primaryImageView setImage:[UIImage imageNamed:@"placeholder-for-no-image"]];
        }
    }

    UIPinchGestureRecognizer *pinchGesture = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinchGesture:)];
    [self.view addGestureRecognizer:pinchGesture];
    
}

- (void)handlePinchGesture:(id)sender
{
    NSLog(@"Recieved pinch");
    
    UIPinchGestureRecognizer *senderGR  = (UIPinchGestureRecognizer *)sender;
    
    if (senderGR.velocity > 0) {
        [self.articleTextView setFont:[UIFont fontWithName:nil size:self.articleTextView.font.pointSize + .25]];
    }else{
        [self.articleTextView setFont:[UIFont fontWithName:nil size:self.articleTextView.font.pointSize - .25]];
    }
    
    NSLog(@"Scale is: %f", senderGR.scale);
    NSLog(@"velo is: %f", senderGR.velocity);
    NSAttributedString *attributedText = [[NSAttributedString alloc] initWithString:_articleTextView.text
                                    attributes:@ { NSFontAttributeName: self.articleTextView.font }];
    CGRect rect = [attributedText boundingRectWithSize:(CGSize){_scrollView.frame.size.width-(2*TEXT_MARGIN), CGFLOAT_MAX}
                                               options:NSStringDrawingUsesLineFragmentOrigin
                                               context:nil];
    _articleTextView.frame = CGRectMake(rect.origin.x+TEXT_MARGIN, rect.origin.y+300, rect.size.width, rect.size.height);
    [_articleTextView setNumberOfLines:0];
    [_scrollView addSubview:_articleTextView];
    [_scrollView setContentSize:CGSizeMake(_scrollView.frame.size.width, _articleTextView.frame.size.height+300)];

}

- (IBAction)shareButtonPressed:(id)sender {
    
    MFMailComposeViewController* controller = [[MFMailComposeViewController alloc] init];
    controller.mailComposeDelegate = self;
    [controller setSubject:[self.detailItem valueForKey:@"title"]];
    [controller setMessageBody:[NSString stringWithFormat:@"%@... \n\nView the full article:  %@",[[self.detailItem valueForKey:@"text"] substringToIndex:240], [self.detailItem valueForKey:@"url"]] isHTML:NO];
    if (controller) [self presentViewController:controller animated:YES completion:^{
        
    }];
}

- (void)mailComposeController:(MFMailComposeViewController*)controller
          didFinishWithResult:(MFMailComposeResult)result
                        error:(NSError*)error;
{
    if (result == MFMailComposeResultSent) {
        NSLog(@"It's away!");
    }
    [self dismissViewControllerAnimated:YES completion:^{
        
    }];
}
- (IBAction)printButtonPressed:(id)sender {
        UIPrintInteractionController *pic = [UIPrintInteractionController sharedPrintController];
        pic.delegate = self;
        
        UIPrintInfo *printInfo = [UIPrintInfo printInfo];
        printInfo.outputType = UIPrintInfoOutputGeneral;
        printInfo.jobName = [self.detailItem valueForKey:@"title"];
        pic.printInfo = printInfo;
        
        UISimpleTextPrintFormatter *textFormatter = [[UISimpleTextPrintFormatter alloc]
                                                     initWithText:[self.detailItem valueForKey:@"text"]];
        textFormatter.startPage = 0;
        textFormatter.contentInsets = UIEdgeInsetsMake(72.0, 72.0, 72.0, 72.0); // 1 inch margins
        textFormatter.maximumContentWidth = 6 * 72.0;
        pic.printFormatter = textFormatter;
        pic.showsPageRange = YES;
        
        void (^completionHandler)(UIPrintInteractionController *, BOOL, NSError *) =
        ^(UIPrintInteractionController *printController, BOOL completed, NSError *error) {
            if (!completed && error) {
                NSLog(@"Printing could not complete because of error: %@", error);
            }
        };
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            [pic presentFromBarButtonItem:sender animated:YES completionHandler:completionHandler];
        } else {
            [pic presentAnimated:YES completionHandler:completionHandler];
        }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    [self configureView];
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    id tracker = [[GAI sharedInstance] defaultTracker];
    [tracker set:kGAIScreenName value:@"Article View"];
    [tracker send:[[GAIDictionaryBuilder createAppView] build]];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)websiteButtonClicked:(id)sender {
    
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[self.detailItem valueForKey:@"url"]]];
    
}

#pragma mark - Split view

- (void)splitViewController:(UISplitViewController *)splitController willHideViewController:(UIViewController *)viewController withBarButtonItem:(UIBarButtonItem *)barButtonItem forPopoverController:(UIPopoverController *)popoverController
{
    barButtonItem.title = NSLocalizedString(@"Master", @"Master");
    [self.navigationItem setLeftBarButtonItem:barButtonItem animated:YES];
    self.masterPopoverController = popoverController;
}

- (void)splitViewController:(UISplitViewController *)splitController willShowViewController:(UIViewController *)viewController invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem
{
    // Called when the view is shown again in the split view, invalidating the button and popover controller.
    [self.navigationItem setLeftBarButtonItem:nil animated:YES];
    self.masterPopoverController = nil;
}

@end
