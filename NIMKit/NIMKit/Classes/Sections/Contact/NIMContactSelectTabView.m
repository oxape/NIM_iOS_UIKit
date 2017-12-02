//
//  NIMContactSelectTabView.m
//  NIMKit
//
//  Created by chris on 15/9/15.
//  Copyright (c) 2015年 NetEase. All rights reserved.
//

#import "NIMContactSelectTabView.h"
#import "NIMContactPickedView.h"
#import "UIView+NIM.h"
#import "UIImage+NIMKit.h"
#import "Masonry.h"

@implementation NIMContactSelectTabView

- (instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        _pickedView = [[NIMContactPickedView alloc] initWithFrame:CGRectMake(0, 0, 40, 40)];
        [self addSubview:_pickedView];
        _doneButton = [UIButton buttonWithType:UIButtonTypeCustom];
        UIImage *doneButtonNormal      = [UIImage nim_imageInKit:@"icon_cell_blue_normal"];
        UIImage *doneButtonHighlighted = [UIImage nim_imageInKit:@"icon_cell_blue_normal"];
        [_doneButton setBackgroundImage:doneButtonNormal forState:UIControlStateNormal];
        [_doneButton setBackgroundImage:doneButtonHighlighted forState:UIControlStateHighlighted];
        [_doneButton setTitle:@"确定" forState:UIControlStateNormal];
        _doneButton.nim_size = doneButtonNormal.size;
        [self addSubview:_doneButton];
        self.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"contact_bg.png"]];
        
        [_pickedView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.top.bottom.equalTo(self);
        }];
        [_doneButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.equalTo(self);
            make.centerY.equalTo(self);
            make.left.equalTo(_pickedView.mas_right);
        }];
    }
    return self;
}

- (void)layoutSubviews{
    [super layoutSubviews];
}

@end
