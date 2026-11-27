package com.codecowboys.cc_core

import android.app.ActivityOptions
import android.content.ContentValues
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Log
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry
import java.util.concurrent.Executors

/// cc_core's Android half. Today only Suite Link (lib/src/suite_link):
/// handing a journal entry to Kick Rocks.
///
/// - `deliver`: quiet. Inserts the envelope into the receiver's
///   `<package>.suite` content provider, which files it in an inbox the
///   receiver drains when it next opens. No screen switch. Runs off the
///   main thread (it may cold-start the receiver's process). The provider
///   checks who's calling, so only Code Cowboys apps get in.
/// - `share`: loud. ACTION_SEND with the suite MIME type; the receiver
///   opens with the entry.
/// - `installed`: the first of the packages that's on the phone.
/// - Back-links: `<scheme>://open/<id>` (Kick Rocks' "Open in ...") is
///   kept until Dart reads it with `initialOpen`; an `open` call nudges a
///   running app. A link stays put while nobody listens (onboarding), and
///   one already read is never read again (Recents, recreation).
/// - Drafts: Kick Rocks' "Log this in…" (ACTION_SEND, suite MIME, into
///   the app's main activity) is kept the same way until Dart reads it
///   with `initialDraft`; a `draft` call nudges a running app. On
///   Android 14+ a share that says it's from anyone but Kick Rocks is
///   dropped. It only pre-fills a form the user still has to save.
class CcCorePlugin : FlutterPlugin, MethodChannel.MethodCallHandler, ActivityAware,
    PluginRegistry.NewIntentListener {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    private var activity: ActivityPluginBinding? = null
    private var pendingOpen: String? = null
    private var pendingDraft: String? = null
    private val io = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, "cc_core/suite_link")
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        io.shutdown()
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        val packages = call.argument<List<String>>("packages") ?: emptyList()
        when (call.method) {
            "installed" -> result.success(packages.firstOrNull(::isInstalled))
            "deliver" -> {
                val text = call.argument<String>("text") ?: ""
                io.execute {
                    val took = deliver(text, packages)
                    main.post { result.success(took) }
                }
            }
            "share" -> result.success(share(call.argument<String>("text") ?: "", packages))
            "initialOpen" -> {
                result.success(pendingOpen)
                pendingOpen = null
            }
            "initialDraft" -> {
                result.success(pendingDraft)
                pendingDraft = null
            }
            else -> result.notImplemented()
        }
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding
        binding.addOnNewIntentListener(this)
        takeLink(binding.activity.intent)?.let { pendingOpen = it }
        takeDraft(binding.activity.intent)?.let { pendingDraft = it }
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
        takeLink(intent)?.let {
            pendingOpen = it
            channel.invokeMethod("open", null)
        }
        takeDraft(intent)?.let {
            pendingDraft = it
            channel.invokeMethod("draft", null)
        }
        return false // let the app see the intent too
    }

    /// A Kick Rocks envelope from ACTION_SEND, once (same replay rules as
    /// [takeLink]). Android 14+ names the sender when it opted in (Kick
    /// Rocks does); a named sender that isn't Kick Rocks is refused.
    private fun takeDraft(intent: Intent?): String? {
        if (intent?.action != Intent.ACTION_SEND || intent.type != SUITE_MIME) return null
        if (intent.flags and Intent.FLAG_ACTIVITY_LAUNCHED_FROM_HISTORY != 0) return null
        if (intent.getBooleanExtra(SEEN, false)) return null
        intent.putExtra(SEEN, true)
        val text = intent.getStringExtra(Intent.EXTRA_TEXT) ?: return null
        if (text.length > 65536) return null
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            val from = activity?.activity?.launchedFromPackage
            if (from != null && from !in KICK_ROCKS) {
                Log.i(TAG, "suite draft from $from refused")
                return null
            }
        }
        return text
    }

    /// `<scheme>://open/<id>` from a VIEW intent, once. Relaunches from
    /// Recents replay the original intent; so can activity recreation.
    /// Both are skipped: the first by its flag, the second by a marker
    /// left on the intent the first time it's read.
    private fun takeLink(intent: Intent?): String? {
        val data = intent?.data ?: return null
        if (intent.action != Intent.ACTION_VIEW || data.host != "open") return null
        if (intent.flags and Intent.FLAG_ACTIVITY_LAUNCHED_FROM_HISTORY != 0) return null
        if (intent.getBooleanExtra(SEEN, false)) return null
        intent.putExtra(SEEN, true)
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
                // Android 14+: let the receiver see it's really us (Kick
                // Rocks refuses unverified shares there).
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                    context.startActivity(send, ActivityOptions.makeBasic().setShareIdentityEnabled(true).toBundle())
                } else {
                    context.startActivity(send)
                }
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
        const val SEEN = "cc_core.suite_link.seen"
        val KICK_ROCKS = setOf("com.codecowboys.kickrocks", "com.codecowboys.kickrocks.dev")
    }
}
