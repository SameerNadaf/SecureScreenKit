# SecureScreenKit

<p align="center">
  <img src="https://img.shields.io/badge/iOS-15.0+-blue.svg" alt="iOS 15.0+">
  <img src="https://img.shields.io/badge/Swift-5.7+-orange.svg" alt="Swift 5.7+">
  <img src="https://img.shields.io/badge/SwiftUI-Compatible-green.svg" alt="SwiftUI">
  <img src="https://img.shields.io/badge/UIKit-Compatible-green.svg" alt="UIKit">
  <img src="https://img.shields.io/badge/License-MIT-lightgrey.svg" alt="MIT License">
</p>

**Enterprise-grade screen capture protection for iOS applications.**

SecureScreenKit provides comprehensive protection against screen recording and screenshots for sensitive content in your iOS apps. Whether you need to protect banking information, medical records, private messages, or any other sensitive data, SecureScreenKit offers flexible, policy-based protection that works seamlessly with both SwiftUI and UIKit.

---

## Table of Contents

- [Features](#features)
- [Requirements](#requirements)
- [Installation](#installation)
- [Quick Start](#quick-start)
- [Protection Types](#protection-types)
- [Full-App Protection](#full-app-protection)
- [SwiftUI Integration](#swiftui-integration)
- [UIKit Integration](#uikit-integration)
- [Protection Policies](#protection-policies)
- [Conditional Protection](#conditional-protection)
- [Violation Handling](#violation-handling)
- [Architecture](#architecture)
- [Platform Limitations](#platform-limitations)
- [API Reference](#api-reference)
- [Examples](#examples)
- [Troubleshooting](#troubleshooting)
- [License](#license)

---

## Features

### Core Capabilities

- 🛡️ **Screenshot Protection** - Makes content invisible in screenshots using iOS secure text field technique
- 📹 **Recording Protection** - Displays overlay (blur, blackout, or custom) during screen recording
- 🔐 **Complete Protection** - Combined screenshot AND recording protection
- 🌐 **Full-App Protection** - One-line setup to protect your entire application

### Framework Support

- ✅ **SwiftUI** - Native SwiftUI views and view modifiers
- ✅ **UIKit** - UIView and UIViewController extensions
- ✅ **Hybrid Apps** - Works in apps using both frameworks

### Flexibility

- 📋 **Policy-Based** - Choose blur, blackout, block message, or custom overlays
- 🎯 **Conditional Protection** - Role-based, screen-based, or custom conditions
- ⚡ **Zero Configuration** - Works out of the box with sensible defaults

---

## Requirements

| Requirement | Minimum Version |
| ----------- | --------------- |
| iOS         | 15.0+           |
| Swift       | 5.7+            |
| Xcode       | 14.0+           |

---

## Installation

### Swift Package Manager (Recommended)

Add SecureScreenKit to your project using Xcode:

1. Go to **File → Add Package Dependencies...**
2. Enter the repository URL
3. Select the version you want to use

Or add to your `Package.swift`:

```swift
dependencies: [
    .package(path: "../SecureScreenKit")
    // Or use URL: .package(url: "https://github.com/SameerNadaf/SecureScreenKit", from: "1.0.0")
]
```

Then add the dependency to your target:

```swift
.target(
    name: "YourApp",
    dependencies: ["SecureScreenKit"]
)
```

---

## Quick Start

### 1. Import the Framework

```swift
import SecureScreenKit
```

### 2. Choose Your Protection Level

#### Option A: Full-App Protection (Easiest)

Protect your entire app with one line:

```swift
// In AppDelegate or @main App init
SecureScreenConfiguration.shared.enableFullAppProtection()
```

This will:

- Make all app content **invisible in screenshots** ✅
- Show a **black overlay during recordings** ✅

#### Option B: Selective Protection (SwiftUI)

Protect specific views:

```swift
struct BankingView: View {
    var body: some View {
        ScreenProtectedView {
            // Your sensitive content here
            Text("Account Balance: $10,000")
        }
    }
}
```

#### Option C: Selective Protection (UIKit)

```swift
class SecretViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        // Add protection to any view
        sensitiveView.enableRecordingProtection(policy: .obscure(style: .blur(radius: 25)))
    }
}
```

---

## Protection Types

SecureScreenKit offers three distinct protection types, each with a clear naming convention:

| Protection Type | What It Does                           | SwiftUI Component           | UIKit Component         | Modifier                 |
| --------------- | -------------------------------------- | --------------------------- | ----------------------- | ------------------------ |
| **Screenshot**  | Makes content invisible in screenshots | `ScreenshotProofView`       | `ScreenshotProofUIView` | `.screenshotProtected()` |
| **Recording**   | Shows overlay during recording         | `RecordingOverlayContainer` | `RecordingOverlayView`  | `.recordingProtected()`  |
| **Complete**    | Both screenshot AND recording          | `ScreenProtectedView`       | `ScreenProtectedUIView` | `.screenProtected()`     |

### How Each Works

#### Screenshot Protection

Uses iOS's `UITextField.isSecureTextEntry` trick. Content placed on the secure layer is automatically excluded from screenshots by iOS itself. This is the most reliable screenshot protection available.

```swift
// The content inside will be INVISIBLE in any screenshot
ScreenshotProofView {
    Text("Secret Code: 1234")
}
```

#### Recording Protection

Monitors for screen recording via `UIScreen.isCaptured` and shows an overlay when detected. You can choose blur, blackout, or a custom overlay.

```swift
// Shows blur overlay during screen recording
RecordingOverlayContainer(policy: .obscure(style: .blur(radius: 25))) {
    Text("This will be blurred during recording")
}
```

#### Complete Protection

Combines both techniques for maximum security:

```swift
// Invisible in screenshots AND shows overlay during recording
ScreenProtectedView {
    Text("Maximum security content")
}
```

---

## Full-App Protection

For apps where all content is sensitive (banking, healthcare, etc.), use full-app protection:

### Basic Setup

```swift
// In your App's init or AppDelegate
import SecureScreenKit

@main
struct MyBankingApp: App {
    init() {
        // One line to protect everything!
        SecureScreenConfiguration.shared.enableFullAppProtection()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

### Protection Styles

```swift
// Blank black screen (default)
SecureScreenConfiguration.shared.enableFullAppProtection()

// Blurred screen
SecureScreenConfiguration.shared.enableFullAppBlurProtection(blurRadius: 30)

// Block message
SecureScreenConfiguration.shared.enableFullAppBlockProtection(
    reason: "Screen recording is not allowed in this app"
)

// Disable when needed
SecureScreenConfiguration.shared.disableFullAppProtection()
```

### Screenshot-Only Protection

If you only want to protect against screenshots (not recordings):

```swift
SecureScreenConfiguration.shared.enableScreenshotProtectionOnly()
```

---

## SwiftUI Integration

### Using View Containers

#### ScreenshotProofView (Screenshot Only)

```swift
import SwiftUI
import SecureScreenKit

struct SecretView: View {
    var body: some View {
        VStack {
            Text("Public Header") // Visible in screenshots

            ScreenshotProofView {
                VStack {
                    Text("Secret Code")
                        .font(.title)
                    Text("1234-5678")
                        .font(.largeTitle.monospacedDigit())
                }
            }
        }
    }
}
```

#### RecordingOverlayContainer (Recording Only)

```swift
struct DocumentView: View {
    var body: some View {
        RecordingOverlayContainer(
            policy: .obscure(style: .blur(radius: 20))
        ) {
            Image("confidential-document")
                .resizable()
                .scaledToFit()
        }
    }
}
```

#### ScreenProtectedView (Complete Protection)

```swift
struct BankingView: View {
    var body: some View {
        ScreenProtectedView(
            recordingPolicy: .block(reason: "Banking data is protected")
        ) {
            VStack {
                Text("Checking Account")
                Text("$25,432.10")
                    .font(.largeTitle)
            }
        }
    }
}
```

### Using View Modifiers

More concise syntax using modifiers:

```swift
struct MyView: View {
    var body: some View {
        VStack {
            // Screenshot protection only
            Text("SSN: XXX-XX-1234")
                .screenshotProtected()

            // Recording protection only
            Text("Medical Records")
                .recordingProtected()

            // Complete protection (both)
            Text("Top Secret")
                .screenProtected()
        }
    }
}
```

### Custom Recording Policies

```swift
// With custom policy
Text("Custom Protected")
    .recordingProtected(policy: .block(reason: "Recording not allowed"))

// With condition
RecordingOverlayContainer(
    policy: .obscure(style: .blur(radius: 25)),
    condition: RoleBasedCondition(exemptRoles: ["admin"]),
    userRole: currentUser.role
) {
    AdminPanel()
}
```

---

## UIKit Integration

### UIView-Based Protection

#### ScreenshotProofUIView

```swift
import UIKit
import SecureScreenKit

class SecretViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        // Create screenshot-proof container
        let screenshotProof = ScreenshotProofUIView()
        screenshotProof.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(screenshotProof)

        // Create your sensitive content
        let secretLabel = UILabel()
        secretLabel.text = "Password: ********"

        // Add to protected container
        screenshotProof.addSecureSubview(secretLabel)

        // Layout
        NSLayoutConstraint.activate([
            screenshotProof.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            screenshotProof.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
}
```

#### RecordingOverlayView

```swift
class DocumentViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        // Create recording-protected container
        let recordingProtected = RecordingOverlayView(
            policy: .obscure(style: .blur(radius: 25))
        )
        recordingProtected.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(recordingProtected)

        // Add your content
        let documentView = UIImageView(image: UIImage(named: "document"))
        recordingProtected.addProtectedSubview(documentView)

        // Layout...
    }
}
```

#### ScreenProtectedUIView (Complete Protection)

```swift
class BankingViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        // Complete protection
        let protected = ScreenProtectedUIView(
            policy: .block(reason: "Banking information protected")
        )
        protected.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(protected)

        // Add your sensitive banking content
        let balanceLabel = UILabel()
        balanceLabel.text = "$50,000.00"
        protected.addSecureContent(balanceLabel)

        // Layout...
    }
}
```

### UIViewController Subclass

For full-screen protection, subclass `RecordingProtectedViewController`:

```swift
class ConfidentialViewController: RecordingProtectedViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        // Set your desired policy
        policy = .obscure(style: .blur(radius: 30))

        // Add your UI
        let label = UILabel()
        label.text = "Confidential Information"
        view.addSubview(label)
    }
}
```

### UIView Extensions

Apply protection to any existing view:

```swift
class ExistingViewController: UIViewController {
    @IBOutlet weak var sensitiveView: UIView!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Add recording protection to existing view
        sensitiveView.enableRecordingProtection(
            policy: .block(reason: "Content protected")
        )
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        // Remove protection when leaving
        sensitiveView.disableRecordingProtection()
    }
}
```

---

## Protection Policies

SecureScreenKit supports four protection policies:

### 1. Allow (No Protection)

```swift
.allow
```

No protection applied. Use for non-sensitive content or to explicitly disable protection.

### 2. Obscure (Blur or Blackout)

```swift
// Blur with custom radius
.obscure(style: .blur(radius: 25))

// Complete blackout
.obscure(style: .blackout)

// Custom view
.obscure(style: .custom({ customView }))
```

### 3. Block (With Message)

```swift
// Default message
.block(reason: nil)

// Custom message
.block(reason: "This content cannot be recorded for security reasons")
```

### 4. Logout (Session Termination)

```swift
.logout
```

Shows blocking message and triggers session termination via `ViolationHandler`.

---

## Conditional Protection

Apply protection based on context:

### Role-Based Protection

Exempt certain user roles:

```swift
RecordingOverlayContainer(
    policy: .obscure(style: .blur(radius: 25)),
    condition: RoleBasedCondition(exemptRoles: ["admin", "supervisor"]),
    userRole: currentUser.role
) {
    SensitiveContent()
}
```

### Screen-Based Protection

Protect only specific screens:

```swift
RecordingOverlayContainer(
    policy: .block(reason: "Protected screen"),
    condition: ScreenBasedCondition(protectedScreens: ["payment", "settings"]),
    screenIdentifier: "payment"
) {
    PaymentForm()
}
```

### Recording-Only Condition

Only protect during recording (not screenshots):

```swift
RecordingOverlayContainer(
    policy: .obscure(style: .blur(radius: 25)),
    condition: RecordingOnlyCondition()
) {
    Content()
}
```

### Custom Conditions

Create your own condition logic:

```swift
class BusinessHoursCondition: CaptureCondition {
    func shouldProtect(context: CaptureContext) -> Bool {
        let hour = Calendar.current.component(.hour, from: Date())
        return hour >= 9 && hour < 17 // Only during business hours
    }
}
```

---

## Violation Handling

Receive callbacks when capture events occur:

### Basic Handler

```swift
SecureScreenConfiguration.shared.violationHandler = BlockViolationHandler(
    onCaptureStarted: {
        print("Screen recording started!")
        Analytics.log("security_event", params: ["type": "recording_started"])
    },
    onCaptureStopped: {
        print("Screen recording stopped")
    },
    onScreenshot: {
        print("Screenshot taken")
        // Note: Screenshot already captured at this point
    }
)
```

### Custom Handler Class

```swift
class SecurityHandler: ViolationHandler {
    func didStartScreenCapture() {
        // Log to analytics
        Analytics.log("recording_detected")

        // Show alert
        showSecurityAlert()
    }

    func didStopScreenCapture() {
        dismissSecurityAlert()
    }

    func screenshotTaken() {
        // Log (content already protected if using screenshot protection)
        Analytics.log("screenshot_attempt")
    }
}

// Use it
SecureScreenConfiguration.shared.violationHandler = SecurityHandler()
```

---

## Architecture

SecureScreenKit is built with a clean, modular architecture:

```
┌─────────────────────────────────────────────────────────────────┐
│                      Public API Layer                           │
├─────────────────────────────────────────────────────────────────┤
│  SecureScreenConfiguration  │  ViolationHandler  │  Policies   │
└─────────────────────────────────────────────────────────────────┘
                              │
┌─────────────────────────────────────────────────────────────────┐
│                     Protection Components                        │
├─────────────────────────────────────────────────────────────────┤
│  SwiftUI                    │  UIKit                             │
│  ├── ScreenshotProofView    │  ├── ScreenshotProofUIView         │
│  ├── RecordingOverlayContainer │ ├── RecordingOverlayView        │
│  ├── ScreenProtectedView    │  ├── ScreenProtectedUIView         │
│  └── View Modifiers         │  └── UIView Extensions             │
└─────────────────────────────────────────────────────────────────┘
                              │
┌─────────────────────────────────────────────────────────────────┐
│                         Core Layer                               │
├─────────────────────────────────────────────────────────────────┤
│  CaptureMonitor  │  CapturePolicyEngine  │  ShieldCoordinator   │
└─────────────────────────────────────────────────────────────────┘
```

### Core Components

| Component             | Purpose                                        |
| --------------------- | ---------------------------------------------- |
| `CaptureMonitor`      | Detects screen recording and screenshot events |
| `CapturePolicyEngine` | Evaluates policies and conditions              |
| `ShieldCoordinator`   | Manages global shield windows                  |
| `ScreenshotProtector` | Applies secure text field trick to windows     |

---

## Platform Limitations

> ⚠️ **Important**: iOS does not allow apps to completely prevent screenshots or screen recordings. Here's what SecureScreenKit actually does:

### Screenshots

- ✅ **Can**: Make content invisible in screenshots (using secure text field trick)
- ✅ **Can**: Detect when a screenshot was taken (after the fact)
- ❌ **Cannot**: Prevent the screenshot from being taken

### Screen Recording

- ✅ **Can**: Detect when recording starts (immediately)
- ✅ **Can**: Show overlay to hide content during recording
- ❌ **Cannot**: Prevent recording from starting
- ❌ **Cannot**: Hide system UI or notification bar

### Detection Timing

- Screenshot detection: **After** the screenshot is captured
- Recording detection: **Immediately** when recording starts

---

## API Reference

### SecureScreenConfiguration

```swift
// Singleton access
SecureScreenConfiguration.shared

// Properties
.isProtectionEnabled: Bool        // Global on/off switch
.defaultPolicy: CapturePolicy     // Default policy for shields
.violationHandler: ViolationHandler?  // Event callbacks
.currentUserRole: String?         // User role for conditions
.isScreenRecordingActive: Bool    // Read-only recording state

// Methods
.enableFullAppProtection(violationHandler:)    // Full protection
.enableFullAppBlurProtection(blurRadius:)      // Full with blur
.enableFullAppBlockProtection(reason:)         // Full with message
.disableFullAppProtection()                    // Disable all
.enableScreenshotProtectionOnly()              // Screenshot only
.startProtection()                             // Start shield coordinator
.stopProtection()                              // Stop shield coordinator
.refreshProtection()                           // Force refresh
```

### SwiftUI Views

```swift
// Screenshot protection only
ScreenshotProofView { content }

// Recording protection only
RecordingOverlayContainer(
    policy: CapturePolicy = .obscure(style: .blur(radius: 20)),
    condition: CaptureCondition? = nil,
    screenIdentifier: String? = nil,
    userRole: String? = nil
) { content }

// Complete protection
ScreenProtectedView(
    recordingPolicy: CapturePolicy = .obscure(style: .blur(radius: 20)),
    condition: CaptureCondition? = nil
) { content }
```

### SwiftUI View Modifiers

```swift
.screenshotProtected()                    // Screenshot only
.recordingProtected(policy:)              // Recording only
.screenProtected(recordingPolicy:)        // Complete
```

### UIKit Classes

```swift
// Screenshot protection
ScreenshotProofUIView()
    .addSecureSubview(view)

// Recording protection
RecordingOverlayView(policy:)
    .addProtectedSubview(view)

// Complete protection
ScreenProtectedUIView(policy:)
    .addSecureContent(view)

// ViewController subclass
RecordingProtectedViewController
    .policy: CapturePolicy
```

### UIView Extensions

```swift
// Recording protection
view.enableRecordingProtection(policy:condition:)
view.disableRecordingProtection()

// Screenshot protection
view.wrapInScreenshotProofContainer()
view.removeFromScreenshotProofContainer()
```

---

## Examples

### Banking App

```swift
struct BankAccountView: View {
    @State private var accounts = [
        ("Checking", "$5,432.10"),
        ("Savings", "$12,890.00")
    ]

    var body: some View {
        NavigationView {
            ScreenProtectedView(
                recordingPolicy: .block(reason: "Banking information protected")
            ) {
                List(accounts, id: \.0) { account in
                    HStack {
                        Text(account.0)
                        Spacer()
                        Text(account.1)
                            .font(.headline)
                    }
                }
            }
            .navigationTitle("Accounts")
        }
    }
}
```

### Healthcare App

```swift
struct PatientRecordsView: View {
    var body: some View {
        VStack {
            // Public header
            Text("Patient: John Doe")

            // Protected medical data
            ScreenProtectedView {
                VStack(alignment: .leading) {
                    Text("Diagnosis: Confidential")
                    Text("Medications: Protected")
                    Text("Lab Results: Hidden")
                }
            }
        }
    }
}
```

### Password Manager

```swift
struct PasswordDetailView: View {
    let password: String
    @State private var isRevealed = false

    var body: some View {
        VStack {
            ScreenshotProofView {
                Text(isRevealed ? password : "••••••••")
                    .font(.title.monospacedDigit())
            }

            Button(isRevealed ? "Hide" : "Reveal") {
                isRevealed.toggle()
            }
        }
    }
}
```

---

## Troubleshooting

### Protection Not Working

1. **Check if protection is enabled**:

   ```swift
   print(SecureScreenConfiguration.shared.isProtectionEnabled) // Should be true
   ```

2. **For screenshot protection**: Must test on a physical device (simulator may not work)

3. **For full-app protection**: Ensure you called `enableFullAppProtection()` early in app lifecycle

### Content Still Visible in Screenshots

- Use `ScreenshotProofView` or `ScreenProtectedView`, not `RecordingOverlayContainer`
- `RecordingOverlayContainer` only protects against recordings, not screenshots

### Overlay Not Appearing During Recording

- Check that `isProtectionEnabled` is `true`
- Verify the policy is not `.allow`
- Ensure the condition (if any) returns `true`

### UIKit Constraints Issues

- Add explicit height constraints to protected views
- Call `translatesAutoresizingMaskIntoConstraints = false`

---

## License

SecureScreenKit is available under the MIT License. See LICENSE file for details.

---

## Contributing

Contributions are welcome! Please read our contributing guidelines before submitting pull requests.

---

## Support

For issues, questions, or feature requests, please open an issue on GitHub.

---

Made with ❤️ for iOS developers who care about user privacy and security.
