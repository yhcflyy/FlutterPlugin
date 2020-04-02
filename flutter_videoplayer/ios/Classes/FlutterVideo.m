#import "FlutterVideo.h"
#import "ZFPlayer.h"
#import "ZFAVPlayerManager.h"
#import "ZFPlayerControlView.h"


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
