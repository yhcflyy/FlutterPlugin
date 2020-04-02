package com.test.flutter_videoplayer;
import android.app.Activity;
import android.content.Context;
import android.view.View;
import android.view.LayoutInflater;
import android.widget.TextView;
import android.util.Log;
import android.os.Handler;

import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import static io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import static io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry.Registrar;
import io.flutter.plugin.platform.PlatformView;

import com.shuyu.gsyvideoplayer.GSYVideoManager;
import com.shuyu.gsyvideoplayer.utils.OrientationUtils;
import com.shuyu.gsyvideoplayer.video.StandardGSYVideoPlayer;
import com.shuyu.gsyvideoplayer.listener.GSYSampleCallBack;
import com.shuyu.gsyvideoplayer.listener.LockClickListener;
import com.shuyu.gsyvideoplayer.builder.GSYVideoOptionBuilder;
import com.shuyu.gsyvideoplayer.player.PlayerFactory;
import com.shuyu.gsyvideoplayer.listener.GSYVideoProgressListener;

import tv.danmaku.ijk.media.exo2.ExoSourceManager;
import tv.danmaku.ijk.media.exo2.Exo2PlayerManager;

import java.util.HashMap;
import java.util.Map;

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
