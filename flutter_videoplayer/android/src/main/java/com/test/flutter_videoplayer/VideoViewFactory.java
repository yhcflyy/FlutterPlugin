package com.test.flutter_videoplayer;

import android.app.Activity;
import android.content.Context;
import com.test.flutter_videoplayer.VideoView;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.platform.PlatformView;
import io.flutter.plugin.common.StandardMessageCodec;
import io.flutter.plugin.platform.PlatformViewFactory;

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
