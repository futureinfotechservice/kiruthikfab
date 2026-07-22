package com.example.kiruthikfab

import android.content.ActivityNotFoundException
import android.content.Intent
import android.net.Uri
import android.util.Log
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val CHANNEL = "kiruthikfab/whatsapp_share"
    private val TAG = "WhatsAppShare"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->
            if (call.method == "shareToWhatsApp") {
                val filePath = call.argument<String>("filePath")
                val message = call.argument<String>("message")
                val phone = call.argument<String>("phone")

                if (filePath == null) {
                    result.error("BAD_ARGS", "filePath is required", null)
                    return@setMethodCallHandler
                }

                try {
                    val file = File(filePath)

                    // Check if file exists
                    if (!file.exists()) {
                        result.error("FILE_NOT_FOUND", "PDF file not found at: $filePath", null)
                        return@setMethodCallHandler
                    }

                    // Get URI using FileProvider
                    val uri: Uri = FileProvider.getUriForFile(
                        this,
                        "$packageName.fileprovider",
                        file
                    )

                    Log.d(TAG, "Sharing file: $filePath, URI: $uri")

                    // Create intent with file attachment
                    val shareIntent = Intent(Intent.ACTION_SEND).apply {
                        type = "application/pdf"
                        putExtra(Intent.EXTRA_STREAM, uri)
                        putExtra(Intent.EXTRA_TEXT, message)
                        setPackage("com.whatsapp")
                        addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP)
                    }

                    startActivity(shareIntent)
                    result.success("FILE_ATTACHED")
                    Log.d(TAG, "WhatsApp opened with file attached")

                } catch (e: ActivityNotFoundException) {
                    Log.e(TAG, "WhatsApp not installed", e)
                    result.error("NOT_INSTALLED", "WhatsApp is not installed on this device", null)
                } catch (e: Exception) {
                    Log.e(TAG, "Share failed", e)
                    result.error("SHARE_FAILED", e.message ?: "Unknown error", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }
}