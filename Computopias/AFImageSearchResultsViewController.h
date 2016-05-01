//
//  AFImageSearchResultsViewController.h
//  AboutFace
//
//  Created by Nate Parrott on 9/29/13.
//  Copyright (c) 2013 Nate Parrott. All rights reserved.
//

#import <UIKit/UIKit.h>

@class AFImageSearchResultsViewController;
@protocol AFImageSearchResultsViewControllerDelegate <NSObject>

-(void)imageSearchResultsViewController:(AFImageSearchResultsViewController*)resultsController didPickImageAtURL:(NSURL*)imageURL sourceImageView:(UIImageView*)imageView;

- (void)imageSearchResultsViewControllerDidStartLoading:(AFImageSearchResultsViewController *)resultsController;
- (void)imageSearchResultsViewControllerDidFinishLoading:(AFImageSearchResultsViewController *)resultsController;

@end

@interface AFImageSearchResultsViewController : UIViewController <UICollectionViewDataSource, UICollectionViewDelegate> {
    id _result;
    NSArray* _items;
    
    IBOutlet UIActivityIndicatorView* _loadingIndicator;
    IBOutlet UILabel* _errorLabel;
}

@property(strong,nonatomic)NSString* query;
@property(weak)id<AFImageSearchResultsViewControllerDelegate> delegate;

@property(strong)IBOutlet UICollectionView* collectionView;

@property(nonatomic)BOOL loadInProgress;

@end
