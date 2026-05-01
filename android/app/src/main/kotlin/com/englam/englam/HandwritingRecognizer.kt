package com.ajmal.englam

import android.content.Context
import com.google.mlkit.common.MlKitException
import com.google.mlkit.common.model.DownloadConditions
import com.google.mlkit.common.model.RemoteModelManager
import com.google.mlkit.vision.digitalink.common.RecognitionResult
import com.google.mlkit.vision.digitalink.recognition.DigitalInkRecognition
import com.google.mlkit.vision.digitalink.recognition.DigitalInkRecognitionModel
import com.google.mlkit.vision.digitalink.recognition.DigitalInkRecognitionModelIdentifier
import com.google.mlkit.vision.digitalink.recognition.DigitalInkRecognizerOptions
import com.google.mlkit.vision.digitalink.recognition.Ink

class HandwritingRecognizer(context: Context) {
    private val modelIdentifier: DigitalInkRecognitionModelIdentifier? =
        try {
            DigitalInkRecognitionModelIdentifier.fromLanguageTag("ml")
        } catch (_: MlKitException) {
            null
        }
            ?: try {
                DigitalInkRecognitionModelIdentifier.fromLanguageTag("ml-Mlym")
            } catch (_: MlKitException) {
                null
            }
            ?: try {
                DigitalInkRecognitionModelIdentifier.fromLanguageTag("ml-IN")
            } catch (_: MlKitException) {
                null
            }

    private val modelManager: RemoteModelManager = RemoteModelManager.getInstance()
    private val model: DigitalInkRecognitionModel? =
        modelIdentifier?.let { DigitalInkRecognitionModel.builder(it).build() }
    private val recognizer =
        model?.let { DigitalInkRecognition.getClient(DigitalInkRecognizerOptions.builder(it).build()) }

    fun ensureModel(onReady: (Boolean) -> Unit) {
        val m = model
        if (m == null) {
            onReady(false)
            return
        }
        modelManager
            .isModelDownloaded(m)
            .addOnSuccessListener { downloaded ->
                if (downloaded) {
                    onReady(true)
                    return@addOnSuccessListener
                }
                val conditions = DownloadConditions.Builder().build()
                modelManager
                    .download(m, conditions)
                    .addOnSuccessListener { onReady(true) }
                    .addOnFailureListener { onReady(false) }
            }.addOnFailureListener {
                onReady(false)
            }
    }

    fun recognize(ink: Ink, onResult: (List<String>) -> Unit, onError: (() -> Unit)? = null) {
        val r = recognizer
        if (r == null) {
            onError?.invoke()
            return
        }
        ensureModel { ok ->
            if (!ok) {
                onError?.invoke()
                return@ensureModel
            }
            r
                .recognize(ink)
                .addOnSuccessListener { result: RecognitionResult ->
                    val out = result.candidates.map { it.text }.distinct().take(10)
                    onResult(out)
                }.addOnFailureListener {
                    onError?.invoke()
                }
        }
    }
}
