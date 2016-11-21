//
//  UZModuleDemo.h
//  UZModule
//
//  Created by kenny on 14-3-5.
//  Copyright (c) 2014年 APICloud. All rights reserved.
//

#import "UZModule.h"
#import "GeTuiSdk.h"


@interface UZModuleGetuiSDK : UZModule <GeTuiSdkDelegate>{
    NSInteger cbId;
    //NSInteger cbIdPayload;
}

//@property (strong, nonatomic) GeTuiSdk *getuiPusher;
@property (retain, nonatomic) NSString *appKey;
@property (retain, nonatomic) NSString *appSecret;
@property (retain, nonatomic) NSString *appID;
@property (retain, nonatomic) NSString *clientId;
@property (assign, nonatomic) SdkStatus sdkStatus;
@property (nonatomic,strong) NSString *deviceToken;

@property (assign, nonatomic) int lastPayloadIndex;
@property (retain, nonatomic) NSString *payloadId;
@property (assign, nonatomic) BOOL isPushTurnOn;


@end
