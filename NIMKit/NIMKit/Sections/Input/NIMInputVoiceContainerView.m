//
//  NIMInputRecordContainerView.m
//  Pods
//
//  Created by oxape on 2017/4/13.
//
//

#import "NIMInputVoiceContainerView.h"
#import "UIView+NIM.h"

@interface NIMInputVoiceContainerView ()

@end

@implementation NIMInputVoiceContainerView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        CGFloat radius = 128;
        _recordButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _recordButton.backgroundColor = [UIColor colorWithRed:0.330 green:0.807 blue:0.999 alpha:1.000];
        _recordButton.layer.cornerRadius = 64;
        _recordButton.nim_width = radius;
        _recordButton.nim_height = radius;
        _recordButton.nim_centerX = self.nim_centerX;
        _recordButton.nim_centerY = self.nim_centerY;
        [self addSubview:_recordButton];
    }
    return self;
}



@end
