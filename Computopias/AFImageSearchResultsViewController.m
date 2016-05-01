//
//  AFImageSearchResultsViewController.m
//  AboutFace
//
//  Created by Nate Parrott on 9/29/13.
//  Copyright (c) 2013 Nate Parrott. All rights reserved.
//

#import "AFImageSearchResultsViewController.h"

@interface AFImageCell : UICollectionViewCell

@property (strong,nonatomic) UIImageView *imageView;
@property (nonatomic) NSURL *imageURL;
@property (nonatomic) NSURLSessionDataTask *task;

@end

@implementation AFImageCell

- (UIImageView*)imageView {
    if (!_imageView) {
        _imageView = [[UIImageView alloc] init];
        _imageView.contentMode = UIViewContentModeScaleAspectFill;
        [self.contentView addSubview:_imageView];
        self.clipsToBounds = YES;
    }
    return _imageView;
}
- (void)layoutSubviews {
    [super layoutSubviews];
    _imageView.frame = self.contentView.bounds;
}

- (void)setImageURL:(NSURL *)imageURL {
    [self.task cancel];
    _imageURL = imageURL;
    if (imageURL) {
        self.task = [[NSURLSession sharedSession] dataTaskWithURL:imageURL completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (imageURL == _imageURL && data) {
                    self.imageView.image = [UIImage imageWithData:data];
                }
            });
        }];
        [self.task resume];
    }
}

@end



@interface AFImageSearchResultsViewController ()

@end

@implementation AFImageSearchResultsViewController

- (id)init {
    self = [super init];
    
    UICollectionViewFlowLayout* layout = [UICollectionViewFlowLayout new];
    layout.itemSize = CGSizeMake(92, 92);
    layout.minimumInteritemSpacing = 11;
    layout.minimumLineSpacing = 11;
    self.collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 0, 100, 100) collectionViewLayout:layout];
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    [self.collectionView registerClass:[AFImageCell class] forCellWithReuseIdentifier:@"ThumbnailCell"];
    self.collectionView.contentInset = UIEdgeInsetsMake(11, 11, 11, 11);
    
    return self;
}

- (void)loadView {
    self.view = self.collectionView;
}

-(void)viewDidLoad {
    [super viewDidLoad];
    if ([UIDevice currentDevice].userInterfaceIdiom==UIUserInterfaceIdiomPad) {
        UICollectionViewFlowLayout* flow = (id)self.collectionView.collectionViewLayout;
        flow.itemSize = CGSizeMake(123, 123);
    }
}
#pragma mark Loading
-(void)setQuery:(NSString *)query {
    if ([query isEqualToString:_query]) return;
    _query = query;
    [self reload];
}
-(void)reload {
    if (self.loadInProgress) return;
    
    self.loadInProgress = YES;
    _items = nil;
    [self.collectionView reloadData];
    
    NSString* key = @"TK8rKU+5A2x/uXz0zY1kvUEJkK9PAZf+inPlZmUn5nk";
    NSString* authString = [[[NSString stringWithFormat:@"%@:%@", key, key] dataUsingEncoding:NSUTF8StringEncoding] base64EncodedStringWithOptions:0];
    NSString* query = self.query;
    
    NSURLComponents *comps = [NSURLComponents componentsWithString:@"https://api.datamarket.azure.com/Bing/Search/v1/Image"];
    comps.queryItems = @[ [NSURLQueryItem queryItemWithName:@"Query" value:[NSString stringWithFormat:@"'%@'", query]], [NSURLQueryItem queryItemWithName:@"$format" value:@"json"] ];
    
    NSURL* url = comps.URL;
    NSMutableURLRequest* req = [[NSMutableURLRequest alloc] initWithURL:url];
    [req addValue:[NSString stringWithFormat:@"Basic %@", authString] forHTTPHeaderField:@"Authorization"];
    
    [[[NSURLSession sharedSession] dataTaskWithRequest:req completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (data && !error) {
                NSDictionary* responseObject = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
                NSArray* itemsUnfiltered = [[responseObject valueForKey:@"d"] valueForKey:@"results"];
                NSMutableArray* items = [NSMutableArray new];
                for (NSDictionary *obj in itemsUnfiltered) {
                    CGSize size = CGSizeMake([[obj valueForKey:@"Width"] floatValue], [[obj valueForKey:@"Height"] floatValue]);
                    if (size.width > 400 && size.height > 400 && size.width < 4000 && size.height < 4000) {
                        [items addObject:obj];
                    }
                }
                _items = items;
                if (_items.count > 0) {
                    [self.collectionView reloadData];
                } else {
                    _errorLabel.text = NSLocalizedString(@"No results", @"");
                    _errorLabel.hidden = NO;
                }
                if (![self.query isEqualToString:query]) {
                    [self reload];
                } else {
                    self.loadInProgress = NO;
                }
            } else {
                self.loadInProgress = NO;
                _errorLabel.text = NSLocalizedString(@"No Internet", @"");
                _errorLabel.hidden = NO;
            }
        });
    }] resume];
    
}
-(void)setLoadInProgress:(BOOL)loadInProgress {
    if (loadInProgress != _loadInProgress) {
        if (loadInProgress) {
            [self.delegate imageSearchResultsViewControllerDidStartLoading:self];
        } else {
            [self.delegate imageSearchResultsViewControllerDidFinishLoading:self];
        }
    }
    _loadInProgress = loadInProgress;
    if (loadInProgress) [_loadingIndicator startAnimating];
    else [_loadingIndicator stopAnimating];
    if (loadInProgress) _errorLabel.hidden = YES;
}
#pragma mark CollectionView
-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}
-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return _items.count;
}
-(UICollectionViewCell*)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    AFImageCell* cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"ThumbnailCell" forIndexPath:indexPath];
    UIImageView* imageView = cell.imageView;
    NSDictionary* item = _items[indexPath.row];
    NSDictionary* thumbInfo = item[@"Thumbnail"];
    cell.imageURL = [NSURL URLWithString:thumbInfo[@"MediaUrl"]];
    imageView.backgroundColor = [UIColor colorWithWhite:0.7 alpha:1];
    return cell;
}
-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary* item = _items[indexPath.row];
    UIImageView* imageView = [(id)[collectionView cellForItemAtIndexPath:indexPath] imageView];
    [self.delegate imageSearchResultsViewController:self didPickImageAtURL:[NSURL URLWithString:item[@"MediaUrl"]] sourceImageView:imageView];
}

@end
