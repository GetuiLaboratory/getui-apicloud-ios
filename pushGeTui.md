/*
Title: pushGeTui
Description: pushGeTui
*/

<p style="color: #ccc; margin-bottom: 30px;">来自于：个推<a style="background-color: #95ba20; color:#fff; padding:4px 8px;border-radius:5px;margin-left:30px; margin-bottom:0px; font-size:12px;text-decoration:none;" target="_blank" href="//www.apicloud.com/mod_detail/pushGeTui">立即使用</a></p>

<ul id="tab" class="clearfix">
	<li class="active"><a href="#basic-content">基础接口</a></li>
	<li><a href="#extended-content">扩展接口</a></li>
	<li><a href="#advanced-content">高级接口</a></li>
</ul>
<div id="basic-content">

<div class="outline">
[initialize](#a1)
[registerDeviceToken](#a2)
</div>

#**概述**

pushGeTui封装了个推消息推送平台的SDK，使用此模块可轻松实现服务端向客户端推送通知和透传消息的功能。

###名词解释：

CID：用于标识推送目标的用户ID；CID全局唯一；同一手机不同包名的应用拥有不同的CID；正常情况下，CID会在SD卡进行存储，因此即使应用卸载重装，CID也保持不变；但SD卡缓存文件被清理的情况下，应用卸载重装CID会变更，第三方应用需要及时将最新的CID更新到第三方服务端

APPKEY/APPID：从个推平台上的获得的应用标识

###个推支持以下三种消息推送形式：

1.指定单个CID进行消息单推；

2.指定一组CID进行消息批量推送；

3.指定同一APPID下的所有CID进行全量推送。

###个推消息推送基本流程说明：

1.在个推开放平台（ http://dev.getui.com ）注册帐号，并创建应用，获取APPKEY/APPID/APPSECRET参数。具体流程常见“个推开放API配置指南”

2.在config中配置pushGeTui feature，填写上述应用参数

3.应用启动后调用initialize进行推送SDK初始化，并调用register接口注册透传消息监听器；

4.推送服务获取到推送标识CID后返回给JS层，应用一般需要将该CID和用户ID做一个绑定，记录到服务端；

5.服务端指定CID进行透传消息推送（可以通过个推开放平台直接操作，也可以使用服务端SDK调用消息推送接口），携带透传消息内容Payload

6.推送服务接收到消息后，通过register接口注册的消息监听器回调给JS层

7.JS层处理透传消息内容Payload，进行相应的处理。

8.服务端也可以指定CID进行通知消息推送，通知点击后启动APICloud应用。

9.补充说明，如果用户需要点击通知并执行相应的后续动作，例如跳转至指定的界面等，则需要在个推开发者平台的推送通知界面，点击高级设置中的透传消息，配置相应的透传信息，这样用户点击通知后，应用将会收到通知附带的透传信息，在 initialize(callback(ret, err)) 中有回调，用于执行后续动作；如果采用的是个推服务端的SDK，则流程同理。


###关于透传消息的
受到JS层目前机制限制，如果apicloud应用未运行，JS层是无法处理透传数据的。


**使用此模块之前需先配置config文件的Feature，方法如下**

	名称：pushGeTui
	参数：android_appkey,android_appid,android_appsecret,android_groupid
	描述：配置个推应用信息
```js
	<feature name="pushGeTui">
	    <param name="ios_appkey" value="xCGkZR1bCp6gscLUB20Dl4" />
		<param name="ios_appid" value="G5lfFkQZ008VoZUXydA2r2" />
		<param name="ios_appsecret" value="RuxlC8ExWA7T4NFoJhQFd6" />
		<param name="android_appkey" value="aiMe49ehZa7IK8sevOTiY8" />
		<param name="android_appid" value="h5AH1rK4KW7vfFGZjT7fG" />
		<param name="android_appsecret" value="wx7779c7c063a9d4d9" />
		<param name="android_groupid" value="" />
	</feature>
```
字段描述:

		1.android_appkey：通过个推平台获得
		2.android_appid：应用ID，通过个推平台获得
		3.android_appsecret：通过个推平台获得
		4.android_groupid: 目前留空即可
        5.active_show_notification iOS平台前台收到通知是否展示
        6.ios_appsecret：通过个推平台获得
        7.ios_appid：应用ID，通过个推平台获得
        8.ios_appkey：通过个推平台获得      

***接口设计说明***
一、cid、payload、occurError都使用通过initialize传递进去的callback，所有的回调里面都定义了一个type参数，我们可以通过判断type参数来判断回调的类型.
type类型参数说明：
        1、cid:初始化（initialize）回调回来的cid；

​        2、payload：下发payload消息；

​        3、occurError：所有发生错误时候的回调；

​        4、status：SDK运行状态通知

​        5、tags：设置标签回调

​        6、queryTag：查询当前绑定tag结果返回

​        7、alias：SDK绑定、解绑回调
​         
​        8、apns: 苹果官方 APNs 推送，即应用在后台时收到的推送消息，若通过点击该推送消息打开应用，则收到该类型的回调，可用于判断是否点击推送消息打开应用；   

二、返回值result值说明：
        1、0：失败
        2、1：成功
        3、-100：不支持的接口   
```js
function callback(ret,err){
      var log;
      switch(ret.type)
      {
          case 'cid':
            log='cid:'+ret.cid;
          break;
          case 'payload':
            log='payload:'+ret.payload;
          break;
          case 'apns':
            log='apns click:'+ret.result+' msg:'+ret.msg;
          break;
          case 'willPresentNotification':
            log='willPresentNotification:'+ret.result+' msg:'+ret.msg;
          break;
          case 'openSettings':
            log='openSettingsForNotification:';
          break;
          case'occurError':
            log='occurError';
          break;
          case 'sendMsgFeedback':
            log='sendMsgFeedback:'+ret.result+' messageid:'+ret.messageId;
          break;
          case 'AppLinkPayload':
            log='applink:'+ret.result+' msg:'+ret.payload;
          break;
      }
    }
```
错误类型回调json
```js
{
    code:300,
    description:"error msg",
    type:"occurError"
}
```
#**initialize**<div id="a1"></div>

初始化推送服务

initialize(callback(ret, err))

##callback(ret, err)

ret：

- 类型：JSON 对象

内部字段：

```js
// cid
{
	result:1                              //操作成功状态值
	type:"cid"                              //CID 类型
  cid:"sdwe435236fdfd"                   //返回的cid的值
}
// payload
{
	result:1                                //操作成功状态值
	type:"payload"                          //payload 类型
	taskId:"taskId"                         //taskId 值
	messageId:"messageId"                   //messageId 值
	payload:"payload"                       //payload 内容
	offLine:"true"                          //判断推送时app是杀死还是启动状态
}
// apns
{
	result:1                              //操作成功状态值
	type:"apns"                           //apns 类型
	msg:"msg"                         	  //apns 消息体
}
// occurError
{
	code:"errorCode"                        //错误吗
	description:"error description"         //错误描述
	type:"occurError"                       //occurError 类型
}
// onNotificationMessageArrived
{
     type:"onNotificationMessageArrived"     //通知到达
     taskid:"tasid"                          //taskid
     messageid:"messageid"                   //消息id
     title:"title"                           //消息标题
     content:"content"                       //消息内容
}
// AppLinkReceive
{
	  result:1
	  type:"AppLinkPayload"
	  payload:"msg"
}
```

err：

- 类型：JSON 对象

内部字段：

```js
{
	code:0       //错误码（详见错误码常量）
	msg:""       //错误描述
}
```


##示例代码

```js
var uzgetuisdk = api.require('pushGeTui');
uzgetuisdk.initialize(function(ret) {
    var value = "";
    switch (ret.type) {
        case 'cid':
            value = 'cid:' + ret.cid;
            break;
        case 'payload':
            value = 'payload:' + ret.payload;
            break;
        case 'occurError':
            value = 'occurError';
            break;
        case'onNotificationMessageClicked':
          value = 'onNotificationMessageClicked' + ret.onNotificationMessageClicked
          break;
        case'onNotificationMessageArrived':
          value = 'onNotificationMessageArrived' + ret.onNotificationMessageArrived
          break;
    }
});

```

##补充说明

在每次应用启动的初始化过程中，都需要调用个推SDK初始化函数。这时候传递的参数callback将会用于cid、payload、occurError的回调。

##可用性

iOS系统，Android系统

可提供的1.0.0及更高版本
#**registerDeviceToken**<div id="a2"></div>

注册deviceToken

registerDeviceToken(callback(ret, err))

##callback(ret, err)

ret：

- 类型：JSON 对象

内部字段：

```js
{
	result:1                                 //操作成功状态值 1成功0失败
}
```


##示例代码

```js
function registerDeviceToken() {
    var param = {
        deviceToken: api.deviceToken,
    };
    uzgetuisdk.registerDeviceToken(param, function(ret, err) {
        var log = 'registerDeviceToken:' + ret.result;
        console.log(log);
    });
}

```

##补充说明
如果发生错误会在occurError里面回调。

##可用性

iOS系统

可提供的1.0.0及更高版本
</div>


<div id="extended-content">

<div class="outline">
[setTag](#b1)

[bindAlias](#b2)

[unBindAlias](#b3)

[stopService](#b4)

[sendFeedbackMessage](#b5)

[fetchClientId](#b6)

[setBadge](#b7)

</div>

#**setTag**<div id="b1"></div>

为用户设置标签。针对单个CID设置标签（tag）列表，服务端推送可以指定标签进行定向群发

setTag({params}, callback(ret, err))

##params

tags：

- 类型：字符串
- 默认值：无
- 描述：标签列表，以逗号(,)分割，标签名建议采用英文和数字的组合

##callback(ret, err)

ret：

- 类型：JSON 对象

内部字段：

```js
{
	result:1               //操作成功状态值
}
```

err：

- 类型：JSON 对象

内部字段：

```js
{
    code:0       //错误码（详见错误码常量）
    msg: ""      //错误描述
}
```

##示例代码

```js
var uzgetuisdk = api.require('pushGeTui');
var param = { tags: "tag1,tag2" };
uzgetuisdk.setTag(param, function(ret) {
    api.alert({ msg: "setTag result:" + ret.result });
});

```

##补充说明

（暂无）

##可用性

iOS系统，Android系统

可提供的1.0.0及更高版本


#**bindAlias**<div id="b2"></div>

绑定用户别名。针对单个CID设置别名，一个别名可以对应多个CID。可以指定别名进行消息推送

bindAlias({params}, callback(ret, err))

##params

alias：

- 类型：字符串
- 默认值：无
- 描述：别名，建议采用英文和数字组合

##callback(ret, err)

ret：

- 类型：JSON 对象

内部字段：

```js
{
	result:1               //操作成功状态值
}
```

err：

- 类型：JSON 对象

内部字段：

```js
{
    code:0       //错误码（详见错误码常量）
    msg: ""      //错误描述
}
```

##示例代码

```js
var uzgetuisdk = api.require('pushGeTui');
var param = { alias: "myalias" };
uzgetuisdk.bindAlias(param, function(ret) {
    api.alert({ msg: "bindAlias result:" + ret.result });
});

```

##补充说明

（暂无）

##可用性

iOS系统，Android系统

可提供的1.0.0及更高版本


#**unBindAlias**<div id="b3"></div>

解绑用户别名。针对单个CID取消设置别名。

unBindAlias({params}, callback(ret, err))

##params

alias：

- 类型：字符串
- 默认值：无
- 描述：别名，建议采用英文和数字组合

##callback(ret, err)

ret：

- 类型：JSON 对象

内部字段：

```js
{
	result:"1"               //操作成功状态值
}
```

err：

- 类型：JSON 对象

内部字段：

```js
{
    code:0       //错误码（详见错误码常量）
    msg: ""      //错误描述
}
```

##示例代码

```js
var uzgetuisdk = api.require('pushGeTui');
var param = { alias: "myalias" };
uzgetuisdk.unBindAlias(param, function(ret) {
    api.alert({ msg: "unbindAlias result:" + ret.result });
});

```

##补充说明

（暂无）

##可用性

iOS系统，Android系统

可提供的1.0.0及更高版本


#**stopService**<div id="b4"></div>

完全停止SDK的服务。停止推送服务，停止所有业务逻辑

stopService(callback(ret, err))

##callback(ret, err)

ret：

- 类型：JSON 对象

内部字段：

```js
{
	result:"1"               //操作成功状态值
}
```

err：

- 类型：JSON 对象

内部字段：

```js
{
    code:0       //错误码（详见错误码常量）
    msg: ""      //错误描述
}
```

##示例代码

```js
var uzgetuisdk = api.require('pushGeTui');
uzgetuisdk.stopService(function(ret) {
    api.alert({ msg: "stopService result:" + ret.result });
});

```

##补充说明

（暂无）

##可用性

Android系统

可提供的1.0.0及更高版本


#**sendFeedbackMessage**<div id="b5"></div>

上行第三方自定义回执。第三方指定自定义actionid，便于对推送效果做统计分析。

sendFeedbackMessage({params}, callback(ret, err))

##params

taskid：

- 类型：字符串
- 默认值：无
- 描述：接收的透传消息任务id

messageid：

- 类型：字符串
- 默认值：无
- 描述：接收的透传消息id

actionid：

- 类型：int
- 默认值：无
- 描述：自定义动作id，范围为90001-90999。第三方可以对支付、页面访问等用户操作进行打点。

##callback(ret, err)

ret：

- 类型：JSON 对象

内部字段：

```js
{
	result:"1"               //操作成功状态值
}
```

err：

- 类型：JSON 对象

内部字段：

```js
{
    code:0       //错误码（详见错误码常量）
    msg: ""      //错误描述
}
```

##示例代码

```js
var uzgetuisdk = api.require('pushGeTui');
var param = { taskid: "GT_1012_AKMw2kc2Oj5Tzy1DvXjMQA", messageid: "GT_1012_AKMw2kc2Oj5Tzy1DvXjMQA", actionid: 90001 };
uzgetuisdk.sendFeedbackMessage(param, function(ret) {
    api.alert({ msg: "sendFeedbackMessage result:" + ret.result });
});

```

##补充说明

（暂无）

##可用性

iOS系统，Android系统

可提供的1.0.0及更高版本

#**fetchClientId**<div id="b6"></div>

获取cid

fetchClientId(callback(ret, err))

##callback(ret, err)

ret：

- 类型：JSON 对象

内部字段：

```js
{
  result:1;
	cid:"0580dc70460e71d5e55a3fec4c0ae92x"               
}
```



##示例代码

```js
var uzgetuisdk = api.require('pushGeTui');
uzgetuisdk.fetchClientId(function(ret, err) {
    api.alert({ msg: "cid:" + ret.cid });
});

```

##补充说明

（暂无）

##可用性

android系统 iOS系统

可提供的1.0.0及更高版本

#**setBadge**<div id="b7"></div>

设置角标功能,同步服务器角标计数

setBadge({params}, callback(ret, err))

##params

badge：

- 类型：int
- 默认值：无
- 描述：角标值，0 为重置角标

##callback(ret, err)

ret：

- 类型：JSON 对象

内部字段：

```js
{
	result:1               //操作成功状态值
}
```

err：

- 类型：JSON 对象

内部字段：

```js
{
    code:0       //错误码（详见错误码常量）
    msg: ""      //错误描述
}
```

##示例代码

```js
var uzgetuisdk = api.require('pushGeTui');
var param = { badge: 1 };
uzgetuisdk.setBadge(param, function(ret) {
    api.alert({ msg: "setBadge result:" + ret.result });
});

```

##补充说明

（暂无）

##可用性

iOS系统

可提供的大于 1.1.9 的版本

</div>
<div id="advanced-content">

<div class="outline">

[turnOnPush](#c1)

[turnOffPush](#c2)

[isPushTurnedOn](#c3)

[getVersion](#c4)

[setSilentTime](#c5)

[sendMessage](#c6)

[payloadMessage](#c7)

[voipRegistration](#c8)

</div>


#**turnOnPush**<div id="c1"></div>

开启Push推送。继续服务端连接。常见turnOffPush

turnOnPush(callback(ret, err))

##callback(ret, err)

ret：

- 类型：JSON 对象

内部字段：

```js
{
	result:1               //操作成功状态值
}
```

err：

- 类型：JSON 对象

内部字段：

```js
{
    code:0       //错误码（详见错误码常量）
    msg: ""      //错误描述
}
```

##示例代码

```js
var uzgetuisdk = api.require('pushGeTui');
uzgetuisdk.turnOnPush(function(ret) {
	api.alert({msg:"turnOnPush result:" + ret.result});
});
```

##补充说明

（暂无）

##可用性

iOS系统，Android系统

可提供的1.0.0及更高版本


#**turnOffPush**<div id="c2"></div>

关闭Push推送。暂停服务端连接，即使调用initialize也不会继续服务端连接。

turnOffPush(callback(ret, err))

##callback(ret, err)

ret：

- 类型：JSON 对象

内部字段：

```js
{
	result:1              //操作成功状态值
}
```

err：

- 类型：JSON 对象

内部字段：

```js
{
    code:0       //错误码（详见错误码常量）
    msg: ""      //错误描述
}
```

##示例代码

```js
var uzgetuisdk = api.require('pushGeTui');
uzgetuisdk.turnOffPush(function(ret) {
	api.alert({msg:"turnOffPush result:" + ret.result});
});
```

##补充说明

（暂无）

##可用性

iOS系统，Android系统

可提供的1.0.0及更高版本


#**isPushTurnedOn**<div id="c3"></div>

获取当前推送服务开关状态。该状态只和turnOnPush和turnOffPush操作相关

isPushTurnedOn(callback(ret, err))

##callback(ret, err)

ret：

- 类型：JSON 对象

内部字段：

```js
{
	result:1                   //操作成功状态值
	isOn:"true"                  //推送服务状态
}
```

err：

- 类型：JSON 对象

内部字段：

```js
{
    code:0       //错误码（详见错误码常量）
    msg: ""      //错误描述
}
```

##示例代码

```js
var uzgetuisdk = api.require('pushGeTui');
uzgetuisdk.isPushTurnedOn(function(ret) {
	api.alert({msg:"isPushTurnedOn result:" + ret.isOn});
});
```

##补充说明

（暂无）

##可用性

iOS系统，Android系统

可提供的1.0.0及更高版本


#**getVersion**<div id="c4"></div>

获取SDK版本号。

getVerison(callback(ret, err))

##callback(ret, err)

ret：

- 类型：JSON 对象

内部字段：

```js
{
	result:1                   //操作成功状态值
	version:"2.3.0.0.apicloud"    //SDK版本号
}
```

err：

- 类型：JSON 对象

内部字段：

```js
{
    code:0       //错误码（详见错误码常量）
    msg: ""      //错误描述
}
```

##示例代码

```js
var uzgetuisdk = api.require('pushGeTui');
uzgetuisdk.getVersion(function(ret) {
	api.alert({msg:"getVersion result:" + ret.version});
});
```

##补充说明

（暂无）

##可用性

Android系统，iOS系统

可提供的1.0.0及更高版本



#**setSilentTime**<div id="c5"></div>

设置SDK静默时间。在指定时间段内，暂停推送服务联网，可以避免用户打扰，同时起到省电省流量的作用。

setSilentTime({params}, callback(ret, err))

##params

beginHour：

- 类型：int
- 默认值：无
- 描述：静默时间段开始时间点，单位小时，取值范围：0-23

duration：

- 类型：int
- 默认值：无
- 描述：静默时间段持续时间，单位小时，取值范围：0-24

解释说明：
- 例如：beginHour=9、duration=12，含义为早9点到晚9点之间静默
- 例如：beginHour=21、duration=12，含义为晚9点到早9点之间静默

##callback(ret, err)

ret：

- 类型：JSON 对象

内部字段：

```js
{
	result:1              //操作成功状态值
}
```

err：

- 类型：JSON 对象

内部字段：

```js
{
    code:0       //错误码（详见错误码常量）
    msg: ""      //错误描述
}
```

##示例代码

```js
var uzgetuisdk = api.require('pushGeTui');
var param = {beginHour:9,duration:12};
uzgetuisdk.setSilentTime(param,function(ret) {
	api.alert({msg:"setSilentTime result:" + ret.result});
});
```



##可用性

Android系统

可提供的1.0.0及更高版本



#**sendMessage**<div id="c6"></div>

发送上行消息，服务端使用MMP SDK接收客户端发送的上行消息。

sendMessage({params}, callback(ret, err))

##params

taskid：

- 类型：字符串
- 默认值：无
- 描述：由客户端生成的上行消息任务id，便于后续跟踪消息

extraData：

- 类型：字符串
- 默认值：无
- 描述：上行消息内容，由客户端自行定义，建议采用json格式

##callback(ret, err)

ret：

- 类型：JSON 对象

内部字段
```js
{
  result:1                                //操作成功状态值
}
```

err：

- 类型：JSON 对象

内部字段：

```js
{
    code:0       //错误码（详见错误码常量）
    msg: ""      //错误描述
}
```

##示例代码

```js
var uzgetuisdk = api.require('pushGeTui');
var param = { taskid: "SX_1111_ABCDEFG", extraData: "any_command" };
uzgetuisdk.sendMessage(param, function(ret) {
    api.alert({ msg: "sendMessage result:" + ret.result });
});

```

##补充说明

（暂无）

##可用性

iOS系统，Android系统

可提供的1.0.0及更高版本


#**payloadMessage**<div id="c7"></div>

app 处于未启动状态时，点击通知打开程序获取透传消息。

payloadMessage(callback(ret, err))

##callback(ret, err)

ret：

- 类型：JSON 对象

内部字段：

```js
{
	payload:""               //透传内容
}
```

err：

- 类型：JSON 对象

内部字段：

```js
{
    code:0       //错误码（详见错误码常量）
    msg: ""      //错误描述
}
```

##示例代码

```js
uzgetuisdk.payloadMessage(function(ret) {
	api.alert({msg:"payloadMessag:" + ret.payload});
});
```


##可用性

Android系统

可提供的1.0.0及更高版本

</div>

#**voipRegistration**<div id="c8"></div>

推送voip通知。

voipRegistration(callback(ret, err))

##callback(ret, err)

ret：

- 类型：JSON 对象

内部字段：

```js
{
	result:1                   // 操作成功状态值
	payload:"payload msg"    	// VoIP 推送消息体
	gmid:""						// 唯一标识
	type:"voipPayload"			// 类型为 voipPayload
}
```

err：

- 类型：JSON 对象

内部字段：

```js
{
    code:0       //错误码（详见错误码常量）
    msg: ""      //错误描述
}
```

##示例代码

```js
var uzgetuisdk = api.require('pushGeTui');
uzgetuisdk.voipRegistration(function(ret,err){
	alert("voip callback = " + JSON.stringify(ret) + "err = " + JSON.stringify(err));
});
```

##补充说明

VoIP 功能需要添加后台运行权限，因此需要在 config.xml 添加如下字段：

```
   <preference name="backgroundMode" value="remote-notification|voip"/>
```

##可用性

iOS系统

可提供的2.0.2及更高版本



