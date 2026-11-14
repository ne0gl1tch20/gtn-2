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
permissions = [
    '    <uses-permission android:name="android.permission.REQUEST_INSTALL_PACKAGES" />',
    '    <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />',
]
for permission in permissions:
    permission_name = re.search(r'android:name="([^"]+)"', permission).group(1)
    if permission_name not in text:
        updated, count = re.subn(
            r"(<manifest\b[^>]*>)", r"\1\n" + permission, text, count=1
        )
        if count != 1:
            print("Could not locate the manifest root element.", file=sys.stderr)
            raise SystemExit(1)
        text = updated
        print(f"Added {permission_name}.")
    else:
        print(f"{permission_name} is already present.")
manifest.write_text(text, encoding="utf-8")

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

# Bridge the Android 13+ notification permission request to the Flutter Settings UI.
main_activity_files = list(Path("android/app/src/main/kotlin").rglob("MainActivity.kt"))
if len(main_activity_files) != 1:
    print("Expected exactly one generated MainActivity.kt.", file=sys.stderr)
    raise SystemExit(1)
main_activity = main_activity_files[0]
activity_text = main_activity.read_text(encoding="utf-8")
package_match = re.search(r"(?m)^package\s+[\w.]+, activity_text)
if not package_match:
    print("Could not read the generated MainActivity package.", file=sys.stderr)
    raise SystemExit(1)
package_line = package_match.group(0)
main_activity.write_text(
    package_line
    + """

import android.Manifest
import android.content.pm.PackageManager
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var notificationPermissionResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            NOTIFICATION_PERMISSION_CHANNEL
        ).setMethodCallHandler { call, result ->
            if (call.method != "request") {
                result.notImplemented()
                return@setMethodCallHandler
            }
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU ||
                checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED
            ) {
                result.success(true)
                return@setMethodCallHandler
            }
            if (notificationPermissionResult != null) {
                result.error("REQUEST_IN_PROGRESS", "A notification permission request is already active.", null)
                return@setMethodCallHandler
            }
            notificationPermissionResult = result
            requestPermissions(
                arrayOf(Manifest.permission.POST_NOTIFICATIONS),
                NOTIFICATION_PERMISSION_REQUEST
            )
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == NOTIFICATION_PERMISSION_REQUEST) {
            notificationPermissionResult?.success(
                grantResults.firstOrNull() == PackageManager.PERMISSION_GRANTED
            )
            notificationPermissionResult = null
        }
    }

    companion object {
        private const val NOTIFICATION_PERMISSION_CHANNEL = "gtn/notification_permission"
        private const val NOTIFICATION_PERMISSION_REQUEST = 7402
    }
}
""",
    encoding="utf-8",
)
print("Configured Android notification permission MethodChannel.")


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
