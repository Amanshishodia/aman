package com.mercyott.app

import android.content.ContentResolver
import android.database.ContentObserver
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.mercyott.app/rotation"
    private val EVENT_CHANNEL = "com.mercyott.app/rotation_listener"
    private var rotationObserver: ContentObserver? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
    val resolver: ContentResolver = contentResolver

    // Send initial state when listener starts
    val isAutoRotateOn =
        Settings.System.getInt(resolver, Settings.System.ACCELEROMETER_ROTATION, 0) == 1
    events?.success(isAutoRotateOn) // Send initial state to Flutter
    println("Initial Auto-Rotate State Sent: $isAutoRotateOn")

    // Register observer for future changes
    rotationObserver = object : ContentObserver(Handler(Looper.getMainLooper())) {
        override fun onChange(selfChange: Boolean) {
            val updatedAutoRotateOn =
                Settings.System.getInt(resolver, Settings.System.ACCELEROMETER_ROTATION, 0) == 1
            println("📢 Auto-rotate changed: $updatedAutoRotateOn")
            events?.success(updatedAutoRotateOn)
        }
    }

    resolver.registerContentObserver(
        Settings.System.getUriFor(Settings.System.ACCELEROMETER_ROTATION),
        false,
        rotationObserver!!
    )
}


                override fun onCancel(arguments: Any?) {
                    rotationObserver?.let {
                        contentResolver.unregisterContentObserver(it)
                    }
                }
            })
    }
}
