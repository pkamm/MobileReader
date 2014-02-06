//
//  ArticleTableViewCell.h
//  DigitasPocketReader
//
//  Created by Peter Kamm on 10/23/13.
//  Copyright (c) 2013 Digitas. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ArticleTableViewCell : UITableViewCell


@property IBOutlet UIImageView* articleImage;
@property (weak, nonatomic) IBOutlet UILabel *title;
@property (weak, nonatomic) IBOutlet UILabel *detailLabel;

@end
