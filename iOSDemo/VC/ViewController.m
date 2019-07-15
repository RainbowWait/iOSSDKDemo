//
//  ViewController.m
//  iOSDemo
//
//  Created by mac on 2019/7/8.
//  Copyright © 2019 mac. All rights reserved.
//

#import "ViewController.h"
#import "ExampleVC.h"

@interface ViewController ()
/** 服务器地址 */
@property (weak, nonatomic) IBOutlet UITextField *severField;
/** 会议室号 */
@property (weak, nonatomic) IBOutlet UITextField *meetingNumField;
/** 参会密码 */
@property (weak, nonatomic) IBOutlet UITextField *joinPwdField;
//是否是多流
@property (weak, nonatomic) IBOutlet UISwitch *multistreamSwitch;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.severField.text = [[NSUserDefaults standardUserDefaults]objectForKey:@"serverAddress"];
        self.meetingNumField.text = [[NSUserDefaults standardUserDefaults]objectForKey:@"meetingNumber"];
        self.joinPwdField.text = [[NSUserDefaults standardUserDefaults]objectForKey:@"joinPassword"];
}
- (IBAction)jumpAction:(UIButton *)sender {
    if (self.severField.text.length < 1) {
        NSLog(@"请输入服务器地址");
        return;
    }
    if (self.meetingNumField.text.length < 1) {
        NSLog(@"请输入会议室号");
        return;
    }
    [[NSUserDefaults standardUserDefaults]setObject:self.severField.text forKey:@"serverAddress"];
    [[NSUserDefaults standardUserDefaults]setObject:self.meetingNumField.text forKey:@"meetingNumber"];
    [[NSUserDefaults standardUserDefaults]setObject:self.joinPwdField.text forKey:@"joinPassword"];
    ExampleVC *vc = [ExampleVC new];
    vc.serverString = self.severField.text;
    vc.meetingNumString = self.meetingNumField.text;
    vc.passwordString = self.joinPwdField.text;
    vc.isMultistream = self.multistreamSwitch.on;
    [self.navigationController presentViewController:vc animated:YES completion:nil];
}


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
