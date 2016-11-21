

#import "UZModuleGetuiSDK.h"
#import "NSDictionaryUtils.h"
#import "UZAppDelegate.h"
#import "UZAppUtils.h"


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
                    if (token!=nil) {
                        [GeTuiSdk registerDeviceToken:token];
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

#pragma mark - 注册DeviceToken
//- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData*)deviceToken {
//    NSString *token = [[deviceToken description] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]];
//    //[_deviceToken release];
//    //_deviceToken = [[token stringByReplacingOccurrencesOfString:@" " withString:@""] retain];
//    
//    //[GeTuiSdk registerDeviceToken:_deviceToken];
//    
//}

@end
