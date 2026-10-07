package app.baadan.later

import android.content.ComponentName
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.ContactsContract
import android.provider.Settings
import androidx.activity.result.contract.ActivityResultContracts
import androidx.core.content.pm.ShortcutInfoCompat
import androidx.core.content.pm.ShortcutManagerCompat
import androidx.core.graphics.drawable.IconCompat
import app.baadan.later.billing.BazaarBilling
import app.baadan.later.widget.WidgetStore
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Hosts the Flutter UI and the small native surface of the app:
 *  - Share sheet / text-selection intake (untrusted input, validated here)
 *  - Widget & launcher-shortcut quick actions
 *  - Widget data, launcher icon switching, system settings shortcuts
 *  - Cafe Bazaar billing bridge
 */
class MainActivity : FlutterFragmentActivity() {

    private var channel: MethodChannel? = null
    private var billing: BazaarBilling? = null

    // Consumed exactly once by Dart via takeInitial*.
    private var pendingShare: Map<String, String?>? = null
    private var pendingAction: String? = null
    private var dartReady = false

    // Contact picker. The system picker returns a one-time read grant for the
    // single contact the user chose, so no READ_CONTACTS permission is needed.
    private var pendingContact: MethodChannel.Result? = null
    private val contactPicker = registerForActivityResult(ActivityResultContracts.PickContact()) { uri ->
        val cb = pendingContact
        pendingContact = null
        if (cb == null) return@registerForActivityResult
        if (uri == null) {
            cb.success(null)
            return@registerForActivityResult
        }
        try {
            contentResolver.query(
                uri,
                arrayOf(
                    ContactsContract.Contacts.DISPLAY_NAME,
                    ContactsContract.Contacts.LOOKUP_KEY,
                    ContactsContract.Contacts._ID,
                ),
                null, null, null,
            )?.use { c ->
                if (c.moveToFirst()) {
                    val name = c.getString(0) ?: ""
                    val lookup = c.getString(1)
                    val id = c.getLong(2)
                    val ref = if (lookup != null) ContactsContract.Contacts.getLookupUri(id, lookup).toString() else uri.toString()
                    cb.success(mapOf("name" to name, "uri" to ref))
                    return@registerForActivityResult
                }
            }
            cb.success(null)
        } catch (e: Exception) {
            cb.success(null)
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // A recreated activity (rotation etc.) must not re-import the same share.
        if (savedInstanceState == null) captureIntent(intent)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        channel = MethodChannel(messenger, CHANNEL).also { it.setMethodCallHandler(::onCall) }
        billing = BazaarBilling(this, messenger)
        current = java.lang.ref.WeakReference(this)
    }

    override fun onDestroy() {
        if (current?.get() === this) current = null
        super.onDestroy()
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        captureIntent(intent)
        // The app is already running: deliver right away.
        if (dartReady) {
            pendingShare?.let { channel?.invokeMethod("share", it); pendingShare = null }
            pendingAction?.let { channel?.invokeMethod("action", it); pendingAction = null }
        }
    }

    // ------------------------------------------------------------------ intents

    /** Extracts share / quick-action data from [intent] and neutralizes it. */
    private fun captureIntent(intent: Intent?) {
        if (intent == null) return
        when (intent.action) {
            Intent.ACTION_SEND -> {
                if (intent.type == "text/plain") {
                    val text = intent.getStringExtra(Intent.EXTRA_TEXT)
                    val subject = intent.getStringExtra(Intent.EXTRA_SUBJECT)
                        ?: intent.getStringExtra(Intent.EXTRA_TITLE)
                    if (!text.isNullOrBlank()) {
                        pendingShare = mapOf(
                            "text" to text.take(MAX_TEXT),
                            "subject" to subject?.take(MAX_SUBJECT),
                        )
                    }
                }
            }
            Intent.ACTION_PROCESS_TEXT -> {
                val text = intent.getCharSequenceExtra(Intent.EXTRA_PROCESS_TEXT)?.toString()
                if (!text.isNullOrBlank()) pendingShare = mapOf("text" to text.take(MAX_TEXT), "subject" to null)
            }
            ACTION_QUICK -> {
                val q = intent.getStringExtra("quick")
                if (q != null && (q in ALLOWED_ACTIONS || ITEM_ACTION.matches(q))) pendingAction = q
            }
        }
        // Do not keep the payload around (avoids re-processing and leaking it
        // through the recents / saved-state machinery).
        intent.action = Intent.ACTION_MAIN
        intent.removeExtra(Intent.EXTRA_TEXT)
        intent.removeExtra(Intent.EXTRA_SUBJECT)
        intent.removeExtra(Intent.EXTRA_PROCESS_TEXT)
        intent.removeExtra("quick")
    }

    // ------------------------------------------------------------------ channel

    private fun onCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "takeInitialShare" -> {
                dartReady = true
                val s = pendingShare
                pendingShare = null
                result.success(s)
            }
            "takeInitialAction" -> {
                val a = pendingAction
                pendingAction = null
                result.success(a)
            }
            "updateWidgets" -> {
                @Suppress("UNCHECKED_CAST")
                val map = call.arguments as? Map<String, Any?>
                if (map == null) {
                    result.success(false)
                } else {
                    WidgetStore.save(this, map)
                    result.success(true)
                }
            }
            "pickContact" -> {
                if (pendingContact != null) {
                    result.success(null)
                } else {
                    pendingContact = result
                    try {
                        contactPicker.launch(null)
                    } catch (e: Exception) {
                        pendingContact = null
                        result.success(null)
                    }
                }
            }
            "moveToBack" -> {
                result.success(moveTaskToBack(true))
            }
            "openContact" -> result.success(openContact(call.arguments as? String))
            "openBatterySettings" -> result.success(openBatterySettings())
            "openExactAlarmSettings" -> result.success(openExactAlarmSettings())
            "setLauncherIcon" -> result.success(setLauncherIcon(call.arguments as? String))
            "configureShortcuts" -> {
                @Suppress("UNCHECKED_CAST")
                result.success(configureShortcuts(call.arguments as? Map<String, String>))
            }
            else -> result.notImplemented()
        }
    }

    private fun openBatterySettings(): Boolean {
        val intents = listOf(
            Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS),
            Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.parse("package:$packageName")),
        )
        for (i in intents) {
            try {
                i.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                startActivity(i)
                return true
            } catch (_: Exception) {
            }
        }
        return false
    }

    /** Only address-book URIs are ever opened. */
    private fun openContact(uri: String?): Boolean {
        if (uri == null || !uri.startsWith("content://com.android.contacts/")) return false
        return try {
            startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(uri)).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
            true
        } catch (_: Exception) {
            false
        }
    }

    private fun openExactAlarmSettings(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) return false
        return try {
            startActivity(
                Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM, Uri.parse("package:$packageName"))
                    .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            )
            true
        } catch (_: Exception) {
            false
        }
    }

    /** Enables exactly one launcher alias (Pro icon customization). */
    private fun setLauncherIcon(variant: String?): Boolean {
        val target = ICON_ALIASES[variant] ?: return false
        val pm = packageManager
        return try {
            for ((_, name) in ICON_ALIASES) {
                val state = if (name == target) PackageManager.COMPONENT_ENABLED_STATE_ENABLED
                else PackageManager.COMPONENT_ENABLED_STATE_DISABLED
                val cn = ComponentName(this, "app.baadan.later.$name")
                if (pm.getComponentEnabledSetting(cn) != state) {
                    pm.setComponentEnabledSetting(cn, state, PackageManager.DONT_KILL_APP)
                }
            }
            true
        } catch (_: Exception) {
            false
        }
    }

    private fun configureShortcuts(labels: Map<String, String>?): Boolean {
        if (labels == null) return false
        return try {
            val defs = listOf(
                Triple("add", R.drawable.ic_shortcut_add, labels["add"]),
                Triple("pick", R.drawable.ic_shortcut_pick, labels["pick"]),
                Triple("search", R.drawable.ic_shortcut_search, labels["search"]),
            )
            val list = defs.mapNotNull { (id, icon, label) ->
                if (label.isNullOrBlank()) return@mapNotNull null
                ShortcutInfoCompat.Builder(this, id)
                    .setShortLabel(label)
                    .setLongLabel(label)
                    .setIcon(IconCompat.createWithResource(this, icon))
                    .setIntent(quickIntent(this, id))
                    .build()
            }
            ShortcutManagerCompat.setDynamicShortcuts(this, list)
            true
        } catch (_: Exception) {
            false
        }
    }

    companion object {
        const val CHANNEL = "app.baadan.later/platform"
        const val ACTION_QUICK = "app.baadan.later.QUICK"
        private const val MAX_TEXT = 20000
        private const val MAX_SUBJECT = 500
        private val ALLOWED_ACTIONS = setOf("add", "pick", "search", "open", "capture", "inbox")
        private val ITEM_ACTION = Regex("^item:[A-Za-z0-9_\\-]{1,64}$")

        @Volatile
        private var current: java.lang.ref.WeakReference<MainActivity>? = null

        /** Asks a running app to push fresh widget data (widget "refresh"). */
        fun requestWidgetRefresh(): Boolean {
            val a = current?.get() ?: return false
            a.runOnUiThread { a.channel?.invokeMethod("refreshWidgets", null) }
            return true
        }
        private val ICON_ALIASES = linkedMapOf(
            "classic" to "LauncherClassic",
            "teal" to "LauncherTeal",
            "rose" to "LauncherRose",
            "dark" to "LauncherDark",
        )

        /** Explicit intent into this app only (used by widgets and shortcuts). */
        fun quickIntent(context: android.content.Context, quick: String): Intent =
            Intent(context, MainActivity::class.java).apply {
                action = ACTION_QUICK
                putExtra("quick", quick)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
            }
    }
}
