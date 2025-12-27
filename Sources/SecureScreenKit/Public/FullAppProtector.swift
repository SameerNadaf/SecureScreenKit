//
//  FullAppProtector.swift
//  SecureScreenKit
//
//  Provides full-app protection from screen recordings
//

import UIKit
import SwiftUI
import Combine

/// Provides full-app protection from screen recordings.
///
/// When enabled, this shows a protective overlay that covers the screen
/// during screen recording. The overlay appears when recording starts
/// and disappears when recording stops.
///
/// ## How It Works
/// - Creates an overlay window that's always on top
/// - The overlay is INVISIBLE during normal use
/// - When recording is detected, the overlay shows immediately
///
/// ## Usage
/// ```swift
/// // Enable protection
/// FullAppProtector.shared.enable()
///
/// // Disable protection
/// FullAppProtector.shared.disable()
/// ```
///
/// - Note: For screenshot protection, use `ScreenshotProofView` to wrap
///   specific sensitive content.
@MainActor
public class FullAppProtector {
    
    // MARK: - Singleton
    
    /// Shared instance
    public static let shared = FullAppProtector()
    
    // MARK: - Properties
    
    private var overlayWindows: [UIWindowScene: ProtectionWindow] = [:]
    private var isEnabled = false
    private var cancellables = Set<AnyCancellable>()
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// Enables full-app protection from screen recordings.
    ///
    /// When enabled, an overlay appears during screen recording
    /// that completely covers the app content.
    ///
    /// - Note: This does NOT protect against screenshots. For screenshot
    ///   protection, use `ScreenshotProofView` around sensitive content.
    public func enable() {
        guard !isEnabled else { return }
        isEnabled = true
        
        // Setup for existing scenes
        for scene in UIApplication.shared.connectedScenes {
            if let windowScene = scene as? UIWindowScene {
                createProtectionWindow(for: windowScene)
            }
        }
        
        // Listen for new scenes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(sceneDidActivate),
            name: UIScene.didActivateNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(sceneDidDisconnect),
            name: UIScene.didDisconnectNotification,
            object: nil
        )
        
        // Start monitoring for recording only
        startRecordingMonitoring()
    }
    
    /// Disables full-app protection.
    public func disable() {
        guard isEnabled else { return }
        isEnabled = false
        
        NotificationCenter.default.removeObserver(self)
        cancellables.removeAll()
        
        // Remove all protection windows
        for (_, window) in overlayWindows {
            window.isHidden = true
        }
        overlayWindows.removeAll()
    }
    
    /// Returns whether protection is currently enabled.
    public var isProtectionEnabled: Bool {
        return isEnabled
    }
    
    // MARK: - Private Methods
    
    @objc private func sceneDidActivate(_ notification: Notification) {
        guard isEnabled, let scene = notification.object as? UIWindowScene else { return }
        createProtectionWindow(for: scene)
    }
    
    @objc private func sceneDidDisconnect(_ notification: Notification) {
        guard let scene = notification.object as? UIWindowScene else { return }
        overlayWindows[scene]?.isHidden = true
        overlayWindows.removeValue(forKey: scene)
    }
    
    private func createProtectionWindow(for scene: UIWindowScene) {
        guard overlayWindows[scene] == nil else { return }
        
        let window = ProtectionWindow(windowScene: scene)
        window.setup()
        
        overlayWindows[scene] = window
    }
    
    private func startRecordingMonitoring() {
        // Monitor for recording state changes only
        CaptureMonitor.shared.$isRecording
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isRecording in
                self?.updateOverlayVisibility(isRecording: isRecording)
            }
            .store(in: &cancellables)
        
        // Check initial state
        updateOverlayVisibility(isRecording: CaptureMonitor.shared.isRecording)
    }
    
    private func updateOverlayVisibility(isRecording: Bool) {
        for (_, window) in overlayWindows {
            window.setRecordingOverlayVisible(isRecording)
        }
    }
}

// MARK: - Protection Window

/// A window that provides recording protection overlay.
@MainActor
internal class ProtectionWindow: UIWindow {
    
    // Recording overlay
    private let recordingOverlay = UIView()
    
    override init(windowScene: UIWindowScene) {
        super.init(windowScene: windowScene)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    func setup() {
        self.windowLevel = .alert + 100 // Above everything
        self.backgroundColor = .clear
        self.isUserInteractionEnabled = false
        
        // Create root view controller
        let vc = UIViewController()
        vc.view.backgroundColor = .clear
        vc.view.isUserInteractionEnabled = false
        self.rootViewController = vc
        
        guard let rootView = vc.view else { return }
        
        // Setup recording overlay (initially hidden)
        setupRecordingOverlay(in: rootView)
        
        // Show window
        self.makeKeyAndVisible()
        
        // Resign key so main window stays key
        restoreMainWindowKey()
    }
    
    private func restoreMainWindowKey() {
        guard let scene = windowScene else { return }
        if let mainWindow = scene.windows.first(where: { $0 !== self && !$0.isHidden }) {
            mainWindow.makeKey()
        }
    }
    
    private func setupRecordingOverlay(in parent: UIView) {
        recordingOverlay.backgroundColor = .black
        recordingOverlay.translatesAutoresizingMaskIntoConstraints = false
        recordingOverlay.isHidden = true
        recordingOverlay.isUserInteractionEnabled = false
        
        parent.addSubview(recordingOverlay)
        
        NSLayoutConstraint.activate([
            recordingOverlay.topAnchor.constraint(equalTo: parent.topAnchor),
            recordingOverlay.leadingAnchor.constraint(equalTo: parent.leadingAnchor),
            recordingOverlay.trailingAnchor.constraint(equalTo: parent.trailingAnchor),
            recordingOverlay.bottomAnchor.constraint(equalTo: parent.bottomAnchor)
        ])
        
        // Add content to overlay
        let contentStack = UIStackView()
        contentStack.axis = .vertical
        contentStack.alignment = .center
        contentStack.spacing = 12
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        
        let iconConfig = UIImage.SymbolConfiguration(pointSize: 48, weight: .medium)
        let iconView = UIImageView(image: UIImage(systemName: "lock.shield.fill", withConfiguration: iconConfig))
        iconView.tintColor = .white
        
        let titleLabel = UILabel()
        titleLabel.text = "Content Protected"
        titleLabel.font = .systemFont(ofSize: 20, weight: .semibold)
        titleLabel.textColor = .white
        
        let subtitleLabel = UILabel()
        subtitleLabel.text = "Screen recording detected"
        subtitleLabel.font = .systemFont(ofSize: 14)
        subtitleLabel.textColor = .white.withAlphaComponent(0.7)
        
        contentStack.addArrangedSubview(iconView)
        contentStack.addArrangedSubview(titleLabel)
        contentStack.addArrangedSubview(subtitleLabel)
        
        recordingOverlay.addSubview(contentStack)
        
        NSLayoutConstraint.activate([
            contentStack.centerXAnchor.constraint(equalTo: recordingOverlay.centerXAnchor),
            contentStack.centerYAnchor.constraint(equalTo: recordingOverlay.centerYAnchor)
        ])
    }
    
    func setRecordingOverlayVisible(_ visible: Bool) {
        recordingOverlay.isHidden = !visible
    }
}
