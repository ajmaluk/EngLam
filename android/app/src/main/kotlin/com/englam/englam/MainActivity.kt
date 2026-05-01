package com.ajmal.englam

import android.content.Intent
import android.content.SharedPreferences
import android.provider.Settings
import android.view.inputmethod.InputMethodManager
import com.google.mlkit.vision.digitalink.recognition.Ink
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "englam/system_keyboard"
    private val settingsChannelName = "englam/settings"
    private val handwritingChannelName = "englam/handwriting"
    private val prefsName = "englam_prefs"
    private lateinit var handwritingRecognizer: HandwritingRecognizer

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        handwritingRecognizer = HandwritingRecognizer(applicationContext)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).setMethodCallHandler { call, result ->
            when (call.method) {
                "openImeSettings" -> {
                    startActivity(Intent(Settings.ACTION_INPUT_METHOD_SETTINGS).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
                    result.success(null)
                }
                "showImePicker" -> {
                    val imm = getSystemService(INPUT_METHOD_SERVICE) as InputMethodManager
                    imm.showInputMethodPicker()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, settingsChannelName).setMethodCallHandler { call, result ->
            when (call.method) {
                "setSettings" -> {
                    val args = call.arguments as? Map<*, *> ?: emptyMap<Any, Any>()
                    val prefs = getSharedPreferences(prefsName, MODE_PRIVATE)
                    val editor = prefs.edit()
                    args.forEach { (k, v) ->
                        val key = k as? String ?: return@forEach
                        when (v) {
                            is Boolean -> editor.putBoolean(key, v)
                            is Int -> editor.putInt(key, v)
                            is Double -> editor.putFloat(key, v.toFloat())
                            is String -> editor.putString(key, v)
                        }
                    }
                    editor.apply()
                    result.success(null)
                }
                "getSettings" -> {
                    val prefs: SharedPreferences = getSharedPreferences(prefsName, MODE_PRIVATE)
                    val out = hashMapOf<String, Any?>()
                    out["keyboardHeightFactor"] = prefs.getFloat("keyboardHeightFactor", 0.58f).toDouble()
                    out["showKeyBorders"] = prefs.getBoolean("showKeyBorders", false)
                    out["layoutMode"] = prefs.getString("layoutMode", "translit")
                    out["isMalayalamMode"] = prefs.getBoolean("isMalayalamMode", true)
                    result.success(out)
                }
                else -> result.notImplemented()
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, handwritingChannelName).setMethodCallHandler { call, result ->
            when (call.method) {
                "recognize" -> {
                    val args = call.arguments as? Map<*, *> ?: emptyMap<Any, Any>()
                    val strokes = args["strokes"] as? List<*> ?: emptyList<Any>()
                    val ink =
                        try {
                            buildInk(strokes)
                        } catch (_: Throwable) {
                            result.success(emptyList<String>())
                            return@setMethodCallHandler
                        }
                    handwritingRecognizer.recognize(
                        ink,
                        onResult = { out -> result.success(out) },
                        onError = { result.success(emptyList<String>()) },
                    )
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun buildInk(rawStrokes: List<*>): Ink {
        val ink = Ink.builder()
        for (s in rawStrokes) {
            val rawPoints = s as? List<*> ?: continue
            val strokeBuilder = Ink.Stroke.builder()
            for (p in rawPoints) {
                val m = p as? Map<*, *> ?: continue
                val x = (m["x"] as? Number)?.toFloat() ?: continue
                val y = (m["y"] as? Number)?.toFloat() ?: continue
                val t = (m["t"] as? Number)?.toLong() ?: 0L
                strokeBuilder.addPoint(Ink.Point.create(x, y, t))
            }
            ink.addStroke(strokeBuilder.build())
        }
        return ink.build()
    }
}
