import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// ---------------------------------------------------------------------------
// Release signing. Secrets are NEVER stored in the repository:
//   * android/key.properties (git-ignored), or
//   * environment variables (CI): LATER_KEYSTORE_FILE, LATER_KEYSTORE_PASSWORD,
//     LATER_KEY_ALIAS, LATER_KEY_PASSWORD.
// See docs/RELEASE.md.
// ---------------------------------------------------------------------------
val keystoreProps = Properties().also { props ->
    val f = rootProject.file("key.properties")
    if (f.exists()) f.inputStream().use { props.load(it) }
}

fun signingValue(propKey: String, envKey: String): String? =
    (keystoreProps.getProperty(propKey) ?: System.getenv(envKey))?.takeIf { it.isNotBlank() }

val releaseStoreFile = signingValue("storeFile", "LATER_KEYSTORE_FILE")
val releaseStorePassword = signingValue("storePassword", "LATER_KEYSTORE_PASSWORD")
val releaseKeyAlias = signingValue("keyAlias", "LATER_KEY_ALIAS")
val releaseKeyPassword = signingValue("keyPassword", "LATER_KEY_PASSWORD")
val hasReleaseSigning = listOf(
    releaseStoreFile, releaseStorePassword, releaseKeyAlias, releaseKeyPassword
).all { it != null }

android {
    namespace = "app.baadan.later"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // Required by flutter_local_notifications (java.time on older Android).
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        applicationId = "app.baadan.later"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // versionCode / versionName come from pubspec.yaml (`version: x.y.z+n`).
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        // Myket billing (plugin myket_iap): which market app to bind to.
        manifestPlaceholders += mapOf(
            "marketApplicationId" to "ir.mservices.market",
            "marketBindAddress" to "ir.mservices.market.InAppBillingService.BIND",
            "marketPermission" to "ir.mservices.market.BILLING",
        )
    }

    flavorDimensions += "distribution"
    productFlavors {
        // What is uploaded to the market. No test tools.
        create("store") {
            dimension = "distribution"
        }
        // Same app, uploaded to Myket (in-app billing through Myket).
        create("myket") {
            dimension = "distribution"
        }
        // Installable test build side-by-side with the store app. Enables the
        // QA tools (Pro simulation, time travel, sample data...).
        create("qa") {
            dimension = "distribution"
            applicationIdSuffix = ".qa"
            versionNameSuffix = "-qa"
        }
    }

    // Cafe Bazaar billing code (Poolakey) is only part of the Bazaar builds.
    sourceSets {
        getByName("store").java.srcDir("src/bazaar/kotlin")
        getByName("qa").java.srcDir("src/bazaar/kotlin")
    }

    signingConfigs {
        create("release") {
            if (hasReleaseSigning) {
                storeFile = file(releaseStoreFile!!)
                storePassword = releaseStorePassword
                keyAlias = releaseKeyAlias
                keyPassword = releaseKeyPassword
            }
        }
    }

    buildTypes {
        release {
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
            // A store release is refused below unless real signing is configured.
            // (QA release builds fall back to the debug key so they stay installable.)
            signingConfig = if (hasReleaseSigning) signingConfigs.getByName("release")
            else signingConfigs.getByName("debug")
        }
    }

    lint {
        // Lint is run explicitly in CI (`./gradlew lintStoreRelease`).
        checkReleaseBuilds = false
        abortOnError = true
    }

    packaging {
        resources.excludes += setOf("/META-INF/{AL2.0,LGPL2.1}")
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
    implementation("androidx.core:core-ktx:1.16.0")
    implementation("androidx.fragment:fragment-ktx:1.8.6")
    // Cafe Bazaar in-app billing (not in the Myket build: both billing
    // libraries contain the same AIDL class, so each build takes only its own).
    "storeImplementation"("com.github.cafebazaar.Poolakey:poolakey:2.2.0")
    "qaImplementation"("com.github.cafebazaar.Poolakey:poolakey:2.2.0")
}

// The myket_iap plugin pulls in Myket's billing client for every build; only
// the Myket build uses it.
configurations.matching { it.name.startsWith("store") || it.name.startsWith("qa") }.configureEach {
    exclude(group = "com.github.myketstore", module = "myket-billing-client")
}

// Guard rail: a store release must never be signed with the debug key.
gradle.taskGraph.whenReady {
    val storeRelease = allTasks.any {
        it.project == project && Regex("(assemble|bundle|package)(Store|Myket)Release").matches(it.name)
    }
    if (storeRelease && !hasReleaseSigning) {
        throw GradleException(
            "Release signing is not configured. Provide android/key.properties or the " +
                "LATER_KEYSTORE_* environment variables (see docs/RELEASE.md)."
        )
    }
}
