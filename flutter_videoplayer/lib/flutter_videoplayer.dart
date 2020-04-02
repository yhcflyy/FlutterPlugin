import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

typedef void FlutterVideoplayerCreatedCallback(
    FlutterVideoplayerController controller);

class FlutterVideoplayerController {
  MethodChannel _channel;

  FlutterVideoplayerController.init(int id) {
    _channel = new MethodChannel('flutter_videoplayer_channel');
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
