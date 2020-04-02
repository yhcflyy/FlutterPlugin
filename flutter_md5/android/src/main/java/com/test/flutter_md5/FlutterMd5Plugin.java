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
