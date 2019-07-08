//
//  ViewController.m
//  iOSDemo
//
//  Created by mac on 2019/6/26.
//  Copyright © 2019 mac. All rights reserved.
//

#import "ExampleVC.h"
#import <VCRTC/VCRTC.h>

@interface ExampleVC ()<VCRtcModuleDelegate>
@property (nonatomic, strong) VCRtcModule *vcrtc;
/** 远端视图 */
@property (weak, nonatomic) IBOutlet UIView *othersView;
/** 远端视频views */
@property (nonatomic, strong) NSMutableArray *farEndViewsArray;
/** 本地视频View */
@property (nonatomic, strong) VCVideoView *localView;

/** 顶部视图 */
@property (weak, nonatomic) IBOutlet UIView *topView;
/** 底部视图 */
@property (weak, nonatomic) IBOutlet UIView *bottomView;
/** 点击隐藏 bottomView topView */
@property (weak, nonatomic) IBOutlet UIButton *clickBtn;



@end

@implementation ExampleVC

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController.navigationBar setHidden:YES];
}
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.farEndViewsArray = [NSMutableArray array];
    //初始化
    self.vcrtc = [VCRtcModule sharedInstance];
    //配置服务器域名
    self.vcrtc.apiServer = @"bss.lalonline.cn";
    //遵循 VCRtcModuleDelegate方法
    self.vcrtc.delegate = self;
    self.vcrtc.groupId = @"group.com.zijingcloud.phone";
    //入会类型配置 点对点
    [self.vcrtc configConnectType:VCConnectTypeUser];
    //入会音视频质量配置
    [self.vcrtc configVideoProfile:VCVideoProfile480P];
     //入会接收流的方式配置
    [self.vcrtc configMultistream:YES];
    //用户账号配置(用户登录需配置,未登录不需要)
//    [self.vcrtc configLoginAccount:@"test_ios_demo@zijingcloud.com"];
    //配置音视频 channel: 用户地址 password: 参会密码 name: 会中显示名称 xiaobeioldone@zijingcloud.com
    [self.vcrtc connectChannel:@"1867" password:@"123456" name:@"test_ios_demo" success:^(id _Nonnull response) {
        NSLog(@"%@",response);
    } failure:^(NSError * _Nonnull error) {
        
    }];
//    self.vcrtc.forceOrientation = UIDeviceOrientationLandscapeLeft;
   
}


#pragma mark - VCRtcModuleDelegate 接收会中音视频处理
//接收本地视频
- (void)VCRtc:(VCRtcModule *)module didAddLocalView:(VCVideoView *)view {
    
    view.frame = self.view.frame;
    self.localView = view;
    view.objectFit = VCVideoViewObjectFitCover;
    [self.view insertSubview:view atIndex:0];
//    [self.view bringSubviewToFront:self.othersView];
   
    
}
// 接收远端视频
- (void)VCRtc:(VCRtcModule *)module didAddView:(VCVideoView *)view uuid:(NSString *)uuid {
    //只处理了3个远端视频
    if (![self.farEndViewsArray containsObject:view] && self.farEndViewsArray.count < 3) {
        [self.farEndViewsArray addObject:view];
        [self layoutFarEndView];
    }
}
//删除远端视频
- (void)VCRtc:(VCRtcModule *)module didRemoveView:(VCVideoView *)view uuid:(NSString *)uuid {
    [view removeFromSuperview];
    [self.farEndViewsArray removeObject:view];
    [self layoutFarEndView];
}
//连接失败
- (void)VCRtc:(VCRtcModule *)module didDisconnectedWithReason:(NSError *)reason {
}
/** 远端视频布局 */
- (void)layoutFarEndView {
    CGFloat viewWidth = 100;
    CGFloat viewHeight = 128;
    for (NSInteger i = 0 ; i < self.farEndViewsArray.count; i++) {
        VCVideoView *subView = self.farEndViewsArray[i];
        [self.othersView addSubview:subView];
        subView.objectFit = VCVideoViewObjectFitCover;
        subView.frame = CGRectMake(i * viewWidth, 0, viewWidth, viewHeight);
    }
}

#pragma mark - button点击方法
//退出会议
- (IBAction)exitMeetingAction:(UIButton *)sender {
    
    [self.vcrtc exitChannelSuccess:^(id  _Nonnull response) {
        for (VCVideoView *subView in self.farEndViewsArray) {
            [subView removeFromSuperview];
        }
        [self.farEndViewsArray removeAllObjects];
        [self.localView removeFromSuperview];
        NSLog(@"退出会议成功");
    } failure:^(NSError * _Nonnull error) {
        NSLog(@"退出会议失败");
    }];
}

- (void)VCRtc:(VCRtcModule *)module didAddParticipant:(Participant *)participant {}
- (void)VCRtc:(VCRtcModule *)module didRemoveParticipant:(Participant *)participant{}
- (void)VCRtc:(VCRtcModule *)module didUpdateParticipants:(NSArray *)participants {}
- (void)VCRtc:(VCRtcModule *)module didUpdateParticipant:(Participant *)participant {}


//静音
- (IBAction)muteAction:(UIButton *)sender {
    sender.selected = !sender.selected;
    [self.vcrtc micEnable:!sender.selected];
}
//静画
- (IBAction)stillPictureAction:(UIButton *)sender {
    sender.selected = !sender.selected;
    [self.vcrtc videoEnable:!sender.selected];
}
//分享
- (IBAction)shareAction:(id)sender {
}


//切换摄像头
- (IBAction)switchCameraAction:(id)sender {
    [self.vcrtc switchCamera];
}

//重新入会
- (IBAction)rejoinMeetingAction:(UIButton *)sender {
    [self.vcrtc connectChannel:@"2207" password:@"123456" name:@"test_ios_demo" success:^(id _Nonnull response) {
        
    } failure:^(NSError * _Nonnull error) {
        
    }];
}
//重连
- (IBAction)reconnectAction:(id)sender {
    [self.vcrtc reMakeMediaCall];
}

//上传日志
- (IBAction)uploadLogAction:(UIButton *)sender {
    [self.vcrtc uploadLoggerWithName:@"iosLog" URLString:@"http://172.20.10.7:3000/upload"];
}
//入会
- (IBAction)joinMeetingAction:(id)sender {
    //初始化
    self.vcrtc = [VCRtcModule sharedInstance];
    //配置服务器域名
    self.vcrtc.apiServer = @"bss.lalonline.cn";
    //遵循 VCRtcModuleDelegate方法
    self.vcrtc.delegate = self;
    //入会类型配置
    [self.vcrtc configConnectType:VCConnectTypeMeeting];
    //入会音视频质量配置
    [self.vcrtc configVideoProfile:VCVideoProfile480P];
    //入会接收流的方式配置
    [self.vcrtc configMultistream:YES];
    //用户账号配置(用户登录需配置,未登录不需要)
    [self.vcrtc configLoginAccount:@"test_ios_demo@zijingcloud.com"];
    //入会配置音视频 channel: 会议室/用户地址 password: 参会密码 name: 会中显示名称
    [self.vcrtc connectChannel:@"2207" password:@"123456" name:@"test_ios_demo" success:^(id _Nonnull response) {
        
    } failure:^(NSError * _Nonnull error) {
        
    }];
}

//开启关闭麦克风
- (IBAction)micHandleAction:(UIButton *)sender {
    sender.selected = !sender.selected;
    //YES开启麦克风 NO关闭麦克风
    [self.vcrtc micEnable:!sender.selected];
}
//开启关闭摄像头
- (IBAction)cameraHandleAction:(UIButton *)sender {
    sender.selected = !sender.selected;
    //YES开启摄像头 NO关闭摄像头
    [self.vcrtc videoEnable:!sender.selected];
}
//摄像头方向操作
- (IBAction)cameraOrientationHandleAction:(UIButton *)sender {
    self.vcrtc.forceOrientation = UIDeviceOrientationLandscapeRight;
}

//锁定会议
- (IBAction)lockedMeetingAction:(UIButton *)sender {
    sender.selected = !sender.selected;
    [self.vcrtc lockMeeting:sender.selected success:^(id  _Nonnull response) {
        
    } failure:^(NSError * _Nonnull error) {
        
    }];
}
//全体静音
- (IBAction)mutedAllParticipantAction:(UIButton *)sender {
    sender.selected = !sender.selected;
    //静音是所有访客静音
    [self.vcrtc muteAllGuest:sender.selected success:^(id  _Nonnull response) {
        
    } failure:^(NSError * _Nonnull error) {
        
    }];
}

//布局
- (IBAction)layoutParticipantAction:(UIButton *)sender {
    sender.selected = !sender.selected;
    //布局 layout：布局（主持人布局） glayout：可传空值（访客布局）传值当前仅支持 （大：小）1：0、4：0、1：7、1：21、2：21
    [self.vcrtc updateLayoutHost:@"4:0" guest:@"" conferenceType:VCConferenceTypeVmr success:^(id  _Nonnull response) {
        
    } failure:^(NSError * _Nonnull error) {
        
    }];
}

//录播
- (IBAction)recordAction:(UIButton *)sender {
    sender.selected = !sender.selected;
    if (sender.selected) {
        //开启录播
        [self.vcrtc enableRecordSuccess:^(id  _Nonnull response) {
            
        } failure:^(NSError * _Nonnull error) {
            
        }];
    } else {
        //关闭录播
        [self.vcrtc disableRecordSuccess:^(id  _Nonnull response) {
            
        } failure:^(NSError * _Nonnull error) {
            
        }];
    }
}
//直播
- (IBAction)liveAction:(UIButton *)sender {
    sender.selected = !sender.selected;
    if (sender.selected) {
        //开启直播
        [self.vcrtc enableLiveSuccess:^(id  _Nonnull response) {
            
        } failure:^(NSError * _Nonnull error) {
            
        }];
    } else {
        //关闭直播
        [self.vcrtc disableLiveSuccess:^(id  _Nonnull response) {
            
        } failure:^(NSError * _Nonnull error) {
            
        }];
    }
}

//全体静音
- (IBAction)muteAllGuest:(UIButton *)sender {
    sender.selected = !sender.selected;
    // mute YES 全体静音 NO取消全体静音 静音只是全体访客静音
    [self.vcrtc muteAllGuest:sender.selected success:^(id  _Nonnull response) {
        
    } failure:^(NSError * _Nonnull error) {
        
    }];
}



#pragma mark - Controller 的屏幕和状态栏

- (BOOL)shouldAutorotate {
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskLandscapeRight ;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation{
    return UIInterfaceOrientationLandscapeRight ;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent ;
}

- (BOOL )prefersStatusBarHidden {
    return self.topView.alpha == 0 ;
}

- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation {
    return UIStatusBarAnimationNone;
}





@end
