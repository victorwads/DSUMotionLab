# DSU Motion Lab

A standalone macOS 14+ SwiftUI / SceneKit diagnostic client for phone motion over Cemuhook DSU (UDP v1001). No external package dependencies.

## Features

- Multiple phone connections with saved names and player labels.
- Automatic connection to saved devices and optional bounded IPv4 LAN discovery.
- Automatic DSU slot selection, raw packet diagnostics and sensor values.
- Generic 3D controller with guided axis/sign calibration, stillness detection and gyro bias measurement.
- Live calibration preview and recentering without losing axis mapping.
- Portuguese, English, Spanish and Traditional Chinese interface selection. Some technical diagnostics remain in English.

## Use

Open DSUController on your phone and allow local-network access. Enter its IP and UDP port, or enable automatic discovery on that port. Keep the phone app open. Only valid responses confirm a device. Discovery scans supported local IPv4 interfaces with at most 1024 addresses; it does not scan the internet.

Choose Calibrate, place the phone screen-up on a stable table and wait for Continue. Follow the animated movements. Pause when asked, test the result live and press OK to save. Recenter can restore a table or steering-wheel pose without repeating the axis calibration.

Use only trusted networks: DSU has no authentication or encryption. Orientation integrates angular velocity and can drift, especially in yaw. A stationary gyro reads near zero; this app does not receive an absolute compass attitude. Table calibration measures gyro bias and gravity, not geographic heading. It is a diagnostic tool, not yet a bridge into games.

## Build

Requires Xcode command-line tools and Swift 6 or newer.

```sh
swift test
./build-app.sh
open "dist/DSU Motion Lab.app"
```

The bundle is built for the host architecture and is not notarized. macOS may require local-network permission. The packaging script does not install the app or change system security settings.

## Validation

11 automated tests currently cover CRC, packets, calibration, axis mapping, recentering, handoff and translation catalogs. Phone packet reception and automatic discovery were also observed with DSUController during development; device-specific calibration still needs broader testing.

## Protocol

[Community Cemuhook protocol specification](https://github.com/v1993/cemuhook-protocol). Compatible phone apps must implement DSU server responses; HTTP-only sensor apps are not supported.

This project is independent of nxnative and NX2Apple and contains no game files, keys or emulator engine code.
