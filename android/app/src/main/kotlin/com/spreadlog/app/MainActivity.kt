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

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handleIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent?) {
        if (intent == null || intent.action != Intent.ACTION_VIEW) return
        val uri: Uri = intent.data ?: return

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

            contentResolver.openInputStream(uri)?.use { inputStream ->
                val cacheFile = File(cacheDir, fileName)
                FileOutputStream(cacheFile).use { outputStream ->
                    inputStream.copyTo(outputStream)
                }
                val path = cacheFile.absolutePath
                pendingBackupPath = path
                methodChannel?.invokeMethod("onBackupFileReceived", path)
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
