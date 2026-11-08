#!/usr/bin/env python3
"""Add the permission required to hand a verified APK to Android Package Installer."""
from pathlib import Path
import re
import sys

manifest = Path("android/app/src/main/AndroidManifest.xml")
if not manifest.is_file():
    print(f"Android manifest not found: {manifest}", file=sys.stderr)
    raise SystemExit(1)
text = manifest.read_text(encoding="utf-8")
permission = '    <uses-permission android:name="android.permission.REQUEST_INSTALL_PACKAGES" />'
if "android.permission.REQUEST_INSTALL_PACKAGES" not in text:
    updated, count = re.subn(r"(<manifest\b[^>]*>)", r"\1\n" + permission, text, count=1)
    if count != 1:
        print("Could not locate the manifest root element.", file=sys.stderr)
        raise SystemExit(1)
    manifest.write_text(updated, encoding="utf-8")
    print("Added REQUEST_INSTALL_PACKAGES.")
else:
    print("REQUEST_INSTALL_PACKAGES is already present.")

# Current Flutter plugins require Android API 36 at compile time. Keep targetSdk
# unchanged so this does not opt users into newer Android runtime behavior.
gradle_file = Path("android/app/build.gradle.kts")
if not gradle_file.is_file():
    print(f"Android app Gradle file not found: {gradle_file}", file=sys.stderr)
    raise SystemExit(1)
gradle_text = gradle_file.read_text(encoding="utf-8")
if "compileSdk = flutter.compileSdkVersion" in gradle_text:
    gradle_text = gradle_text.replace(
        "compileSdk = flutter.compileSdkVersion", "compileSdk = 36", 1
    )
elif re.search(r"compileSdk\s*=\s*\d+", gradle_text):
    gradle_text = re.sub(r"compileSdk\s*=\s*\d+", "compileSdk = 36", gradle_text, count=1)
else:
    print("Could not locate the Android compileSdk setting.", file=sys.stderr)
    raise SystemExit(1)
gradle_file.write_text(gradle_text, encoding="utf-8")
print("Configured Android compileSdk 36 for current plugin requirements.")


# AGP 9's new DSL is not yet compatible with Flutter's Gradle plugin and some
# older Flutter plugins. Opt into the legacy DSL until those dependencies are
# upgraded, then align Android library modules with compileSdk 36.
gradle_properties = Path("android/gradle.properties")
if not gradle_properties.is_file():
    print(f"Android Gradle properties not found: {gradle_properties}", file=sys.stderr)
    raise SystemExit(1)
properties_text = gradle_properties.read_text(encoding="utf-8")
if not re.search(r"(?m)^android\.newDsl\s*=", properties_text):
    properties_text += "\nandroid.newDsl=false\n"
else:
    properties_text = re.sub(
        r"(?m)^android\.newDsl\s*=.*$",
        "android.newDsl=false",
        properties_text,
        count=1,
    )
gradle_properties.write_text(properties_text, encoding="utf-8")
print("Disabled the incompatible AGP 9 new DSL for Flutter plugin compatibility.")

# Install a native verifier that compares the downloaded APK certificate with both
# the release manifest fingerprint and the currently installed application's signer.
main_activity = Path("android/app/src/main/kotlin/com/jarrlyyy/gtn_2/MainActivity.kt")
main_activity.parent.mkdir(parents=True, exist_ok=True)
main_activity.write_text(r'''package com.jarrlyyy.gtn_2

import android.content.pm.PackageInfo
import android.content.pm.PackageManager
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.security.MessageDigest

class MainActivity : FlutterActivity() {
    private val signingChannel = "com.jarrlyyy.gtn_2/signing"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, signingChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "verifyApkSigningCertificate" -> {
                        val apkPath = call.argument<String>("apkPath")
                        val expected = call.argument<String>("expectedCertificateSha256")
                        if (apkPath.isNullOrBlank() || expected.isNullOrBlank()) {
                            result.error("INVALID_ARGUMENT", "APK path and expected certificate are required.", null)
                        } else {
                            try {
                                result.success(verifyApkSigningCertificate(apkPath, expected))
                            } catch (error: Exception) {
                                result.error("SIGNATURE_CHECK_FAILED", error.message, null)
                            }
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    @Suppress("DEPRECATION")
    private fun verifyApkSigningCertificate(apkPath: String, expectedFingerprint: String): Boolean {
        val apk = File(apkPath)
        if (!apk.isFile || !apk.canRead()) return false

        val expected = normalizeFingerprint(expectedFingerprint) ?: return false
        val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            PackageManager.GET_SIGNING_CERTIFICATES
        } else {
            PackageManager.GET_SIGNATURES
        }

        val archivedInfo = packageManager.getPackageArchiveInfo(apk.absolutePath, flags) ?: return false
        if (archivedInfo.packageName != applicationContext.packageName) return false
        val installedInfo = packageManager.getPackageInfo(applicationContext.packageName, flags)

        val archivedFingerprint = certificateFingerprint(archivedInfo) ?: return false
        val installedFingerprint = certificateFingerprint(installedInfo) ?: return false
        return archivedFingerprint == expected && installedFingerprint == expected
    }

    @Suppress("DEPRECATION")
    private fun certificateFingerprint(info: PackageInfo): String? {
        val signatures = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            info.signingInfo?.apkContentsSigners
        } else {
            info.signatures
        } ?: return null

        // GTN2 distributes a single-signer APK. Reject ambiguous multi-signer packages.
        if (signatures.size != 1) return null
        val digest = MessageDigest.getInstance("SHA-256").digest(signatures[0].toByteArray())
        return digest.joinToString("") { byte -> "%02x".format(byte.toInt() and 0xff) }
    }

    private fun normalizeFingerprint(value: String): String? {
        val normalized = value.replace(":", "").lowercase()
        return normalized.takeIf { it.matches(Regex("^[a-f0-9]{64}$")) }
    }
}
''', encoding="utf-8")
android_manifest = Path("android/app/src/main/AndroidManifest.xml")
manifest_text = android_manifest.read_text(encoding="utf-8")
if 'android:name=".MainActivity"' not in manifest_text and 'android:name="com.jarrlyyy.gtn_2.MainActivity"' not in manifest_text:
    print("Generated Android manifest does not declare the expected MainActivity.", file=sys.stderr)
    raise SystemExit(1)
print("Configured native APK signing-certificate verification.")
