package de.anurag.guided_notes

import io.flutter.embedding.android.FlutterActivity
import android.app.Activity
import android.content.Intent
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.nio.ByteBuffer
import java.nio.charset.CodingErrorAction

class MainActivity : FlutterActivity() {
    private var pending: MethodChannel.Result? = null
    private var contents: String? = null
    private val limit = 10 * 1024 * 1024

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "de.anurag.guided_notes/backup")
            .setMethodCallHandler { call, result ->
                if (call.method != "save" && call.method != "open") {
                    result.notImplemented()
                } else if (pending != null) {
                    result.error("busy", "Ein Dateidialog ist bereits geöffnet.", null)
                } else {
                    val saving = call.method == "save"
                    val text = call.argument<String>("contents")
                    if (saving && (text == null || text.toByteArray(Charsets.UTF_8).size > limit)) {
                        result.error("size", "Ungültige Dateigröße.", null)
                    } else {
                        pending = result
                        contents = text
                        try {
                            val intent = Intent(if (saving) Intent.ACTION_CREATE_DOCUMENT else Intent.ACTION_OPEN_DOCUMENT)
                                .addCategory(Intent.CATEGORY_OPENABLE)
                                .setType(if (saving) "application/json" else "*/*")
                            if (saving) intent.putExtra(Intent.EXTRA_TITLE, "the-guide-backup.json")
                            startActivityForResult(intent, if (saving) 4101 else 4102)
                        } catch (_: Exception) {
                            pending = null
                            contents = null
                            result.error("picker", "Dateidialog nicht verfügbar.", null)
                        }
                    }
                }
            }
    }

    @Deprecated("Activity result bridge for Flutter")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != 4101 && requestCode != 4102) return
        val result = pending ?: return
        val text = contents
        val uri = data?.data
        if (resultCode != Activity.RESULT_OK || uri == null) {
            pending = null
            contents = null
            result.success(null)
            return
        }
        Thread {
            try {
                val value: Any = if (requestCode == 4101) {
                    val bytes = requireNotNull(text).toByteArray(Charsets.UTF_8)
                    requireNotNull(contentResolver.openOutputStream(uri, "wt")).use { it.write(bytes) }
                    true
                } else {
                    val bytes = requireNotNull(contentResolver.openInputStream(uri)).use { input ->
                        val output = java.io.ByteArrayOutputStream()
                        val buffer = ByteArray(8192)
                        while (true) {
                            val count = input.read(buffer)
                            if (count == -1) break
                            if (output.size() + count > limit) throw IllegalArgumentException("size")
                            output.write(buffer, 0, count)
                        }
                        output.toByteArray()
                    }
                    Charsets.UTF_8.newDecoder().onMalformedInput(CodingErrorAction.REPORT)
                        .decode(ByteBuffer.wrap(bytes)).toString()
                }
                runOnUiThread { pending = null; contents = null; result.success(value) }
            } catch (_: Exception) {
                runOnUiThread {
                    pending = null
                    contents = null
                    result.error("file", "Datei konnte nicht verarbeitet werden.", null)
                }
            }
        }.start()
    }
}
