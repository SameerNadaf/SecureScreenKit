//
//  ShieldWindow.swift
//  SecureScreenKit
//
//  Enterprise-grade screen capture protection for iOS
//

import UIKit

/// A dedicated window for displaying global protection overlays.
///
/// `ShieldWindow` sits above all other application windows and is used
/// to display obscuring content when screen capture is detected. It uses
/// a window level above `.alert` to ensure it covers all application content.
///
/// ## Architecture
/// This window is managed by `ShieldCoordinator` and should not be
/// instantiated or managed directly by application code.
///
/// - Important: The shield window passes through touch events when hidden
///   to avoid interfering with normal user interaction.
@MainActor
internal final class ShieldWindow: UIWindow {
    
    // MARK: - Properties
    
    /// The view controller managing the shield content.
    private(set) var shieldViewController: ShieldViewController?
    
    // MARK: - Initialization
    
    /// Creates a shield window for the given scene.
    ///
    /// - Parameter windowScene: The window scene to attach to.
    override init(windowScene: UIWindowScene) {
        super.init(windowScene: windowScene)
        configure()
    }
    
    /// Creates a shield window (legacy, for iOS 13+ without scenes).
    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }
    
    // MARK: - Configuration
    
    private func configure() {
        // Position above all other windows
        windowLevel = .alert + 1
        
        // Transparent when no shield is active
        backgroundColor = .clear
        
        // Start hidden
        isHidden = true
        
        // Create and set the shield view controller
        let shieldVC = ShieldViewController()
        self.shieldViewController = shieldVC
        rootViewController = shieldVC
    }
    
    // MARK: - Shield Control
    
    /// Shows the shield with the specified obscure style.
    ///
    /// - Parameter style: The visual style to display.
    func showShield(style: ObscureStyle) {
        shieldViewController?.applyStyle(style)
        
        if isHidden {
            isHidden = false
            alpha = 0
            
            UIView.animate(withDuration: 0.2) {
                self.alpha = 1
            }
        }
    }
    
    /// Shows the shield with a blocking message.
    ///
    /// - Parameter reason: Optional reason to display.
    func showBlockingMessage(reason: String?) {
        shieldViewController?.showBlockingMessage(reason: reason)
        
        if isHidden {
            isHidden = false
            alpha = 0
            
            UIView.animate(withDuration: 0.2) {
                self.alpha = 1
            }
        }
    }
    
    /// Hides the shield overlay.
    func hideShield() {
        UIView.animate(withDuration: 0.2) {
            self.alpha = 0
        } completion: { _ in
            self.isHidden = true
            self.shieldViewController?.clearContent()
        }
    }
    
    // MARK: - Hit Testing
    
    /// Pass through touches when the shield is not actively blocking.
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        // When hidden, don't capture any touches
        guard !isHidden else {
            return nil
        }
        
        // Let the shield view controller handle touch blocking logic
        return super.hitTest(point, with: event)
    }
}
