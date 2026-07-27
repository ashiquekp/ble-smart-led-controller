# App setup

This is a Flutter package (not yet run through `flutter create`), since it
was authored file-by-file for clarity. To get it running:

```bash
cd app
flutter create --platforms=android .   # generates android/ project files
flutter pub get
```

## Required Android permissions

After `flutter create` generates `android/app/src/main/AndroidManifest.xml`,
add these inside the `<manifest>` tag (above `<application>`):

```xml
<uses-permission android:name="android.permission.BLUETOOTH_SCAN"
    android:usesPermissionFlags="neverForLocation" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"
    android:maxSdkVersion="30" />
```

- `BLUETOOTH_SCAN` / `BLUETOOTH_CONNECT` are the Android 12+ (API 31+)
  runtime BLE permissions.
- `neverForLocation` tells Android we don't derive physical location from
  scan results, so we don't need to request location permission on newer
  Android versions.
- `ACCESS_FINE_LOCATION` with `maxSdkVersion="30"` is only needed for
  devices on Android 11 and below, where BLE scanning is still tied to
  location permission.

Also set `minSdkVersion` to at least 21 in `android/app/build.gradle`
(`flutter_blue_plus` requires this).

## Running

```bash
flutter run
```

Make sure the ESP32-C3 is flashed and advertising (see `/firmware`) before
scanning from the app.
