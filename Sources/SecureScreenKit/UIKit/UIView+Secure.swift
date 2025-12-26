//
//  UIView+Secure.swift
//  SecureScreenKit
//
//  Enterprise-grade screen capture protection for iOS
//

import UIKit
import Combine

/// Extension providing screen capture protection for UIView.
///
/// This extension adds the ability to protect individual views from
/// screen capture using both the secure text container technique
/// and overlay-based protection.
public extension UIView {
    
    // MARK: - Associated Keys
    
    private enum AssociatedKeys {
        static var secureContainer = "secureContainer"
        static var overlayView = "overlayView"
        static var cancellables = "cancellables"
        static var policy = "policy"
        static var condition = "condition"
    }
    
    // MARK: - Properties
    
    /// The secure container wrapping this view (if any).
    private var secureContainer: UIView? {
        get {
            objc_getAssociatedObject(self, &AssociatedKeys.secureContainer) as? UIView
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.secureContainer, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    /// The protection overlay on this view (if any).
    private var protectionOverlay: UIView? {
        get {
            objc_getAssociatedObject(self, &AssociatedKeys.overlayView) as? UIView
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.overlayView, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    /// Cancellables for Combine subscriptions.
    private var secureCancellables: Set<AnyCancellable> {
        get {
            objc_getAssociatedObject(self, &AssociatedKeys.cancellables) as? Set<AnyCancellable> ?? Set<AnyCancellable>()
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.cancellables, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    /// The current protection policy for this view.
    private(set) var securePolicy: CapturePolicy? {
        get {
            objc_getAssociatedObject(self, &AssociatedKeys.policy) as? CapturePolicy
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.policy, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    // MARK: - Secure Text Container
    
    /// Wraps this view in a secure text container that hides content during capture.
    ///
    /// This technique uses `UITextField.isSecureTextEntry` which causes iOS
    /// to exclude the content from screen captures. This is the most reliable
    /// method for hiding content but has some UI limitations.
    ///
    /// ## Limitations
    /// - The view must be added as a subview of the secure container's layer
    /// - Some animation and layout behaviors may differ
    /// - Best for static content that doesn't need interaction
    ///
    /// - Returns: The secure container view that now hosts this view.
    @discardableResult
    func wrapInSecureContainer() -> UIView {
        // Remove any existing container
        removeFromSecureContainer()
        
        // Create the secure text field (hidden but functional)
        let secureTextField = UITextField()
        secureTextField.isSecureTextEntry = true
        secureTextField.isUserInteractionEnabled = false
        secureTextField.translatesAutoresizingMaskIntoConstraints = false
        
        // Get the secure layer from the text field
        guard let secureLayer = secureTextField.layer.sublayers?.first else {
            // Fallback: just return the view's existing superview or self
            return superview ?? self
        }
        
        // Create container
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        
        // Store original position
        let originalSuperview = superview
        let originalFrame = frame
        let originalConstraints = constraints
        
        // Move this view into secure layer
        removeFromSuperview()
        secureLayer.addSublayer(layer)
        
        // Add text field to container
        container.addSubview(secureTextField)
        
        // Add container to original superview
        if let superview = originalSuperview {
            container.frame = originalFrame
            superview.addSubview(container)
            
            // Restore constraints on container if possible
            for constraint in originalConstraints {
                if constraint.firstItem as? UIView === self {
                    let newConstraint = NSLayoutConstraint(
                        item: container,
                        attribute: constraint.firstAttribute,
                        relatedBy: constraint.relation,
                        toItem: constraint.secondItem,
                        attribute: constraint.secondAttribute,
                        multiplier: constraint.multiplier,
                        constant: constraint.constant
                    )
                    newConstraint.isActive = true
                }
            }
        }
        
        // Store reference
        self.secureContainer = container
        
        return container
    }
    
    /// Removes this view from its secure container.
    func removeFromSecureContainer() {
        guard let container = secureContainer else { return }
        
        // Restore this view's layer to a normal view
        if let superview = container.superview {
            translatesAutoresizingMaskIntoConstraints = false
            superview.insertSubview(self, aboveSubview: container)
            frame = container.frame
        }
        
        container.removeFromSuperview()
        self.secureContainer = nil
    }
    
    // MARK: - Overlay Protection
    
    /// Enables capture protection on this view with the specified policy.
    ///
    /// When screen capture is detected, an overlay matching the policy
    /// will be shown over this view.
    ///
    /// - Parameters:
    ///   - policy: The protection policy to apply.
    ///   - condition: Optional condition for conditional protection.
    func enableCaptureProtection(
        policy: CapturePolicy,
        condition: (any CaptureCondition)? = nil
    ) {
        // Store policy
        securePolicy = policy
        
        // Cancel any existing subscriptions
        secureCancellables.removeAll()
        
        // Subscribe to capture state changes
        var cancellables = self.secureCancellables
        
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            
            CaptureMonitor.shared.$captureState
                .receive(on: DispatchQueue.main)
                .sink { [weak self] _ in
                    self?.updateViewProtection(policy: policy, condition: condition)
                }
                .store(in: &cancellables)
            
            self.secureCancellables = cancellables
            
            // Initial check
            self.updateViewProtection(policy: policy, condition: condition)
        }
    }
    
    /// Disables capture protection on this view.
    func disableCaptureProtection() {
        secureCancellables.removeAll()
        securePolicy = nil
        removeProtectionOverlay()
    }
    
    // MARK: - Private Methods
    
    private func updateViewProtection(
        policy: CapturePolicy,
        condition: (any CaptureCondition)?
    ) {
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            
            let engine = CapturePolicyEngine.shared
            let action = engine.resolvePolicy(policy, condition: condition)
            
            if action.requiresAction {
                self.showProtectionOverlay(for: action)
            } else {
                self.removeProtectionOverlay()
            }
        }
    }
    
    private func showProtectionOverlay(for action: ResolvedAction) {
        // Remove existing overlay
        removeProtectionOverlay()
        
        let overlay: UIView
        
        switch action {
        case .none:
            return
            
        case .obscure(let style):
            overlay = createObscureOverlay(style: style)
            
        case .block(let reason):
            overlay = createBlockingOverlay(reason: reason)
            
        case .logout:
            overlay = createBlockingOverlay(reason: "Session ended")
        }
        
        overlay.translatesAutoresizingMaskIntoConstraints = false
        addSubview(overlay)
        
        NSLayoutConstraint.activate([
            overlay.topAnchor.constraint(equalTo: topAnchor),
            overlay.leadingAnchor.constraint(equalTo: leadingAnchor),
            overlay.trailingAnchor.constraint(equalTo: trailingAnchor),
            overlay.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        self.protectionOverlay = overlay
    }
    
    private func removeProtectionOverlay() {
        protectionOverlay?.removeFromSuperview()
        protectionOverlay = nil
    }
    
    private func createObscureOverlay(style: ObscureStyle) -> UIView {
        switch style {
        case .blur(let radius):
            let blurStyle: UIBlurEffect.Style = radius < 15 ? .systemThinMaterial : .systemThickMaterial
            let blurEffect = UIBlurEffect(style: blurStyle)
            return UIVisualEffectView(effect: blurEffect)
            
        case .blackout:
            let view = UIView()
            view.backgroundColor = .black
            return view
            
        case .custom(let viewProvider):
            return viewProvider()
        }
    }
    
    private func createBlockingOverlay(reason: String?) -> UIView {
        let container = UIView()
        container.backgroundColor = .black.withAlphaComponent(0.9)
        
        let label = UILabel()
        label.text = reason ?? "Protected"
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .white
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        
        container.addSubview(label)
        
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])
        
        return container
    }
}

// MARK: - UIViewController Extension

public extension UIViewController {
    
    /// Configures screen capture protection for this view controller.
    ///
    /// This method adds capture monitoring and will show an overlay
    /// when screen capture is detected, based on the specified policy.
    ///
    /// - Parameters:
    ///   - policy: The protection policy to apply.
    ///   - condition: Optional condition for conditional protection.
    func secure(
        policy: CapturePolicy,
        condition: (any CaptureCondition)? = nil
    ) {
        view.enableCaptureProtection(policy: policy, condition: condition)
    }
    
    /// Removes screen capture protection from this view controller.
    func removeSecure() {
        view.disableCaptureProtection()
    }
}
