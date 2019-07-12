/*
 *  Copyright 2018 The WebRTC Project Authors. All rights reserved.
 *
 *  Use of this source code is governed by a BSD-style license
 *  that can be found in the LICENSE file in the root of the source
 *  tree. An additional intellectual property rights grant can be found
 *  in the file PATENTS.  All contributing project authors may
 *  be found in the AUTHORS file in the root of the source tree.
 */

#import "ARDExternalSampleCapturer.h"

#import <WebRTC/RTCCVPixelBuffer.h>
#import <WebRTC/RTCVideoFrameBuffer.h>
#import <ReplayKit/ReplayKit.h>
@interface ARDExternalSampleCapturer()
@end
@implementation ARDExternalSampleCapturer

- (instancetype)initWithDelegate:(__weak id<RTCVideoCapturerDelegate>)delegate {
  return [super initWithDelegate:delegate];
}

#pragma mark - ARDExternalSampleDelegate

- (void)didCaptureSampleBuffer:(CMSampleBufferRef)sampleBuffer {
    @autoreleasepool {

      if (CMSampleBufferGetNumSamples(sampleBuffer) != 1 || !CMSampleBufferIsValid(sampleBuffer) ||
          !CMSampleBufferDataIsReady(sampleBuffer)) {
        return;
      }

      CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
      if (pixelBuffer == nil) {
        return;
      }

      RTCVideoRotation rotation = [self orientationFromSamperBuffer:sampleBuffer];

      RTCCVPixelBuffer *rtcPixelBuffer = [[RTCCVPixelBuffer alloc] initWithPixelBuffer:pixelBuffer];
      int64_t timeStampNs =
          CMTimeGetSeconds(CMSampleBufferGetPresentationTimeStamp(sampleBuffer)) * NSEC_PER_SEC;
      RTCVideoFrame *videoFrame = [[RTCVideoFrame alloc] initWithBuffer:rtcPixelBuffer
                                                               rotation:rotation
                                                            timeStampNs:timeStampNs];
      [self.delegate capturer:self didCaptureVideoFrame:videoFrame];
    }
}

- (NSInteger)orientationFromSamperBuffer:(CMSampleBufferRef)sampleBuffer{
  CFStringRef RPVideoSampleOrientationKeyRef = (__bridge CFStringRef)RPVideoSampleOrientationKey;
  NSNumber *orientation = (NSNumber *)CMGetAttachment(sampleBuffer, RPVideoSampleOrientationKeyRef,NULL);
  switch ([orientation integerValue]){
    //竖屏时候
    //SDK内部会做图像大小自适配(不会变形) 所以上层只要控制横屏时候的影像旋转的问题
    case kCGImagePropertyOrientationUp:{
      return RTCVideoRotation_0;
    }
    case kCGImagePropertyOrientationDown:{
      return RTCVideoRotation_180;
    }
    case kCGImagePropertyOrientationLeft: {
      //静音键那边向上 所需转90度
      return RTCVideoRotation_90;
    }
          break;
    case kCGImagePropertyOrientationRight:{
      //关机键那边向上 所需转270
      return RTCVideoRotation_270;
    }
    default:
      return RTCVideoRotation_0;
  }
}

@end
