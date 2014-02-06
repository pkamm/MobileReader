//
//  DetailViewController.h
//  DigitasPocketReader
//
//  Created by Peter Kamm on 10/18/13.
//  Copyright (c) 2013 Digitas. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GAITrackedViewController.h"
#import <MessageUI/MFMailComposeViewController.h>


@interface DetailViewController : GAITrackedViewController <UISplitViewControllerDelegate, MFMailComposeViewControllerDelegate, UIPrintInteractionControllerDelegate>

@property (strong, nonatomic) id detailItem;
@property (weak, nonatomic) IBOutlet UILabel *authorLabel;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *dateLabel;
@property (weak, nonatomic) IBOutlet UIButton *websiteButton;

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (strong, nonatomic) IBOutlet UILabel *articleTextView;
@property (weak, nonatomic) IBOutlet UIImageView *primaryImageView;
@property (weak, nonatomic) IBOutlet UILabel *detailDescriptionLabel;
@end
