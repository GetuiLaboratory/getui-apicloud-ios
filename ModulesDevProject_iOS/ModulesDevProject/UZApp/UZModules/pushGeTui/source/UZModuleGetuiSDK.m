

#import "UZModuleGetuiSDK.h"
#import "NSDictionaryUtils.h"
#import "UZAppDelegate.h"
#import "UZAppUtils.h"
#import <UserNotifications/UserNotifications.h>

typedef enum {
    SetTags,
    BindAlias,
    UnBindAlias,
    RegiserDeviceToken
}commonApiType;
@implementation UZModuleGetuiSDK

//@synthesize getuiPusher = _getuiPusher;
@synthesize appKey = _appKey;
@synthesize appSecret = _appSecret;
@synthesize appID = _appID;
@synthesize clientId = _clientId;
//@synthesize sdkStatus = _sdkStatus;
@synthesize lastPayloadIndex = _lastPaylodIndex;
@synthesize payloadId = _payloadId;

//@synthesize cbIdCid = _cbIdCid;
//@synthesize cbIdPayload = _cbIdPayload;

+ (void)launch {
    //在module.json里面配置的launchClassMethod，必须为类方法，引擎会在应用启动时调用配置的方法，模块可以在其中做一些初始化操作
}

- (id)initWithUZWebView:(UZWebView *)webView_ {
    if (self = [super initWithUZWebView:webView_]) {
        [theApp addAppHandle:self];
    }
    return self;
}

- (void)dispose {
    //do clean
//    if(_getuiPusher){
//        [_getuiPusher destroy];
//        _sdkStatus=SdkStatusStoped;
//        //cbId=-1;
//    }
    
    [GeTuiSdk destroy];
    
    [theApp removeAppHandle:self];
}

#pragma mark - property
- (SdkStatus)sdkStatus
{
    return [GeTuiSdk status];
}
#pragma mark - private method
//获取js层的回调函数cbId
-(NSInteger) fetchCbId:(NSDictionary *)paramDict{
    return [paramDict integerValueForKey:@"cbId" defaultValue:-1];
}
//通用的api接口处理 回调bool结果
-(void)commonApiWithBool:(commonApiType)t cbId:(NSDictionary *)paramDict{
    NSInteger cbIdTmp=[self fetchCbId:paramDict];
    NSInteger result=0;
        @try {
            switch (t){
                case SetTags:{
                    NSString *arrayTagsStr=[paramDict stringValueForKey:@"tags" defaultValue:nil];
                    if (arrayTagsStr!=nil) {
                        NSArray *arrayTags=[arrayTagsStr componentsSeparatedByString:@","];
                        result=[GeTuiSdk setTags:arrayTags];
                    }
                }
                    break;
                case BindAlias:{
                    NSString *alias=[paramDict stringValueForKey:@"alias" defaultValue:nil];
                    if (alias!=nil) {
                        [GeTuiSdk bindAlias:alias andSequenceNum:@"sn"];
                        result=1;
                    }
                }
                    break;
                case UnBindAlias:{
                    NSString *alias=[paramDict stringValueForKey:@"alias" defaultValue:nil];
                    if (alias!=nil) {
                        [GeTuiSdk unbindAlias:alias andSequenceNum:@"sn"];
                        result=1;
                    }
                }
                    break;
                case RegiserDeviceToken:{
                    NSString *token=[paramDict stringValueForKey:@"deviceToken" defaultValue:nil];
                    if (token!=nil || !_deviceToken) {
                        [GeTuiSdk registerDeviceToken:token?token:_deviceToken];
                        result=1;
                    }
                }
                    break;
            }
        }
        @catch (NSException *exception) {
            NSLog(@"%@",[exception description]);
        }
    NSDictionary *ret=[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInteger:result],@"result",nil];
    if (cbIdTmp>-1) {
        [self sendResultEventWithCallbackId:cbIdTmp dataDict:ret errDict:nil doDelete:YES];
    }
}
// 模块接口定义
- (void)initialize:(NSDictionary*)paramDict{
        NSDictionary *feature=[self getFeatureByName:@"pushGeTui"];
        self.appID=[feature stringValueForKey:@"ios_appid" defaultValue:nil];
        self.appKey=[feature stringValueForKey:@"ios_appkey" defaultValue:nil];
        self.appSecret=[feature stringValueForKey:@"ios_appsecret" defaultValue:nil];
        _clientId = nil;
        cbId= [self fetchCbId:paramDict];
        [GeTuiSdk startSdkWithAppId:_appID appKey:_appKey appSecret:_appSecret delegate:self];
        self.isPushTurnOn = YES;
    [self registerRemoteNotification];
}

-(void)registerDeviceToken:(NSDictionary *)paramDict {
    [self commonApiWithBool:RegiserDeviceToken cbId:paramDict];
}

-(void)setTag:(NSDictionary *)paramDict{
    [self commonApiWithBool:SetTags cbId:paramDict];
}

-(void)bindAlias:(NSDictionary *)paramDict{
    [self commonApiWithBool:BindAlias cbId:paramDict];
}

-(void)unBindAlias:(NSDictionary *)paramDict{
    [self commonApiWithBool:UnBindAlias cbId:paramDict];
}
-(void)fetchClientId:(NSDictionary *)paramDict{
    NSInteger cbIdTmp=[self fetchCbId:paramDict];
    NSInteger result=0;
    if(self.sdkStatus==SdkStatusStarted)
    {
        result=1;
    }
    NSDictionary *ret=[NSDictionary dictionaryWithObjectsAndKeys:[GeTuiSdk clientId],@"cid",
                       [NSNumber numberWithInteger:result],@"result",
                       nil];
    if(cbIdTmp>-1){
        [self sendResultEventWithCallbackId:cbIdTmp dataDict:ret errDict:nil doDelete:YES];
    }
}
-(void)getVersion:(NSDictionary *)paramDict{
    NSInteger cbIdTmp=[self fetchCbId:paramDict];
    if(cbIdTmp>-1)
    {
        NSDictionary *ret=[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInteger:1],@"result",
                           [GeTuiSdk version],@"version",
                           nil];
        [self sendResultEventWithCallbackId:cbIdTmp dataDict:ret errDict:nil doDelete:YES];
    }
}
-(void)sendMessage:(NSDictionary *)paramDict{
    NSInteger cbIdTmp=[self fetchCbId:paramDict];
    if(cbIdTmp>-1)
    {
        NSString *sendStr = [paramDict stringValueForKey:@"extraData" defaultValue:nil];
        NSData *sendData = [sendStr dataUsingEncoding:NSUTF8StringEncoding];
        NSError *error = nil;
        [GeTuiSdk sendMessage:sendData error:&error];
        NSInteger result = 1;
        NSString *errorMsg = nil;
        
        NSDictionary *ret=[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInteger:result],@"result",nil];
        if (error) {
            result = 0;
            errorMsg = error.description;
            ret=[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInteger:result],@"result",errorMsg,@"msg",0,@"code",nil];
        }
        [self sendResultEventWithCallbackId:cbIdTmp dataDict:ret errDict:nil doDelete:YES];
    }
    
    //NSArray *sendArray=[paramDict arrayValueForKey:@"sendArray" defaultValue:nil];
    //    NSData *sendData=[NSKeyedArchiver archivedDataWithRootObject:sendArray];
    //NSString *sendStr=[paramDict stringValueForKey:@"extraData"  defaultValue:nil];
    //NSData *sendData=[sendStr dataUsingEncoding:NSUTF8StringEncoding];
    //NSError *error=nil;
    //NSString *messageId=[_gexinPusher sendMessage:sendData error:&error];
    
    //if(cbId>-1&&error!=nil){
     //   NSDictionary *ret=[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInteger:0],@"result",
    //                       messageId,@"messageId",
     //                      @"sendMsgFeedback",@"type", nil];
     //   [self sendResultEventWithCallbackId:cbId dataDict:ret errDict:nil doDelete:YES];
   // }
}
//暂时不支持接口result都返回-100
-(void)stopService:(NSDictionary *)paramDict{
    NSInteger cbIdTmp=[self fetchCbId:paramDict];
    if(cbIdTmp>-1)
    {
       NSDictionary *ret=[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInteger:-100],@"result",nil];
      [self sendResultEventWithCallbackId:cbIdTmp dataDict:ret errDict:nil doDelete:YES];
    }
}
-(void)sendFeedbackMessage:(NSDictionary *)paramDict{
    NSInteger cbIdTmp=[self fetchCbId:paramDict];
    
    if(cbIdTmp>-1)
    {
        NSInteger actionId = [paramDict integerValueForKey:@"actionid" defaultValue:0];
        NSString *taskId = [paramDict stringValueForKey:@"taskid" defaultValue:nil];
        NSString *messageId = [paramDict stringValueForKey:@"messageid" defaultValue:nil];
        NSInteger result = 0;
        if ([GeTuiSdk sendFeedbackMessage:actionId andTaskId:taskId andMsgId:messageId]) {
            result = 1;
        }
        NSDictionary *ret=[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInteger:result],@"result",nil];
        [self sendResultEventWithCallbackId:cbIdTmp dataDict:ret errDict:nil doDelete:YES];
    }
}
-(void)turnOnPush:(NSDictionary *)paramDict{
    NSInteger cbIdTmp=[self fetchCbId:paramDict];
    if(cbIdTmp>-1)
    {
        [GeTuiSdk setPushModeForOff:NO];
        self.isPushTurnOn = YES;
        NSDictionary *ret=[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInteger:1],@"result",nil];
        [self sendResultEventWithCallbackId:cbIdTmp dataDict:ret errDict:nil doDelete:YES];
    }
}
-(void)turnOffPush:(NSDictionary *)paramDict{
    NSInteger cbIdTmp=[self fetchCbId:paramDict];
    if(cbIdTmp>-1)
    {
        [GeTuiSdk setPushModeForOff:YES];
        self.isPushTurnOn = NO;
        NSDictionary *ret=[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInteger:1],@"result",nil];
        [self sendResultEventWithCallbackId:cbIdTmp dataDict:ret errDict:nil doDelete:YES];
    }
}
-(void)isPushTurnedOn:(NSDictionary *)paramDict{
    NSInteger cbIdTmp=[self fetchCbId:paramDict];
    if(cbIdTmp>-1)
    {
        NSString *isOn = @"false";
        if (self.isPushTurnOn) {
            isOn = @"true";
        }
        NSDictionary *ret=[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInteger:1],@"result",isOn,@"isOn",nil];
        [self sendResultEventWithCallbackId:cbIdTmp dataDict:ret errDict:nil doDelete:YES];
    }
}
-(void)setSilentTime:(NSDictionary *)paramDict{
    NSInteger cbIdTmp=[self fetchCbId:paramDict];
    if(cbIdTmp>-1)
    {
        NSDictionary *ret=[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInteger:-100],@"result",nil];
        [self sendResultEventWithCallbackId:cbIdTmp dataDict:ret errDict:nil doDelete:YES];
    }
}
-(void)payloadMessage:(NSDictionary *)paramDict{
    NSInteger cbIdTmp=[self fetchCbId:paramDict];
    if(cbIdTmp>-1)
    {
        NSDictionary *ret=[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInteger:-100],@"result",nil];
        [self sendResultEventWithCallbackId:cbIdTmp dataDict:ret errDict:nil doDelete:YES];
    }
}

// 个推sdk接口回调
#pragma mark - GexinSdkDelegate
- (void)GeTuiSdkDidRegisterClient:(NSString *)clientId{
    self.clientId=clientId;
    if (cbId>-1) {
        NSDictionary *ret = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithInteger:1], @"result",
                             @"cid",@"type",
                             clientId, @"cid", nil];
        [self sendResultEventWithCallbackId:cbId dataDict:ret errDict:nil doDelete:NO];
    }
}
-(void)GeTuiSdkDidReceivePayloadData:(NSData *)payloadData andTaskId:(NSString *)taskId andMsgId:(NSString *)msgId andOffLine:(BOOL)offLine fromGtAppId:(NSString *)appId
{

    
    NSString *payloadMsg = nil;
    if (payloadData) {
        payloadMsg = [[NSString alloc] initWithData:payloadData encoding:NSUTF8StringEncoding];
    }
    if (cbId>-1) {
        NSDictionary *ret = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithInteger:1], @"result",
                             @"payload",@"type",
                             taskId, @"taskId",
                             msgId, @"messageId",
                             payloadMsg, @"payload", nil];
        [self sendResultEventWithCallbackId:cbId dataDict:ret errDict:nil doDelete:NO];
    }
}

- (void)GeTuiSdkDidSendMessage:(NSString *)messageId result:(int)result {
    // [4-EXT]:发送上行消息结果反馈
    //NSString *record = [NSString stringWithFormat:@"Received sendmessage:%@ result:%d", messageId, result];
    if(cbId>-1){
        NSDictionary *ret=[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:result],@"result",
                           messageId,@"messageId",
                           @"sendMsgFeedback",@"type", nil];
        [self sendResultEventWithCallbackId:cbId dataDict:ret errDict:nil doDelete:NO];
    }
}

- (void)GeTuiSdkDidOccurError:(NSError *)error {
    // [EXT]:个推错误报告，集成步骤发生的任何错误都在这里通知，如果集成后，无法正常收到消息，查看这里的通知。
    //[_viewController logMsg:[NSString stringWithFormat:@">>>[GexinSdk error]:%@", [error localizedDescription]]];
    if (cbId>-1) {
        NSDictionary *ret=[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInteger:error.code],@"code",
                           [error localizedDescription],@"description",
                           @"occurError",@"type",nil];
        [self sendResultEventWithCallbackId:cbId dataDict:ret errDict:nil doDelete:NO];
    }
}
#pragma mark - 用户通知(推送) _自定义方法

/** 注册远程通知 */
- (void)registerRemoteNotification {
    /*
     警告：Xcode8的需要手动开启“TARGETS -> Capabilities -> Push Notifications”
     */
    
    /*
     警告：该方法需要开发者自定义，以下代码根据APP支持的iOS系统不同，代码可以对应修改。
     以下为演示代码，注意根据实际需要修改，注意测试支持的iOS系统都能获取到DeviceToken
     */
    if ([[UIDevice currentDevice].systemVersion floatValue] >= 10.0) {
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_10_0 // Xcode 8编译会调用
        UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
        center.delegate = self;
        [center requestAuthorizationWithOptions:(UNAuthorizationOptionBadge | UNAuthorizationOptionSound | UNAuthorizationOptionAlert | UNAuthorizationOptionCarPlay) completionHandler:^(BOOL granted, NSError *_Nullable error) {
            if (!error) {
                NSLog(@"request authorization succeeded!");
            }
        }];
        
        [[UIApplication sharedApplication] registerForRemoteNotifications];
#else // Xcode 7编译会调用
        UIUserNotificationType types = (UIUserNotificationTypeAlert | UIUserNotificationTypeSound | UIUserNotificationTypeBadge);
        UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:types categories:nil];
        [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
        [[UIApplication sharedApplication] registerForRemoteNotifications];
#endif
    } else if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0) {
        UIUserNotificationType types = (UIUserNotificationTypeAlert | UIUserNotificationTypeSound | UIUserNotificationTypeBadge);
        UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:types categories:nil];
        [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
        [[UIApplication sharedApplication] registerForRemoteNotifications];
    } else {
        UIRemoteNotificationType apn_type = (UIRemoteNotificationType)(UIRemoteNotificationTypeAlert |
                                                                       UIRemoteNotificationTypeSound |
                                                                       UIRemoteNotificationTypeBadge);
        [[UIApplication sharedApplication] registerForRemoteNotificationTypes:apn_type];
    }
}
#pragma mark - iOS 10中收到推送消息

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_10_0
//  iOS 10: App在前台获取到通知
- (void)userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions))completionHandler {
    
    NSLog(@"willPresentNotification：%@", notification.request.content.userInfo);
    
    // 根据APP需要，判断是否要提示用户Badge、Sound、Alert
    completionHandler(UNNotificationPresentationOptionBadge | UNNotificationPresentationOptionSound | UNNotificationPresentationOptionAlert);
}

//  iOS 10: 点击通知进入App时触发
- (void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void (^)())completionHandler {
    
    NSLog(@"didReceiveNotification：%@", response.notification.request.content.userInfo);
    
    // [ GTSdk ]：将收到的APNs信息传给个推统计
    [GeTuiSdk handleRemoteNotification:response.notification.request.content.userInfo];
    if (cbId>-1) {
        NSDictionary *ret = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithInteger:1], @"result",
                             @"apns",@"type",
                             response.notification.request.content.userInfo, @"msg", nil];
        [self sendResultEventWithCallbackId:cbId dataDict:ret errDict:nil doDelete:NO];
    }
    completionHandler();
}
#endif
#pragma mark - APP运行中接收到通知(推送)处理 - iOS 10以下版本收到推送

/** APP已经接收到“远程”通知(推送) - (App运行在后台/App运行在前台)  */
- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult result))completionHandler {
    
    // [ GTSdk ]：将收到的APNs信息传给个推统计
    [GeTuiSdk handleRemoteNotification:userInfo];
    
    // 显示APNs信息到页面
//    NSString *record = [NSString stringWithFormat:@"[APN]%@, %@", [NSDate date], userInfo];
    if (cbId>-1) {
        NSDictionary *ret = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithInteger:1], @"result",
                             @"apns",@"type",
                             userInfo, @"msg", nil];
        [self sendResultEventWithCallbackId:cbId dataDict:ret errDict:nil doDelete:NO];
    }
    completionHandler(UIBackgroundFetchResultNewData);
}


#pragma mark - 注册DeviceToken
#pragma mark - 远程通知(推送)回调--注册DeviceToken

/** 远程通知注册成功委托 */
- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    NSString *token = [[deviceToken description] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]];
    token = [token stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSLog(@"\n>>>[DeviceToken Success]:%@\n\n", token);
    
    // [3]:向个推服务器注册deviceToken
    _deviceToken = token;
    [GeTuiSdk registerDeviceToken:token];
}

/** 远程通知注册失败委托 */
- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    NSLog(@"register device Token Fail %@",[NSString stringWithFormat:@"didFailToRegisterForRemoteNotificationsWithError:%@", [error localizedDescription]]);
}

@end