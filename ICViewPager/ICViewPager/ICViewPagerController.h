//
//  ViewPagerController.h
//  ICViewPager
//
//  Created by Ilter Cengiz on 28/08/2013.
//  Copyright (c) 2013 Ilter Cengiz. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 * Main parts of the ViewPagerController
 *
 * ICViewPagerIndicator: The colored line in the view of the active tab
 * ICViewPagerTabsView: The tabs view itself
 * ICViewPagerContent: Provided views goes here as content
 */
typedef NS_ENUM(NSUInteger, ICViewPagerComponent) {
    ICViewPagerIndicator,
    ICViewPagerTabsView,
    ICViewPagerContent
};

typedef NS_ENUM(NSUInteger, ICViewPagerTabLocation) {
    ViewPagerTabLocationBottom = 0,
    ViewPagerTabLocationTop = 1
};

@protocol ICViewPagerDataSource;
@protocol ICViewPagerDelegate;

@interface ICViewPagerController : UIViewController

@property (nonatomic) ICViewPagerTabLocation tabLocation;
@property (nonatomic) float tabHeight;
@property (nonatomic) float tabOffset;
@property (nonatomic) BOOL initalIndex;
@property (nonatomic) BOOL centerCurrentTab;
@property (nonatomic) BOOL fixFormerTabsPositions;
@property (nonatomic) BOOL fixLatterTabsPositions;
@property (nonatomic) BOOL ignoreTopLayoutGuide;
@property (nonatomic) BOOL tabSwipeEnabled;

/**
 * The object that acts as the data source of the receiving viewPager
 * @discussion The data source must adopt the ViewPagerDataSource protocol. The data source is not retained.
 */
@property (weak) id <ICViewPagerDataSource> dataSource;
/**
 * The object that acts as the delegate of the receiving viewPager
 * @discussion The delegate must adopt the ViewPagerDelegate protocol. The delegate is not retained.
 */
@property (weak) id <ICViewPagerDelegate> delegate;

#pragma mark Methods
/**
 * Reloads all tabs and contents
 */
- (void)reloadData;

/**
 * Selects the given tab and shows the content at this index
 *
 * @param index The index of the tab that will be selected
 */
- (void)selectTabAtIndex:(NSUInteger)index;

/**
 * Reloads the appearance of the tabs view.
 * Adjusts tabs' width, offset, the center, fix former/latter tabs cases.
 * Without implementing the - viewPager:valueForOption:withDefault: delegate method,
 * this method does nothing.
 * Calling this method without changing any option will affect the performance.
 */
- (void)setNeedsReloadOptions;

/**
 * Reloads the colors.
 * You can make ViewPager to reload its components colors.
 * Changing `ViewPagerTabsView` and `ViewPagerContent` color will have no effect to performance,
 * but `ViewPagerIndicator`, as it will need to iterate through all tabs to update it.
 * Calling this method without changing any color won't affect the performance,
 * but will cause your delegate method (if you implemented it) to be called three times.
 */
- (void)setNeedsReloadColors;

/**
 * Call this method to get the color of a given component.
 * Returns [UIColor clearColor] for any undefined component.
 *
 * @param component The component key. Keys are defined in ViewPagerController.h
 *
 * @return A UIColor for the given component
 */
- (UIColor *)colorForComponent:(ICViewPagerComponent)component;

@end

#pragma mark dataSource

@protocol ICViewPagerDataSource <NSObject>
/**
 * Asks dataSource how many tabs will there be.
 *
 * @param viewPager The viewPager that's subject to
 * @return Number of tabs
 */
- (NSUInteger)numberOfTabsForViewPager:(ICViewPagerController *)viewPager;
/**
 * Asks dataSource to give a view to display as a tab item.
 * It is suggested to return a view with a clearColor background.
 * So that un/selected states can be clearly seen.
 *
 * @param viewPager The viewPager that's subject to
 * @param index The index of the tab whose view is asked
 *
 * @return A view that will be shown as tab at the given index
 */
- (UIView *)viewPager:(ICViewPagerController *)viewPager viewForTabAtIndex:(NSUInteger)index;

/**
 * The content for any tab. Return a width will use it to show as content.
 *
 * @param viewPager The viewPager that's subject to
 * @param index The index of the content whose view is asked
 *
 * @return A width which will be shown as content
 */
- (CGFloat)viewPager:(ICViewPagerController *)viewPager widthForTabAtIndex:(NSUInteger)index;

@optional
/**
 * The content for any tab. Return a view controller and ViewPager will use its view to show as content.
 *
 * @param viewPager The viewPager that's subject to
 * @param index The index of the content whose view is asked
 *
 * @return A viewController whose view will be shown as content
 */
- (UIViewController *)viewPager:(ICViewPagerController *)viewPager contentViewControllerForTabAtIndex:(NSUInteger)index;
/**
 * The content for any tab. Return a view and ViewPager will use it to show as content.
 *
 * @param viewPager The viewPager that's subject to
 * @param index The index of the content whose view is asked
 *
 * @return A view which will be shown as content
 */
- (UIView *)viewPager:(ICViewPagerController *)viewPager contentViewForTabAtIndex:(NSUInteger)index;

@end

#pragma mark delegate

@protocol ICViewPagerDelegate <NSObject>

@optional
/**
 * delegate object must implement this method if wants to be informed when a tab changes
 *
 * @param viewPager The viewPager that's subject to
 * @param index The index of the active tab
 */
- (void)viewPager:(ICViewPagerController *)viewPager didChangeTabToIndex:(NSUInteger)index;

/**
 * Use this method to customize the look and feel.
 * viewPager will ask its delegate for colors for its components.
 * And if they are provided, it will use them, otherwise it will use default colors.
 * Also not that, colors for tab and content views will change the tabView's and contentView's background
 * (you should provide these views with a clearColor to see the colors),
 * and indicator will change its own color.
 *
 * @param viewPager The viewPager that's subject to
 * @param component The component key. Keys are defined in ViewPagerController.h
 * @param color The default color for the given component
 *
 * @return A UIColor for the given component
 */
- (UIColor *)viewPager:(ICViewPagerController *)viewPager colorForComponent:(ICViewPagerComponent)component withDefault:(UIColor *)color;

@end
