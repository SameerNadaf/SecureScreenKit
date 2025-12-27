//
//  SecureScreenConfiguration.swift
//  SecureScreenKit
//
//  Enterprise-grade screen capture protection for iOS
//

import UIKit

/// Global configuration singleton for SecureScreenKit.
///
/// Use this class to configure global protection settings, default policies,
/// and violation handlers. All protection decisions check this configuration.
///
/// ## Setup
/// Configure the SDK early in your app's lifecycle:
/// ```swift
/// // In AppDelegate
/// func application(_ application: UIApplication,
///                  didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
///
///     // Enable protection globally
///     SecureScreenConfiguration.shared.isProtectionEnabled = true
///
///     // Set default policy
///     SecureScreenConfiguration.shared.defaultPolicy = .obscure(style: .blur(radius: 20))
///
///     // Set violation handler
///     SecureScreenConfiguration.shared.violationHandler = MyViolationHandler()
///
///     // Start the shield coordinator
///     SecureScreenConfiguration.shared.startProtection()
///
///     return true
/// }
/// ```
///
/// ## Kill Switch
/// The `isProtectionEnabled` property acts as a global kill switch.
/// When set to `false`, ALL protection features are disabled, regardless
/// of individual view or controller policy settings.
@MainActor
public final class SecureScreenConfiguration {
    
    // MARK: - Singleton
    
    /// Shared configuration instance.
    public static let shared = SecureScreenConfiguration()
    
    // MARK: - Properties
    
    /// Global enable/disable switch for all protection.
    ///
    /// When `false`, no protection will be applied regardless of
    /// individual policy settings. Defaults to `true`.
    ///
    /// Use this for:
    /// - Debug/development builds
    /// - Feature flags
    /// - User preference settings
    public var isProtectionEnabled: Bool = true {
        didSet {
            if isProtectionEnabled != oldValue {
                handleProtectionStateChange()
            }
        }
    }
    
    /// Default policy applied when no specific policy is set.
    ///
    /// This policy is used by:
    /// - Views using `.secureContent()` without explicit policy
    /// - The global shield window
    /// - Controllers without explicit policy
    ///
    /// Defaults to `.obscure(style: .blur(radius: 20))`.
    public var defaultPolicy: CapturePolicy = .obscure(style: .blur(radius: 20)) {
        didSet {
            ShieldCoordinator.shared.refreshShields()
        }
    }
    
    /// Handler for capture violation events.
    ///
    /// Set this to receive callbacks when:
    /// - Screen recording starts
    /// - Screen recording stops
    /// - A screenshot is taken
    ///
    /// - Note: Use the handler for logging, analytics, session invalidation,
    ///   or other business logic responses to capture events.
    public var violationHandler: ViolationHandler?
    
    // MARK: - Read-Only State
    
    /// Whether screen recording is currently active.
    ///
    /// This is a convenience accessor for `CaptureMonitor.isRecording`.
    public var isScreenRecordingActive: Bool {
        CaptureMonitor.shared.isRecording
    }
    
    /// Current capture state.
    ///
    /// This is a convenience accessor for the current capture state.
    public var currentCaptureState: CaptureState {
        CaptureMonitor.shared.captureState
    }
    
    /// Whether the shield coordinator has been started.
    public var isProtectionStarted: Bool {
        ShieldCoordinator.shared.isStarted
    }
    
    // MARK: - Configuration
    
    /// Additional user context for policy evaluation.
    ///
    /// Set this to provide user role information for role-based policies.
    public var currentUserRole: String?
    
    // MARK: - Initialization
    
    private init() {
        // Private to enforce singleton
    }
    
    // MARK: - Control Methods
    
    /// Starts the global protection system.
    ///
    /// Call this once in your app's initialization to enable:
    /// - Global shield window management
    /// - Capture state monitoring
    /// - Automatic protection activation
    ///
    /// - Important: This method is idempotent. Calling it multiple times
    ///   has no additional effect.
    public func startProtection() {
        guard isProtectionEnabled else { return }
        ShieldCoordinator.shared.start()
    }
    
    /// Stops the global protection system.
    ///
    /// Call this to completely disable protection and clean up resources.
    /// You will need to call `startProtection()` again to re-enable.
    public func stopProtection() {
        ShieldCoordinator.shared.stop()
    }
    
    /// Forces a refresh of all protection states.
    ///
    /// Call this after changing configuration or when you suspect
    /// the protection state may be out of sync.
    public func refreshProtection() {
        CaptureMonitor.shared.refreshState()
        ShieldCoordinator.shared.refreshShields()
    }
    
    // MARK: - Private Methods
    
    private func handleProtectionStateChange() {
        if isProtectionEnabled {
            ShieldCoordinator.shared.refreshShields()
        } else {
            ShieldCoordinator.shared.stop()
        }
    }
}

// MARK: - Convenience Extensions

public extension SecureScreenConfiguration {
    
    /// Configures the SDK with common settings in one call.
    ///
    /// - Parameters:
    ///   - enabled: Whether protection is enabled.
    ///   - defaultPolicy: The default protection policy.
    ///   - violationHandler: Optional violation handler.
    func configure(
        enabled: Bool = true,
        defaultPolicy: CapturePolicy = .obscure(style: .blur(radius: 20)),
        violationHandler: ViolationHandler? = nil
    ) {
        self.isProtectionEnabled = enabled
        self.defaultPolicy = defaultPolicy
        self.violationHandler = violationHandler
    }
    
    /// Enables full-app protection from screen recordings.
    ///
    /// When enabled, a black overlay covers the entire screen during recording.
    ///
    /// ## Usage
    /// ```swift
    /// // In AppDelegate or App.init()
    /// SecureScreenConfiguration.shared.enableFullAppProtection()
    /// ```
    ///
    /// - Note: For screenshot protection, use `ScreenshotProofView` to wrap
    ///   specific sensitive content.
    ///
    /// - Parameters:
    ///   - violationHandler: Optional handler for capture events (logging, analytics, etc)
    public func enableFullAppProtection(violationHandler: ViolationHandler? = nil) {
        self.isProtectionEnabled = true
        self.defaultPolicy = .obscure(style: .blackout)
        if let handler = violationHandler {
            self.violationHandler = handler
        }
        
        // Enable recording protection overlay
        FullAppProtector.shared.enable()
        
        // Enable component-level recording protection
        startProtection()
    }
    
    /// Enables full-app protection with a blur effect during recording.
    ///
    /// Similar to `enableFullAppProtection()` but uses a blur effect instead
    /// of a solid black overlay.
    ///
    /// - Parameters:
    ///   - blurRadius: The blur radius to apply (default: 30)
    ///   - violationHandler: Optional handler for capture events
    public func enableFullAppBlurProtection(blurRadius: CGFloat = 30, violationHandler: ViolationHandler? = nil) {
        self.isProtectionEnabled = true
        self.defaultPolicy = .obscure(style: .blur(radius: blurRadius))
        if let handler = violationHandler {
            self.violationHandler = handler
        }
        
        // Enable recording protection overlay
        FullAppProtector.shared.enable()
        
        // Enable component-level recording protection
        startProtection()
    }
    
    /// Enables full-app protection with a blocking message during recording.
    ///
    /// Shows a "Content Protected" message with optional reason text
    /// when screen recording is detected.
    ///
    /// - Parameters:
    ///   - reason: Optional reason to display to the user
    ///   - violationHandler: Optional handler for capture events
    public func enableFullAppBlockProtection(reason: String? = nil, violationHandler: ViolationHandler? = nil) {
        self.isProtectionEnabled = true
        self.defaultPolicy = .block(reason: reason)
        if let handler = violationHandler {
            self.violationHandler = handler
        }
        
        // Enable recording protection overlay
        FullAppProtector.shared.enable()
        
        // Enable component-level recording protection
        startProtection()
    }
    
    /// Disables full-app recording protection.
    ///
    /// Call this to turn off global protection.
    public func disableFullAppProtection() {
        // Disable recording protection
        stopProtection()
        isProtectionEnabled = false
        
        // Disable overlay
        FullAppProtector.shared.disable()
    }
}
