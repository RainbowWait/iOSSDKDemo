//
//  ViewController.h
//  iOSDemo
//
//  Created by mac on 2019/6/26.
//  Copyright © 2019 mac. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ExampleVC : UIViewController
/** 服务器地址 */
@property (nonatomic, copy) NSString *serverString;
/** 会议室号 */
@property (nonatomic, copy) NSString *meetingNumString;
/** 参会密码 */
@property (nonatomic, copy) NSString *passwordString;

@end

