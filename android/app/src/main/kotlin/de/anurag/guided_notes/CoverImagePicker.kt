package de.anurag.guided_notes

import android.app.Activity
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Matrix
import android.media.ExifInterface
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayInputStream
import java.io.ByteArrayOutputStream
import kotlin.math.max
import kotlin.math.roundToInt

/** Copies a bounded, oriented image into a small JPEG; never keeps URI permissions. */
class CoverImagePicker(private val activity: Activity, messenger: BinaryMessenger) {
    private var pending: MethodChannel.Result? = null
    private val request = 4201

    init {
        MethodChannel(messenger, "de.anurag.guided_notes/images").setMethodCallHandler { call, result ->
            if (call.method != "pick") result.notImplemented()
            else if (pending != null) result.error("busy", "Die Bildauswahl ist bereits geöffnet.", null)
            else {
                pending = result
                try {
                    activity.startActivityForResult(Intent(Intent.ACTION_OPEN_DOCUMENT)
                        .addCategory(Intent.CATEGORY_OPENABLE).setType("image/*"), request)
                } catch (_: Exception) {
                    pending = null
                    result.error("picker", "Die Bildauswahl ist nicht verfügbar.", null)
                }
            }
        }
    }

    fun dispose() {
        val result = pending
        pending = null
        result?.error("cancelled", "Bildauswahl durch App-Neustart abgebrochen.", null)
    }

    fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (requestCode != request) return
        val result = pending ?: return
        val uri = data?.data
        if (resultCode != Activity.RESULT_OK || uri == null) {
            pending = null
            result.success(null)
            return
        }
        Thread {
            try {
                val bytes = requireNotNull(activity.contentResolver.openInputStream(uri)).use { input ->
                    val output = ByteArrayOutputStream()
                    val buffer = ByteArray(8192)
                    while (true) {
                        val count = input.read(buffer)
                        if (count < 0) break
                        require(output.size() + count <= 20 * 1024 * 1024)
                        output.write(buffer, 0, count)
                    }
                    output.toByteArray()
                }
                val image = normalize(bytes)
                activity.runOnUiThread {
                    if (pending === result) {
                        pending = null
                        result.success(image)
                    }
                }
            } catch (_: Exception) {
                activity.runOnUiThread {
                    if (pending === result) {
                        pending = null
                        result.error("image", "Dieses Bild konnte nicht geladen werden. Bitte ein anderes Bild (höchstens 20 MB) wählen.", null)
                    }
                }
            }
        }.start()
    }

    private fun normalize(bytes: ByteArray): ByteArray {
        val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        BitmapFactory.decodeByteArray(bytes, 0, bytes.size, bounds)
        require(bounds.outWidth > 0 && bounds.outHeight > 0)
        require(bounds.outWidth.toLong() * bounds.outHeight <= 100_000_000L)
        var sample = 1
        while (max(bounds.outWidth, bounds.outHeight) / sample > 2560) sample *= 2
        var bitmap = requireNotNull(BitmapFactory.decodeByteArray(bytes, 0, bytes.size,
            BitmapFactory.Options().apply { inSampleSize = sample }))
        try {
            val orientation = try {
                ExifInterface(ByteArrayInputStream(bytes)).getAttributeInt(ExifInterface.TAG_ORIENTATION, 1)
            } catch (_: Exception) { 1 }
            val matrix = Matrix()
            when (orientation) {
                2 -> matrix.setScale(-1f, 1f)
                3 -> matrix.setRotate(180f)
                4 -> matrix.setScale(1f, -1f)
                5 -> { matrix.setRotate(90f); matrix.postScale(-1f, 1f) }
                6 -> matrix.setRotate(90f)
                7 -> { matrix.setRotate(-90f); matrix.postScale(-1f, 1f) }
                8 -> matrix.setRotate(-90f)
            }
            if (!matrix.isIdentity) {
                val oriented = Bitmap.createBitmap(bitmap, 0, 0, bitmap.width, bitmap.height, matrix, true)
                if (oriented !== bitmap) { bitmap.recycle(); bitmap = oriented }
            }
            val ratio = 1280f / max(bitmap.width, bitmap.height)
            if (ratio < 1) {
                val scaled = Bitmap.createScaledBitmap(bitmap, max(1, (bitmap.width * ratio).roundToInt()), max(1, (bitmap.height * ratio).roundToInt()), true)
                if (scaled !== bitmap) { bitmap.recycle(); bitmap = scaled }
            }
            for (quality in listOf(85, 70, 55, 40)) {
                val output = ByteArrayOutputStream()
                require(bitmap.compress(Bitmap.CompressFormat.JPEG, quality, output))
                if (output.size() <= 256 * 1024) return output.toByteArray()
            }
            throw IllegalArgumentException("size")
        } finally { bitmap.recycle() }
    }
}
