# SecureScreenKit

Enterprise-grade screen capture protection for iOS applications.

## Overview

SecureScreenKit provides detection and response capabilities for screen capture events on iOS. Protect sensitive content by obscuring or hiding views when screen recording or screenshots are detected.

## Features

- ✅ **Screen Recording Detection** - Real-time detection of iOS screen recording, AirPlay mirroring
- ✅ **Screenshot Detection** - Notification when screenshots are taken
- ✅ **Policy-Based Protection** - Flexible policies (blur, blackout, block, logout)
- ✅ **Conditional Protection** - Role-based, screen-based, and custom conditions
- ✅ **SwiftUI & UIKit Support** - Full support for both frameworks
- ✅ **Global Shield** - System-wide overlay for immediate protection
- ✅ **Screenshot-Proof Content** - Uses secure text field trick to hide content from captures

## Platform Requirements

- iOS 14.0+
- Swift 5.7+
- Xcode 15.0+

## Installation

### Swift Package Manager

Add to your `Package.swift`:

```swift
dependencies: [
    .package(path: "../SecureScreenKit")
]
```

Or in Xcode: File → Add Package Dependencies → Add Local...

## ⚠️ Important Platform Limitations

> **iOS does NOT allow apps to prevent screenshots or screen recordings.**

| What SecureScreenKit CAN Do                   | What It CANNOT Do            |
| --------------------------------------------- | ---------------------------- |
| ✅ Detect screen recording                    | ❌ Block screen recording    |
| ✅ Detect screenshots (after taken)           | ❌ Prevent screenshots       |
| ✅ Obscure content during recording           | ❌ Delete captured images    |
| ✅ Hide content using secure text field trick | ❌ 100% guarantee protection |

## Quick Start

### 1. Configure at App Launch

```swift
import SecureScreenKit

@main
struct MyApp: App {
    init() {
        SecureScreenConfiguration.shared.isProtectionEnabled = true
        SecureScreenConfiguration.shared.defaultPolicy = .obscure(style: .blur(radius: 20))
        SecureScreenConfiguration.shared.startProtection()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

### 2. Protect SwiftUI Content

```swift
// Option A: SecureContainer (shows overlay during recording)
SecureContainer(policy: .block(reason: "Protected content")) {
    SensitiveDataView()
}

// Option B: View modifier
Text("Secret: ABC123")
    .secureContent(policy: .obscure(style: .blur(radius: 25)))

// Option C: Screenshot-proof (actually hidden from captures)
SecureContentView {
    Text("PIN: 1234")
}

// Or use modifier
Text("Hidden PIN").screenshotProof()
```

### 3. Protect UIKit Content

```swift
// Subclass SecureViewController
class BankingVC: SecureViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        policy = .obscure(style: .blackout)
    }
}

// Or use extension
myViewController.secure(policy: .block(reason: "Protected"))

// Screenshot-proof UIKit view
let secureView = SecureUIView()
secureView.addSecureSubview(mySecretLabel)
```

## Protection Policies

| Policy                            | Behavior                       |
| --------------------------------- | ------------------------------ |
| `.allow`                          | No protection                  |
| `.obscure(style: .blur(radius:))` | Blur overlay during capture    |
| `.obscure(style: .blackout)`      | Black overlay during capture   |
| `.block(reason:)`                 | Full-screen block with message |
| `.logout`                         | Triggers logout action         |

## Conditional Protection

```swift
// Only protect during recording (not screenshots)
SecureContainer(
    policy: .obscure(style: .blur(radius: 20)),
    condition: RecordingOnlyCondition()
) {
    content
}

// Role-based: admins are exempt
SecureContainer(
    policy: .block(reason: "Protected"),
    condition: RoleBasedCondition(exemptRoles: ["admin"]),
    userRole: currentUser.role
) {
    content
}

// Custom condition
let customCondition = ClosureCondition { context in
    context.captureState == .recording && !context.isInBackground
}
```

## Violation Handling

```swift
SecureScreenConfiguration.shared.violationHandler = BlockViolationHandler(
    onCaptureStarted: {
        print("Recording started!")
        Analytics.log("screen_recording_detected")
    },
    onCaptureStopped: {
        print("Recording stopped")
    },
    onScreenshot: {
        print("Screenshot taken!")
        // Note: Screenshot already captured at this point
    }
)
```

## Screenshot-Proof Content

The `SecureContentView` uses the `UITextField.isSecureTextEntry` technique to make content actually invisible in screenshots and recordings:

```swift
SecureContentView {
    VStack {
        Text("Bank Account: 1234-5678")
        Text("Balance: $10,000")
    }
}
```

> ⚠️ This relies on undocumented iOS behavior. While it works in current iOS versions, Apple could change this in the future.

## Architecture

```
SecureScreenKit/
├── Core/           # Detection engine
├── Policy/         # Policy engine & conditions
├── Shield/         # Global overlay window
├── SwiftUI/        # SwiftUI components
├── UIKit/          # UIKit components
└── Public/         # Configuration & handlers
```

## License

Copyright © 2024. All rights reserved.
