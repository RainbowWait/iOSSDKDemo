//
//  ViewController.m
//  iOSDemo
//
//  Created by mac on 2019/6/26.
//  Copyright © 2019 mac. All rights reserved.
//

#import "ExampleVC.h"
#import "VideoViewModel.h"
#import "SmallView.h"
#import "ZJConferenceVCCell.h"
#import "ZJConferenceHeaderView.h"
#import "VCPresentionView.h"
#import "ShareModel.h"
@interface ExampleVC ()<VCRtcModuleDelegate,TZImagePickerControllerDelegate,VCPresentionViewDelegate>
@property (nonatomic, strong) VCRtcModule *vcrtc;
/** 远端视图 */
@property (weak, nonatomic) IBOutlet UIView *othersView;
/** 远端视频views */
@property (nonatomic, strong) NSMutableArray <VideoViewModel *>*farEndViewsArray;
/** 本地视频View */
@property (nonatomic, strong) VCVideoView *localView;

/** 顶部视图 */
@property (weak, nonatomic) IBOutlet UIView *topView;
/** 底部视图 */
@property (weak, nonatomic) IBOutlet UIView *bottomView;
/** 点击隐藏 bottomView topView */
@property (weak, nonatomic) IBOutlet UIButton *clickBtn;
/** 分享 */
@property (weak, nonatomic) IBOutlet UIButton *shareBtn;
/** 显示会议室号 */
@property (weak, nonatomic) IBOutlet UILabel *nameLab;
/** 质量统计 */
@property (weak, nonatomic) IBOutlet UITableView *table;
/** 质量统计数据 */
@property (nonatomic, strong) NSMutableArray<NSArray<NSString *> *> *statisticsArray;
/** 显示分享图片视图 */
@property (nonatomic, strong)VCPresentionView *shareView;
/** 图片清晰度要求 */
@property (nonatomic, assign) YCPhotoSourceType photoType;
/** 分享的图片 */
@property (nonatomic, strong) NSArray *shareImages;
/** 分享相关的状态记录 */
@property (nonatomic, strong) ShareModel *shareModel;
@property (nonatomic, assign) BOOL  isShiTong;
/** 本地屏幕录制状态显示 */
@property (weak, nonatomic) IBOutlet UIImageView *screenRecordStateImg;
/** 屏幕录制由于屏幕录制关闭后, 无法及时获取该状态,所以使用定时器时刻监测该状态 */
@property (nonatomic, strong) NSTimer *recordTimer ;

@end

@implementation ExampleVC
- (void)dealloc
{
    NSLog(@"----------------dealloc");
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController.navigationBar setHidden:YES];
}

- (ShareModel *)shareModel {
    if (!_shareModel) {
        _shareModel = [[ShareModel alloc]init];
        _shareModel.shareType = @"none";
        _shareModel.isSharing = NO;
        _shareModel.uuid = @"";
    }
    return _shareModel;
}

- (VCPresentionView *)shareView {
    if (!_shareView) {
        _shareView = [[VCPresentionView alloc]initWithFrame:self.view.frame showImagesOrURLs:self.shareImages PhotoSourceType:self.photoType];
        _shareView.delegate = self;
        _shareView.backgroundColor = [UIColor clearColor];
    }
    return _shareView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self viewPropertySet];
    self.farEndViewsArray = [NSMutableArray array];
    [self joinMeetingSet];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(closeShareScreen) name:@"closeShareScreen" object:nil];
    
}
- (void)closeShareScreen {
    [self.vcrtc stopRecordScreen];
}
//入会配置
- (void)joinMeetingSet {
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
    [self.vcrtc connectChannel:@"1866" password:@"123456" name:@"test_ios_demo" success:^(id _Nonnull response) {
        //记录此时会议状态
        NSUserDefaults *userDefault = [[NSUserDefaults alloc]initWithSuiteName:kGroupId];
        [userDefault setObject:@"inmeeting" forKey:kScreenRecordMeetingState];
        
    } failure:^(NSError * _Nonnull error) {
        NSUserDefaults *userDefault = [[NSUserDefaults alloc]initWithSuiteName:kGroupId];
        [userDefault setObject:@"outmeeting" forKey:kScreenRecordMeetingState];
    }];
    self.vcrtc.forceOrientation = UIDeviceOrientationLandscapeLeft;
    [[NSRunLoop currentRunLoop] addTimer:self.recordTimer forMode:NSRunLoopCommonModes];
}

//视图的属性设置
- (void)viewPropertySet {
    self.topView.backgroundColor = [[UIColor colorWithRed:18/255.0 green:26/255.0 blue:44/255.0 alpha:1.0] colorWithAlphaComponent:0.9];
    self.bottomView.backgroundColor = [[UIColor colorWithRed:18/255.0 green:26/255.0 blue:44/255.0 alpha:1.0] colorWithAlphaComponent:0.9];
    self.table.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.8];
    [self.table registerClass:[ZJConferenceVCCell class] forCellReuseIdentifier:@"ZJConferenceVCCell"];
    self.nameLab.text = @"1867";
}


/**
 监测本端屏幕共享是否结束
 */
-(NSTimer *)recordTimer {
    if (!_recordTimer) {
        _recordTimer = [NSTimer timerWithTimeInterval:1.0 target:self selector:@selector(monitoringScreenRecordStopState) userInfo:nil repeats:YES];
    }
    return _recordTimer ;
}


#pragma mark - VCRtcModuleDelegate 接收会中音视频处理
//接收本地视频
- (void)VCRtc:(VCRtcModule *)module didAddLocalView:(VCVideoView *)view {
    Participant *localParticipant = self.vcrtc.rosterList[self.vcrtc.uuid];
    if (localParticipant == nil || localParticipant.uuid.length == 0) {
        Participant *tempParticipant = [[Participant alloc] init];
        tempParticipant.role = @"host";
        tempParticipant.uuid = self.vcrtc.uuid ;
        tempParticipant.overlayText = @"我";
        localParticipant = tempParticipant;
        
    }
    [self.farEndViewsArray addObject:[[VideoViewModel alloc] initWithuuid:self.vcrtc.uuid videoView:view participant:localParticipant]];
    
     [self layoutFarEndView:self.vcrtc.layoutParticipants];
    
    
}
// 接收远端视频
- (void)VCRtc:(VCRtcModule *)module didAddView:(VCVideoView *)view uuid:(NSString *)uuid {
    BOOL isContain = NO;
    //该数组是否包含该参会者的视频视图
    for (VideoViewModel *model in self.farEndViewsArray) {
        if ([model.uuid isEqualToString:uuid]) {
            isContain = YES;
        }
    }
    //只处理了3个远端视频
    if (!isContain) {
        
        [self.farEndViewsArray addObject:[[VideoViewModel alloc] initWithuuid:uuid videoView:view participant:self.vcrtc.rosterList[uuid]]];
        [self layoutFarEndView:self.vcrtc.layoutParticipants];
    }
}

//有参会者离开会议
- (void)VCRtc:(VCRtcModule *)module didRemoveView:(VCVideoView *)view uuid:(NSString *)uuid {
    //从视图上移除
    for (SmallView *smallView in self.othersView.subviews) {
        if ([smallView.uuid isEqualToString:uuid]) {
            [smallView removeFromSuperview];
        }
    }
    //从数组上移除
    [self.farEndViewsArray enumerateObjectsUsingBlock:^(VideoViewModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        if ([obj.uuid isEqualToString:uuid]) {
            [self.farEndViewsArray removeObject:obj];
        }
    }];
    [self layoutFarEndView:self.vcrtc.layoutParticipants];
}

- (void)VCRtc:(VCRtcModule *)module didLayoutParticipants:(NSArray *)participants {
    
    [self layoutFarEndView:participants];
}


//连接失败
- (void)VCRtc:(VCRtcModule *)module didDisconnectedWithReason:(NSError *)reason {
    NSLog(@"失败原因: %@",reason);
}

//质量统计数据
- (void)VCRtc:(VCRtcModule *)module didReceivedStatistics:(NSArray<VCMediaStat *> *)mediaStats {
    [self statisticsHandle:mediaStats];
}

//MARK: - 分享 - 远端 本端发送图片 、 本端录制屏幕

/**
 公有云下:
 自己本端分享图片和屏幕共享的时候didStartImage方法不会调用 只有远端共享图片和屏幕共享的时候才会调用
 */
- (void)VCRtc:(VCRtcModule *)module didStartImage:(NSString *)shareUuid {
        NSUserDefaults *userDefaults = [[NSUserDefaults alloc]initWithSuiteName:self.vcrtc.groupId ];
    //本地屏幕共享 被远端抢流(远端屏幕共享,分享图片)
    //ongoing 本端屏幕录制进行中
    //start 本端屏幕录制开始中
    if (([[userDefaults objectForKey:kScreenRecordState] isEqualToString:@"ongoing"] || [[userDefaults objectForKey:kScreenRecordState] isEqualToString:@"start"]) && self.shareModel.isSharing && [self.shareModel.shareType isEqualToString:@"localScreenShare"] ) {
        //被抢流本端屏幕共享停止
        [userDefaults setObject:@"stop" forKey:kScreenRecordState];
        //分享类型是远端分享
        self.shareModel.shareType = @"remote";
        //远端正在开始准备分享
        self.shareModel.isSharing = YES;
        //远端分享者的唯一标识
        self.shareModel.uuid = shareUuid;
        //本端屏幕录制状态图隐藏
        self.screenRecordStateImg.hidden = YES;
        //本端分享按钮非选中状态
        self.shareBtn.selected = NO;
     
    }
//        else if ([[userDefaults objectForKey:kScreenRecordState] isEqualToString:@"start"] ) {
//        if ([shareUuid isEqualToString:self.vcrtc.uuid]) {
//            self.shareModel.shareType = @"localScreenShare";
//            self.shareModel.isSharing = YES;
//            self.shareModel.uuid = shareUuid;
//            self.screenRecordStateImg.hidden = NO;
//            self.shareBtn.selected = YES;
//        }
//
//    }
    else {
        //远端图片分享或屏幕共享
        if (![shareUuid isEqualToString:self.vcrtc.uuid]) {
            //分享按钮非选中状态
            self.shareBtn.selected = NO;
        }
        //分享类型 远端图片分享或屏幕共享
        self.shareModel.shareType = @"remote";
        //分享人的唯一标识
        self.shareModel.uuid = shareUuid;
        //正在分享
        self.shareModel.isSharing = YES;
    }
}


/**
 这个方法无论是本端分享或屏幕共享还是远端分享或屏幕共享,该方法都会调用
 */
- (void)VCRtc:(VCRtcModule *)module didUpdateImage:(NSString *)imageStr uuid:(NSString *)uuid {
    NSUserDefaults *userDefaults = [[NSUserDefaults alloc]initWithSuiteName:self.vcrtc.groupId ];
    //本端正在屏幕共享
    if ([[userDefaults objectForKey:kScreenRecordState] isEqualToString:@"start"] || [[userDefaults objectForKey:kScreenRecordState] isEqualToString:@"ongoing"]) {
        //状态更改为正在屏幕共享进行中
        [userDefaults setObject:@"ongoing" forKey:kScreenRecordState];
        //本端屏幕共享
        self.shareModel.shareType = @"localScreenShare";
        //正在屏幕共享
        self.shareModel.isSharing = YES;
        //显示屏幕共享状态图
        self.screenRecordStateImg.hidden = NO;
        //分享按钮选中状态
        self.shareBtn.selected = YES;
    } else {
        //分享图片自己本端分享的时候不做处理 或者是屏幕录制也不做处理
        if (([self.shareModel.shareType isEqualToString:@"local"] || [self.shareModel.shareType isEqualToString:@"localScreenShare"]) && self.shareModel.isSharing ) {
            return;
        }
        //图片来源是否修改高清的链接
        self.photoType = YCPhotoSourceType_URL ;
        //远端分享或屏幕共享的图片URL
        NSURL *url= [NSURL URLWithString:imageStr];
        self.shareImages = @[url];
        [self loadPresentationView];
    }

}


- (void)monitoringScreenRecordStopState {
                NSUserDefaults *userDefault = [[NSUserDefaults alloc]initWithSuiteName:self.vcrtc.groupId];
    if ([[userDefault objectForKey:@"screen_record_open_state"] isEqualToString:@"stop"] ||
        [[userDefault objectForKey:kScreenRecordState] isEqualToString:@"appfinsh"]) {
        [userDefault setObject:@"applaunch" forKey:kScreenRecordState];
        NSLog(@"定时器 检测到stop... +++++++++++++++++++++++++++++++++++++++++");
        [self.vcrtc stopRecordScreen];
    }
}

- (void)VCRtc:(VCRtcModule *)module didStopImage:(NSString *)imageStr {
    NSUserDefaults *userDefaults = [[NSUserDefaults alloc]initWithSuiteName:self.vcrtc.groupId ];
    if ([self.shareModel.shareType isEqualToString:@"localScreenShare"] && self.shareModel.isSharing && self.shareBtn.selected) {
        if ([[userDefaults objectForKey:kScreenRecordState] isEqualToString:@"stop"] || [[userDefaults objectForKey:kScreenRecordState] isEqualToString:@"applaunch"]) {
            [userDefaults setObject:kScreenRecordState forKey:@"stop"];
            self.shareBtn.selected = NO;
            self.screenRecordStateImg.hidden = YES;
            self.shareModel = nil;
             [self layoutFarEndView:self.vcrtc.layoutParticipants] ;
        }
    } else {
        if (![self.shareModel.shareType isEqualToString:@"local"]) {
            [self.shareView removeFromSuperview];
            self.shareView = nil;
            self.shareImages = nil;
            self.shareModel = nil;
            [self layoutFarEndView:self.vcrtc.layoutParticipants] ;
        }
    }

    
}

/** 远端视频布局 */
- (void)layoutFarEndView: (NSArray <NSString *>*)participants  {
   
    if (participants == nil || participants.count == 0) {
         [self clearAllView];
        //只有本地视图
        [self createBigView];
        [self createSmallView];
        
    } else {
        //排序规则 根据是否有人发言 有发言放在大视频上面 根据participants返回的数据排序 我自己本地始终放在小视频第一个
        NSMutableArray *tempArray = [NSMutableArray array];
        //participants
        for (NSString *uuid in participants) {
            for (VideoViewModel *videoViewModel in self.farEndViewsArray) {
                if ([uuid isEqualToString:videoViewModel.uuid] && ![uuid isEqualToString:self.vcrtc.uuid]) {
                    if (![tempArray containsObject:videoViewModel]) {
                        //不包含自己
                        [tempArray addObject:videoViewModel];
                    }
                }
            }
        }
        
        for (VideoViewModel *model in self.farEndViewsArray) {
            if ( [model.uuid isEqualToString:self.vcrtc.uuid]) {
                //添加自己,并且把位置放在小视频的第一位
                if (![tempArray containsObject:model]) {
                    if (tempArray.count >= 2) {
                        [tempArray insertObject:model atIndex:1];
                    } else {
                        [tempArray addObject:model];
                    }
                }
            }
        }
        
        self.farEndViewsArray = tempArray;
        [self clearAllView];
        if (self.shareModel.isSharing) {
            [self updatePresentSmallView];
        } else {
            [self createBigView];
            [self createSmallView];
        }
        
        
    }

}

- (void)clearAllView {
    for (SmallView *view in self.othersView.subviews) {
        [view removeFromSuperview];
    }
}

- (void)createBigView {
    if (self.farEndViewsArray.count < 1) {
        return;
    }
     VideoViewModel *videoViewModel = [self.farEndViewsArray firstObject];
    SmallView *bigView = [SmallView loadSmallViewWithVideoView:videoViewModel.videoView isTurnOffTheCamera:NO withParticipant:videoViewModel.participant isBig:YES uuid:videoViewModel.uuid];
    bigView.frame = self.othersView.bounds;
    [self.othersView addSubview:bigView];
    
}

- (void)createSmallView {
    if (self.farEndViewsArray.count < 2) {
        return;
    }
    CGFloat viewWidth = (self.othersView.frame.size.width - 20)/5;
    CGFloat viewHeight = 72 ;
    for (NSInteger i = 1 ; i < self.farEndViewsArray.count; i++) {
        //获取会中显示昵称
        VideoViewModel *videoViewModel = self.farEndViewsArray[i];
        SmallView *smallView = [SmallView loadSmallViewWithVideoView:videoViewModel.videoView isTurnOffTheCamera:NO withParticipant:videoViewModel.participant isBig:NO uuid:videoViewModel.uuid];
        [self.othersView addSubview:smallView];
        smallView.frame = CGRectMake((i - 1) * viewWidth + 10, self.othersView.frame.size.height - viewHeight, viewWidth, viewHeight);
    }
}


#pragma mark - 按钮点击方法
//退出会议
- (IBAction)exitMeetingAction:(UIButton *)sender {
    
    [self.vcrtc exitChannelSuccess:^(id  _Nonnull response) {
        
    } failure:^(NSError * _Nonnull error) {
        NSLog(@"退出会议失败");
    }];
    [self.recordTimer invalidate];
    self.recordTimer = nil;
    [self dismissViewControllerAnimated:YES completion:nil];
}
//会中质量统计
- (IBAction)showQualityStatisticsAction:(UIButton *)sender {
    self.table.hidden = NO;
    self.topView.hidden = YES;
    self.bottomView.hidden = YES;
    [self setNeedsStatusBarAppearanceUpdate];//状态栏的显示隐藏
}


//麦克风关闭打开
- (IBAction)microphoneControlAction:(UIButton *)sender {
    sender.selected = !sender.selected;
    [self.vcrtc micEnable:!sender.selected];
}
//分享
- (IBAction)shareAction:(id)sender {
    if (self.shareBtn.selected) {
        if (self.isShiTong) {
            //终止图片分享
            [self.vcrtc shareToStreamImageData:[NSData data]
                                          open:NO
                                        change:NO
                                       success:^(id  _Nonnull response) {}
                                       failure:^(NSError * _Nonnull error) {}];
        } else {
            //终止图片分享
            [self.vcrtc shareImageData:[NSData data]
                                  open:NO
                                change:NO
                               success:^(id  _Nonnull response) {}
                               failure:^(NSError * _Nonnull error) {}];
            
        }
        [self.shareView removeFromSuperview];
        self.shareView = nil;
        self.shareImages = nil;
        self.shareModel = nil;
        self.shareBtn.selected = NO;
    } else {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
        UIAlertAction *photoAction = [UIAlertAction actionWithTitle:@"照片" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self photoShareAction];
        }];
        
        UIAlertAction *screenAction = [UIAlertAction actionWithTitle:@"屏幕" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            
        }];
        UIAlertAction *iCloudction = [UIAlertAction actionWithTitle:@"iCloud" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            
        }];
        
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            
        }];
        [alert addAction:photoAction];
        [alert addAction:screenAction];
        [alert addAction:iCloudction];
        [alert addAction:cancelAction];
        [self presentViewController:alert animated:YES completion:nil];
    }
    
}

- (void)photoShareAction {

        TZImagePickerController *imagePickerVc = [[TZImagePickerController alloc] initWithMaxImagesCount:9 columnNumber:6 delegate:self pushPhotoPickerVc:YES];
        imagePickerVc.allowPickingOriginalPhoto = NO;
        [imagePickerVc setDidFinishPickingPhotosHandle:^(NSArray<UIImage *> *photos, NSArray *assets, BOOL isSelectOriginalPhoto) {
            self.shareImages = photos;
            self.photoType = YCPhotoSourceType_Image;
            [self loadPresentationView];
            [self submitSharingImage:[photos firstObject] change:NO];
        }];
        [self presentViewController:imagePickerVc animated:true completion:nil];

}

- (void)submitSharingImage:(UIImage *)image change:(BOOL )myChange{
    NSData* data = UIImageJPEGRepresentation(image, 1);
    BOOL isShiTong = NO;
    if (isShiTong) {
        [self.vcrtc shareToStreamImageData:data open:YES change:self.shareModel.uuid.length ? YES : NO success:^(id  _Nonnull response) {
//            NSLog(@"分享成功：%@ -- ",response);
//            self.shareUuid = @"new";
//            self.shareBbtn.selected = YES ;
//            self.localSharing = YES ;
//            self.sharing = YES ;
//            self.sharingStuts = [self.sharingStuts isEqualToString:@"video"] ? @"local_remote" : @"local" ;
        } failure:^(NSError * _Nonnull error) {
            NSLog(@"分享失败：%@ -- ",error);
//            if(self.shareBbtn.selected == NO) return ;
//            self.shareBbtn.selected = NO ;
//            self.sharing = NO ;
//            self.localSharing = NO ;
        }];

//        if (myChange != YES) {
//            self.shareUuid = @"new";
//            self.shareBbtn.selected = YES ;
//            self.localSharing = YES ;
//            self.sharing = YES ;
//            self.sharingStuts = [self.sharingStuts isEqualToString:@"none"] ? @"local" : @"local_remote" ;
//        }


    } else {//self.shareUuid.length ? YES :
        [self.vcrtc shareImageData:data open:YES change: myChange success:^(id  _Nonnull response) {
            NSLog(@"分享成功：%@ -- ",response);
            //更新shareModel的相关状态
            self.shareModel.shareType = @"local";
            self.shareModel.isSharing = YES;
            self.shareModel.uuid = self.vcrtc.uuid;
            self.shareBtn.selected = YES ;
        } failure:^(NSError * _Nonnull error) {
            NSLog(@"分享失败：%@ -- ",error);
            if(self.shareBtn.selected == NO) return ;
            self.shareBtn.selected = NO ;
            self.shareModel.isSharing = NO ;
        }];
    }

}


//加载显示图片分享的View
- (void)loadPresentationView {
    dispatch_async(dispatch_get_main_queue(), ^{
        //点击分享视图显示或隐藏topView和bottomView
        UITapGestureRecognizer *tagSingle = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(clickAction:)];
        tagSingle.numberOfTapsRequired = 1 ;
        tagSingle.numberOfTouchesRequired = 1;
        [self.shareView addGestureRecognizer:tagSingle];
        self.shareView.userInteractionEnabled = YES ;
        [self.view insertSubview:self.shareView atIndex:2];
        [self.shareView loadShowImagesOrURLs:self.shareImages PhotoSourceType:self.photoType];
        //分享图片界面放置一个小视频 (根据自己的需求)
        [self updatePresentSmallView];
    });
}

//分享图片时的小视频
- (void)updatePresentSmallView {
    if (!self.farEndViewsArray.count) {
        return ;
    }
    if (self.shareModel.isSharing) {
        VideoViewModel *model ;
        if (self.farEndViewsArray.count == 0) {
            return ;
        } else if (self.farEndViewsArray.count == 1) {
            model = [self.farEndViewsArray firstObject] ;
        } else if (self.farEndViewsArray.count > 1) {
            //显示自己的小视频
            for (VideoViewModel *tempModel in self.farEndViewsArray) {
                if ([tempModel.uuid isEqualToString:self.vcrtc.uuid]) {
                    model = tempModel;
                }
            }
        }
        //查看当前这个视图上是否有小视频 如果有只是更改小视频的VCVideoView 如果没有再新建 (防止重复创建改视图)
        BOOL isContainSmallView = NO;
        for (UIView *view in self.shareView.subviews) {
            if ([view isKindOfClass:[SmallView class]]) {
                SmallView *smallView = (SmallView *)view;
                smallView.videoView = model.videoView;
                smallView.uuid = model.uuid;
                isContainSmallView = YES;
                return;
            }
        }
        if (!isContainSmallView) {
            SmallView *samllView = [SmallView loadSmallViewWithVideoView:model.videoView isTurnOffTheCamera:NO withParticipant:model.participant isBig:NO uuid:model.uuid];
            CGFloat viewWidth = (self.othersView.frame.size.width - 20)/5;
            //72 小视频的高度 viewWidth小视频的高度
            samllView.frame = CGRectMake(10, self.shareView.frame.size.height - 72, viewWidth, 72);
            [self.shareView addSubview:samllView];
        }
    }
}



//切换摄像头
- (IBAction)switchCameraAction:(id)sender {
    [self.vcrtc switchCamera];
}

//屏幕点击
- (IBAction)clickAction:(UIButton *)sender {
    self.topView.hidden = !self.topView.hidden;
    self.bottomView.hidden = !self.bottomView.hidden;
    [self setNeedsStatusBarAppearanceUpdate];
}


//开启关闭摄像头
- (IBAction)cameraHandleAction:(UIButton *)sender {
    sender.selected = !sender.selected;
    //YES开启摄像头 NO关闭摄像头
    [self.vcrtc videoEnable:!sender.selected];
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

//setNeedsStatusBarAppearanceUpdate 调用这个方法
- (BOOL )prefersStatusBarHidden {
    return self.topView.hidden ;
}

- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation {
    return UIStatusBarAnimationNone;
}



#pragma mark - tableViewDelegate & datasoruce

/** 质量统计数据处理 */
- (void)statisticsHandle:(NSArray<VCMediaStat *> *)mediaStats {
    self.statisticsArray = [NSMutableArray array];
    [self.statisticsArray addObject:@[@"",@"通道名称",@"编码格式",@"分辨率",@"帧率",@"码率",@"抖动",@"丢包率"]];
    
    for (VCMediaStat *stat in mediaStats) {
//        if ([stat.direction isEqualToString:@"recv"] && [stat.mediaType isEqualToString:@"video"]&& [stat.uuid isEqualToString:self.vcrtc.uuid]) {
//            continue;
//        }
        NSMutableArray *tempArray = [NSMutableArray array];
        NSString *display = @"";
        if ([self.vcrtc.rosterList.allKeys containsObject:stat.uuid]) {
            Participant *p = self.vcrtc.rosterList[stat.uuid];
            display = p.displayName ;
        }
        [tempArray addObject:([stat.direction isEqualToString:@"send"] ? @"本端" : ( display.length && stat.uuid != self.vcrtc.uuid ) ? display : @"远端")] ;
        [tempArray addObject:[NSString stringWithFormat:@"%@%@",([stat.mediaType isEqualToString:@"audio"] ? @"音频" : @"视频" ),([stat.direction isEqualToString:@"send"] ? @"发送" : @"接收")]];
        [tempArray addObject:stat.codec];
        [tempArray addObject:stat.resolution ? stat.resolution : @"--" ];
        [tempArray addObject:stat.frameRate ? [NSString stringWithFormat:@"%ld",(long)stat.frameRate] : @"--"];
        [tempArray addObject:[NSString stringWithFormat:@"%ld",(long)stat.bitrate]];
        [tempArray addObject:[NSString stringWithFormat:@"%.0fms",stat.jitter]];
        [tempArray addObject:[NSString stringWithFormat:@"%.1f%%",stat.percentageLost]];
        [self.statisticsArray addObject:tempArray];
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.table reloadData];
    });
    
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    return 95 ;
}


- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    ZJConferenceHeaderView *headerView = [[ZJConferenceHeaderView alloc]init];
    headerView.frame = CGRectMake(0, 0, self.table.frame.size.width, 95);
    headerView.titleArray = [self.statisticsArray firstObject];
    __weak typeof (self) weakSelf = self;
    headerView.block = ^{
        [weakSelf closeNetworkingView];
    };
    headerView.backgroundColor = [UIColor clearColor];
    return headerView;
    
}

- (void)closeNetworkingView {
    self.table.hidden = YES ;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.statisticsArray.count - 1 ;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ZJConferenceVCCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ZJConferenceVCCell"];
    cell.tableViewWidth = self.table.frame.size.width;
    cell.titleArray = self.statisticsArray[indexPath.row + 1];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 40 ;
}

#pragma mark - VCPresentionViewDelegate(分享图片, 远端屏幕共享)

//多张图片时切换图片
- (void)VCPresentionView:(VCPresentionView *)view changePage:(NSInteger )page  {
    self.photoType = YCPhotoSourceType_Image ;
    [self submitSharingImage:self.shareImages[page] change:YES];
}

//图片缩放
- (void)VCPresentionView:(VCPresentionView *)view zoomEndImage:(UIImage *)image {
    [self submitSharingImage:image change:YES];
}
//图片加载失败
- (void)VCPresentionView:(VCPresentionView *)view loadImageUrlFaild:(NSString *)urlStr PhotoSourceType:(YCPhotoSourceType)sourceType {
    if ([urlStr isEqualToString:self.vcrtc.shareImageURL]) {
        NSLog(@"加载Image URl %@ faild ", urlStr);
    } else {
        NSLog(@"加载Image URl %@ reload ", self.vcrtc.shareImageURL);
        [view loadShowImagesOrURLs:@[self.vcrtc.shareImageURL] PhotoSourceType:sourceType];
    }
}



@end
