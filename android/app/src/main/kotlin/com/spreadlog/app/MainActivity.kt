package com.spreadlog.app

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream
import android.app.Activity
import android.util.Log
import com.google.mlkit.vision.documentscanner.GmsDocumentScannerOptions
import com.google.mlkit.vision.documentscanner.GmsDocumentScanning
import com.google.mlkit.vision.documentscanner.GmsDocumentScanningResult

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.spreadlog.app/backup_intent"
    private var pendingBackupPath: String? = null
    private var methodChannel: MethodChannel? = null
    private var backupListenerReady = false
    private var scanResult: MethodChannel.Result? = null

    private fun startScan(manual: Boolean, result: MethodChannel.Result) {
        if (scanResult != null) {
            result.error("ALREADY_ACTIVE", "A scan is already in progress", null)
            return
        }
        scanResult = result
        try {
            if (manual) {
                val intent = Intent().setClassName(this,
                    "biz.cunning.cunning_document_scanner.fallback.DocumentScannerActivity")
                intent.putExtra("maxNumDocuments", 20)
                startActivityForResult(intent, 7102)
            } else {
                val options = GmsDocumentScannerOptions.Builder()
                    .setPageLimit(20).setGalleryImportAllowed(true)
                    .setResultFormats(GmsDocumentScannerOptions.RESULT_FORMAT_JPEG)
                    .setScannerMode(GmsDocumentScannerOptions.SCANNER_MODE_FULL).build()
                GmsDocumentScanning.getClient(options).getStartScanIntent(this)
                    .addOnSuccessListener { sender ->
                        try {
                            startIntentSenderForResult(sender, 7101, null, 0, 0, 0)
                        } catch (e: Exception) { failScan(e) }
                    }.addOnFailureListener { e -> failScan(e) }
            }
        } catch (e: Exception) { failScan(e) }
    }

    private fun failScan(e: Exception) {
        Log.e("SpreadlogScanner", "Scanner initialization failed", e)
        scanResult?.error("SCANNER_UNAVAILABLE", e.message ?: e.javaClass.simpleName,
            mapOf("stackTrace" to Log.getStackTraceString(e)))
        scanResult = null
    }

    @Deprecated("Uses the activity result API required by the scanner plugin")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != 7101 && requestCode != 7102) return
        val result = scanResult ?: return
        scanResult = null
        if (resultCode != Activity.RESULT_OK) { result.success(emptyList<String>()); return }
        try {
            val paths = if (requestCode == 7102) {
                data?.getStringArrayListExtra("croppedImageResults")?.map { it.removePrefix("file://") }
                    ?: throw IllegalStateException("Manual scanner returned no images")
            } else {
                val pages = GmsDocumentScanningResult.fromActivityResultIntent(data)?.pages
                    ?: throw IllegalStateException("Automatic scanner returned no images")
                pages.map { page ->
                    val file = File.createTempFile("scan_", ".jpg", cacheDir)
                    contentResolver.openInputStream(page.imageUri)?.use { input ->
                        file.outputStream().use { output -> input.copyTo(output) }
                    } ?: throw IllegalStateException("Cannot read scanned image")
                    file.absolutePath
                }
            }
            result.success(paths)
        } catch (e: Exception) {
            Log.e("SpreadlogScanner", "Cannot read scanner result", e)
            result.error("SCAN_READ_FAILED", e.message, null)
        }
    }

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
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.spreadlog.app/scanner")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "scanAutomatic" -> startScan(false, result)
                    "scanManual" -> startScan(true, result)
                    else -> result.notImplemented()
                }
            }

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
