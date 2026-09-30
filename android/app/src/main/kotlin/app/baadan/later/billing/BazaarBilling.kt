package app.baadan.later.billing

import android.content.pm.PackageManager
import androidx.fragment.app.FragmentActivity
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import ir.cafebazaar.poolakey.Connection
import ir.cafebazaar.poolakey.ConnectionState
import ir.cafebazaar.poolakey.Payment
import ir.cafebazaar.poolakey.config.PaymentConfiguration
import ir.cafebazaar.poolakey.config.SecurityCheck
import ir.cafebazaar.poolakey.entity.PurchaseInfo
import ir.cafebazaar.poolakey.entity.PurchaseState
import ir.cafebazaar.poolakey.request.PurchaseRequest
import java.util.UUID

/**
 * Cafe Bazaar in-app billing bridge (Poolakey).
 *
 * Products are consumable time packs (`later_pro_1m/3m/6m`). The app stacks
 * durations itself, so each purchase is consumed right after activation and
 * can be bought again. A random developer payload guards against replayed
 * results. The RSA key (Bazaar developer panel) is supplied by Dart via
 * `--dart-define=BAZAAR_RSA_KEY=...` and never stored in the repository.
 *
 * Needs the Bazaar app + a configured developer account; cannot be exercised
 * on an emulator without them.
 */
class BazaarBilling(
    private val activity: FragmentActivity,
    messenger: BinaryMessenger,
) : MethodChannel.MethodCallHandler {

    private val channel = MethodChannel(messenger, "app.baadan.later/billing")
    private var payment: Payment? = null
    private var connection: Connection? = null
    private var connectedKey: String? = null

    init {
        channel.setMethodCallHandler(this)
    }

    private fun bazaarInstalled(): Boolean = try {
        activity.packageManager.getPackageInfo("com.farsitel.bazaar", 0)
        true
    } catch (_: PackageManager.NameNotFoundException) {
        false
    }

    private fun withConnection(rsaKey: String, onReady: (Payment) -> Unit, onFail: (Throwable) -> Unit) {
        val existing = payment
        if (existing != null && connection?.getState() == ConnectionState.Connected && connectedKey == rsaKey) {
            onReady(existing)
            return
        }
        connection?.disconnect()
        val security = if (rsaKey.isBlank()) SecurityCheck.Disable else SecurityCheck.Enable(rsaKey)
        val p = Payment(activity, PaymentConfiguration(localSecurityCheck = security))
        payment = p
        connectedKey = rsaKey
        connection = p.connect {
            connectionSucceed { onReady(p) }
            connectionFailed { onFail(it) }
            disconnected { }
        }
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "isAvailable" -> result.success(bazaarInstalled())
            "purchase" -> purchase(call, result)
            "pending" -> pending(call, result)
            "consume" -> consume(call, result)
            else -> result.notImplemented()
        }
    }

    private fun purchase(call: MethodCall, result: MethodChannel.Result) {
        val sku = call.argument<String>("sku")
        val rsaKey = call.argument<String>("rsaKey") ?: ""
        if (sku.isNullOrBlank() || !bazaarInstalled()) {
            result.success(mapOf("status" to "unavailable"))
            return
        }
        val payload = UUID.randomUUID().toString()
        var answered = false
        fun answer(map: Map<String, Any?>) {
            if (!answered) {
                answered = true
                result.success(map)
            }
        }
        withConnection(rsaKey, { p ->
            p.purchaseProduct(
                registry = activity.activityResultRegistry,
                request = PurchaseRequest(productId = sku, payload = payload),
            ) {
                purchaseFlowBegan { }
                failedToBeginFlow { answer(mapOf("status" to "failed")) }
                purchaseCanceled { answer(mapOf("status" to "cancelled")) }
                purchaseFailed { answer(mapOf("status" to "failed")) }
                purchaseSucceed { info ->
                    if (info.purchaseState == PurchaseState.PURCHASED && info.payload == payload && info.productId == sku) {
                        answer(purchaseMap(info, "success"))
                    } else {
                        answer(mapOf("status" to "failed"))
                    }
                }
            }
        }, { answer(mapOf("status" to "unavailable")) })
    }

    private fun pending(call: MethodCall, result: MethodChannel.Result) {
        val rsaKey = call.argument<String>("rsaKey") ?: ""
        if (!bazaarInstalled()) {
            result.success(emptyList<Map<String, Any?>>())
            return
        }
        var answered = false
        fun answer(list: List<Map<String, Any?>>) {
            if (!answered) {
                answered = true
                result.success(list)
            }
        }
        withConnection(rsaKey, { p ->
            p.getPurchasedProducts {
                querySucceed { list ->
                    answer(list.filter { it.purchaseState == PurchaseState.PURCHASED }.map { purchaseMap(it, "success") })
                }
                queryFailed { answer(emptyList()) }
            }
        }, { answer(emptyList()) })
    }

    private fun consume(call: MethodCall, result: MethodChannel.Result) {
        val token = call.argument<String>("token")
        val rsaKey = call.argument<String>("rsaKey") ?: ""
        if (token.isNullOrBlank() || !bazaarInstalled()) {
            result.success(false)
            return
        }
        var answered = false
        fun answer(ok: Boolean) {
            if (!answered) {
                answered = true
                result.success(ok)
            }
        }
        withConnection(rsaKey, { p ->
            p.consumeProduct(token) {
                consumeSucceed { answer(true) }
                consumeFailed { answer(false) }
            }
        }, { answer(false) })
    }

    private fun purchaseMap(info: PurchaseInfo, status: String) = mapOf(
        "status" to status,
        "sku" to info.productId,
        "token" to info.purchaseToken,
        "orderId" to info.orderId,
        "purchaseTime" to info.purchaseTime,
    )
}
