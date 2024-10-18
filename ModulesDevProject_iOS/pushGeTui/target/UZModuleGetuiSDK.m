

#import "NSDictionaryUtils.h"
#import "UZAppDelegate.h"
#import "UZAppUtils.h"
#import "UZModuleGetuiSDK.h"
#import <UserNotifications/UserNotifications.h>
#import "GeTuiSdk.h"
#import <PushKit/PushKit.h>

typedef enum {
    SetTags,
    BindAlias,
    UnBindAlias,
    RegiserDeviceToken,
    SetBadge,
    SetChannelId,
} commonApiType;

@interface UZModuleGetuiSDK ()<GeTuiSdkDelegate, PKPushRegistryDelegate, UIApplicationDelegate>
{
    NSInteger cbId;
    NSInteger voipCBId;
}

@property (copy, nonatomic) NSString *appKey;
@property (copy, nonatomic) NSString *appSecret;
@property (copy, nonatomic) NSString *appID;
@property (copy, nonatomic) NSString *clientId;
@property (assign, nonatomic) SdkStatus sdkStatus;
@property (nonatomic,copy) NSString *deviceToken;

@property (assign, nonatomic) int lastPayloadIndex;
@property (copy, nonatomic) NSString *payloadId;
@property (assign, nonatomic) BOOL isPushTurnOn;
@property (assign, nonatomic) BOOL isBackgroundEnable;
@property (assign, nonatomic) BOOL islbsLocationEnable;
@property (assign, nonatomic) BOOL activeShowNotification;
@property (nullable, class, nonatomic) NSDictionary *launchOptions;

@end

@implementation UZModuleGetuiSDK

@synthesize appKey = _appKey;
@synthesize appSecret = _appSecret;
@synthesize appID = _appID;
@synthesize clientId = _clientId;
@synthesize lastPayloadIndex = _lastPaylodIndex;
@synthesize payloadId = _payloadId;

+ (void)onAppLaunch:(NSDictionary *)launchOptions {
    // 方法在应用启动时被调用
    self.launchOptions = launchOptions;
}

- (id)initWithUZWebView:(UZWebView *)webView_ {
    if (self = [super initWithUZWebView:webView_]) {
        [theApp addAppHandle:self];
    }
    return self;
}

- (void)dispose {
    [GeTuiSdk destroy];
    
    [theApp removeAppHandle:self];
}

#pragma mark - property

- (SdkStatus)sdkStatus {
    NSLog(@"GTSDK>>>sdkStatus");
    return [GeTuiSdk status];
}

static NSDictionary *_gtStaticLaunchOptions;
+ (NSDictionary *)launchOptions
{
    return _gtStaticLaunchOptions;
}

+ (void)setLaunchOptions:(NSDictionary *)launchOptions
{
    _gtStaticLaunchOptions = launchOptions;
}

#pragma mark - private method

//获取js层的回调函数cbId
- (NSInteger)fetchCbId:(NSDictionary *)paramDict {
    return [paramDict integerValueForKey:@"cbId" defaultValue:-1];
}

//通用的api接口处理 回调bool结果
- (void)commonApiWithBool:(commonApiType)t cbId:(NSDictionary *)paramDict {
    NSInteger cbIdTmp = [self fetchCbId:paramDict];
    NSInteger result = 0;
    @try {
        switch (t) {
            case SetTags: {
                NSString *arrayTagsStr = [paramDict stringValueForKey:@"tags" defaultValue:nil];
                if (arrayTagsStr != nil) {
                    NSArray *arrayTags = [arrayTagsStr componentsSeparatedByString:@","];
                    NSLog(@"GTSDK>>>setTags %@", arrayTags);
                    result = [GeTuiSdk setTags:arrayTags];
                }
            } break;
            case BindAlias: {
                NSString *alias = [paramDict stringValueForKey:@"alias" defaultValue:nil];
                if (alias != nil) {
                    NSLog(@"GTSDK>>>bindAlias %@", alias);
                    [GeTuiSdk bindAlias:alias andSequenceNum:@"sn"];
                    result = 1;
                }
            } break;
            case UnBindAlias: {
                NSString *alias = [paramDict stringValueForKey:@"alias" defaultValue:nil];
                if (alias != nil) {
                    NSLog(@"GTSDK>>>unbindAlias %@", alias);
                    [GeTuiSdk unbindAlias:alias andSequenceNum:@"sn" andIsSelf:YES];
                    result = 1;
                }
            } break;
            case RegiserDeviceToken: {
                NSString *token = [paramDict stringValueForKey:@"deviceToken" defaultValue:nil];
                if (token != nil || !_deviceToken) {
                    NSLog(@"GTSDK>>>registerDeviceToken %@", token ? token : _deviceToken);
                    // 2.5.2.0 之前版本需要调用： 现版本自动注册
                    [GeTuiSdk registerDeviceToken:token ? token : _deviceToken];
                    result = 1;
                }
            } break;
            case SetBadge: {
                NSInteger badge = [paramDict integerValueForKey:@"badge" defaultValue:0];
                NSLog(@"GTSDK>>>setBadge %@", @(badge));
                [GeTuiSdk setBadge:badge];
                result = 1;
            } break;
            case SetChannelId: {
                NSString *channelId = [paramDict stringValueForKey:@"channelId" defaultValue:nil];
                if (channelId != nil) {
                    NSLog(@"GTSDK>>>setChannelId %@", channelId);
                    [GeTuiSdk setChannelId:channelId];
                    result = 1;
                }
            } break;;
        }
    }
    @catch (NSException *exception) {
        NSLog(@"%@", [exception description]);
    }
    
    NSDictionary *ret = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInteger:result], @"result", nil];
    if (cbIdTmp > -1) {
        [self sendResultEventWithCallbackId:cbIdTmp dataDict:ret errDict:nil doDelete:YES];
    }
}

// 模块接口定义
- (void)initialize:(NSDictionary *)paramDict {
    NSLog(@"GTSDK>>>startsdk");
    NSDictionary *feature = [self getFeatureByName:@"pushGeTui"];
    self.appID = [feature stringValueForKey:@"ios_appid" defaultValue:nil];
    self.appKey = [feature stringValueForKey:@"ios_appkey" defaultValue:nil];
    self.appSecret = [feature stringValueForKey:@"ios_appsecret" defaultValue:nil];
    self.activeShowNotification = [feature stringValueForKey:@"active_show_notification" defaultValue:@"0"].boolValue;
    _clientId = nil;
    cbId = [self fetchCbId:paramDict];

    [GeTuiSdk startSdkWithAppId:_appID appKey:_appKey appSecret:_appSecret delegate:self launchingOptions:self.class.launchOptions];
    self.class.launchOptions = nil;
    self.isPushTurnOn = YES;
    self.isBackgroundEnable = NO;
    self.islbsLocationEnable = NO;
    [self registerRemoteNotification];
}

/** 注册远程通知 */
- (void)registerRemoteNotification {
    NSLog(@"GTSDK>>>registerRemoteNotification");
    // [ 参考代码，开发者注意根据实际需求自行修改 ] 注册远程通知
    [GeTuiSdk registerRemoteNotification: (UNAuthorizationOptionSound | UNAuthorizationOptionAlert | UNAuthorizationOptionBadge)];
}

- (void)setTag:(NSDictionary *)paramDict {
    [self commonApiWithBool:SetTags cbId:paramDict];
}

- (void)setBadge:(NSDictionary *)paramDict {
    [self commonApiWithBool:SetBadge cbId:paramDict];
}

- (void)bindAlias:(NSDictionary *)paramDict {
    [self commonApiWithBool:BindAlias cbId:paramDict];
}

- (void)unBindAlias:(NSDictionary *)paramDict {
    [self commonApiWithBool:UnBindAlias cbId:paramDict];
}

- (void)setChannelId:(NSDictionary *)paramDict {
    [self commonApiWithBool:SetChannelId cbId:paramDict];
}

- (void)fetchClientId:(NSDictionary *)paramDict {
    NSInteger cbIdTmp = [self fetchCbId:paramDict];
    NSInteger result = 0;
    if (self.sdkStatus == SdkStatusStarted) {
        result = 1;
    }
    NSDictionary *ret = [NSDictionary dictionaryWithObjectsAndKeys:[GeTuiSdk clientId], @"cid",
                         [NSNumber numberWithInteger:result], @"result",
                         nil];
    if (cbIdTmp > -1) {
        [self sendResultEventWithCallbackId:cbIdTmp dataDict:ret errDict:nil doDelete:YES];
    }
}

- (void)getVersion:(NSDictionary *)paramDict {
    NSLog(@"GTSDK>>>getVersion");
    NSInteger cbIdTmp = [self fetchCbId:paramDict];
    if (cbIdTmp > -1) {
        NSDictionary *ret = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithInteger:1], @"result",
                             [GeTuiSdk version], @"version",
                             nil];
        [self sendResultEventWithCallbackId:cbIdTmp dataDict:ret errDict:nil doDelete:YES];
    }
}

- (void)sendMessage:(NSDictionary *)paramDict {
    NSLog(@"GTSDK>>>sendMessage %@", paramDict);
    NSInteger cbIdTmp = [self fetchCbId:paramDict];
    if (cbIdTmp > -1) {
        NSString *sendStr = [paramDict stringValueForKey:@"extraData" defaultValue:nil];
        NSData *sendData = [sendStr dataUsingEncoding:NSUTF8StringEncoding];
        NSError *error = nil;
        [GeTuiSdk sendMessage:sendData error:&error];
        NSInteger result = 1;
        NSString *errorMsg = nil;
        
        NSDictionary *ret = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInteger:result], @"result", nil];
        if (error) {
            result = 0;
            errorMsg = error.description;
            ret = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInteger:result], @"result", errorMsg, @"msg", 0, @"code", nil];
        }
        [self sendResultEventWithCallbackId:cbIdTmp dataDict:ret errDict:nil doDelete:YES];
    }
}

//暂时不支持接口result都返回-100
- (void)stopService:(NSDictionary *)paramDict {
    NSLog(@"GTSDK>>>stopService");
    NSInteger cbIdTmp = [self fetchCbId:paramDict];
    if (cbIdTmp > -1) {
        NSDictionary *ret = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInteger:-100], @"result", nil];
        [self sendResultEventWithCallbackId:cbIdTmp dataDict:ret errDict:nil doDelete:YES];
    }
}

- (void)sendFeedbackMessage:(NSDictionary *)paramDict {
    NSLog(@"GTSDK>>>sendFeedbackMessage %@",paramDict);
    NSInteger cbIdTmp = [self fetchCbId:paramDict];
    
    if (cbIdTmp > -1) {
        NSInteger actionId = [paramDict integerValueForKey:@"actionid" defaultValue:0];
        NSString *taskId = [paramDict stringValueForKey:@"taskid" defaultValue:nil];
        NSString *messageId = [paramDict stringValueForKey:@"messageid" defaultValue:nil];
        NSInteger result = 0;
        if ([GeTuiSdk sendFeedbackMessage:actionId andTaskId:taskId andMsgId:messageId]) {
            result = 1;
        }
        NSDictionary *ret = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInteger:result], @"result", nil];
        [self sendResultEventWithCallbackId:cbIdTmp dataDict:ret errDict:nil doDelete:YES];
    }
}

- (void)turnOnPush:(NSDictionary *)paramDict {
    NSLog(@"GTSDK>>>turnOnPush");
    NSInteger cbIdTmp = [self fetchCbId:paramDict];
    if (cbIdTmp > -1) {
        [GeTuiSdk setPushModeForOff:NO];
        self.isPushTurnOn = YES;
        NSDictionary *ret = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInteger:1], @"result", nil];
        [self sendResultEventWithCallbackId:cbIdTmp dataDict:ret errDict:nil doDelete:YES];
    }
}

- (void)turnOffPush:(NSDictionary *)paramDict {
    NSLog(@"GTSDK>>>turnOffPush");
    NSInteger cbIdTmp = [self fetchCbId:paramDict];
    if (cbIdTmp > -1) {
        [GeTuiSdk setPushModeForOff:YES];
        self.isPushTurnOn = NO;
        NSDictionary *ret = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInteger:1], @"result", nil];
        [self sendResultEventWithCallbackId:cbIdTmp dataDict:ret errDict:nil doDelete:YES];
    }
}

- (void)isPushTurnedOn:(NSDictionary *)paramDict {
    NSLog(@"GTSDK>>>isPushTurnedOn");
    NSInteger cbIdTmp = [self fetchCbId:paramDict];
    if (cbIdTmp > -1) {
        NSString *isOn = @"false";
        if (self.isPushTurnOn) {
            isOn = @"true";
        }
        NSDictionary *ret = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInteger:1], @"result", isOn, @"isOn", nil];
        [self sendResultEventWithCallbackId:cbIdTmp dataDict:ret errDict:nil doDelete:YES];
    }
}

- (void)runBackgroundOn:(NSDictionary *)paramDict {
    NSLog(@"GTSDK>>>runBackgroundOn");
    NSInteger cbIdTmp = [self fetchCbId:paramDict];
    if (cbIdTmp > -1) {
        [GeTuiSdk runBackgroundEnable:YES];
        self.isBackgroundEnable = YES;
        NSDictionary *ret = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInteger:1], @"result", nil];
        [self sendResultEventWithCallbackId:cbIdTmp dataDict:ret errDict:nil doDelete:YES];
    }
}

- (void)runBackgroundOff:(NSDictionary *)paramDict {
    NSLog(@"GTSDK>>>runBackgroundOff");
    NSInteger cbIdTmp = [self fetchCbId:paramDict];
    if (cbIdTmp > -1) {
        [GeTuiSdk runBackgroundEnable:NO];
        self.isBackgroundEnable = NO;
        NSDictionary *ret = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInteger:1], @"result", nil];
        [self sendResultEventWithCallbackId:cbIdTmp dataDict:ret errDict:nil doDelete:YES];
    }
}

- (void)lbsLocationOn:(NSDictionary *)paramDict {
    NSLog(@"GTSDK>>>lbsLocationOn");
    NSInteger cbIdTmp = [self fetchCbId:paramDict];
    if (cbIdTmp > -1) {
        [GeTuiSdk lbsLocationEnable:YES andUserVerify:NO];
        self.islbsLocationEnable = YES;
        NSDictionary *ret = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInteger:1], @"result", nil];
        [self sendResultEventWithCallbackId:cbIdTmp dataDict:ret errDict:nil doDelete:YES];
    }
}

- (void)lbsLocationOff:(NSDictionary *)paramDict {
    NSLog(@"GTSDK>>>lbsLocationOff");
    NSInteger cbIdTmp = [self fetchCbId:paramDict];
    if (cbIdTmp > -1) {
        [GeTuiSdk lbsLocationEnable:NO andUserVerify:NO];
        self.islbsLocationEnable = NO;
        NSDictionary *ret = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInteger:1], @"result", nil];
        [self sendResultEventWithCallbackId:cbIdTmp dataDict:ret errDict:nil doDelete:YES];
    }
}

- (void)setSilentTime:(NSDictionary *)paramDict {
    NSLog(@"GTSDK>>>setSilentTime");
    NSInteger cbIdTmp = [self fetchCbId:paramDict];
    if (cbIdTmp > -1) {
        NSDictionary *ret = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInteger:-100], @"result", nil];
        [self sendResultEventWithCallbackId:cbIdTmp dataDict:ret errDict:nil doDelete:YES];
    }
}

- (void)payloadMessage:(NSDictionary *)paramDict {
    NSLog(@"GTSDK>>>payloadMessage");
    NSInteger cbIdTmp = [self fetchCbId:paramDict];
    if (cbIdTmp > -1) {
        NSDictionary *ret = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInteger:-100], @"result", nil];
        [self sendResultEventWithCallbackId:cbIdTmp dataDict:ret errDict:nil doDelete:YES];
    }
}

- (void)registerDeviceToken:(NSDictionary *)paramDict {
    [self commonApiWithBool:RegiserDeviceToken cbId:paramDict];
}

- (void)clearAllNotificationForNotificationBar:(NSDictionary *)paramDict {
    NSLog(@"GTSDK>>>clearAllNotificationForNotificationBar");
    NSInteger cbIdTmp = [self fetchCbId:paramDict];
    if (cbIdTmp > -1) {
        [GeTuiSdk clearAllNotificationForNotificationBar];
        NSDictionary *ret = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInteger:1], @"result", nil];
        [self sendResultEventWithCallbackId:cbIdTmp dataDict:ret errDict:nil doDelete:YES];
    }
}

// 个推sdk接口回调
#pragma mark - GtSdkDelegate

- (void)GeTuiSdkDidRegisterClient:(NSString *)clientId {
    NSLog(@"GTSDK>>>GeTuiSdkDidRegisterClient %@",clientId);
    self.clientId = clientId;
    if (cbId > -1) {
        NSDictionary *ret = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithInteger:1], @"result",
                             @"cid", @"type",
                             clientId, @"cid", nil];
        [self sendResultEventWithCallbackId:cbId dataDict:ret errDict:nil doDelete:NO];
    }
}

- (void)GeTuiSdkDidSendMessage:(NSString *)messageId result:(BOOL)isSuccess error:(nullable NSError *)aError {
    NSLog(@"GTSDK>>>GeTuiSdkDidSendMessage:%@ result:%d error:%@", messageId, isSuccess, aError);
    if (cbId > -1) {
        NSDictionary *ret = [NSDictionary dictionaryWithObjectsAndKeys:@(isSuccess), @"result",
                             messageId, @"messageId",
                             @"sendMsgFeedback", @"type", nil];
        [self sendResultEventWithCallbackId:cbId dataDict:ret errDict:aError.userInfo doDelete:NO];
    }
}

- (void)GeTuiSDkDidNotifySdkState:(SdkStatus)aStatus {
    NSLog(@"GTSDK>>>GeTuiSDkDidNotifySdkState %@",@(aStatus));
    if (cbId > -1) {
        NSDictionary *ret = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithInteger:1], @"result",
                             @"status", @"type",
                             [NSNumber numberWithUnsignedInteger:aStatus], @"status", nil];
        [self sendResultEventWithCallbackId:cbId dataDict:ret errDict:nil doDelete:NO];
    }
}

- (void)GeTuiSdkDidAliasAction:(NSString *)action result:(BOOL)isSuccess sequenceNum:(NSString *)aSn error:(NSError *)aError {
    NSLog(@"GTSDK>>>GeTuiSdkDidAliasAction action:%@ isSuccess:%@ sn:%@ error:%@",action,@(isSuccess),aSn, aError);
    if (cbId > -1) {
        NSDictionary *ret = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithInteger:1], @"result",
                             @"alias", @"type",
                             action, @"action",
                             aSn,@"aSn",
                             isSuccess ? @"true" : @"false", @"isSuccess",
                             aError.localizedDescription, @"error", nil];
        [self sendResultEventWithCallbackId:cbId dataDict:ret errDict:nil doDelete:NO];
    }
}

- (void)GeTuiSdkDidSetTagsAction:(NSString *)sequenceNum result:(BOOL)isSuccess error:(NSError *)aError {
    NSLog(@"GTSDK>>>GeTuiSdkDidSetTagAction sequenceNum:%@ isSuccess:%@ error: %@", sequenceNum, @(isSuccess), aError);
    if (cbId > -1) {
        NSDictionary *ret = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithInteger:1], @"result",
                             @"tags", @"type",
                             sequenceNum, @"sequenceNum",
                             isSuccess ? @"true" : @"false", @"isSuccess",
                             aError.localizedDescription, @"error", nil];
        [self sendResultEventWithCallbackId:cbId dataDict:ret errDict:nil doDelete:NO];
    }
}

- (void)GetuiSdkDidQueryTag:(NSArray*)aTags sequenceNum:(NSString *)aSn error:(NSError *)aError {
    NSLog(@"GTSDK>>>GetuiSdkDidQueryTag tags:%@ sn:%@ error:%@", aTags, aSn, aError);
    if (cbId > -1) {
        NSDictionary *ret = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithInteger:1], @"result",
                             @"queryTag", @"type",
                             aTags, @"aTags",
                             aSn, @"aSn",
                             aError.localizedDescription, @"error", nil];
        [self sendResultEventWithCallbackId:cbId dataDict:ret errDict:nil doDelete:NO];
    }
}

- (void)GeTuiSdkDidOccurError:(NSError *)error {
    NSLog(@"GTSDK>>>GeTuiSdkDidOccurError %@",error);
    // [EXT]:个推错误报告，集成步骤发生的任何错误都在这里通知，如果集成后，无法正常收到消息，查看这里的通知。
    //[_viewController logMsg:[NSString stringWithFormat:@">>>[GexinSdk error]:%@", [error localizedDescription]]];
    if (cbId > -1) {
        NSDictionary *ret = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInteger:error.code], @"code",
                             [error localizedDescription], @"description",
                             @"occurError", @"type", nil];
        [self sendResultEventWithCallbackId:cbId dataDict:ret errDict:nil doDelete:NO];
    }
}

#pragma mark 通知回调

/// 通知展示（iOS10及以上版本）
/// @param center center
/// @param notification notification
/// @param completionHandler completionHandler
- (void)GeTuiSdkNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification completionHandler:(void (^)(UNNotificationPresentationOptions))completionHandler {
    NSLog(@"GTSDK>>>willPresentNotification：%@", notification.request.content.userInfo);
    
    if (cbId > -1) {
        NSDictionary *ret = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithInteger:1], @"result",
                             @"willPresentNotification", @"type",
                             notification.request.content.userInfo, @"msg", nil];
        [self sendResultEventWithCallbackId:cbId dataDict:ret errDict:nil doDelete:NO];
    }
    
    
    // 根据APP需要，判断是否要提示用户Badge、Sound、Alert
    if (completionHandler) {
        if (self.activeShowNotification) {
            completionHandler(UNNotificationPresentationOptionBadge | UNNotificationPresentationOptionSound | UNNotificationPresentationOptionAlert);
        } else {
            completionHandler(UNNotificationPresentationOptionNone);
        }
    }
}

/// 收到通知信息
/// @param userInfo apns通知内容
/// @param center UNUserNotificationCenter（iOS10及以上版本）
/// @param response UNNotificationResponse（iOS10及以上版本）
/// @param completionHandler 用来在后台状态下进行操作（iOS10以下版本）
- (void)GeTuiSdkDidReceiveNotification:(NSDictionary *)userInfo notificationCenter:(UNUserNotificationCenter *)center response:(UNNotificationResponse *)response fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    NSLog(@"GTSDK>>>GeTuiSdkDidReceiveNotification %@", userInfo);
    if (cbId > -1) {
        NSDictionary *ret = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithInteger:1], @"result",
                             @"apns", @"type",
                             userInfo, @"msg", nil];
        [self sendResultEventWithCallbackId:cbId dataDict:ret errDict:nil doDelete:NO];
    }
    
    if (completionHandler) {
        completionHandler(UIBackgroundFetchResultNoData);
    }
}

/// 收到透传消息
/// @param userInfo    推送消息内容
/// @param fromGetui   YES: 个推通道  NO：苹果apns通道
/// @param offLine     是否是离线消息，YES.是离线消息
/// @param appId       应用的appId
/// @param taskId      推送消息的任务id
/// @param msgId       推送消息的messageid
/// @param completionHandler 用来在后台状态下进行操作（通过苹果apns通道的消息 才有此参数值）
- (void)GeTuiSdkDidReceiveSlience:(NSDictionary *)userInfo fromGetui:(BOOL)fromGetui offLine:(BOOL)offLine appId:(NSString *)appId taskId:(NSString *)taskId msgId:(NSString *)msgId fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    NSLog(@"GTSDK>>>GeTuiSdkDidReceiveSlience %@ fromGetui:%@ appId:%@ offLine:%@ taskId:%@ msgId:%@ userInfo:%@ ", NSStringFromSelector(_cmd), fromGetui ? @"个推消息" : @"APNs消息", appId, offLine ? @"离线" : @"在线", taskId, msgId, userInfo);
    if (cbId > -1) {
        NSDictionary *ret = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithInteger:1], @"result",
                             @"payload", @"type",
                             taskId, @"taskId",
                             msgId, @"messageId",
                             offLine ? @"true" : @"false", @"offLine",
                             userInfo[@"payload"] ? :@"", @"payload", nil];
        [self sendResultEventWithCallbackId:cbId dataDict:ret errDict:nil doDelete:NO];
    }
    
    if(completionHandler) {
        completionHandler(UIBackgroundFetchResultNoData);
    }
}

- (void)GeTuiSdkNotificationCenter:(UNUserNotificationCenter *)center
       openSettingsForNotification:(nullable UNNotification *)notification {
    NSLog(@"GTSDK>>>openSettingsForNotification");
    if (cbId > -1) {
        NSDictionary *ret = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithInteger:1], @"result",
                             @"openSettings", @"type",nil];
        [self sendResultEventWithCallbackId:cbId dataDict:ret errDict:nil doDelete:NO];
    }
}

#pragma mark - 远程通知(推送)回调--注册DeviceToken

/** 远程通知注册成功委托 */
- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    // [ GTSDK ]：向个推服务器注册deviceToken
    // SDK内Hook失效 原因可能是平台在sdk注册前已申请通知权限
    [GeTuiSdk registerDeviceTokenData:deviceToken];
    
    _deviceToken = [self getHexStringForData:deviceToken];
    NSLog(@"GTSDK>>>[DeviceToken Success]:data:%@\n\n string:%@\n\n", deviceToken, _deviceToken);
}

/** 远程通知注册失败委托 */
- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    NSLog(@"GTSDK>>>register device Token Fail %@", [NSString stringWithFormat:@"didFailToRegisterForRemoteNotificationsWithError:%@", [error localizedDescription]]);
}

#pragma mark - VOIP related

- (void)voipRegistration:(NSDictionary *)paramDict {
    NSLog(@"GTSDK>>>voipRegistration");
    voipCBId = [self fetchCbId:paramDict];
    if (voipCBId > -1) {
        dispatch_queue_t mainQueue = dispatch_get_main_queue();
        PKPushRegistry *voipRegistry = [[PKPushRegistry alloc] initWithQueue:mainQueue];
        voipRegistry.delegate = self;
        // Set the push type to VoIP
        voipRegistry.desiredPushTypes = [NSSet setWithObject:PKPushTypeVoIP];
    }
}

// 实现 PKPushRegistryDelegate 协议方法

/** 系统返回VOIPToken，并提交个推服务器 */

- (void)pushRegistry:(PKPushRegistry *)registry didUpdatePushCredentials:(PKPushCredentials *)credentials forType:(NSString *)type {
    //向个推服务器注册 VoipToken 为了方便开发者，建议使用新方法
    [GeTuiSdk registerVoipTokenCredentials:credentials.token];
    NSLog(@"GTSDK>>>[VoipToken(NSData)]: %@", credentials.token);

}

/** 接收VOIP推送中的payload进行业务逻辑处理（一般在这里调起本地通知实现连续响铃、接收视频呼叫请求等操作），并执行个推VOIP回执统计 */
- (void)pushRegistry:(PKPushRegistry *)registry didReceiveIncomingPushWithPayload:(PKPushPayload *)payload forType:(NSString *)type {
    //个推VOIP回执统计
    [GeTuiSdk handleVoipNotification:payload.dictionaryPayload];
    
    //TODO:接受 VoIP 推送中的 payload 内容进行具体业务逻辑处理
    NSLog(@"GTSDK>>> [VoIP Payload]:%@,%@", payload, payload.dictionaryPayload);
    
    NSDictionary *ret = [NSDictionary dictionaryWithObjectsAndKeys:
                         [NSNumber numberWithInteger:1], @"result",
                         @"voipPayload", @"type",
                         payload.dictionaryPayload[@"payload"], @"payload",
                         payload.dictionaryPayload[@"_gmid_"], @"gmid",  nil];
    
    [self sendResultEventWithCallbackId:voipCBId dataDict:ret errDict:nil doDelete:NO];
}

#pragma mark - applink

- (BOOL)application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void(^)(NSArray<id<UIUserActivityRestoring>> * __nullable restorableObjects))restorationHandler {
    NSLog(@"GTSDK>>continueUserActivity");
    if ([userActivity.activityType isEqualToString:NSUserActivityTypeBrowsingWeb]) {
        NSURL* webUrl = userActivity.webpageURL;
        
        //处理个推APPLink回执统计
        //APPLink url 示例：https://link.gl.ink/getui?n=payload&p=mid， 其中 n=payload 字段存储用户透传信息，可以根据透传内容进行业务操作。
        NSString* payload = [GeTuiSdk handleApplinkFeedback:webUrl];
        if (payload) {
            NSLog(@"GTSDK>>> 个推APPLink中携带的用户payload信息: %@,URL : %@", payload, webUrl);
            //TODO:用户可根据具体 payload 进行业务处理
            
            if (cbId > -1) {
                NSDictionary *ret = [NSDictionary dictionaryWithObjectsAndKeys:
                                     [NSNumber numberWithInteger:1], @"result",
                                     @"AppLinkPayload", @"type",
                                     payload, @"payload",
                                     nil];
                
                [self sendResultEventWithCallbackId:cbId dataDict:ret errDict:nil doDelete:NO];
            }
        }
    }
    return true;
}

#pragma mark - utils

- (NSString *)getHexStringForData:(NSData *)data {
    NSUInteger len = [data length];
        char *chars = (char *) [data bytes];
        NSMutableString *hexString = [[NSMutableString alloc] init];
        for (NSUInteger i = 0; i < len; i++) {
            [hexString appendString:[NSString stringWithFormat:@"%0.2hhx", chars[i]]];
        }
        return hexString;
}
@end
