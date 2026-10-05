package com.spreadlog.app

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.spreadlog.app/backup_intent"
    private var pendingBackupPath: String? = null
    private var methodChannel: MethodChannel? = null
    private var backupListenerReady = false

    override fun getInitialRoute(): String {
        return "/"
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handleIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        handleIntent(intent)
        // Prevent Flutter engine from pushing raw content:// URIs to the Navigator
        val sanitizedIntent = Intent(intent).apply { data = null }
        super.onNewIntent(sanitizedIntent)
    }

    private fun handleIntent(intent: Intent?) {
        if (intent == null) return
        val action = intent.action
        if (action != Intent.ACTION_VIEW && action != Intent.ACTION_SEND) return

        @Suppress("DEPRECATION")
        val uri: Uri = if (action == Intent.ACTION_SEND) {
            intent.getParcelableExtra<Uri>(Intent.EXTRA_STREAM) ?: intent.data
        } else {
            intent.data
        } ?: return

        try {
            var fileName = "incoming_backup.spbackup"
            if (uri.scheme == "content") {
                contentResolver.query(uri, null, null, null, null)?.use { cursor ->
                    val nameIndex = cursor.getColumnIndex(android.provider.OpenableColumns.DISPLAY_NAME)
                    if (nameIndex != -1 && cursor.moveToFirst()) {
                        val name = cursor.getString(nameIndex)
                        if (!name.isNullOrBlank()) {
                            fileName = File(name).name
                        }
                    }
                }
            } else if (!uri.lastPathSegment.isNullOrBlank()) {
                fileName = File(uri.lastPathSegment!!).name
            }

            contentResolver.openInputStream(uri)?.buffered()?.use { inputStream ->
                val header = ByteArray(4)
                var offset = 0
                while (offset < header.size) {
                    val read = inputStream.read(header, offset, header.size - offset)
                    if (read < 0) return
                    offset += read
                }
                if (!header.contentEquals(byteArrayOf(0x53, 0x50, 0x42, 0x4b))) return
                val cacheFile = File.createTempFile("incoming_", ".spbackup", cacheDir)
                FileOutputStream(cacheFile).use { outputStream ->
                    outputStream.write(header)
                    inputStream.copyTo(outputStream)
                }
                val path = cacheFile.absolutePath
                if (backupListenerReady) {
                    methodChannel?.invokeMethod("onBackupFileReceived", path)
                } else {
                    pendingBackupPath = path
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel = channel

        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "getPendingBackupPath" -> {
                    backupListenerReady = true
                    val path = pendingBackupPath
                    pendingBackupPath = null
                    result.success(path)
                }
                else -> result.notImplemented()
            }
        }

        pendingBackupPath?.let { path ->
            channel.invokeMethod("onBackupFileReceived", path)
        }
    }
}
