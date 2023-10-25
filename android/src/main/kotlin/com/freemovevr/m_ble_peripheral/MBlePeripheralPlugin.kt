package com.freemovevr.m_ble_peripheral

import android.content.Context
import android.util.Log
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.EventChannel.EventSink
import io.flutter.plugin.common.EventChannel.StreamHandler
import io.flutter.plugin.common.MethodChannel

/** MBlePeripheralPlugin */
class MBlePeripheralPlugin : FlutterPlugin, ActivityAware {
    private lateinit var advertisingChannel: MethodChannel
    private lateinit var gattChannel: MethodChannel
    private lateinit var gattEventChannel: EventChannel
    private lateinit var context: Context
    private lateinit var advertisingHandler: AdvertisingHandler
    private lateinit var gattHandler: GattHandler

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        Log.d("MBlePeripheralPlugin", "onAttachedToEngine!")
        advertisingChannel = MethodChannel(flutterPluginBinding.binaryMessenger, "m:kbp/advertising")
        gattChannel = MethodChannel(flutterPluginBinding.binaryMessenger, "m:kbp/gatt")
        gattEventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "e:kbp/gatt")

    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        Log.d("MBlePeripheralPlugin", "onDetachedFromEngine")
        advertisingChannel.setMethodCallHandler(null)
        gattChannel.setMethodCallHandler(null)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        Log.d("MBlePeripheralPlugin", "onAttachedToActivity!!")
        context = binding.activity
        advertisingHandler = AdvertisingHandler(context)
        gattHandler = GattHandler(context)

        advertisingChannel.setMethodCallHandler(advertisingHandler)
        gattChannel.setMethodCallHandler(gattHandler)

        gattEventChannel.setStreamHandler(object : StreamHandler {
            override fun onListen(arguments: Any?, events: EventSink) {
                gattHandler.eventSink = events
            }

            override fun onCancel(arguments: Any?) {
                gattHandler.eventSink = null
            }
        })
    }

    override fun onDetachedFromActivityForConfigChanges() {
        Log.d("MBlePeripheralPlugin", "onDetachedFromActivityForConfigChanges")
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        Log.d("MBlePeripheralPlugin", "onReattachedToActivityForConfigChanges")
    }

    override fun onDetachedFromActivity() {
        Log.d("MBlePeripheralPlugin", "onDetachedFromActivity")
    }
}
