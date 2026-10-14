package app.baadan.later.billing

import androidx.fragment.app.FragmentActivity
import io.flutter.plugin.common.BinaryMessenger

/**
 * The Myket build has no Cafe Bazaar billing (its payments go through the
 * myket_iap plugin). This empty stand-in keeps the shared MainActivity code
 * identical for every build.
 */
@Suppress("UNUSED_PARAMETER")
class BazaarBilling(activity: FragmentActivity, messenger: BinaryMessenger)
