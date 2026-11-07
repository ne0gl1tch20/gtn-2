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
