//
//  NIMInputView.m
//  NIMKit
//
//  Created by chris.
//  Copyright (c) 2015年 NetEase. All rights reserved.
//

#import "NIMInputView.h"
#import <AVFoundation/AVFoundation.h>
#import "NIMInputMoreContainerView.h"
#import "NIMInputEmoticonContainerView.h"
#import "NIMInputAudioRecordIndicatorView.h"
#import "NIMInputVoiceContainerView.h"
#import "UIView+NIM.h"
#import "NIMInputEmoticonDefine.h"
#import "NIMInputEmoticonManager.h"
#import "NIMInputToolBar.h"
#import "UIImage+NIMKit.h"
#import "NIMGlobalMacro.h"
#import "NIMContactSelectViewController.h"
#import "NIMKit.h"
#import "NIMKitInfoFetchOption.h"
#import "NIMKitKeyboardInfo.h"
#import "NIMInputToolBar.h"
#import "Masonry.h"

@interface NIMInputView()<NIMInputToolBarDelegate,NIMInputEmoticonProtocol,NIMContactSelectDelegate>
{
    UIView  *_emoticonView;
}

@property (nonatomic, strong) NIMInputAudioRecordIndicatorView *audioRecordIndicator;
@property (nonatomic, assign) NIMAudioRecordPhase recordPhase;
@property (nonatomic, weak) id<NIMSessionConfig> inputConfig;
@property (nonatomic, weak) id<NIMInputDelegate> inputDelegate;
@property (nonatomic, weak) id<NIMInputActionDelegate> actionDelegate;
@property (nonatomic, assign) CGFloat containerHeight;

@property (nonatomic, assign) CGFloat keyBoardFrameTop; //键盘的frame的top值，屏幕高度 - 键盘高度，由于有旋转的可能，这个值只有当 键盘弹出时才有意义。

@end


@implementation NIMInputView

@synthesize emoticonContainer = _emoticonContainer;
@synthesize moreContainer = _moreContainer;

- (instancetype)initWithFrame:(CGRect)frame
                       config:(id<NIMSessionConfig>)config
{
    self = [super initWithFrame:frame];
    if (self)
    {
        _recording = NO;
        _recordPhase = AudioRecordPhaseEnd;
        _atCache = [[NIMInputAtCache alloc] init];
        _inputConfig = config;
        self.backgroundColor = [UIColor whiteColor];
    }
    return self;
}

- (void)didMoveToWindow
{
    [self setup];
}

- (CGSize)sizeThatFits:(CGSize)size
{
    //这里不做.语法 get 操作，会提前初始化组件导致卡顿
    CGFloat toolBarHeight = _toolBar.nim_height;
    CGFloat containerHeight = 0;
    switch (self.status)
    {
        case NIMInputStatusEmoticon:
            containerHeight = _emoticonContainer.nim_height;
            break;
        case NIMInputStatusMore:
            containerHeight = _moreContainer.nim_height;
            break;
        case NIMInputStatusAudio:
            containerHeight = _voiceContainer.nim_height;
            break;
        default:
            containerHeight = [NIMKitKeyboardInfo instance].keyboardHeight;
            break;
    }
    CGFloat height = toolBarHeight + containerHeight;
    CGFloat width = self.superview? self.superview.nim_width : self.nim_width;
    return CGSizeMake(width, height);
}


- (void)setInputDelegate:(id<NIMInputDelegate>)delegate
{
    _inputDelegate = delegate;
}

- (void)setInputActionDelegate:(id<NIMInputActionDelegate>)actionDelegate
{
    _actionDelegate = actionDelegate;
}

- (void)reset
{
    self.nim_width = self.superview.nim_width;
    [self refreshStatus:NIMInputStatusText];
    [self sizeToFit];
}

- (void)refreshStatus:(NIMInputStatus)status
{
    self.status = status;
    [self.toolBar update:status];
}



- (NIMInputAudioRecordIndicatorView *)audioRecordIndicator {
    if(!_audioRecordIndicator) {
        _audioRecordIndicator = [[NIMInputAudioRecordIndicatorView alloc] init];
    }
    return _audioRecordIndicator;
}

- (void)setRecordPhase:(NIMAudioRecordPhase)recordPhase {
    NIMAudioRecordPhase prevPhase = _recordPhase;
    _recordPhase = recordPhase;
    self.audioRecordIndicator.phase = _recordPhase;
    if(prevPhase == AudioRecordPhaseEnd) {
        if(AudioRecordPhaseStart == _recordPhase) {
            if ([_actionDelegate respondsToSelector:@selector(onStartRecording)]) {
                [_actionDelegate onStartRecording];
            }
        }
    } else if (prevPhase == AudioRecordPhaseStart || prevPhase == AudioRecordPhaseRecording) {
        if (AudioRecordPhaseEnd == _recordPhase) {
            if ([_actionDelegate respondsToSelector:@selector(onStopRecording)]) {
                [_actionDelegate onStopRecording];
            }
        }
    } else if (prevPhase == AudioRecordPhaseCancelling) {
        if(AudioRecordPhaseEnd == _recordPhase) {
            if ([_actionDelegate respondsToSelector:@selector(onCancelRecording)]) {
                [_actionDelegate onCancelRecording];
            }
        }
    }
}

- (void)setup
{
    if (!_toolBar)
    {
        _toolBar = [[NIMInputToolBar alloc] initWithFrame:CGRectMake(0, 0, self.nim_width, 0)];
        
        [self addSubview:_toolBar];
        
        //设置placeholder
        NSString *placeholder = [NIMKit sharedKit].config.placeholder;
        [_toolBar setPlaceHolder:placeholder];
        
        //设置input bar 上的按钮
        if ([_inputConfig respondsToSelector:@selector(inputBarItemTypes)]) {
            NSArray *types = [_inputConfig inputBarItemTypes];
            [_toolBar setInputBarItemTypes:types];
        }
        
        _toolBar.delegate = self;
        [_toolBar.emoticonBtn addTarget:self action:@selector(onTouchEmoticonBtn:) forControlEvents:UIControlEventTouchUpInside];
//MODIFY HEAD:NIMKit/NIMKit/Classes/Sections/Input/NIMInputView.m
//        [_toolBar.moreMediaBtn addTarget:self action:@selector(onTouchMoreBtn:) forControlEvents:UIControlEventTouchUpInside];
//        [_toolBar.voiceButton addTarget:self action:@selector(onTouchVoiceBtn:) forControlEvents:UIControlEventTouchUpInside];
//        [_toolBar.recordButton addTarget:self action:@selector(onTouchRecordBtnDown:) forControlEvents:UIControlEventTouchDown];
//        [_toolBar.recordButton addTarget:self action:@selector(onTouchRecordBtnDragInside:) forControlEvents:UIControlEventTouchDragInside];
//        [_toolBar.recordButton addTarget:self action:@selector(onTouchRecordBtnDragOutside:) forControlEvents:UIControlEventTouchDragOutside];
//        [_toolBar.recordButton addTarget:self action:@selector(onTouchRecordBtnUpInside:) forControlEvents:UIControlEventTouchUpInside];
//        [_toolBar.recordButton addTarget:self action:@selector(onTouchRecordBtnUpOutside:) forControlEvents:UIControlEventTouchUpOutside];
//=======
        [_toolBar.voiceButton addTarget:self action:@selector(onTouchVoiceBtn:) forControlEvents:UIControlEventTouchUpInside];
        [_toolBar.photoBtn addTarget:self action:@selector(onTouchPhotoBtn:) forControlEvents:UIControlEventTouchUpInside];
        [_toolBar.voteBtn addTarget:self action:@selector(onTouchVoteBtn:) forControlEvents:UIControlEventTouchUpInside];
        [_toolBar.shotBtn addTarget:self action:@selector(onTouchShotBtn:) forControlEvents:UIControlEventTouchUpInside];
//>>>>>>> v1.2.0:NIMKit/NIMKit/Sections/Input/NIMInputView.m
        _toolBar.nim_size = [_toolBar sizeThatFits:CGSizeMake(self.nim_width, CGFLOAT_MAX)];
        _toolBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        
        //设置最大输入字数
        NSInteger textInputLength = [NIMKit sharedKit].config.inputMaxLength;
        self.maxTextLength = textInputLength;
        
        [self refreshStatus:NIMInputStatusText];
        [self sizeToFit];
    }
}

- (UIView *)moreContainer
{
    if (!_moreContainer) {
        NIMInputMoreContainerView *moreContainer = [[NIMInputMoreContainerView alloc] initWithFrame:CGRectZero];
        moreContainer.nim_size = [moreContainer sizeThatFits:CGSizeMake(self.nim_width, CGFLOAT_MAX)];
        moreContainer.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        moreContainer.hidden   = YES;
        moreContainer.config   = _inputConfig;
        moreContainer.actionDelegate = self.actionDelegate;
        _moreContainer = moreContainer;
    }
    
    //可能是外部主动设置进来的，统一放在这里添加 subview
    if (!_moreContainer.superview)
    {
        [self addSubview:_moreContainer];
    }
    
    return _moreContainer;
}

- (void)setMoreContainer:(UIView *)moreContainer
{
    _moreContainer = moreContainer;
    [self sizeToFit];
}

- (UIView *)emoticonContainer
{
    if (!_emoticonContainer) {
        NIMInputEmoticonContainerView *emoticonContainer = [[NIMInputEmoticonContainerView alloc] initWithFrame:CGRectZero];
        
        emoticonContainer.nim_size = [emoticonContainer sizeThatFits:CGSizeMake(self.nim_width, CGFLOAT_MAX)];
        emoticonContainer.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        emoticonContainer.delegate = self;
        emoticonContainer.hidden = YES;
        emoticonContainer.config = _inputConfig;
        
        _emoticonContainer = emoticonContainer;
    }
    
    //可能是外部主动设置进来的，统一放在这里添加 subview
    if (!_emoticonContainer.superview)
    {
        [self addSubview:_emoticonContainer];
    }
    
    return _emoticonContainer;
}

//MODIFY HEAD:NIMKit/NIMKit/Classes/Sections/Input/NIMInputView.m
//- (void)setEmoticonContainer:(UIView *)emoticonContainer
//=======
- (NIMInputVoiceContainerView *)voiceContainer {
    if (!_voiceContainer) {
        NIMInputVoiceContainerView *voiceContainer = [[NIMInputVoiceContainerView alloc] initWithFrame:CGRectZero];
        
        CGSize size = [voiceContainer sizeThatFits:CGSizeMake(self.nim_width, CGFLOAT_MAX)];
        voiceContainer.nim_size = size;
        voiceContainer.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    
        [voiceContainer.recordButton addTarget:self action:@selector(onTouchRecordBtnDown:) forControlEvents:UIControlEventTouchDown];
        [voiceContainer.recordButton addTarget:self action:@selector(onTouchRecordBtnDragInside:) forControlEvents:UIControlEventTouchDragInside];
        [voiceContainer.recordButton addTarget:self action:@selector(onTouchRecordBtnDragOutside:) forControlEvents:UIControlEventTouchDragOutside];
        [voiceContainer.recordButton addTarget:self action:@selector(onTouchRecordBtnUpInside:) forControlEvents:UIControlEventTouchUpInside];
        [voiceContainer.recordButton addTarget:self action:@selector(onTouchRecordBtnUpOutside:) forControlEvents:UIControlEventTouchUpOutside];
        [voiceContainer.recordButton setTitle:@"按住说话" forState:UIControlStateNormal];
        [self addSubview:voiceContainer];
        [voiceContainer mas_makeConstraints:^(MASConstraintMaker *make) {
            make.bottom.mas_greaterThanOrEqualTo(self);
            make.size.mas_equalTo(size);
        }];
//        _voiceContainer = [[NIMInputVoiceContainerView alloc] initWithFrame:CGRectMake(0,0,
//                                                                                       self.nim_width, 216)];
//        voiceContainer.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        _voiceContainer = voiceContainer;
    }
    return _voiceContainer;
}

//- (void)dealloc
//>>>>>>> v1.2.0:NIMKit/NIMKit/Sections/Input/NIMInputView.m
- (void)setEmoticonContainer:(UIView *)emoticonContainer
{
    _emoticonContainer = emoticonContainer;
    [self sizeToFit];
}

- (void)setRecording:(BOOL)recording
{
    if(recording)
    {
        self.audioRecordIndicator.center = self.superview.center;
        [self.superview addSubview:self.audioRecordIndicator];
        self.recordPhase = AudioRecordPhaseRecording;
    }
    else
    {
        [self.audioRecordIndicator removeFromSuperview];
        self.recordPhase = AudioRecordPhaseEnd;
    }
    _recording = recording;
}

#pragma mark - 外部接口
- (void)setInputTextPlaceHolder:(NSString*)placeHolder
{
    [_toolBar setPlaceHolder:placeHolder];
}

- (void)updateAudioRecordTime:(NSTimeInterval)time {
    self.audioRecordIndicator.recordTime = time;
}

- (void)updateVoicePower:(float)power {
    
}

#pragma mark - private methods

- (void)setFrame:(CGRect)frame
{
    CGFloat height = self.frame.size.height;
    [super setFrame:frame];
    if (frame.size.height != height)
    {
        [self callDidChangeHeight];
    }
}

- (void)callDidChangeHeight
{
    if (_inputDelegate && [_inputDelegate respondsToSelector:@selector(didChangeInputHeight:)])
    {
        if (self.status == NIMInputStatusMore || self.status == NIMInputStatusEmoticon || self.status == NIMInputStatusAudio)
        {
            //这个时候需要一个动画来模拟键盘
            [UIView animateWithDuration:0.25 delay:0 options:7 animations:^{
                [_inputDelegate didChangeInputHeight:self.nim_height];
            } completion:nil];
        }
        else
        {
            [_inputDelegate didChangeInputHeight:self.nim_height];
        }
    }
}

- (void)layoutSubviews
{
    [super layoutSubviews];
//MODIFY HEAD:NIMKit/NIMKit/Classes/Sections/Input/NIMInputView.m
    //这里不做.语法 get 操作，会提前初始化组件导致卡顿
    _moreContainer.nim_top     = self.toolBar.nim_bottom;
    _emoticonContainer.nim_top = self.toolBar.nim_bottom;
//=======
//    self.moreContainer.nim_top     = self.toolBar.nim_bottom;
//    self.emoticonContainer.nim_top = self.toolBar.nim_bottom;
    _voiceContainer.nim_top = self.toolBar.nim_bottom;
//>>>>>>> v1.2.0:NIMKit/NIMKit/Sections/Input/NIMInputView.m
}

#pragma mark - button actions
- (IBAction)onTouchRecordBtnDown:(id)sender {
    self.recordPhase = AudioRecordPhaseStart;
}
- (IBAction)onTouchRecordBtnUpInside:(id)sender {
    // finish Recording
    self.recordPhase = AudioRecordPhaseEnd;
}
- (IBAction)onTouchRecordBtnUpOutside:(id)sender {
    // cancel Recording
    self.recordPhase = AudioRecordPhaseEnd;
}

- (IBAction)onTouchRecordBtnDragInside:(id)sender {
    // "手指上滑，取消发送"
    self.recordPhase = AudioRecordPhaseRecording;
}
- (IBAction)onTouchRecordBtnDragOutside:(id)sender {
    // "松开手指，取消发送"
    self.recordPhase = AudioRecordPhaseCancelling;
}

- (void)onTouchVoiceBtn:(id)sender {
    // image change
    if (self.status!= NIMInputStatusAudio) {
        __weak typeof(self) weakSelf = self;
        if ([[AVAudioSession sharedInstance] respondsToSelector:@selector(requestRecordPermission:)]) {
            [[AVAudioSession sharedInstance] performSelector:@selector(requestRecordPermission:) withObject:^(BOOL granted) {
                if (granted) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [weakSelf bringSubviewToFront:weakSelf.voiceContainer];
                        [weakSelf.emoticonContainer setHidden:YES];
                        [weakSelf.voiceContainer setHidden:NO];
                        [weakSelf.moreContainer setHidden:YES];
                        [weakSelf refreshStatus:NIMInputStatusAudio];
                        if (weakSelf.toolBar.showsKeyboard)
                        {
                            weakSelf.toolBar.showsKeyboard = NO;
                        }
                        [weakSelf sizeToFit];
                    });
                }
                else {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (weakSelf.toolBar.showsKeyboard) {
//                            weakSelf.status = NIMInputStatusDown;
                            weakSelf.status = NIMInputStatusMore;
                            weakSelf.toolBar.showsKeyboard = NO;
                        }else{
//                            [weakSelf refreshStatus:NIMInputStatusDown];
                            [weakSelf refreshStatus:NIMInputStatusMore];
                            [weakSelf callDidChangeHeight];
                        }
                        [[[UIAlertView alloc] initWithTitle:nil
                                                    message:@"没有麦克风权限"
                                                   delegate:nil
                                          cancelButtonTitle:@"确定"
                                          otherButtonTitles:nil] show];
                    });
                }
            }];
        }
    }
    else
    {
        if ([self.toolBar.inputBarItemTypes containsObject:@(NIMInputBarItemTypeTextAndRecord)])
        {
            [self refreshStatus:NIMInputStatusText];
            self.toolBar.showsKeyboard = YES;
        }
    }
}

- (void)onTouchEmoticonBtn:(id)sender
{
    if (self.status != NIMInputStatusEmoticon) {
        [self bringSubviewToFront:self.emoticonContainer];
        [self.emoticonContainer setHidden:NO];
        [self.voiceContainer setHidden:YES];
        [self.moreContainer setHidden:YES];
        [self refreshStatus:NIMInputStatusEmoticon];
        [self sizeToFit];
        
        
        if (self.toolBar.showsKeyboard)
        {
            self.toolBar.showsKeyboard = NO;
        }
    }
    else
    {
        [self refreshStatus:NIMInputStatusText];
        self.toolBar.showsKeyboard = YES;
    }
}

- (void)onTouchMoreBtn:(id)sender {
    if (self.status != NIMInputStatusMore)
    {
        [self bringSubviewToFront:self.moreContainer];
        [self.moreContainer setHidden:NO];
        [self.voiceContainer setHidden:YES];
        [self.emoticonContainer setHidden:YES];
        [self refreshStatus:NIMInputStatusMore];
        [self sizeToFit];

        if (self.toolBar.showsKeyboard)
        {
            self.toolBar.showsKeyboard = NO;
        }
    }
    else
    {
        [self refreshStatus:NIMInputStatusText];
        self.toolBar.showsKeyboard = YES;
    }
}

- (void)onTouchPhotoBtn:(id)sender {
    NIMMediaItem *item = [NIMMediaItem item:@"onTapMediaItemPicture:"
                                normalImage:[UIImage nim_imageInKit:@"bk_media_picture_normal"]
                              selectedImage:[UIImage nim_imageInKit:@"bk_media_picture_nomal_pressed"]
                                      title:@"相册"];
    if ([self.actionDelegate respondsToSelector:@selector(onTapMediaItem:)]) {
        [self.actionDelegate onTapMediaItem:item];
    }
}

- (void)onTouchVoteBtn:(id)sender {
    NIMMediaItem *item = [NIMMediaItem item:@"onTapMediaItemVote:"
                                normalImage:[UIImage nim_imageInKit:@"bk_media_picture_normal"]
                              selectedImage:[UIImage nim_imageInKit:@"bk_media_picture_nomal_pressed"]
                                      title:@"相册"];
    if ([self.actionDelegate respondsToSelector:@selector(onTapMediaItem:)]) {
        [self.actionDelegate onTapMediaItem:item];
    }
}

- (void)onTouchShotBtn:(id)sender {
    NIMMediaItem *item = [NIMMediaItem item:@"onTapMediaItemShot:"
                                normalImage:[UIImage nim_imageInKit:@"bk_media_picture_normal"]
                              selectedImage:[UIImage nim_imageInKit:@"bk_media_picture_nomal_pressed"]
                                      title:@"相册"];
    if ([self.actionDelegate respondsToSelector:@selector(onTapMediaItem:)]) {
        [self.actionDelegate onTapMediaItem:item];
    }
}

- (BOOL)endEditing:(BOOL)force
{
    BOOL endEditing = [super endEditing:force];
    if (!self.toolBar.showsKeyboard) {
        UIViewAnimationCurve curve = UIViewAnimationCurveEaseInOut;
        void(^animations)() = ^{
            [self refreshStatus:NIMInputStatusText];
            [self sizeToFit];
            if (self.inputDelegate && [self.inputDelegate respondsToSelector:@selector(didChangeInputHeight:)]) {
                [self.inputDelegate didChangeInputHeight:self.nim_height];
            }
        };
        NSTimeInterval duration = 0.25;
        [UIView animateWithDuration:duration delay:0.0f options:(curve << 16 | UIViewAnimationOptionBeginFromCurrentState) animations:animations completion:nil];
    }
    return endEditing;
}


#pragma mark - NIMInputToolBarDelegate

- (BOOL)textViewShouldBeginEditing
{
    self.status = NIMInputStatusText;
    if ([self.actionDelegate respondsToSelector:@selector(inputViewShouldBeginEditing)]) {
        return [self.actionDelegate inputViewShouldBeginEditing];
    }
    return YES;
}

- (BOOL)shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    if ([text isEqualToString:@"\n"])
    {
        [self didPressSend:nil];
        return NO;
    }
//MODIFY HEAD:NIMKit/NIMKit/Classes/Sections/Input/NIMInputView.m
//    if ([text isEqualToString:@""] && range.length == 1 )
//    {
//        //非选择删除
//        return [self onTextDelete];
//    }
    if ([self shouldCheckAt])
    {
        // @ 功能
        [self checkAt:text];
//=======
    }
    if ([text isEqualToString:@""] && range.length == 1 ) {//非选择删除
        return [self onTextDelete];
    }
    if ([text isEqualToString:NIMInputAtStartChar] && self.session.sessionType == NIMSessionTypeTeam) {
        NIMContactTeamMemberSelectConfig *config = [[NIMContactTeamMemberSelectConfig alloc] init];
        config.needMutiSelected = NO;
        config.teamId = self.session.sessionId;
        config.filterIds = @[[NIMSDK sharedSDK].loginManager.currentAccount];
        NIMContactSelectViewController *vc = [[NIMContactSelectViewController alloc] initWithConfig:config];
        vc.delegate = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            [vc show];
        });
        
//>>>>>>> v1.2.0:NIMKit/NIMKit/Sections/Input/NIMInputView.m
    }
    NSString *str = [self.toolBar.contentText stringByAppendingString:text];
    if (str.length > self.maxTextLength)
    {
        return NO;
    }
    return YES;
}

- (BOOL)shouldCheckAt
{
    BOOL disable = NO;
    if ([self.inputConfig respondsToSelector:@selector(disableAt)])
    {
        disable = [self.inputConfig disableAt];
    }
    return !disable;
}

- (void)checkAt:(NSString *)text
{
    if ([text isEqualToString:NIMInputAtStartChar]) {
        switch (self.session.sessionType) {
            case NIMSessionTypeTeam:{
                NIMContactTeamMemberSelectConfig *config = [[NIMContactTeamMemberSelectConfig alloc] init];
                if ([self.inputConfig respondsToSelector:@selector(enableRobot)])
                {
                    config.enableRobot = [self.inputConfig enableRobot];
                }
                else
                {
                    config.enableRobot = YES;
                }
                config.needMutiSelected = NO;
                config.teamId = self.session.sessionId;
                config.filterIds = @[[NIMSDK sharedSDK].loginManager.currentAccount];
                NIMContactSelectViewController *vc = [[NIMContactSelectViewController alloc] initWithConfig:config];
                vc.delegate = self;
                dispatch_async(dispatch_get_main_queue(), ^{
                    [vc show];
                });
            }
                break;
            case NIMSessionTypeP2P:
            case NIMSessionTypeChatroom:{
                if (([self.inputConfig respondsToSelector:@selector(enableRobot)] && self.inputConfig.enableRobot) || [NIMSDK sharedSDK].isUsingDemoAppKey)
                {
                    NIMContactRobotSelectConfig *config = [[NIMContactRobotSelectConfig alloc] init];
                    config.needMutiSelected = NO;
                    NIMContactSelectViewController *vc = [[NIMContactSelectViewController alloc] initWithConfig:config];
                    vc.delegate = self;
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [vc show];
                    });
                }
            }
                break;
            default:
                break;
        }
    }
}


- (void)textViewDidChange
{
    if (self.actionDelegate && [self.actionDelegate respondsToSelector:@selector(onTextChanged:)])
    {
        [self.actionDelegate onTextChanged:self];
    }
}


- (void)toolBarDidChangeHeight:(CGFloat)height
{
    [self sizeToFit];
}



#pragma mark - NIMContactSelectDelegate
- (void)didFinishedSelect:(NSArray *)selectedContacts
{
    NSMutableString *str = [[NSMutableString alloc] initWithString:@""];
    NIMKitInfoFetchOption *option = [[NIMKitInfoFetchOption alloc] init];
    option.session = self.session;
    option.forbidaAlias = YES;
    for (NSString *uid in selectedContacts) {
        NSString *nick = [[NIMKit sharedKit].provider infoByUser:uid option:option].showName;
        [str appendString:nick];
        [str appendString:NIMInputAtEndChar];
        if (![selectedContacts.lastObject isEqualToString:uid]) {
            [str appendString:NIMInputAtStartChar];
        }
        NIMInputAtItem *item = [[NIMInputAtItem alloc] init];
        item.uid  = uid;
        item.name = nick;
        [self.atCache addAtItem:item];
    }
    [self.toolBar insertText:str];
}

#pragma mark - InputEmoticonProtocol
- (void)selectedEmoticon:(NSString*)emoticonID catalog:(NSString*)emotCatalogID description:(NSString *)description{
    if (!emotCatalogID) { //删除键
        [self onTextDelete];
    }else{
        if ([emotCatalogID isEqualToString:NIMKit_EmojiCatalog]) {
            [self.toolBar insertText:description];
        }else{
            //发送贴图消息
            if ([self.actionDelegate respondsToSelector:@selector(onSelectChartlet:catalog:)]) {
                [self.actionDelegate onSelectChartlet:emoticonID catalog:emotCatalogID];
            }
        }
        
        
    }
}

- (void)didPressSend:(id)sender{
    if ([self.actionDelegate respondsToSelector:@selector(onSendText:atUsers:)] && [self.toolBar.contentText length] > 0) {
        NSString *sendText = self.toolBar.contentText;
        [self.actionDelegate onSendText:sendText atUsers:[self.atCache allAtUid:sendText]];
        [self.atCache clean];
        self.toolBar.contentText = @"";
        [self.toolBar layoutIfNeeded];
    }
}



- (BOOL)onTextDelete
{
    NSRange range = [self delRangeForEmoticon];
    if (range.length == 1)
    {
        //删的不是表情，可能是@
        NIMInputAtItem *item = [self delRangeForAt];
        if (item) {
            range = item.range;
            [self.toolBar deleteText:range];
            return YES;
        }
    } else if (range.length > 0) {
        [self.toolBar deleteText:range];
    }
//MODIFY HEAD:NIMKit/NIMKit/Classes/Sections/Input/NIMInputView.m
    if (range.length == 1) {
        //自动删除
        return YES;
    }
    [self.toolBar deleteText:range];
//=======
//>>>>>>> v1.2.0:NIMKit/NIMKit/Sections/Input/NIMInputView.m
    return NO;
}

- (NSRange)delRangeForEmoticon
{
    NSString *text = self.toolBar.contentText;
    NSRange range = [self rangeForPrefix:@"[" suffix:@"]"];
    NSRange selectedRange = [self.toolBar selectedRange];
    if (range.length > 1)
    {
        NSString *name = [text substringWithRange:range];
        NIMInputEmoticon *icon = [[NIMInputEmoticonManager sharedManager] emoticonByTag:name];
        range = icon? range : NSMakeRange(selectedRange.location - 1, 1);
    }
    return range;
}


- (NIMInputAtItem *)delRangeForAt
{
    NSString *text = self.toolBar.contentText;
    NSRange range = [self rangeForPrefix:NIMInputAtStartChar suffix:NIMInputAtEndChar];
    NSRange selectedRange = [self.toolBar selectedRange];
    NIMInputAtItem *item = nil;
    if (range.length > 1)
    {
        NSString *name = [text substringWithRange:range];
        NSString *set = [NIMInputAtStartChar stringByAppendingString:NIMInputAtEndChar];
        name = [name stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:set]];
        item = [self.atCache item:name];
        range = item? range : NSMakeRange(selectedRange.location - 1, 1);
    }
    item.range = range;
    return item;
}


- (NSRange)rangeForPrefix:(NSString *)prefix suffix:(NSString *)suffix
{
    NSString *text = self.toolBar.contentText;
    NSRange range = [self.toolBar selectedRange];
    NSString *selectedText = range.length ? [text substringWithRange:range] : text;
    NSInteger endLocation = range.location;
    if (endLocation <= 0)
    {
        return NSMakeRange(NSNotFound, 0);
    }
    NSInteger index = -1;
    if ([selectedText hasSuffix:suffix]) {
        //往前搜最多20个字符，一般来讲是够了...
        NSInteger p = 20;
        for (NSInteger i = endLocation; i >= endLocation - p && i-1 >= 0 ; i--)
        {
            NSRange subRange = NSMakeRange(i - 1, 1);
            NSString *subString = [text substringWithRange:subRange];
            if ([subString compare:prefix] == NSOrderedSame)
            {
                index = i - 1;
                break;
            }
        }
    }
    return index == -1? NSMakeRange(endLocation - 1, 1) : NSMakeRange(index, endLocation - index);
}

@end
