//
//  ShieldCoordinator.swift
//  SecureScreenKit
//
//  Enterprise-grade screen capture protection for iOS
//

import UIKit
import Combine

/// Coordinates the global shield window based on capture state changes.
///
/// `ShieldCoordinator` observes `CaptureMonitor` for state changes and
/// activates/deactivates the global shield window accordingly. It uses
/// `CapturePolicyEngine` to resolve the appropriate action.
///
/// ## Architecture
/// This is the glue between detection (CaptureMonitor), policy resolution
/// (CapturePolicyEngine), and visual shielding (ShieldWindow).
///
/// ## Usage
/// The coordinator is typically started once in your app's lifecycle:
/// ```swift
/// // In AppDelegate or SceneDelegate
/// ShieldCoordinator.shared.start()
/// ```
@MainActor
internal final class ShieldCoordinator {
    
    // MARK: - Singleton
    
    /// Shared coordinator instance.
    static let shared = ShieldCoordinator()
    
    // MARK: - Properties
    
    /// Shield windows for each connected scene.
    private var shieldWindows: [UIWindowScene: ShieldWindow] = [:]
    
    /// Cancellables for Combine subscriptions.
    private var cancellables = Set<AnyCancellable>()
    
    /// Whether the coordinator has been started.
    private(set) var isStarted = false
    
    /// Reference to capture monitor.
    private let monitor: CaptureMonitor
    
    /// Reference to policy engine.
    private let policyEngine: CapturePolicyEngine
    
    // MARK: - Initialization
    
    private init() {
        self.monitor = CaptureMonitor.shared
        self.policyEngine = CapturePolicyEngine.shared
    }
    
    // MARK: - Lifecycle
    
    /// Starts the shield coordinator.
    ///
    /// Call this once in your app's initialization (e.g., `application(_:didFinishLaunchingWithOptions:)`
    /// or `scene(_:willConnectTo:options:)`).
    func start() {
        guard !isStarted else { return }
        isStarted = true
        
        setupSceneObservers()
        setupCaptureObserver()
        setupExistingScenes()
    }
    
    /// Stops the shield coordinator and cleans up.
    func stop() {
        guard isStarted else { return }
        isStarted = false
        
        cancellables.removeAll()
        
        // Hide and remove all shield windows
        shieldWindows.values.forEach { $0.hideShield() }
        shieldWindows.removeAll()
    }
    
    // MARK: - Setup
    
    private func setupSceneObservers() {
        // Scene connected
        NotificationCenter.default.publisher(
            for: UIScene.willConnectNotification
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] notification in
            guard let scene = notification.object as? UIWindowScene else { return }
            self?.createShieldWindow(for: scene)
        }
        .store(in: &cancellables)
        
        // Scene disconnected
        NotificationCenter.default.publisher(
            for: UIScene.didDisconnectNotification
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] notification in
            guard let scene = notification.object as? UIWindowScene else { return }
            self?.removeShieldWindow(for: scene)
        }
        .store(in: &cancellables)
    }
    
    private func setupCaptureObserver() {
        // Observe capture state changes
        monitor.$captureState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.handleCaptureStateChange(state)
            }
            .store(in: &cancellables)
        
        // Also observe isRecording for more immediate response
        monitor.$isRecording
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isRecording in
                if isRecording {
                    self?.activateShieldsIfNeeded()
                } else if self?.monitor.captureState == .idle {
                    self?.deactivateShields()
                }
            }
            .store(in: &cancellables)
    }
    
    private func setupExistingScenes() {
        // Create shield windows for any already-connected scenes
        for scene in UIApplication.shared.connectedScenes {
            if let windowScene = scene as? UIWindowScene {
                createShieldWindow(for: windowScene)
            }
        }
        
        // Check if capture is already active
        if monitor.isRecording {
            activateShieldsIfNeeded()
        }
    }
    
    // MARK: - Window Management
    
    private func createShieldWindow(for scene: UIWindowScene) {
        guard shieldWindows[scene] == nil else { return }
        
        let shieldWindow = ShieldWindow(windowScene: scene)
        shieldWindows[scene] = shieldWindow
        
        // If capture is currently active, show the shield immediately
        if monitor.isRecording && policyEngine.shouldProtectWithDefaultPolicy() {
            applyDefaultPolicyToWindow(shieldWindow)
        }
    }
    
    private func removeShieldWindow(for scene: UIWindowScene) {
        shieldWindows[scene]?.hideShield()
        shieldWindows.removeValue(forKey: scene)
    }
    
    // MARK: - State Handling
    
    private func handleCaptureStateChange(_ state: CaptureState) {
        switch state {
        case .idle:
            deactivateShields()
            
        case .recording:
            activateShieldsIfNeeded()
            
        case .screenshotTaken:
            // Screenshots are after-the-fact; we can optionally flash the shield
            flashShieldsForScreenshot()
        }
    }
    
    private func activateShieldsIfNeeded() {
        guard policyEngine.shouldProtectWithDefaultPolicy() else { return }
        
        for shieldWindow in shieldWindows.values {
            applyDefaultPolicyToWindow(shieldWindow)
        }
    }
    
    private func deactivateShields() {
        for shieldWindow in shieldWindows.values {
            shieldWindow.hideShield()
        }
    }
    
    private func applyDefaultPolicyToWindow(_ window: ShieldWindow) {
        let policy = SecureScreenConfiguration.shared.defaultPolicy
        
        switch policy {
        case .allow:
            window.hideShield()
            
        case .obscure(let style):
            window.showShield(style: style)
            
        case .block(let reason):
            window.showBlockingMessage(reason: reason)
            
        case .logout:
            window.showBlockingMessage(reason: "Session ended for security")
            // Note: Actual logout logic should be handled by ViolationHandler
        }
    }
    
    private func flashShieldsForScreenshot() {
        // Brief flash to indicate screenshot was detected
        // This is informational only - the screenshot already happened
        guard SecureScreenConfiguration.shared.isProtectionEnabled else { return }
        
        for shieldWindow in shieldWindows.values {
            // Only flash if not already showing
            if shieldWindow.isHidden {
                shieldWindow.showShield(style: .blackout)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    shieldWindow.hideShield()
                }
            }
        }
    }
    
    // MARK: - Public Methods
    
    /// Forces a refresh of shield state across all windows.
    func refreshShields() {
        if monitor.isRecording {
            activateShieldsIfNeeded()
        } else {
            deactivateShields()
        }
    }
    
    /// Returns whether shields are currently active.
    var areShieldsActive: Bool {
        shieldWindows.values.contains { !$0.isHidden }
    }
}
