//
//  SecureAppWindow.swift
//  SecureScreenKit
//
//  A secure window that hides ALL app content from screenshots and recordings
//

import UIKit

/// A secure window that makes the entire app invisible in screenshots.
///
/// This window uses the `isSecureTextEntry` trick to hide all content
/// from screenshots. It wraps the entire app's view hierarchy in a secure layer.
///
/// ## Usage
/// Replace your app's main window with `SecureAppWindow`:
/// ```swift
/// // In SceneDelegate
/// func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
///     guard let windowScene = scene as? UIWindowScene else { return }
///     
///     let window = SecureAppWindow(windowScene: windowScene)
///     window.rootViewController = YourRootViewController()
///     window.makeKeyAndVisible()
///     self.window = window
/// }
/// ```
@MainActor
public class SecureAppWindow: UIWindow {
    
    // MARK: - Properties
    
    /// The secure text field that creates the protected layer
    private let secureTextField = UITextField()
    
    /// Whether screenshot protection is enabled
    public var isScreenshotProtectionEnabled: Bool = true {
        didSet {
            secureTextField.isSecureTextEntry = isScreenshotProtectionEnabled
        }
    }
    
    // MARK: - Initialization
    
    public override init(windowScene: UIWindowScene) {
        super.init(windowScene: windowScene)
        setupSecureLayer()
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupSecureLayer()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupSecureLayer()
    }
    
    // MARK: - Setup
    
    private func setupSecureLayer() {
        // Configure secure text field
        secureTextField.isSecureTextEntry = true
        secureTextField.isUserInteractionEnabled = false
        secureTextField.backgroundColor = .clear
        
        // Layout will be handled in layoutSubviews
    }
    
    // MARK: - Layout
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        // Ensure secure text field is in place
        if secureTextField.superview == nil {
            insertSecureLayer()
        }
    }
    
    private func insertSecureLayer() {
        // Add to window
        addSubview(secureTextField)
        
        // Find the secure layer
        DispatchQueue.main.async { [weak self] in
            self?.moveContentToSecureLayer()
        }
    }
    
    private func moveContentToSecureLayer() {
        // Get secure layer from text field
        guard let secureLayer = findSecureLayer(in: secureTextField) else {
            return
        }
        
        // Move all other subviews' layers into the secure layer
        for subview in subviews where subview !== secureTextField {
            secureLayer.addSublayer(subview.layer)
        }
    }
    
    private func findSecureLayer(in textField: UITextField) -> CALayer? {
        // Search for the secure layer in text field subviews
        for subview in textField.subviews {
            if let layer = subview.layer.sublayers?.first {
                return layer
            }
        }
        return textField.layer.sublayers?.first
    }
}

// MARK: - Window Wrapper for Existing Apps

/// A helper class to add screenshot protection to an existing window.
@MainActor
public class ScreenshotProtector {
    
    /// Shared instance
    public static let shared = ScreenshotProtector()
    
    private var secureTextField: UITextField?
    private var isEnabled = false
    
    private init() {}
    
    /// Enables screenshot protection for the entire app.
    ///
    /// This adds a secure layer to all app windows, making their content
    /// invisible in screenshots.
    ///
    /// ## Usage
    /// ```swift
    /// // In AppDelegate or early initialization
    /// ScreenshotProtector.shared.protect()
    /// ```
    ///
    /// - Important: This only works for screenshots. For recording protection,
    ///   use `SecureScreenConfiguration.shared.enableFullAppProtection()` in addition.
    public func protect() {
        guard !isEnabled else { return }
        isEnabled = true
        
        // Apply to all windows
        for scene in UIApplication.shared.connectedScenes {
            if let windowScene = scene as? UIWindowScene {
                for window in windowScene.windows {
                    applySecureLayer(to: window)
                }
            }
        }
        
        // Listen for new windows
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(windowDidBecomeVisible),
            name: UIWindow.didBecomeVisibleNotification,
            object: nil
        )
    }
    
    /// Disables screenshot protection.
    public func unprotect() {
        guard isEnabled else { return }
        isEnabled = false
        
        NotificationCenter.default.removeObserver(self, name: UIWindow.didBecomeVisibleNotification, object: nil)
        
        // Remove secure layers
        removeSecureLayers()
    }
    
    @objc private func windowDidBecomeVisible(_ notification: Notification) {
        guard isEnabled, let window = notification.object as? UIWindow else { return }
        applySecureLayer(to: window)
    }
    
    private func applySecureLayer(to window: UIWindow) {
        // Skip if already has secure text field
        if window.subviews.contains(where: { $0 is UITextField && ($0 as! UITextField).isSecureTextEntry }) {
            return
        }
        
        // Create secure text field
        let textField = UITextField()
        textField.isSecureTextEntry = true
        textField.isUserInteractionEnabled = false
        textField.backgroundColor = .clear
        textField.tag = 999999 // For identification
        
        // Add to window at bottom
        window.insertSubview(textField, at: 0)
        
        // Let it create the secure layer
        textField.layoutIfNeeded()
        
        // Move window content into secure layer
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.moveWindowContentToSecureLayer(window: window, textField: textField)
        }
    }
    
    private func moveWindowContentToSecureLayer(window: UIWindow, textField: UITextField) {
        guard let secureLayer = findSecureLayer(in: textField) else { return }
        
        for subview in window.subviews where subview !== textField {
            secureLayer.addSublayer(subview.layer)
        }
    }
    
    private func findSecureLayer(in textField: UITextField) -> CALayer? {
        for subview in textField.subviews {
            if let layer = subview.layer.sublayers?.first {
                return layer
            }
        }
        return textField.layer.sublayers?.first
    }
    
    private func removeSecureLayers() {
        for scene in UIApplication.shared.connectedScenes {
            if let windowScene = scene as? UIWindowScene {
                for window in windowScene.windows {
                    // Find and remove secure text field
                    if let textField = window.subviews.first(where: { $0.tag == 999999 }) {
                        // Move layers back first
                        if let secureLayer = findSecureLayer(in: textField as! UITextField) {
                            for sublayer in secureLayer.sublayers ?? [] {
                                window.layer.addSublayer(sublayer)
                            }
                        }
                        textField.removeFromSuperview()
                    }
                }
            }
        }
    }
}
