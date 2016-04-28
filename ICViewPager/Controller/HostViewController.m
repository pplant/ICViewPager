//
//  HostViewController.m
//  ICViewPager
//
//  Created by Ilter Cengiz on 28/08/2013.
//  Copyright (c) 2013 Ilter Cengiz. All rights reserved.
//

#import "HostViewController.h"
#import "ContentViewController.h"

@interface HostViewController () <ICViewPagerDataSource, ICViewPagerDelegate>

@property (nonatomic) NSUInteger numberOfTabs;

@end

@implementation HostViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    self.dataSource = self;
    self.delegate = self;
    self.initalIndex = 0;
    
    self.title = @"View Pager";
    self.navigationItem.rightBarButtonItem = ({
        
        UIBarButtonItem *button;
        button = [[UIBarButtonItem alloc] initWithTitle:@"Reduce" style:UIBarButtonItemStylePlain target:self action:@selector(reduce)];
        
        button;
    });
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.numberOfTabs = 0;
}

- (void) reduce{
    self.numberOfTabs = 5;
}

#pragma mark - Setters
- (void)setNumberOfTabs:(NSUInteger)numberOfTabs {
    // Set numberOfTabs
    _numberOfTabs = numberOfTabs;
    
    // Reload data
    [self reloadData];
    
}

#pragma mark - Interface Orientation Changes

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    
    // Update changes after screen rotates
    [self performSelector:@selector(setNeedsReloadOptions) withObject:nil afterDelay:duration];
}

#pragma mark - ViewPagerDataSource

- (NSUInteger)numberOfTabsForViewPager:(ICViewPagerController *)viewPager {
    return self.numberOfTabs;
}

- (UIView *)viewPager:(ICViewPagerController *)viewPager viewForTabAtIndex:(NSUInteger)index {
    
    UILabel *label = [UILabel new];
    label.backgroundColor = [UIColor clearColor];
    label.font = [UIFont systemFontOfSize:12.0];
    label.text = [NSString stringWithFormat:@"Tab #%lu", (unsigned long)index];
    label.textAlignment = NSTextAlignmentCenter;
    label.textColor = [UIColor blackColor];
    [label sizeToFit];
    
    return label;
}

- (UIViewController *)viewPager:(ICViewPagerController *)viewPager contentViewControllerForTabAtIndex:(NSUInteger)index {
    
    ContentViewController *cvc = [self.storyboard instantiateViewControllerWithIdentifier:@"contentViewController"];
    
    cvc.labelString = [NSString stringWithFormat:@"Content View #%lu", (unsigned long)index];
    
    return cvc;
}

#pragma mark - ViewPagerDelegate

- (CGFloat)viewPager:(ICViewPagerController *)viewPager widthForTabAtIndex:(NSUInteger)index{
    return 50.0;
}

- (UIColor *)viewPager:(ICViewPagerController *)viewPager colorForComponent:(ICViewPagerComponent)component withDefault:(UIColor *)color {
    
    switch (component) {
        case ICViewPagerIndicator:
            return [[UIColor redColor] colorWithAlphaComponent:0.64];
        case ICViewPagerTabsView:
            return [[UIColor lightGrayColor] colorWithAlphaComponent:0.32];
        case ICViewPagerContent:
            return [[UIColor darkGrayColor] colorWithAlphaComponent:0.32];
        default:
            return color;
    }
}

@end
