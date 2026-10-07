package app.baadan.later.widget

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import org.json.JSONArray
import org.json.JSONObject
import java.util.Calendar

/** Snapshot pushed from Dart; rendered by the widget providers. */
data class TodayRow(val id: String, val title: String, val color: Int, val overdue: Boolean)

data class WidgetData(
    val count: Int,
    val pro: Boolean,
    val suggestion: String?,
    val suggestionId: String?,
    val items: List<String>,
    val counts: Map<String, Int>,
    val smartText: String?,
    val smartId: String?,
    val today: List<TodayRow>,
    val strings: Map<String, String>,
) {
    fun str(key: String, fallback: String = ""): String = strings[key] ?: fallback

    /** Counter shown with Persian digits when the app language is Persian. */
    fun num(n: Int): String {
        val s = n.toString()
        if (strings["fa"] != "1") return s
        return s.map { if (it in '0'..'9') ('۰' + (it - '0')) else it }.joinToString("")
    }

    /** True when the snapshot was written on another day: "today" is unknown. */
    fun isStaleDay(): Boolean {
        val day = strings["day"]?.toIntOrNull() ?: return false
        val c = Calendar.getInstance()
        val now = c.get(Calendar.YEAR) * 10000 + (c.get(Calendar.MONTH) + 1) * 100 + c.get(Calendar.DAY_OF_MONTH)
        return day != now
    }

    /** Today's rows; empty when the snapshot is from another day (we cannot know). */
    fun todayRows(): List<TodayRow> = if (isStaleDay()) emptyList() else today

    fun counter(key: String): String {
        if (key == "today" && isStaleDay()) return "—"
        return num(counts[key] ?: 0)
    }
}

object WidgetStore {
    private const val PREFS = "later_widget"
    private const val KEY = "snapshot"

    fun save(context: Context, map: Map<String, Any?>) {
        val json = JSONObject()
        json.put("count", (map["count"] as? Number)?.toInt() ?: 0)
        json.put("pro", map["pro"] as? Boolean ?: false)
        json.put("suggestion", map["suggestion"] as? String)
        json.put("suggestionId", map["suggestionId"] as? String)
        json.put("items", JSONArray((map["items"] as? List<*>)?.filterIsInstance<String>()?.take(4) ?: emptyList<String>()))
        val c = JSONObject()
        (map["counts"] as? Map<*, *>)?.forEach { (k, v) -> if (k is String && v is Number) c.put(k, v.toInt()) }
        json.put("counts", c)
        json.put("smartText", map["smartText"] as? String)
        json.put("smartId", map["smartId"] as? String)
        val t = JSONArray()
        (map["today"] as? List<*>)?.take(6)?.forEach { e ->
            val m = e as? Map<*, *> ?: return@forEach
            val id = m["id"] as? String ?: return@forEach
            val title = m["title"] as? String ?: return@forEach
            t.put(
                JSONObject().put("id", id).put("title", title)
                    .put("color", (m["color"] as? Number)?.toLong() ?: 0xFF5B4FD6L)
                    .put("overdue", m["overdue"] as? Boolean ?: false)
            )
        }
        json.put("today", t)
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
            val counts = j.optJSONObject("counts")?.let { o -> o.keys().asSequence().associateWith { o.getInt(it) } } ?: emptyMap()
            WidgetData(
                count = j.optInt("count", 0),
                pro = j.optBoolean("pro", false),
                suggestion = if (j.isNull("suggestion")) null else j.optString("suggestion"),
                suggestionId = if (j.isNull("suggestionId")) null else j.optString("suggestionId"),
                items = items,
                counts = counts,
                smartText = if (j.isNull("smartText")) null else j.optString("smartText"),
                smartId = if (j.isNull("smartId")) null else j.optString("smartId"),
                today = j.optJSONArray("today")?.let { a ->
                    (0 until a.length()).mapNotNull { i ->
                        val o = a.optJSONObject(i) ?: return@mapNotNull null
                        TodayRow(o.getString("id"), o.getString("title"), o.optLong("color", 0xFF5B4FD6L).toInt(), o.optBoolean("overdue", false))
                    }
                } ?: emptyList(),
                strings = strings,
            )
        } catch (_: Exception) {
            null
        }
    }

    private val providers = listOf(
        LaterWidgetProvider::class.java,
        LaterMediumWidgetProvider::class.java,
        LaterLargeWidgetProvider::class.java,
        LaterListWidgetProvider::class.java,
    )

    /** Redraws every placed widget from the last saved snapshot. */
    fun refreshAll(context: Context) {
        val mgr = AppWidgetManager.getInstance(context)
        for (cls in providers) {
            val ids = mgr.getAppWidgetIds(ComponentName(context, cls))
            if (ids.isEmpty()) continue
            when (cls) {
                LaterWidgetProvider::class.java -> LaterWidgetProvider.update(context, mgr, ids)
                LaterMediumWidgetProvider::class.java -> LaterMediumWidgetProvider.update(context, mgr, ids)
                LaterLargeWidgetProvider::class.java -> LaterLargeWidgetProvider.update(context, mgr, ids)
                LaterListWidgetProvider::class.java -> LaterListWidgetProvider.update(context, mgr, ids)
            }
        }
    }
}
