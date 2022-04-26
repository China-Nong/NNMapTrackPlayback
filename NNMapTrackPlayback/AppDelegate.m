//
//  AppDelegate.m
//  NNMapTrackPlayback
//
//  Created by 微克iOS on 2022/4/24.
//

#import "AppDelegate.h"

@import AMapFoundationKit;
@import MAMapKit;
@import AMapSearchKit;

static NSString *APIKey = @""; /// 高德地图key

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    [self configureAPIKey];
    
    //判断是否是首次启动
    if(![[NSUserDefaults standardUserDefaults] boolForKey:@"agreeStatus"]){
        //添加隐私合规弹窗
        [self addAlertController];
        //更新App是否显示隐私弹窗的状态，隐私弹窗是否包含高德SDK隐私协议内容的状态. since 8.1.0
        [MAMapView updatePrivacyShow:AMapPrivacyShowStatusDidShow privacyInfo:AMapPrivacyInfoStatusDidContain];
    }
    
    return YES;
}

- (void)configureAPIKey
{
    if ([APIKey length] == 0)
    {
        NSString *reason = [NSString stringWithFormat:@"apiKey为空，请检查key是否正确设置。"];
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"提示" message:reason delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        
        [alert show];
    }
    
    [AMapServices sharedServices].apiKey = (NSString *)APIKey;
}

- (void)addAlertController{
//    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
//
//    paragraphStyle.alignment = NSTextAlignmentLeft;
//
//    NSMutableAttributedString *message = [[NSMutableAttributedString alloc] initWithString:@"\n亲，感谢您对XXX一直以来的信任！我们依据最新的监管要求更新了XXX《隐私权政策》，特向您说明如下\n1.为向您提供交易相关基本功能，我们会收集、使用必要的信息；\n2.基于您的明示授权，我们可能会获取您的位置（为您提供附近的商品、店铺及优惠资讯等）等信息，您有权拒绝或取消授权；\n3.我们会采取业界先进的安全措施保护您的信息安全；\n4.未经您同意，我们不会从第三方处获取、共享或向提供您的信息；" attributes:@{
//        NSParagraphStyleAttributeName:paragraphStyle,
//    }];
//
//    [message setAttributes:@{NSForegroundColorAttributeName:[UIColor blueColor]} range:[[message string] rangeOfString:@"《隐私权政策》"]];
//
//    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"温馨提示(隐私合规示例)" message:@"" preferredStyle:UIAlertControllerStyleAlert];
//
//    [alert setValue:message forKey:@"attributedMessage"];
//
//    UIAlertAction *conform = [UIAlertAction actionWithTitle:@"同意" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
//        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"agreeStatus"];
//        [[NSUserDefaults standardUserDefaults] synchronize];
        //更新用户授权高德SDK隐私协议状态. since 8.1.0
        [MAMapView updatePrivacyAgree:AMapPrivacyAgreeStatusDidAgree];
//    }];
//
//    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"不同意" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
//        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"agreeStatus"];
//        [[NSUserDefaults standardUserDefaults] synchronize];
//        //更新用户授权高德SDK隐私协议状态. since 8.1.0
//        [MAMapView updatePrivacyAgree:AMapPrivacyAgreeStatusNotAgree];
//    }];

//    [alert addAction:conform];
//    [alert addAction:cancel];
//
//    [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:alert animated:YES completion:nil];
}



#pragma mark - UISceneSession lifecycle


- (UISceneConfiguration *)application:(UIApplication *)application configurationForConnectingSceneSession:(UISceneSession *)connectingSceneSession options:(UISceneConnectionOptions *)options {
    // Called when a new scene session is being created.
    // Use this method to select a configuration to create the new scene with.
    return [[UISceneConfiguration alloc] initWithName:@"Default Configuration" sessionRole:connectingSceneSession.role];
}


- (void)application:(UIApplication *)application didDiscardSceneSessions:(NSSet<UISceneSession *> *)sceneSessions {
    // Called when the user discards a scene session.
    // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
    // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
}


@end
