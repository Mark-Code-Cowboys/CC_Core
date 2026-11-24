package com.codecowboys.cc_core

import android.content.ContentValues
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.util.Log
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.PluginRegistry
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/// cc_core's Android half. Today only Suite Link (lib/src/suite_link):
/// handing a journal entry to Kick Rocks.
///
/// - `deliver`: quiet. Inserts the envelope into the receiver's
///   `<package>.suite` content provider, which files it in an inbox the
///   receiver drains when it next opens. No screen switch. The provider
///   checks who's calling, so only Code Cowboys apps get in.
/// - `share`: loud. ACTION_SEND with the suite MIME type; the receiver
///   opens with the entry.
/// - `installed`: the first of the packages that's on the phone.
/// - Back-links: `<scheme>://open/<id>` (Kick Rocks' "Open in ...")
///   reaches Dart as `initialOpen` at launch, then `open` calls. Each app
///   declares its own scheme in its manifest.
class CcCorePlugin : FlutterPlugin, MethodChannel.MethodCallHandler, ActivityAware,
    PluginRegistry.NewIntentListener {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    private var activity: ActivityPluginBinding? = null
    private var initialOpen: String? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, "cc_core/suite_link")
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        val packages = call.argument<List<String>>("packages") ?: emptyList()
        when (call.method) {
            "initialOpen" -> {
                result.success(initialOpen)
                initialOpen = null
            }
            "installed" -> result.success(packages.firstOrNull(::isInstalled))
            "deliver" -> result.success(deliver(call.argument<String>("text") ?: "", packages))
            "share" -> result.success(share(call.argument<String>("text") ?: "", packages))
            else -> result.notImplemented()
        }
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding
        binding.addOnNewIntentListener(this)
        initialOpen = openLinkOf(binding.activity.intent)
    }

    override fun onDetachedFromActivityForConfigChanges() = onDetachedFromActivity()

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding
        binding.addOnNewIntentListener(this)
    }

    override fun onDetachedFromActivity() {
        activity?.removeOnNewIntentListener(this)
        activity = null
    }

    override fun onNewIntent(intent: Intent): Boolean {
        val link = openLinkOf(intent) ?: return false
        channel.invokeMethod("open", link)
        return true
    }

    /// `<scheme>://open/<id>` from a VIEW intent; anything else is the app's business.
    private fun openLinkOf(intent: Intent?): String? {
        val data = intent?.data ?: return null
        if (intent.action != Intent.ACTION_VIEW || data.host != "open") return null
        return data.toString()
    }

    private fun deliver(text: String, packages: List<String>): String? {
        for (pkg in packages) {
            if (!isInstalled(pkg)) continue
            try {
                val uri = Uri.parse("content://$pkg.suite/moments")
                val values = ContentValues().apply { put("envelope", text) }
                if (context.contentResolver.insert(uri, values) != null) return pkg
            } catch (e: Exception) {
                // An older build without the inbox, or it refused us.
                Log.i(TAG, "suite deliver to $pkg: ${e.message}")
            }
        }
        return null
    }

    private fun share(text: String, packages: List<String>): String? {
        for (pkg in packages) {
            val send = Intent(Intent.ACTION_SEND).apply {
                setPackage(pkg)
                type = SUITE_MIME
                putExtra(Intent.EXTRA_TEXT, text)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            if (send.resolveActivity(context.packageManager) == null) continue
            return try {
                context.startActivity(send)
                pkg
            } catch (e: Exception) {
                Log.i(TAG, "suite share to $pkg: ${e.message}")
                null
            }
        }
        return null
    }

    private fun isInstalled(pkg: String): Boolean = try {
        context.packageManager.getPackageInfo(pkg, 0)
        true
    } catch (e: PackageManager.NameNotFoundException) {
        false
    }

    private companion object {
        const val TAG = "SuiteLink"
        const val SUITE_MIME = "application/vnd.codecowboys.moment+json"
    }
}
