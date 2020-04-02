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
