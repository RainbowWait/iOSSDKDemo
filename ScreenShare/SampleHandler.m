//
//  SampleHandler.m
//  ScreenShare
//
//  Created by mac on 2019/6/28.
//  Copyright © 2019 mac. All rights reserved.
//


#import "SampleHandler.h"//group.com.zijingcloud.phone
#import <ZJRTCScreenShare/ZJRTCScreenShare.h>

@interface SampleHandler ()
@property (nonatomic, strong) ScreenHelper *screenHelper;
@end

@implementation SampleHandler

- (void)broadcastStartedWithSetupInfo:(NSDictionary<NSString *,NSObject *> *)setupInfo {
    // User has requested to start the broadcast. Setup info from the UI extension can be supplied but optional.
    self.screenHelper = [ScreenHelper sharedInstance];
    //1.配置GroupId
    self.screenHelper.groupId = @"填写在apple develope创建的group id" ;
    //2. 链接到分享
    [self.screenHelper connect];
}

- (void)broadcastPaused {
    // User has requested to pause the broadcast. Samples will stop being delivered.
}

- (void)broadcastResumed {
    // User has requested to resume the broadcast. Samples delivery will resume.
}

- (void)broadcastFinished {
    // User has requested to finish the broadcast.
}

- (void)processSampleBuffer:(CMSampleBufferRef)sampleBuffer withType:(RPSampleBufferType)sampleBufferType {
    
    switch (sampleBufferType) {
        case RPSampleBufferTypeVideo:
            // Handle video sample buffer
            //3.更新录制屏幕的数据流
            [self.screenHelper didCaptureSampleBuffer:sampleBuffer];
            break;
        case RPSampleBufferTypeAudioApp:
            // Handle audio sample buffer for app audio
            break;
        case RPSampleBufferTypeAudioMic:
            // Handle audio sample buffer for mic audio
            break;
            
        default:
            break;
    }
}

@end
