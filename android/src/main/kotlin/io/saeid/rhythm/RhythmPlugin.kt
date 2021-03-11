package io.saeid.rhythm

import android.content.pm.PackageManager
import android.os.Handler
import android.os.Looper
import androidx.annotation.NonNull
import be.tarsos.dsp.AudioDispatcher
import be.tarsos.dsp.io.android.AudioDispatcherFactory
import be.tarsos.dsp.pitch.PitchDetectionHandler
import be.tarsos.dsp.pitch.PitchProcessor
import be.tarsos.dsp.pitch.PitchProcessor.PitchEstimationAlgorithm
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry

/** RhythmPlugin */
class RhythmPlugin : FlutterPlugin, MethodCallHandler, PluginRegistry.RequestPermissionsResultListener, ActivityAware {

    private lateinit var channel: MethodChannel
    private var audioDispatcher: AudioDispatcher? = null
    private val mainThread = Handler(Looper.getMainLooper())

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "rhythm")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        when (call.method) {
            "startPitchDetection" -> {
                audioDispatcher?.stop()
                val tuning = call.argument<List<String>>("tuning");
                val audioSource = call.argument<Int>("audioSource");
                val sampleRate = call.argument<Int>("sampleRate");
                val audioBufferSize = call.argument<Int>("audioBufferSize");
                val bufferOverlap = call.argument<Int>("bufferOverlap");

                audioDispatcher = AudioDispatcherFactory.fromDefaultMicrophone(sampleRate!!, audioBufferSize!!, bufferOverlap!!)

                val pitchHandler = PitchDetectionHandler { pitchResult, audioEvent ->
                    val pitchInHz = pitchResult.pitch
                    mainThread.post {
                        channel.invokeMethod("onPitchUpdatesReceived", listOf(pitchInHz))
                    }
                }

                val pitchProcessor = PitchProcessor(PitchEstimationAlgorithm.FFT_YIN, sampleRate.toFloat(), audioBufferSize, pitchHandler)
                audioDispatcher?.addAudioProcessor(pitchProcessor)
                Thread(audioDispatcher, "Audio Dispatcher").start()
            }
            "disposePitchDetection" -> {
                audioDispatcher?.stop()
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<String>, grantResults: IntArray): Boolean {
        val requestAudioPermissionCode = 200
        when (requestCode) {
            requestAudioPermissionCode -> if (grantResults[0] == PackageManager.PERMISSION_GRANTED) return true
        }
        return false
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        binding.addRequestPermissionsResultListener(this)
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        binding.addRequestPermissionsResultListener(this)
    }

    override fun onDetachedFromActivityForConfigChanges() {}

    override fun onDetachedFromActivity() {}

}
