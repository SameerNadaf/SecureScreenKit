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
/// from screenshots. Content added to this window will be placed inside
/// the secure container view.
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
    
    /// The container inside the secure text field where content lives
    private var secureContainerView: UIView?
    
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
        secureTextField.translatesAutoresizingMaskIntoConstraints = false
        
        // Add text field to window
        super.addSubview(secureTextField)
        
        // Fill the window
        NSLayoutConstraint.activate([
            secureTextField.topAnchor.constraint(equalTo: topAnchor),
            secureTextField.leadingAnchor.constraint(equalTo: leadingAnchor),
            secureTextField.trailingAnchor.constraint(equalTo: trailingAnchor),
            secureTextField.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        // Trigger layout to create secure container
        secureTextField.layoutIfNeeded()
        
        // Find the secure container
        if let containerView = secureTextField.subviews.first {
            self.secureContainerView = containerView
            containerView.isUserInteractionEnabled = true
        }
    }
    
    // MARK: - Override to route content to secure container
    
    public override var rootViewController: UIViewController? {
        get {
            return super.rootViewController
        }
        set {
            super.rootViewController = newValue
            
            // Move the root view controller's view to secure container
            if let vc = newValue, let secureContainer = secureContainerView {
                vc.view.translatesAutoresizingMaskIntoConstraints = false
                secureContainer.addSubview(vc.view)
                
                NSLayoutConstraint.activate([
                    vc.view.topAnchor.constraint(equalTo: secureContainer.topAnchor),
                    vc.view.leadingAnchor.constraint(equalTo: secureContainer.leadingAnchor),
                    vc.view.trailingAnchor.constraint(equalTo: secureContainer.trailingAnchor),
                    vc.view.bottomAnchor.constraint(equalTo: secureContainer.bottomAnchor)
                ])
            }
        }
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        secureContainerView?.frame = bounds
    }
}

// MARK: - Window Wrapper for Existing Apps

/// A helper class to add screenshot protection to an existing window.
///
/// This class provides a simple way to enable screenshot protection for
/// the entire app without replacing the window class.
///
/// ## Usage
/// ```swift
/// // In AppDelegate or early initialization
/// ScreenshotProtector.shared.protect()
/// ```
///
/// - Important: This works by making content inside ScreenshotProofView
///   invisible in screenshots. For complete protection including recordings,
///   use `SecureScreenConfiguration.shared.enableFullAppProtection()`.
@MainActor
public class ScreenshotProtector {
    
    /// Shared instance
    public static let shared = ScreenshotProtector()
    
    private var secureTextFields: [UIWindow: UITextField] = [:]
    private var isEnabled = false
    
    private init() {}
    
    /// Enables screenshot protection for the entire app.
    ///
    /// This adds a secure layer to all app windows, making their content
    /// invisible in screenshots.
    ///
    /// - Important: This only works for screenshots. For recording protection,
    ///   use `SecureScreenConfiguration.shared.startProtection()` in addition.
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
        // Skip if already protected
        guard secureTextFields[window] == nil else { return }
        
        // Skip SecureAppWindow (already protected)
        if window is SecureAppWindow { return }
        
        // Create secure text field
        let textField = UITextField()
        textField.isSecureTextEntry = true
        textField.isUserInteractionEnabled = false
        textField.backgroundColor = .clear
        textField.translatesAutoresizingMaskIntoConstraints = false
        
        // Add to window
        window.addSubview(textField)
        
        // Fill the window
        NSLayoutConstraint.activate([
            textField.topAnchor.constraint(equalTo: window.topAnchor),
            textField.leadingAnchor.constraint(equalTo: window.leadingAnchor),
            textField.trailingAnchor.constraint(equalTo: window.trailingAnchor),
            textField.bottomAnchor.constraint(equalTo: window.bottomAnchor)
        ])
        
        // Trigger layout
        textField.layoutIfNeeded()
        
        // Find secure container and move existing content
        if let secureContainer = textField.subviews.first {
            secureContainer.isUserInteractionEnabled = true
            
            // Move all existing subviews (except the text field) to secure container
            for subview in window.subviews where subview !== textField {
                subview.removeFromSuperview()
                secureContainer.addSubview(subview)
            }
        }
        
        // Store reference
        secureTextFields[window] = textField
        
        // Send to back so it doesn't cover new content
        window.sendSubviewToBack(textField)
    }
    
    private func removeSecureLayers() {
        for (window, textField) in secureTextFields {
            // Move content back to window
            if let secureContainer = textField.subviews.first {
                for subview in secureContainer.subviews {
                    subview.removeFromSuperview()
                    window.addSubview(subview)
                }
            }
            textField.removeFromSuperview()
        }
        secureTextFields.removeAll()
    }
}
