#import "FlutterVideoplayerPlugin.h"
#import "FlutterVideo.h"

@implementation FlutterVideoplayerPlugin

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  FlutterVideoFactory* viewFactory =
          [[FlutterVideoFactory alloc] initWithMessenger:registrar.messenger];
  [registrar registerViewFactory:viewFactory withId:@"plugins.fluttervideoplayer/view"];
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
  if ([@"getPlatformVersion" isEqualToString:call.method]) {
    result([@"iOS " stringByAppendingString:[[UIDevice currentDevice] systemVersion]]);
  } else {
    result(FlutterMethodNotImplemented);
  }
}

@end
