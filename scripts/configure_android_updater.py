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
main_activity.write_text("package com.jarrlyyy.gtn_2\n\nimport android.content.pm.PackageInfo\nimport android.content.pm.PackageManager\nimport android.os.Build\nimport io.flutter.embedding.android.FlutterActivity\nimport io.flutter.embedding.engine.FlutterEngine\nimport io.flutter.plugin.common.MethodChannel\nimport java.io.File\nimport java.security.MessageDigest\n\nclass MainActivity : FlutterActivity() {\n    private val signingChannel = \"com.jarrlyyy.gtn_2/signing\"\n\n    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {\n        super.configureFlutterEngine(flutterEngine)\n        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, signingChannel)\n            .setMethodCallHandler { call, result ->\n                when (call.method) {\n                    \"verifyApkSigningCertificate\" -> {\n                        val apkPath = call.argument<String>(\"apkPath\")\n                        val expected = call.argument<String>(\"expectedCertificateSha256\")\n                        if (apkPath.isNullOrBlank() || expected.isNullOrBlank()) {\n                            result.error(\"INVALID_ARGUMENT\", \"APK path and expected certificate are required.\", null)\n                        } else {\n                            try {\n                                result.success(verifyApkSigningCertificate(apkPath, expected))\n                            } catch (error: Exception) {\n                                result.error(\"SIGNATURE_CHECK_FAILED\", error.message, null)\n                            }\n                        }\n                    }\n                    else -> result.notImplemented()\n                }\n            }\n    }\n\n    private fun verifyApkSigningCertificate(apkPath: String, expectedFingerprint: String): Boolean {\n        val apk = File(apkPath)\n        if (!apk.isFile || !apk.canRead()) return false\n\n        val expected = normalizeFingerprint(expectedFingerprint) ?: return false\n        val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {\n            PackageManager.GET_SIGNING_CERTIFICATES\n        } else {\n            @Suppress(\"DEPRECATION\")\n            PackageManager.GET_SIGNATURES\n        }\n\n        val archivedInfo = packageManager.getPackageArchiveInfo(apk.absolutePath, flags) ?: return false\n        if (archivedInfo.packageName != applicationContext.packageName) return false\n\n        val installedInfo = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {\n            packageManager.getPackageInfo(applicationContext.packageName, flags)\n        } else {\n            @Suppress(\"DEPRECATION\")\n            packageManager.getPackageInfo(applicationContext.packageName, flags)\n        }\n\n        val archivedFingerprint = certificateFingerprint(archivedInfo) ?: return false\n        val installedFingerprint = certificateFingerprint(installedInfo) ?: return false\n\n        // Require all three values to agree: trusted release manifest, downloaded APK,\n        // and the currently installed app. This prevents a different signer being handed\n        // to Android's installer even when the downloaded file's checksum is valid.\n        return archivedFingerprint == expected && installedFingerprint == expected\n    }\n\n    private fun certificateFingerprint(info: PackageInfo): String? {\n        val signatures = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {\n            info.signingInfo?.apkContentsSigners\n        } else {\n            @Suppress(\"DEPRECATION\")\n            info.signatures\n        } ?: return null\n\n        // GTN2 distributes a single-signer APK. Reject ambiguous multi-signer packages.\n        if (signatures.size != 1) return null\n        val digest = MessageDigest.getInstance(\"SHA-256\").digest(signatures[0].toByteArray())\n        return digest.joinToString(\"\") { byte -> \"%02x\".format(byte) }\n    }\n\n    private fun normalizeFingerprint(value: String): String? {\n        val normalized = value.replace(\":\", \"\").lowercase()\n        return normalized.takeIf { it.matches(Regex(\"^[a-f0-9]{64}$\")) }\n    }\n}\n", encoding="utf-8")
android_manifest = Path("android/app/src/main/AndroidManifest.xml")
manifest_text = android_manifest.read_text(encoding="utf-8")
if 'android:name=".MainActivity"' not in manifest_text and 'android:name="com.jarrlyyy.gtn_2.MainActivity"' not in manifest_text:
    print("Generated Android manifest does not declare the expected MainActivity.", file=sys.stderr)
    raise SystemExit(1)
print("Configured native APK signing-certificate verification.")
