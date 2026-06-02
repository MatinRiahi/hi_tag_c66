package com.example.hi_tag_c66

import android.content.Context
import android.media.AudioManager
import android.media.ToneGenerator
import android.os.Handler
import android.os.Looper
import androidx.annotation.NonNull
import com.rscja.deviceapi.RFIDWithUHFUART
import com.rscja.deviceapi.entity.UHFTAGInfo
import com.rscja.deviceapi.interfaces.IUHFInventoryCallback
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    // نام کانال‌ها - باید با کد دارت یکی باشه
    companion object {
        const val METHOD_CHANNEL = "com.hitag.rfid/methods"
        const val EVENT_CHANNEL = "com.hitag.rfid/events"
    }

    private var rfid: RFIDWithUHFUART? = null
    private var eventSink: EventChannel.EventSink? = null
    private val mainHandler = Handler(Looper.getMainLooper())

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // ── Method Channel ──────────────────────────────────────
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            METHOD_CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {

                "init" -> {
                    val success = initRFID()
                    result.success(success)
                }

                "startScan" -> {
                    val success = startScan()
                    result.success(success)
                }

                "stopScan" -> {
                    val success = stopScan()
                    result.success(success)
                }

                "free" -> {
                    val success = freeRFID()
                    result.success(success)
                }

                else -> result.notImplemented()
            }
        }

        // ── Event Channel (برای stream تگ‌ها) ───────────────────
        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            EVENT_CHANNEL
        ).setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, sink: EventChannel.EventSink?) {
                eventSink = sink
            }
            override fun onCancel(arguments: Any?) {
                eventSink = null
            }
        })
    }

    // ── توابع اصلی ───────────────────────────────────────────────

    private fun initRFID(): Boolean {
        return try {
            rfid = RFIDWithUHFUART.getInstance()
            rfid?.init(context) ?: false
        } catch (e: Exception) {
            false
        }
    }

    private fun startScan(): Boolean {
        return try {
            // ست کردن callback برای دریافت تگ‌ها
            rfid?.setInventoryCallback(IUHFInventoryCallback { uhfTagInfo ->
                uhfTagInfo?.let { tag ->
                    val epc = tag.epc ?: ""
                    val rssi = tag.rssi ?: ""

                    // بیپ بزن
                    playBeep()

                    // بفرست به فلاتر (باید روی main thread باشه)
                    mainHandler.post {
                        eventSink?.success(
                            mapOf(
                                "epc" to epc,
                                "rssi" to rssi
                            )
                        )
                    }
                }
            })

            rfid?.startInventoryTag() ?: false
        } catch (e: Exception) {
            false
        }
    }

    private fun stopScan(): Boolean {
        return try {
            rfid?.stopInventory() ?: false
        } catch (e: Exception) {
            false
        }
    }

    private fun freeRFID(): Boolean {
        return try {
            stopScan()
            rfid?.free() ?: false
        } catch (e: Exception) {
            false
        }
    }

    // ── صدای بیپ ─────────────────────────────────────────────────
    private fun playBeep() {
        try {
            val toneGen = ToneGenerator(AudioManager.STREAM_MUSIC, 100)
            toneGen.startTone(ToneGenerator.TONE_CDMA_PIP, 150)
        } catch (e: Exception) {
            // اگه صدا کار نکرد اپ کرش نکنه
        }
    }

    // ── lifecycle ────────────────────────────────────────────────
    override fun onDestroy() {
        freeRFID()
        super.onDestroy()
    }
}