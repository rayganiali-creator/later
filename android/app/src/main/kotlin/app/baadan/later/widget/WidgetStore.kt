package app.baadan.later.widget

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import org.json.JSONArray
import org.json.JSONObject

/** Snapshot pushed from Dart; rendered by the widget providers. */
data class WidgetData(
    val count: Int,
    val pro: Boolean,
    val suggestion: String?,
    val items: List<String>,
    val strings: Map<String, String>,
) {
    fun str(key: String, fallback: String = ""): String = strings[key] ?: fallback
}

object WidgetStore {
    private const val PREFS = "later_widget"
    private const val KEY = "snapshot"

    fun save(context: Context, map: Map<String, Any?>) {
        val json = JSONObject()
        json.put("count", (map["count"] as? Number)?.toInt() ?: 0)
        json.put("pro", map["pro"] as? Boolean ?: false)
        json.put("suggestion", map["suggestion"] as? String)
        json.put("items", JSONArray((map["items"] as? List<*>)?.filterIsInstance<String>()?.take(4) ?: emptyList<String>()))
        val s = JSONObject()
        (map["strings"] as? Map<*, *>)?.forEach { (k, v) -> if (k is String && v is String) s.put(k, v) }
        json.put("strings", s)
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit().putString(KEY, json.toString()).apply()
        refreshAll(context)
    }

    fun load(context: Context): WidgetData? {
        val raw = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).getString(KEY, null) ?: return null
        return try {
            val j = JSONObject(raw)
            val items = j.optJSONArray("items")?.let { a -> (0 until a.length()).map { a.getString(it) } } ?: emptyList()
            val strings = j.optJSONObject("strings")?.let { o -> o.keys().asSequence().associateWith { o.getString(it) } } ?: emptyMap()
            WidgetData(
                count = j.optInt("count", 0),
                pro = j.optBoolean("pro", false),
                suggestion = if (j.isNull("suggestion")) null else j.optString("suggestion"),
                items = items,
                strings = strings,
            )
        } catch (_: Exception) {
            null
        }
    }

    fun refreshAll(context: Context) {
        val mgr = AppWidgetManager.getInstance(context)
        LaterWidgetProvider.update(context, mgr, mgr.getAppWidgetIds(ComponentName(context, LaterWidgetProvider::class.java)))
        LaterListWidgetProvider.update(context, mgr, mgr.getAppWidgetIds(ComponentName(context, LaterListWidgetProvider::class.java)))
    }
}
