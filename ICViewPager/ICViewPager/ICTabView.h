//
//  TabView.h
//  ICViewPager
//
//  Created by Peter Plant on 28/04/16.
//  Copyright © 2016 Ilter Cengiz. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ICTabView : UIView

@property (nonatomic, getter = isSelected) BOOL selected;
@property (nonatomic) UIColor *indicatorColor;

@end
