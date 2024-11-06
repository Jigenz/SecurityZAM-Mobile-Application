// android/app/src/main/kotlin/com/example/mobile_security_app/MainActivity.kt

package com.example.mobile_security_app

import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity: FlutterActivity() {
    private val CHANNEL = "mobile_security_app/root_detection"

    override fun configureFlutterEngine(flutterEngine: io.flutter.embedding.engine.FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
            call, result ->
            if (call.method == "isDeviceRooted") {
                val isRooted = isDeviceRooted()
                result.success(isRooted)
            } else {
                result.notImplemented()
            }
        }
    }

    private fun isDeviceRooted(): Boolean {
        return checkBuildTags() || checkSuBinary() || checkForDangerousApps() || checkForRWPaths() || checkForInstalledApps()
    }

    private fun checkBuildTags(): Boolean {
        val buildTags = android.os.Build.TAGS
        return buildTags != null && buildTags.contains("test-keys")
    }

    private fun checkSuBinary(): Boolean {
        val suPaths = arrayOf(
            "/system/app/Superuser.apk",
            "/sbin/su",
            "/system/bin/su",
            "/system/xbin/su",
            "/data/local/xbin/su",
            "/data/local/bin/su",
            "/system/sd/xbin/su",
            "/system/bin/failsafe/su",
            "/data/local/su"
        )
        for (path in suPaths) {
            if (File(path).exists()) return true
        }
        return false
    }

    private fun checkForDangerousApps(): Boolean {
        val dangerousApps = arrayOf(
            "com.noshufou.android.su",
            "com.thirdparty.superuser",
            "eu.chainfire.supersu",
            "com.koushikdutta.superuser",
            "com.zachspong.temprootremovejb",
            "com.ramdroid.appquarantine",
            "com.topjohnwu.magisk"
        )
        val packageManager = this.packageManager
        for (app in dangerousApps) {
            try {
                packageManager.getPackageInfo(app, 0)
                return true
            } catch (e: Exception) {
                // App not found
            }
        }
        return false
    }

    private fun checkForRWPaths(): Boolean {
        val paths = arrayOf(
            "/system",
            "/system/bin",
            "/system/sbin",
            "/system/xbin",
            "/data",
            "/data/local",
            "/data/local/bin",
            "/data/local/xbin",
            "/data/local/tmp",
            "/data/tmp",
            "/dev",
            "/proc",
            "/sys",
            "/vendor"
        )
        for (path in paths) {
            val file = File(path)
            if (file.exists() && file.canWrite()) {
                return true
            }
        }
        return false
    }

    private fun checkForInstalledApps(): Boolean {
        val suspiciousApps = arrayOf(
            "com.noshufou.android.su",
            "com.thirdparty.superuser",
            "eu.chainfire.supersu",
            "com.koushikdutta.superuser",
            "com.zachspong.temprootremovejb",
            "com.ramdroid.appquarantine",
            "com.topjohnwu.magisk",
            "com.kingroot.kinguser",
            "com.stealthy.hook",
            "com.eltechs.axs",
            "com.hammerpig.rootkit"
        )
        val packageManager = this.packageManager
        for (app in suspiciousApps) {
            try {
                packageManager.getPackageInfo(app, 0)
                return true
            } catch (e: Exception) {
                // App not found
            }
        }
        return false
    }
}
