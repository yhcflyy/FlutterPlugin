# Flutter插件

本教程将分为一般插件和UI插件，一个插件将会将flutter传过来的字符串用Android和iOS原生求md5后返回给Flutter端，另一个插件将会使用开源的项目实现一个视频播放UI插件。

## 非UI插件--获取md5

flutter中与原生通信主要涉及到3种通信类型，分别是：

- BasicMessageChannel：用于传递字符串和半结构化的信息
- MethodChannel：用于传递方法调用，通常用来调用native中某个方法
- EventChannel: 用于数据流的通信，有监听功能，比如电量变化之后直接推送数据给flutter端。

以上三种通信方式都是全双工的，也就是说他们两端既可以发送消息也可以接收消息。本次根据需求特点我们选择BasicMessageChannel来实现我们的需求

###### 创建插件项目

```shell
flutter create --template=plugin --org com.test -a java -i objc flutter_md5
```

使用以上命令即可创建一个名为flutter_md5的插件，其中--template=plugin表明创建的是flutter插件，--org是指定包名，-a是指定Android使用的语言，可以是java和kotlin，-i是指定iOS使用的语言，可以是objc和swift。

以下是插件的Android端的java代码：

```java
package com.test.flutter_md5;

import androidx.annotation.NonNull;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry.Registrar;

/** FlutterMd5Plugin */
public class FlutterMd5Plugin implements FlutterPlugin, MethodCallHandler {
  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
    final MethodChannel channel = new MethodChannel(flutterPluginBinding.getFlutterEngine().getDartExecutor(), "flutter_md5");
    channel.setMethodCallHandler(new FlutterMd5Plugin());
  }

  // This static function is optional and equivalent to onAttachedToEngine. It supports the old
  // pre-Flutter-1.12 Android projects. You are encouraged to continue supporting
  // plugin registration via this function while apps migrate to use the new Android APIs
  // post-flutter-1.12 via https://flutter.dev/go/android-project-migration.
  //
  // It is encouraged to share logic between onAttachedToEngine and registerWith to keep
  // them functionally equivalent. Only one of onAttachedToEngine or registerWith will be called
  // depending on the user's project. onAttachedToEngine or registerWith must both be defined
  // in the same class.
  public static void registerWith(Registrar registrar) {
    final MethodChannel channel = new MethodChannel(registrar.messenger(), "flutter_md5");
    channel.setMethodCallHandler(new FlutterMd5Plugin());
  }

  @Override
  public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
    if (call.method.equals("getPlatformVersion")) {
      result.success("Android " + android.os.Build.VERSION.RELEASE);
    } else {
      result.notImplemented();
    }
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
  }
}
```

###### 修改模板代码

上面是创建插件时为我们自动生成的代码，flutter在1.12之前会进入registerWith方法，在1.12及之后会进入onAttachedToEngine，自动生成的模板代码时使用MethodChannel获取系统版本号的。我们需要将它改成BasicMessageChannel。在android端为了兼容所有版本的flutter我们需要两个函数里面都创建BasicMessageChannel。将以上代码调整如下即可满足需求：

```java
package com.test.flutter_md5;

import androidx.annotation.NonNull;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry.Registrar;
import io.flutter.plugin.common.BasicMessageChannel;
import io.flutter.plugin.common.StandardMessageCodec;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.io.UnsupportedEncodingException;

/** FlutterMd5Plugin */
public class FlutterMd5Plugin implements FlutterPlugin, MethodCallHandler {
  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
    createChannel(flutterPluginBinding.getFlutterEngine().getDartExecutor());
  }

  // This static function is optional and equivalent to onAttachedToEngine. It supports the old
  // pre-Flutter-1.12 Android projects. You are encouraged to continue supporting
  // plugin registration via this function while apps migrate to use the new Android APIs
  // post-flutter-1.12 via https://flutter.dev/go/android-project-migration.
  //
  // It is encouraged to share logic between onAttachedToEngine and registerWith to keep
  // them functionally equivalent. Only one of onAttachedToEngine or registerWith will be called
  // depending on the user's project. onAttachedToEngine or registerWith must both be defined
  // in the same class.
  public static void registerWith(Registrar registrar) {
    createChannel(registrar.messenger());
  }

  public static void createChannel(BinaryMessenger messenger){
    BasicMessageChannel<Object> messageChannel = new BasicMessageChannel<Object>(messenger, "flutter_md5", StandardMessageCodec.INSTANCE);
    messageChannel.setMessageHandler(new BasicMessageChannel.MessageHandler<Object>() {
      @Override
      public void onMessage(Object obj, BasicMessageChannel.Reply<Object> reply) {
        String content = (String)obj;
        reply.reply(md5(content));
      }
    });
  }

  @Override
  public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
    if (call.method.equals("getPlatformVersion")) {
      result.success("Android " + android.os.Build.VERSION.RELEASE);
    } else {
      result.notImplemented();
    }
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
  }

  public static String md5(String content) {
    byte[] hash;
    try {
      hash = MessageDigest.getInstance("MD5").digest(content.getBytes("UTF-8"));
    } catch (NoSuchAlgorithmException e) {
      throw new RuntimeException("NoSuchAlgorithmException",e);
    } catch (UnsupportedEncodingException e) {
      throw new RuntimeException("UnsupportedEncodingException", e);
    }

    StringBuilder hex = new StringBuilder(hash.length * 2);
    for (byte b : hash) {
      if ((b & 0xFF) < 0x10){
        hex.append("0");
      }
      hex.append(Integer.toHexString(b & 0xFF));
    }
    return hex.toString();
  }
}
```

iOS 端我们也需要将FlutterMethodChannel替换成FlutterBasicMessageChannel，并实现md5方法，调整后的代码如下：

```objective-c
#import "FlutterMd5Plugin.h"
#import <CommonCrypto/CommonDigest.h>

@implementation FlutterMd5Plugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    FlutterBasicMessageChannel *messageChannel = [FlutterBasicMessageChannel messageChannelWithName:@"flutter_md5" binaryMessenger:[registrar messenger]];
    [messageChannel setMessageHandler:^(id message, FlutterReply callback) {
        NSString *content = (NSString*)message;
        callback([self.class md5:content]);
    }];
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
  if ([@"getPlatformVersion" isEqualToString:call.method]) {
    result([@"iOS " stringByAppendingString:[[UIDevice currentDevice] systemVersion]]);
  } else {
    result(FlutterMethodNotImplemented);
  }
}

+ (NSString *)md5:(NSString *)str{
    const char* input = [str UTF8String];
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    CC_MD5(input, (CC_LONG)strlen(input), result);
    NSMutableString *digest = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for (NSInteger i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
        [digest appendFormat:@"%02x", result[i]];
    }
    return digest;
}


@end

```

Flutter插件端也需要将MethodChannel改为BasicMessageChannel，并提供一个md5方法供flutter调用：

```dart
import 'dart:async';
import 'package:flutter/services.dart';

class FlutterMd5 {
  static const BasicMessageChannel _channel =
  const BasicMessageChannel("flutter_md5", StandardMessageCodec());

  static Future<String> md5(String msg) async {
    String reply =
    await _channel.send(msg);
    return reply;
  }
}

```

###### flutter端dart调用插件代码

以上通过在Android和iOS本地端实现md5方法，dart就可以通过插件获取字符串的md5了：

```dart
var md5 = await FlutterMd5.md5("TestMd5");//d004e4ec78d3273c1a7cab59dbd903fe
```

### 总结

通过以上的流程可以发现要实现一个非UI相关的插件，流程相对来说还是比较简单的。通过flutter提供的3个基本channel类型就可以完成很多原生平台的功能了。

## UI插件--视频播放器

###### 背景

Flutter目前实现视频播放主要有两种方式，一种是通过官方的video_player插件和第三方通过封装ijkplayer实现的插件，这两种方式都是通过Texture Widget渲染。用这种方式实现的话比较纯粹，基本上都是flutter层面上的东西，但是性能消耗比较大、CPU占用比较高，而且用flutter实现视频操作相关的ui也是比较复杂。这种方式是比较通用的方案。例一种是通过PlatformView将原生平台的View封装成Flutter可用的Widget，这种方式性能是接近原生的，但缺点是要求开发人员必须同时熟悉iOS和Android。本教程主要是讲解如果通过PlatformView实现一个视频播放器

首先我们通过上面介绍的命令创建一个flutter_videoplayer插件。编辑flutter_videoplayer.dart文件，编写如下代码

````dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

typedef void FlutterVideoplayerCreatedCallback(
    FlutterVideoplayerController controller);

class FlutterVideoplayerController {
  MethodChannel _channel;

  FlutterVideoplayerController.init(int id) {
    _channel = new MethodChannel('flutter_videoplayer');
    _channel.setMethodCallHandler(platformCallHandler);
  }

  Future<void> loadUrl(var param) async {
    assert(param != null);
    return _channel.invokeMethod('loadUrl', param);
  }

  Future<dynamic> platformCallHandler(MethodCall call) async {

  }
}

class FlutterVideoplayerWidget extends StatefulWidget {
  final FlutterVideoplayerCreatedCallback onPlayerCreated;

  FlutterVideoplayerWidget(this.onPlayerCreated);

  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    return _FlutterVideoplayerWidgetState();
  }
}

class _FlutterVideoplayerWidgetState extends State<FlutterVideoplayerWidget> {
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidView(
        viewType: 'plugins.fluttervideoplayer/view',
        onPlatformViewCreated: onPlatformViewCreated,
        creationParamsCodec: const StandardMessageCodec(),
      );
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      return UiKitView(
        viewType: 'plugins.fluttervideoplayer/view',
        onPlatformViewCreated: onPlatformViewCreated,
        creationParamsCodec: const StandardMessageCodec(),
      );
    }
    return new Text(
        '$defaultTargetPlatform is not yet supported by this plugin');
  }

  Future<void> onPlatformViewCreated(id) async {
    if (widget.onPlayerCreated == null) {
      return;
    }
    widget.onPlayerCreated(FlutterVideoplayerController.init(id));
  }
}
````

首先我们得创建一个flutter中能用的widget-FlutterVideoplayerWidget，这个widget中通过调用AndroidView和UiKitView从而实现将android和iOS的原生view显示到flutter中，AndroidView和UiKitView中的viewType是一个字符串，这个字符串必须和原生中的值保持一致，onPlatformViewCreated是view创建完成之后的回调,这个回调主要方便用于flutter和原生view之间做交互，在这个需求中主要用于flutter端将url传给原生播放器进行播放。

###### android端

我们主要是使用开源的播放器实现播放器

1. 在build.gradle中引入implementation 'com.shuyu:GSYVideoPlayer:7.1.3'

2. 编辑FlutterVideoplayerPlugin.java文件，由于我们需要实现UI相关的需求，在flutter1.12后需要实现ActivityAware接口。在类中声明一个FlutterPluginBinding变量，然后在onAttachedToEngine把FlutterPluginBinding保存起来，这样就能在onAttachedToActivity中通过FlutterPluginBinding注册PlatformViewFactory，获取messager和activity。为了兼容老版本我们也要在registerWith中实现相关方法

   ```java
   public class FlutterVideoplayerPlugin implements FlutterPlugin, MethodCallHandler,ActivityAware {
     private FlutterPluginBinding pluginBinding;
   
     @Override
     public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
       pluginBinding = flutterPluginBinding;
     }
   
     // This static function is optional and equivalent to onAttachedToEngine. It supports the old
     // pre-Flutter-1.12 Android projects. You are encouraged to continue supporting
     // plugin registration via this function while apps migrate to use the new Android APIs
     // post-flutter-1.12 via https://flutter.dev/go/android-project-migration.
     //
     // It is encouraged to share logic between onAttachedToEngine and registerWith to keep
     // them functionally equivalent. Only one of onAttachedToEngine or registerWith will be called
     // depending on the user's project. onAttachedToEngine or registerWith must both be defined
     // in the same class.
     public static void registerWith(Registrar registrar) {
       registrar.platformViewRegistry().registerViewFactory("plugins.fluttervideoplayer/view", new VideoViewFactory(registrar.messenger(),registrar.activity()));
     }
   
     @Override
     public void onAttachedToActivity(ActivityPluginBinding activityPluginBinding) {
       pluginBinding.getPlatformViewRegistry().registerViewFactory("plugins.fluttervideoplayer/view", new VideoViewFactory(pluginBinding.getBinaryMessenger(),activityPluginBinding.getActivity()));
     }
   
     @Override
     public void onDetachedFromActivityForConfigChanges() {
   
     }
   
     @Override
     public void onReattachedToActivityForConfigChanges(ActivityPluginBinding activityPluginBinding) {
   
     }
   
     @Override
     public void onDetachedFromActivity() {
   
     }
   
     @Override
     public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
       if (call.method.equals("getPlatformVersion")) {
         result.success("Android " + android.os.Build.VERSION.RELEASE);
       } else {
         result.notImplemented();
       }
     }
   
     @Override
     public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
     }
   }
   ```

3. 新建布局文件video.xml

   ```xml
   <?xml version="1.0" encoding="utf-8"?>
   <com.shuyu.gsyvideoplayer.video.StandardGSYVideoPlayer
       xmlns:android="http://schemas.android.com/apk/res/android"
       android:id="@+id/jz_video"
       android:layout_width="match_parent"
       android:layout_height="match_parent" />
   ```

   

4. 创建VideoView类并实现PlatformView接口，然后实现一个最重要的方法getView()返回一个android的view，即可使这个view显示在flutter中，VideoView大致如下

   ```java
   public class VideoView implements PlatformView,MethodCallHandler {
       private StandardGSYVideoPlayer bmsVideo;
       private OrientationUtils orientationUtils;
       private GSYVideoOptionBuilder gsyVideoOption;
       private final MethodChannel methodChannel;
       private final BinaryMessenger messenger;
       private final Activity activity;
   
       VideoView(Context context, int viewId, Object args,BinaryMessenger messenger,Activity activity) {
           this.messenger = messenger;
           this.activity = activity;
   
           this.methodChannel = new MethodChannel(messenger, "flutter_videoplayer_channel");
           this.methodChannel.setMethodCallHandler(this);
   
           PlayerFactory.setPlayManager(Exo2PlayerManager.class);//EXO模式
           ExoSourceManager.setSkipSSLChain(true);
           bmsVideo = (StandardGSYVideoPlayer) LayoutInflater.from(activity).inflate(R.layout.video, null);
           bmsVideo.setShrinkImageRes(R.drawable.custom_shrink);
           bmsVideo.setEnlargeImageRes(R.drawable.custom_enlarge);
       }
   
       @Override
       public View getView() {
           return bmsVideo;
       }
   
       @Override
       public void onMethodCall(MethodCall methodCall, MethodChannel.Result result) {
           switch (methodCall.method) {
               case "loadUrl":
                   String url = methodCall.argument("playUrl");
                   String title = methodCall.argument("title");
                   getBmsVideo(url,title);
                   break;
               default:
                   result.notImplemented();
           }
       }
   
       @Override
       public void dispose() {
   //        GSYExoVideoManager.releaseAllVideos();
           GSYVideoManager.releaseAllVideos();
       }
   
       private void getBmsVideo(String url,String title) {
           // 初始化
           //设置旋转
           orientationUtils = new OrientationUtils(activity, bmsVideo);
   
           //是否可以滑动调整
           bmsVideo.setIsTouchWiget(true);
           //设置返回按键
           bmsVideo.getBackButton().setVisibility(View.VISIBLE);
   
           //初始化不打开外部的旋转
           orientationUtils.setEnable(false);
   
           Map<String,String> headers = new HashMap();
           headers.put("User-Agent","custumAgent");
           gsyVideoOption = new GSYVideoOptionBuilder();
           gsyVideoOption.setIsTouchWiget(true)
                   .setRotateViewAuto(false)
                   .setLockLand(false)
                   .setAutoFullWithSize(false)
                   .setShowFullAnimation(false)
                   .setNeedLockFull(true)
                   .setUrl(url)
                   .setSetUpLazy(true)
                   .setVideoTitle(title)
                   .setCacheWithPlay(false)
                   .setSeekRatio(3)
                   .setMapHeadData(headers)
                   .setVideoAllCallBack(new GSYSampleCallBack() {
                       @Override
                       public void onPrepared(String url, Object... objects) {
                           super.onPrepared(url, objects);
                           //开始播放了才能旋转和全屏
                           orientationUtils.setEnable(true);
                           // isPlay = true;
                       }
   
                       @Override
                       public void onQuitFullscreen(String url, Object... objects) {
                           super.onQuitFullscreen(url, objects);
                           if (orientationUtils != null) {
                               orientationUtils.backToProtVideo();
                           }
                       }
                   }).setLockClickListener(new LockClickListener() {
               @Override
               public void onClick(View view, boolean lock) {
                   if (orientationUtils != null) {
                       //配合下方的onConfigurationChanged
                       orientationUtils.setEnable(!lock);
                   }
               }
           }).build(bmsVideo);
           bmsVideo.startPlayLogic();
       }
   }
   ```

   

5. 然后创建一个VideoViewFactory继承自PlatformViewFactory

   ````java
   public class VideoViewFactory extends PlatformViewFactory {
       private final BinaryMessenger messenger;
       private final Activity activity;
   
       public VideoViewFactory(BinaryMessenger messenger,Activity activity) {
           super(StandardMessageCodec.INSTANCE);
           this.messenger = messenger;
           this.activity = activity;
       }
   
       @Override
       public PlatformView create(Context context, int viewId, Object args) {
           return new VideoView(context, viewId, args, this.messenger,this.activity);
       }
   }
   ````

   以上基本就实现了android端的视频播放器了

   

   ###### iOS端

   在iOS端将会使用ZFPlayer来实现视频播放功能

   1. 在github中下载ZFPlayer源码，拷贝代码到工程iOS目录下的ZFPlayer目录下面，将ZFPlayer所需的资源文件拷贝到Assets目录下，并编辑flutter_videoplayer.podspec文件添加如下代码

      ```shell
      s.resource_bundles = {
          'ZFPlayer' => ['Assets/*.png']
        }
      ```

   2. 创建FlutterVideoController类，继承自NSObject需要实现FlutterPlatformView协议，FlutterPlatformView协议中有一个必须要实现的方法- (UIView*)view，实现之后即可将UIView显示在Flutter中。

      ```objective-c
      @interface FlutterVideoController()
      
      @property (nonatomic, strong) ZFPlayerController *player;
      @property (nonatomic, strong) UIImageView *containerView;
      @property (nonatomic, strong) ZFPlayerControlView *controlView;
      @property (nonatomic, strong) FlutterMethodChannel *channel;
      @property (nonatomic, assign) int64_t viewId;
      @property (nonatomic, assign) NSInteger lastPosition;
      
      @end
      
      @implementation FlutterVideoController
      
      - (instancetype)initWithWithFrame:(CGRect)frame
                         viewIdentifier:(int64_t)viewId
                              arguments:(id _Nullable)args
                        binaryMessenger:(NSObject<FlutterBinaryMessenger>*)messenger {
        if ([super init]) {
          _viewId = viewId;
          NSString* channelName = [NSString stringWithFormat:@"flutter_videoplayer_channel"];
          FlutterMethodChannel *channel = [FlutterMethodChannel methodChannelWithName:channelName binaryMessenger:messenger];
          __weak __typeof__(self) weakSelf = self;
          [channel setMethodCallHandler:^(FlutterMethodCall* call, FlutterResult result) {
            [weakSelf onMethodCall:call result:result];
          }];
          _channel = channel;
        }
        return self;
      }
      
      - (UIView*)view {
        return self.containerView;
      }
      
      - (void)onMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
        if ([[call method] isEqualToString:@"loadUrl"]) {
           NSDictionary* param = [call arguments];
           NSString *playUrl = [param objectForKey:@"playUrl"];
      //     NSString *imageUrl = param[@"imageUrl"];
           NSString *title = param[@"title"];
          [self.player stop];
          self.player.assetURL = [NSURL URLWithString:playUrl];
          [self.player playTheIndex:0];
          [self.controlView showTitle:title coverURLString:nil fullScreenMode:ZFFullScreenModeAutomatic];
          [self onLoadUrl:call result:result];
        }else {
          result(FlutterMethodNotImplemented);
        }
      }
      
      - (void)onLoadUrl:(FlutterMethodCall*)call result:(FlutterResult)result {
        NSDictionary* param = [call arguments];
        NSString *url = [param objectForKey:@"playUrl"];
        if (![self loadUrl:url]) {
          result([FlutterError errorWithCode:@"loadUrl_failed"
                                     message:@"Failed parsing the URL"
                                     details:[NSString stringWithFormat:@"URL was: '%@'", url]]);
        } else {
          result(nil);
        }
      }
      
      - (bool)loadUrl:(NSString*)url {
        NSURL* nsUrl = [NSURL URLWithString:url];
        if (!nsUrl) {
          return false;
        }
        return true;
      }
      
      - (ZFPlayerController*)player{
          if (!_player){
              ZFAVPlayerManager *playerManager = [[ZFAVPlayerManager alloc] init:YES];
              /// 播放器相关
              ZFPlayerController *player = [ZFPlayerController playerWithPlayerManager:playerManager containerView:self.containerView];
              player.controlView = self.controlView;
              /// 设置退到后台继续播放
              player.pauseWhenAppResignActive = NO;
              player.allowOrentitaionRotation = YES;
              player.statusBarHidden = NO;
              player.forceDeviceOrientation = YES;
      
              /// 播放完成
              __weak __typeof__(player) weakPlayer = player;
              player.playerDidToEnd = ^(id  _Nonnull asset) {
                  [weakPlayer.currentPlayerManager replay];
                  [weakPlayer playTheNext];
              };
      
              player.customAudioSession = YES;
              player.playerReadyToPlay = ^(id<ZFPlayerMediaPlayback>  _Nonnull asset, NSURL * _Nonnull assetURL) {
                  [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback withOptions:AVAudioSessionCategoryOptionAllowBluetooth error:nil];
                  [[AVAudioSession sharedInstance] setActive:YES error:nil];
              };
              @weakify(self)
              player.playerPlayTimeChanged = ^(id<ZFPlayerMediaPlayback>  _Nonnull asset, NSTimeInterval currentTime, NSTimeInterval duration) {
                  @strongify(self)
                  if (self.lastPosition != (int)currentTime){
                      [self.channel invokeMethod:@"position" arguments:@{@"current":@((int)currentTime),@"duration":@((int)duration)}];
                  }
                  self.lastPosition = (int)currentTime;
              };
              _player = player;
          }
          return _player;
      }
      
      - (ZFPlayerControlView *)controlView {
          if (!_controlView) {
              _controlView = [ZFPlayerControlView new];
              @weakify(self);
              _controlView.portraitControlView.backBtnCallback = ^(){
                  @strongify(self);
                  [self.channel invokeMethod:@"popPage" arguments:nil];
              };
              _controlView.fastViewAnimated = YES;
              _controlView.autoHiddenTimeInterval = 5;
              _controlView.autoFadeTimeInterval = 0.5;
              _controlView.prepareShowLoading = YES;
          }
          return _controlView;
      }
      
      - (UIImageView *)containerView {
          if (!_containerView) {
              _containerView = [UIImageView new];
          }
          return _containerView;
      }
      
      @end
      ```

      

   3. 然后再创建FlutterVideoFactory类，实现FlutterPlatformViewFactory协议，大致代码如下

      ```objective-c
      @implementation FlutterVideoFactory {
        NSObject<FlutterBinaryMessenger>* _messenger;
      }
      
      - (instancetype)initWithMessenger:(NSObject<FlutterBinaryMessenger>*)messenger {
        self = [super init];
        if (self) {
          _messenger = messenger;
        }
        return self;
      }
      
      - (NSObject<FlutterMessageCodec>*)createArgsCodec {
        return [FlutterStandardMessageCodec sharedInstance];
      }
      
      - (NSObject<FlutterPlatformView>*)createWithFrame:(CGRect)frame
                                         viewIdentifier:(int64_t)viewId
                                              arguments:(id _Nullable)args {
        FlutterVideoController* viewController =
            [[FlutterVideoController alloc] initWithWithFrame:frame
                                             viewIdentifier:viewId
                                                  arguments:args
                                            binaryMessenger:_messenger];
        return viewController;
      }
      
      @end
      ```

      

   4. 最后也是很重要的一步是在iOS的example宿主工程的info.plist文件中创建一个key值为io.flutter.embedded_views_preview，值为YES的文件，然后运行可以就可以正常的播放视频了

      以下分别是iOS和Android下的实现效果
   
      | ![](https://raw.githubusercontent.com/yhcflyy/FlutterPlugin/master/android.png) | ![](https://raw.githubusercontent.com/yhcflyy/FlutterPlugin/master/ios.png)     |
   | ------------------------------------------------------------ | ---- |
      |                                                              |      |
   
   
   

#### 参考资源

https://www.jianshu.com/p/75ee04e64b28

https://flutter.dev/docs/development/packages-and-plugins/plugin-api-migration