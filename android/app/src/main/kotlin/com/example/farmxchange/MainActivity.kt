package com.example.farmxchange

import android.content.ActivityNotFoundException
import android.content.Intent
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "farmxchange/whatsapp"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            channelName
        ).setMethodCallHandler { call, result ->
            if (call.method != "openWhatsApp") {
                result.notImplemented()
                return@setMethodCallHandler
            }

            val phone = call.argument<String>("phone").orEmpty()
            val message = call.argument<String>("message").orEmpty()
            val encodedMessage = Uri.encode(message)
            val uri = Uri.parse("https://wa.me/$phone?text=$encodedMessage")

            val packages = listOf("com.whatsapp", "com.whatsapp.w4b")

            for (packageName in packages) {
                try {
                    val whatsappIntent = Intent(Intent.ACTION_VIEW, uri).apply {
                        setPackage(packageName)
                    }
                    startActivity(whatsappIntent)
                    result.success(true)
                    return@setMethodCallHandler
                } catch (_: Exception) {
                }
            }

            try {
                startActivity(Intent(Intent.ACTION_VIEW, uri))
                result.success(true)
            } catch (_: ActivityNotFoundException) {
                result.success(false)
            }
        }
    }
}
