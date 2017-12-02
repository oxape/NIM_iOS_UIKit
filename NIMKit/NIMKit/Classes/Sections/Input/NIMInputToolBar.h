//
//  NIMInputToolBar.h
//  NIMKit
//
//  Created by chris.
//  Copyright (c) 2015年 NetEase. All rights reserved.
//

#import <UIKit/UIKit.h>


typedef NS_ENUM(NSInteger,NIMInputStatus)
{
    NIMInputStatusText,
    NIMInputStatusAudio,
    NIMInputStatusEmoticon,
    NIMInputStatusMore
};

typedef NS_ENUM(NSInteger, NIMInputType){
    InputTypeText = 1,
    InputTypeEmot = 2,
    InputTypeMedia = 4,
    InputTypeVoice= 5,
};

@protocol NIMInputToolBarDelegate <NSObject>

@optional

- (BOOL)textViewShouldBeginEditing;

- (void)textViewDidEndEditing;

- (BOOL)shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)replacementText;

- (void)textViewDidChange;

- (void)toolBarWillChangeHeight:(CGFloat)height;

- (void)toolBarDidChangeHeight:(CGFloat)height;

@end


@interface NIMInputToolBar : UIView

@property (nonatomic,strong) UIButton    *voiceButton;

@property (nonatomic,strong) UIButton    *emoticonBtn;

@property (nonatomic,strong) UIButton    *photoBtn;

@property (nonatomic,strong) UIButton    *voteBtn;

@property (nonatomic,strong) UIButton    *shotBtn;

@property (nonatomic,strong) UIButton    *moreMediaBtn;

@property (nonatomic,strong) UIImageView *inputTextBkgImage;

@property (nonatomic,copy) NSString *contentText;

@property (nonatomic,weak) id<NIMInputToolBarDelegate> delegate;

@property (nonatomic,assign) BOOL showsKeyboard;

@property (nonatomic,assign) NSArray *inputBarItemTypes;

@property (nonatomic,assign) NSInteger maxNumberOfInputLines;

- (void)update:(NIMInputStatus)status;

@end

@interface NIMInputToolBar(InputText)

- (NSRange)selectedRange;

- (void)setPlaceHolder:(NSString *)placeHolder;

- (void)insertText:(NSString *)text;

- (void)deleteText:(NSRange)range;

@end
