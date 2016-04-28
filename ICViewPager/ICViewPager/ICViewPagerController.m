//
//  ViewPagerController.m
//  ICViewPager
//
//  Created by Ilter Cengiz on 28/08/2013.
//  Copyright (c) 2013 Ilter Cengiz. All rights reserved.
//

#import "ICViewPagerController.h"
#import "ICTabView.h"
#import "UIColor+Equality.h"

#pragma mark - Constants and macros
#define kTabViewTag 38
#define kContentViewTag 34

#define kTabHeight 44.0
#define kTabOffset 56.0
#define kTabWidth 128.0

#define kIndicatorColor [UIColor colorWithRed:178.0/255.0 green:203.0/255.0 blue:57.0/255.0 alpha:0.75]
#define kTabsViewBackgroundColor [UIColor colorWithRed:234.0/255.0 green:234.0/255.0 blue:234.0/255.0 alpha:0.75]
#define kContentViewBackgroundColor [UIColor colorWithRed:248.0/255.0 green:248.0/255.0 blue:248.0/255.0 alpha:0.75]

#pragma mark - ViewPagerController
@interface ICViewPagerController () <UIPageViewControllerDataSource, UIPageViewControllerDelegate, UIScrollViewDelegate>

// Tab and content stuff
@property UIScrollView *tabsView;
@property UIView *contentView;

@property UIPageViewController *pageViewController;
@property (assign) id<UIScrollViewDelegate> actualDelegate;

// Tab and content cache
@property NSMutableArray *tabs;
@property NSMutableArray *contents;

@property (nonatomic) NSUInteger tabCount;
@property (nonatomic) NSUInteger activeTabIndex;
@property (nonatomic) NSUInteger activeContentIndex;

@property (getter = isAnimatingToTab, assign) BOOL animatingToTab;
@property (getter = isDefaultSetupDone, assign) BOOL defaultSetupDone;

// Colors
@property (nonatomic) UIColor *indicatorColor;
@property (nonatomic) UIColor *tabsViewBackgroundColor;
@property (nonatomic) UIColor *contentViewBackgroundColor;

@end

@implementation ICViewPagerController

#pragma mark - Init

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self defaultSettings];
    }
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [self defaultSettings];
    }
    return self;
}

#pragma mark - View life cycle

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    // Do setup if it's not done yet
    if (![self isDefaultSetupDone]) {
        [self defaultSetup];
    }
}

- (void)viewWillLayoutSubviews {
    [self layoutSubviews];
}

- (void)layoutSubviews {
    CGFloat topLayoutGuide = 0.0;

    
    if (!self.ignoreTopLayoutGuide) {
        topLayoutGuide = 20.0;
        if (self.navigationController && !self.navigationController.navigationBarHidden) {
            topLayoutGuide += self.navigationController.navigationBar.frame.size.height;
        }
    }
    
    CGRect frame = self.tabsView.frame;
    frame.origin.x = 0.0;
    frame.origin.y = self.tabLocation ? topLayoutGuide : CGRectGetHeight(self.view.frame) - self.tabHeight;
    frame.size.width = CGRectGetWidth(self.view.frame);
    frame.size.height = self.tabHeight;
    self.tabsView.frame = frame;
    
    frame = self.contentView.frame;
    frame.origin.x = 0.0;
    frame.origin.y = self.tabLocation ? topLayoutGuide + CGRectGetHeight(self.tabsView.frame) : topLayoutGuide;
    frame.size.width = CGRectGetWidth(self.view.frame);
    frame.size.height = CGRectGetHeight(self.view.frame) - (topLayoutGuide + CGRectGetHeight(self.tabsView.frame)) - CGRectGetHeight(self.tabBarController.tabBar.frame);
    self.contentView.frame = frame;
}

#pragma mark - IBAction

- (IBAction)handleTapGesture:(id)sender {
    
    // Get the desired page's index
    UITapGestureRecognizer *tapGestureRecognizer = (UITapGestureRecognizer *)sender;
    UIView *tabView = tapGestureRecognizer.view;
    __block NSUInteger index = [self.tabs indexOfObject:tabView];
    
    //if Tap is not selected Tab(new Tab)
    if (self.activeTabIndex != index) {
        // Select the tab
        [self selectTabAtIndex:index];
    }
}

#pragma mark - Interface rotation

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    
    // Re-layout sub views
    [self layoutSubviews];
    
    // Re-align tabs if needed
    self.activeTabIndex = self.activeTabIndex;
}

#pragma mark - Setters

- (void)setTabHeight:(float)tabHeight {
    if (tabHeight < 4.0){
        _tabHeight = 4.0;
    }
    
    _tabHeight = tabHeight;
}

- (void)setActiveTabIndex:(NSUInteger)activeTabIndex {
    
    ICTabView *activeTabView;
    
    // Set to-be-inactive tab unselected
    activeTabView = [self tabViewAtIndex:self.activeTabIndex];
    activeTabView.selected = NO;
    
    // Set to-be-active tab selected
    activeTabView = [self tabViewAtIndex:activeTabIndex];
    activeTabView.selected = YES;
    
    // Set current activeTabIndex
    _activeTabIndex = activeTabIndex;
    
    // Bring tab to active position
    // Position the tab in center if centerCurrentTab option is provided as YES
    UIView *tabView = [self tabViewAtIndex:self.activeTabIndex];
    CGRect frame = tabView.frame;
    
    if (self.centerCurrentTab) {
        frame.origin.x += (CGRectGetWidth(frame) / 2);
        frame.origin.x -= CGRectGetWidth(self.tabsView.frame) / 2;
        frame.size.width = CGRectGetWidth(self.tabsView.frame);
        
        if (frame.origin.x < 0) {
            frame.origin.x = 0;
        }
        
        if ((frame.origin.x + CGRectGetWidth(frame)) > self.tabsView.contentSize.width) {
            frame.origin.x = (self.tabsView.contentSize.width - CGRectGetWidth(self.tabsView.frame));
        }
    } else {
        frame.origin.x -= self.tabOffset;
        frame.size.width = CGRectGetWidth(self.tabsView.frame);
    }
    
    [self.tabsView scrollRectToVisible:frame animated:YES];
}

- (void)setActiveContentIndex:(NSUInteger)activeContentIndex {
    
    // Get the desired viewController
    UIViewController *viewController = [self viewControllerAtIndex:activeContentIndex];
    
    if (!viewController) {
        viewController = [[UIViewController alloc] init];
        viewController.view = [[UIView alloc] init];
        viewController.view.backgroundColor = [UIColor clearColor];
    }
    
    // __weak pageViewController to be used in blocks to prevent retaining strong reference to self
    __weak UIPageViewController *weakPageViewController = self.pageViewController;
    __weak ICViewPagerController *weakSelf = self;
    
    if (activeContentIndex == self.activeContentIndex) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.pageViewController setViewControllers:@[viewController]
                                          direction:UIPageViewControllerNavigationDirectionForward
                                           animated:NO
                                         completion:^(BOOL completed) {
                                             weakSelf.animatingToTab = NO;
                                         }];
        });
    } else if (!(activeContentIndex + 1 == self.activeContentIndex || activeContentIndex - 1 == self.activeContentIndex)) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.pageViewController setViewControllers:@[viewController]
                                          direction:(activeContentIndex < self.activeContentIndex) ? UIPageViewControllerNavigationDirectionReverse : UIPageViewControllerNavigationDirectionForward
                                           animated:YES
                                         completion:^(BOOL completed) {
                                             
                                             weakSelf.animatingToTab = NO;
                                             
                                             // Set the current page again to obtain synchronisation between tabs and content
                                             dispatch_async(dispatch_get_main_queue(), ^{
                                                 [weakPageViewController setViewControllers:@[viewController]
                                                                                  direction:(activeContentIndex < weakSelf.activeContentIndex) ? UIPageViewControllerNavigationDirectionReverse : UIPageViewControllerNavigationDirectionForward
                                                                                   animated:NO
                                                                                 completion:nil];
                                             });
                                         }];
        });
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.pageViewController setViewControllers:@[viewController]
                                          direction:(activeContentIndex < self.activeContentIndex) ? UIPageViewControllerNavigationDirectionReverse : UIPageViewControllerNavigationDirectionForward
                                           animated:YES
                                         completion:^(BOOL completed) {
                                             weakSelf.animatingToTab = NO;
                                         }];
        });
    }
    
    // Clean out of sight contents
    NSInteger index;
    index = self.activeContentIndex - 1;
    if (index < self.contents.count && index >= 0 && index != activeContentIndex && index != activeContentIndex - 1){
        [self.contents replaceObjectAtIndex:index withObject:[NSNull null]];
    }
    
    index = self.activeContentIndex;
    if (index < self.contents.count && index != activeContentIndex - 1 && index != activeContentIndex && index != activeContentIndex + 1){
        [self.contents replaceObjectAtIndex:index withObject:[NSNull null]];
    }
    
    index = self.activeContentIndex + 1;
    if (index < self.contents.count && index != activeContentIndex && index != activeContentIndex + 1)
    {
        [self.contents replaceObjectAtIndex:index withObject:[NSNull null]];
    }
    
    _activeContentIndex = activeContentIndex;
}

#pragma mark - Getters

- (UIColor *)indicatorColor {
    
    if (!_indicatorColor) {
        UIColor *color = kIndicatorColor;
        if ([self.delegate respondsToSelector:@selector(viewPager:colorForComponent:withDefault:)]) {
            color = [self.delegate viewPager:self colorForComponent:ICViewPagerIndicator withDefault:color];
        }
        self.indicatorColor = color;
    }
    return _indicatorColor;
}

- (UIColor *)tabsViewBackgroundColor {
    
    if (!_tabsViewBackgroundColor) {
        UIColor *color = kTabsViewBackgroundColor;
        if ([self.delegate respondsToSelector:@selector(viewPager:colorForComponent:withDefault:)]) {
            color = [self.delegate viewPager:self colorForComponent:ICViewPagerTabsView withDefault:color];
        }
        self.tabsViewBackgroundColor = color;
    }
    return _tabsViewBackgroundColor;
}

- (UIColor *)contentViewBackgroundColor {
    
    if (!_contentViewBackgroundColor) {
        UIColor *color = kContentViewBackgroundColor;
        if ([self.delegate respondsToSelector:@selector(viewPager:colorForComponent:withDefault:)]) {
            color = [self.delegate viewPager:self colorForComponent:ICViewPagerContent withDefault:color];
        }
        self.contentViewBackgroundColor = color;
    }
    return _contentViewBackgroundColor;
}

#pragma mark - Public methods

- (void)reloadData {
    // Empty all colors
    _indicatorColor = nil;
    _tabsViewBackgroundColor = nil;
    _contentViewBackgroundColor = nil;
    
    // Call to setup again with the updated data
    [self defaultSetup];
}

- (void)selectTabAtIndex:(NSUInteger)index {
    if (index >= self.tabCount) {
        return;
    }

    self.animatingToTab = YES;
    self.activeTabIndex = index;
    self.activeContentIndex = index;
    
    // Inform delegate about the change
    if ([self.delegate respondsToSelector:@selector(viewPager:didChangeTabToIndex:)]) {
        [self.delegate viewPager:self didChangeTabToIndex:self.activeTabIndex];
    }
}

- (void)setNeedsReloadOptions {
    CGFloat tabWidthAtIndex = kTabWidth;
    if ([self.dataSource respondsToSelector:@selector(viewPager:widthForTabAtIndex:)]) {
        tabWidthAtIndex = [self.dataSource viewPager:self widthForTabAtIndex:_activeTabIndex];
    }
    
    // We should update contentSize property of our tabsView, so we should recalculate it with the new values
    CGFloat contentSizeWidth = 0;
    
    // Give the standard offset if fixFormerTabsPositions is provided as YES
    if (self.fixFormerTabsPositions) {
        
        // And if the centerCurrentTab is provided as YES fine tune the offset according to it
        if (self.centerCurrentTab) {
            contentSizeWidth = (CGRectGetWidth(self.tabsView.frame) - tabWidthAtIndex) / 2.0;
        } else {
            contentSizeWidth = self.tabOffset;
        }
    }
    
    // Update every tab's frame
    for (NSUInteger i = 0; i < self.tabCount; i++) {
        
        UIView *tabView = [self tabViewAtIndex:i];
        CGFloat tabWidthAtIndex = kTabWidth;
        if ([self.dataSource respondsToSelector:@selector(viewPager:widthForTabAtIndex:)]) {
            tabWidthAtIndex = [self.dataSource viewPager:self widthForTabAtIndex:_activeTabIndex];
        }
        CGRect frame = tabView.frame;
        frame.origin.x = contentSizeWidth;
        frame.size.width = tabWidthAtIndex;
        tabView.frame = frame;
        
        contentSizeWidth += CGRectGetWidth(tabView.frame);
    }
    
    // Extend contentSizeWidth if fixLatterTabsPositions is provided YES
    if (self.fixLatterTabsPositions) {
        // And if the centerCurrentTab is provided as YES fine tune the content size according to it
        if (self.centerCurrentTab) {
            contentSizeWidth += (CGRectGetWidth(self.tabsView.frame) - tabWidthAtIndex) / 2.0;
        } else {
            contentSizeWidth += CGRectGetWidth(self.tabsView.frame) - tabWidthAtIndex - self.tabOffset;
        }
    }
    
    // Update tabsView's contentSize with the new width
    self.tabsView.contentSize = CGSizeMake(contentSizeWidth, self.tabHeight);
    
}

- (void)setNeedsReloadColors {
    // If our delegate doesn't respond to our colors method, return
    // Otherwise reload colors
    if (![self.delegate respondsToSelector:@selector(viewPager:colorForComponent:withDefault:)]) {
        return;
    }
    
    // These colors will be updated
    UIColor *indicatorColor;
    UIColor *tabsViewBackgroundColor;
    UIColor *contentViewBackgroundColor;
    
    // Get indicatorColor and check if it is different from the current one
    // If it is, update it
    indicatorColor = [self.delegate viewPager:self colorForComponent:ICViewPagerIndicator withDefault:kIndicatorColor];
    
    if (![self.indicatorColor isEqualToColor:indicatorColor]) {
        
        // We will iterate through all of the tabs to update its indicatorColor
        [self.tabs enumerateObjectsUsingBlock:^(ICTabView *tabView, NSUInteger index, BOOL *stop) {
            tabView.indicatorColor = indicatorColor;
        }];
        
        // Update indicatorColor to check again later
        self.indicatorColor = indicatorColor;
    }
    
    // Get tabsViewBackgroundColor and check if it is different from the current one
    // If it is, update it
    tabsViewBackgroundColor = [self.delegate viewPager:self colorForComponent:ICViewPagerTabsView withDefault:kTabsViewBackgroundColor];
    
    if (![self.tabsViewBackgroundColor isEqualToColor:tabsViewBackgroundColor]) {
        
        // Update it
        self.tabsView.backgroundColor = tabsViewBackgroundColor;
        
        // Update tabsViewBackgroundColor to check again later
        self.tabsViewBackgroundColor = tabsViewBackgroundColor;
    }
    
    // Get contentViewBackgroundColor and check if it is different from the current one
    // Yeah update it, too
    contentViewBackgroundColor = [self.delegate viewPager:self colorForComponent:ICViewPagerContent withDefault:kContentViewBackgroundColor];
    
    if (![self.contentViewBackgroundColor isEqualToColor:contentViewBackgroundColor]) {
        
        // Yup, update
        self.contentView.backgroundColor = contentViewBackgroundColor;
        
        // Update this, too, to check again later
        self.contentViewBackgroundColor = contentViewBackgroundColor;
    }
    
}

- (UIColor *)colorForComponent:(ICViewPagerComponent)component {
    switch (component) {
        case ICViewPagerIndicator:
            return [self indicatorColor];
        case ICViewPagerTabsView:
            return [self tabsViewBackgroundColor];
        case ICViewPagerContent:
            return [self contentViewBackgroundColor];
        default:
            return [UIColor clearColor];
    }
}

#pragma mark - Private methods

- (void)defaultSettings {
    self.tabHeight = kTabHeight;
    self.tabOffset = kTabOffset;
    self.tabLocation = ViewPagerTabLocationTop;
    self.tabSwipeEnabled = YES;
    
    // pageViewController
    self.pageViewController = [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll
                                                              navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal
                                                                            options:nil];
    [self addChildViewController:self.pageViewController];
    
    // Setup some forwarding events to hijack the scrollView
    // Keep a reference to the actual delegate
    self.actualDelegate = ((UIScrollView *)[self.pageViewController.view.subviews objectAtIndex:0]).delegate;
    // Set self as new delegate
    ((UIScrollView *)[self.pageViewController.view.subviews objectAtIndex:0]).delegate = self;
    
    self.pageViewController.dataSource = self;
    self.pageViewController.delegate = self;
    
    self.animatingToTab = NO;
    self.defaultSetupDone = NO;
}

- (void)defaultSetup {
    for (UIView *tabView in self.tabs) {
        [tabView removeFromSuperview];
    }
    self.tabsView.contentSize = CGSizeZero;
    
    [self.tabs removeAllObjects];
    [self.contents removeAllObjects];
    
    // Get tabCount from dataSource
    self.tabCount = [self.dataSource numberOfTabsForViewPager:self];
    self.view.userInteractionEnabled = self.tabCount > 0;
    
    // Populate arrays with [NSNull null];
    self.tabs = [NSMutableArray arrayWithCapacity:self.tabCount];
    for (NSUInteger i = 0; i < self.tabCount; i++) {
        [self.tabs addObject:[NSNull null]];
    }
    
    self.contents = [NSMutableArray arrayWithCapacity:self.tabCount];
    for (NSUInteger i = 0; i < self.tabCount; i++) {
        [self.contents addObject:[NSNull null]];
    }
    
    // Add tabsView
    self.tabsView = (UIScrollView *)[self.view viewWithTag:kTabViewTag];
    
    if (!self.tabsView) {
        self.tabsView = [[UIScrollView alloc] initWithFrame:CGRectMake(0.0, 0.0, CGRectGetWidth(self.view.frame), self.tabHeight)];
        self.tabsView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        self.tabsView.backgroundColor = self.tabsViewBackgroundColor;
        self.tabsView.scrollsToTop = NO;
        self.tabsView.scrollEnabled = self.tabSwipeEnabled;
        self.tabsView.scrollEnabled = YES;
        self.tabsView.showsHorizontalScrollIndicator = NO;
        self.tabsView.showsVerticalScrollIndicator = NO;
        self.tabsView.tag = kTabViewTag;
        
        [self.view insertSubview:self.tabsView atIndex:0];
    }
    
    // Add tab views to _tabsView
    CGFloat contentSizeWidth = 0;
    CGFloat tabWidthAtIndex = kTabWidth;
    if ([self.dataSource respondsToSelector:@selector(viewPager:widthForTabAtIndex:)]) {
        tabWidthAtIndex = [self.dataSource viewPager:self widthForTabAtIndex:_activeTabIndex];
    }
    
    // Give the standard offset if fixFormerTabsPositions is provided as YES
    if (self.fixFormerTabsPositions) {
        // And if the centerCurrentTab is provided as YES fine tune the offset according to it
        if (self.centerCurrentTab) {
            contentSizeWidth = (CGRectGetWidth(self.tabsView.frame) - tabWidthAtIndex) / 2.0;
        } else {
            contentSizeWidth = self.tabOffset;
        }
    }
    
    for (NSUInteger i = 0; i < self.tabCount; i++) {
        
        UIView *tabView = [self tabViewAtIndex:i];
        
        CGRect frame = tabView.frame;
        frame.origin.x = contentSizeWidth;
        int tabWidthAtIndex = kTabWidth;
        if ([self.dataSource respondsToSelector:@selector(viewPager:widthForTabAtIndex:)]) {
            tabWidthAtIndex = [self.dataSource viewPager:self widthForTabAtIndex:i];
        }
        frame.size.width = tabWidthAtIndex;
        tabView.frame = frame;
        
        [self.tabsView addSubview:tabView];
        
        contentSizeWidth += CGRectGetWidth(tabView.frame);
        
        // To capture tap events
        UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture:)];
        [tabView addGestureRecognizer:tapGestureRecognizer];
    }
    
    // Extend contentSizeWidth if fixLatterTabsPositions is provided YES
    if (self.fixLatterTabsPositions) {
        // And if the centerCurrentTab is provided as YES fine tune the content size according to it
        if (self.centerCurrentTab) {
            contentSizeWidth += (CGRectGetWidth(self.tabsView.frame) - tabWidthAtIndex) / 2.0;
        } else {
            contentSizeWidth += CGRectGetWidth(self.tabsView.frame) - tabWidthAtIndex - self.tabOffset;
        }
    }
    
    self.tabsView.contentSize = CGSizeMake(contentSizeWidth, self.tabHeight);
    
    // Add contentView
    self.contentView = [self.view viewWithTag:kContentViewTag];
    
    if (!self.contentView) {
        self.contentView = self.pageViewController.view;
        self.contentView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        self.contentView.backgroundColor = self.contentViewBackgroundColor;
        self.contentView.bounds = self.view.bounds;
        self.contentView.tag = kContentViewTag;
        
        [self.view insertSubview:self.contentView atIndex:0];
    }
    
    // Select starting tab
    NSUInteger index = self.initalIndex < self.tabCount ? self.initalIndex : 0;
    [self selectTabAtIndex:index];
    
    // Set setup done
    self.defaultSetupDone = YES;
}

- (ICTabView *)tabViewAtIndex:(NSUInteger)index {
    if (index >= self.tabCount) {
        return nil;
    }
    
    if ([[self.tabs objectAtIndex:index] isEqual:[NSNull null]]) {
        // Get view from dataSource
        UIView *tabViewContent = [self.dataSource viewPager:self viewForTabAtIndex:index];
        tabViewContent.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        ICTabView *tabView;
        int tabWidthAtIndex = kTabWidth;
        if ([self.dataSource respondsToSelector:@selector(viewPager:widthForTabAtIndex:)]) {
            tabWidthAtIndex = [self.dataSource viewPager:self widthForTabAtIndex:index];
        }
        tabView = [[ICTabView alloc] initWithFrame:CGRectMake(0.0, 0.0, tabWidthAtIndex, self.tabHeight)];
        [tabView addSubview:tabViewContent];
        [tabView setClipsToBounds:YES];
        [tabView setIndicatorColor:self.indicatorColor];
        tabViewContent.center = tabView.center;
        
        // Replace the null object with tabView
        [self.tabs replaceObjectAtIndex:index withObject:tabView];
    }
    
    return [self.tabs objectAtIndex:index];
}
- (NSUInteger)indexForTabView:(UIView *)tabView {
    
    return [self.tabs indexOfObject:tabView];
}

- (UIViewController *)viewControllerAtIndex:(NSUInteger)index {
    
    if (index >= self.tabCount) {
        return nil;
    }
    
    if ([[self.contents objectAtIndex:index] isEqual:[NSNull null]]) {
        
        UIViewController *viewController;
        
        if ([self.dataSource respondsToSelector:@selector(viewPager:contentViewControllerForTabAtIndex:)]) {
            viewController = [self.dataSource viewPager:self contentViewControllerForTabAtIndex:index];
        } else if ([self.dataSource respondsToSelector:@selector(viewPager:contentViewForTabAtIndex:)]) {
            
            UIView *view = [self.dataSource viewPager:self contentViewForTabAtIndex:index];
            
            // Adjust view's bounds to match the pageView's bounds
            UIView *pageView = [self.view viewWithTag:kContentViewTag];
            view.frame = pageView.bounds;
            
            viewController = [UIViewController new];
            viewController.view = view;
        } else {
            viewController = [[UIViewController alloc] init];
            viewController.view = [[UIView alloc] init];
        }
        
        [self.contents replaceObjectAtIndex:index withObject:viewController];
    }
    
    return [self.contents objectAtIndex:index];
}

- (NSUInteger)indexForViewController:(UIViewController *)viewController {
    
    return [self.contents indexOfObject:viewController];
}

#pragma mark - UIPageViewControllerDataSource

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController {
    NSUInteger index = [self indexForViewController:viewController];
    index++;
    return [self viewControllerAtIndex:index];
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController {
    NSUInteger index = [self indexForViewController:viewController];
    index--;
    return [self viewControllerAtIndex:index];
}

#pragma mark - UIPageViewControllerDelegate

- (void)pageViewController:(UIPageViewController *)pageViewController didFinishAnimating:(BOOL)finished previousViewControllers:(NSArray *)previousViewControllers transitionCompleted:(BOOL)completed {
    UIViewController *viewController = self.pageViewController.viewControllers[0];
    // Select tab
    NSUInteger index = [self indexForViewController:viewController];
    [self selectTabAtIndex:index];
}

#pragma mark - UIScrollViewDelegate, Responding to Scrolling and Dragging

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if ([self.actualDelegate respondsToSelector:@selector(scrollViewDidScroll:)]) {
        [self.actualDelegate scrollViewDidScroll:scrollView];
    }
    
    if (![self isAnimatingToTab]) {
        UIView *tabView = [self tabViewAtIndex:self.activeTabIndex];
        
        // Get the related tab view position
        CGRect frame = tabView.frame;
        
        CGFloat movedRatio = (scrollView.contentOffset.x / CGRectGetWidth(scrollView.frame)) - 1;
        frame.origin.x += movedRatio * CGRectGetWidth(frame);
        
        if (self.centerCurrentTab) {
            frame.origin.x += (frame.size.width / 2);
            frame.origin.x -= CGRectGetWidth(self.tabsView.frame) / 2;
            frame.size.width = CGRectGetWidth(self.tabsView.frame);
            
            if (frame.origin.x < 0) {
                frame.origin.x = 0;
            }
            
            if ((frame.origin.x + frame.size.width) > self.tabsView.contentSize.width) {
                frame.origin.x = (self.tabsView.contentSize.width - CGRectGetWidth(self.tabsView.frame));
            }
        } else {
            
            frame.origin.x -= self.tabOffset;
            frame.size.width = CGRectGetWidth(self.tabsView.frame);
        }
        
        [self.tabsView scrollRectToVisible:frame animated:NO];
    }
}
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    if ([self.actualDelegate respondsToSelector:@selector(scrollViewWillBeginDragging:)]) {
        [self.actualDelegate scrollViewWillBeginDragging:scrollView];
    }
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
    if ([self.actualDelegate respondsToSelector:@selector(scrollViewWillEndDragging:withVelocity:targetContentOffset:)]) {
        [self.actualDelegate scrollViewWillEndDragging:scrollView withVelocity:velocity targetContentOffset:targetContentOffset];
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate{
    if ([self.actualDelegate respondsToSelector:@selector(scrollViewDidEndDragging:willDecelerate:)]) {
        [self.actualDelegate scrollViewDidEndDragging:scrollView willDecelerate:decelerate];
    }
}

- (BOOL)scrollViewShouldScrollToTop:(UIScrollView *)scrollView{
    if ([self.actualDelegate respondsToSelector:@selector(scrollViewShouldScrollToTop:)]) {
        return [self.actualDelegate scrollViewShouldScrollToTop:scrollView];
    }
    return NO;
}

- (void)scrollViewDidScrollToTop:(UIScrollView *)scrollView {
    if ([self.actualDelegate respondsToSelector:@selector(scrollViewDidScrollToTop:)]) {
        [self.actualDelegate scrollViewDidScrollToTop:scrollView];
    }
}

- (void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView {
    if ([self.actualDelegate respondsToSelector:@selector(scrollViewWillBeginDecelerating:)]) {
        [self.actualDelegate scrollViewWillBeginDecelerating:scrollView];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    if ([self.actualDelegate respondsToSelector:@selector(scrollViewDidEndDecelerating:)]) {
        [self.actualDelegate scrollViewDidEndDecelerating:scrollView];
    }
}

#pragma mark - UIScrollViewDelegate, Managing Zooming

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    if ([self.actualDelegate respondsToSelector:@selector(viewForZoomingInScrollView:)]) {
        return [self.actualDelegate viewForZoomingInScrollView:scrollView];
    }
    return nil;
}

- (void)scrollViewWillBeginZooming:(UIScrollView *)scrollView withView:(UIView *)view {
    if ([self.actualDelegate respondsToSelector:@selector(scrollViewWillBeginZooming:withView:)]) {
        [self.actualDelegate scrollViewWillBeginZooming:scrollView withView:view];
    }
}

- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(CGFloat)scale {
    if ([self.actualDelegate respondsToSelector:@selector(scrollViewDidEndZooming:withView:atScale:)]) {
        [self.actualDelegate scrollViewDidEndZooming:scrollView withView:view atScale:scale];
    }
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
    if ([self.actualDelegate respondsToSelector:@selector(scrollViewDidZoom:)]) {
        [self.actualDelegate scrollViewDidZoom:scrollView];
    }
}

#pragma mark - UIScrollViewDelegate, Responding to Scrolling Animations

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    if ([self.actualDelegate respondsToSelector:@selector(scrollViewDidEndScrollingAnimation:)]) {
        [self.actualDelegate scrollViewDidEndScrollingAnimation:scrollView];
    }
}

@end

