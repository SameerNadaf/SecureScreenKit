//
//  SecureHostingController.swift
//  SecureScreenKit
//
//  Enterprise-grade screen capture protection for iOS
//

import SwiftUI
import Combine

/// A UIHostingController subclass with integrated screen capture protection.
///
/// Use `SecureHostingController` when embedding SwiftUI views in UIKit
/// and you need capture protection at the controller level.
///
/// ## Example Usage
/// ```swift
/// let secureController = SecureHostingController(
///     rootView: SensitiveSwiftUIView(),
///     policy: .obscure(style: .blur(radius: 20))
/// )
/// navigationController.pushViewController(secureController, animated: true)
/// ```
///
/// ## Architecture
/// This controller adds an overlay layer that responds to capture events,
/// working in conjunction with the global shield system.
@MainActor
public final class SecureHostingController<Content: View>: UIHostingController<Content> {
    
    // MARK: - Properties
    
    /// The protection policy for this controller.
    public var policy: CapturePolicy {
        didSet {
            updateProtection()
        }
    }
    
    /// Optional condition for conditional protection.
    public var condition: (any CaptureCondition)? {
        didSet {
            updateProtection()
        }
    }
    
    /// Screen identifier for context.
    public var screenIdentifier: String?
    
    /// User role for context.
    public var userRole: String?
    
    // MARK: - Private Properties
    
    private var cancellables = Set<AnyCancellable>()
    private var overlayView: UIView?
    private let monitor = CaptureMonitor.shared
    private let policyEngine = CapturePolicyEngine.shared
    
    // MARK: - Initialization
    
    /// Creates a secure hosting controller with specified policy.
    ///
    /// - Parameters:
    ///   - rootView: The SwiftUI view to host.
    ///   - policy: The protection policy.
    ///   - condition: Optional condition for conditional protection.
    public init(
        rootView: Content,
        policy: CapturePolicy,
        condition: (any CaptureCondition)? = nil
    ) {
        self.policy = policy
        self.condition = condition
        super.init(rootView: rootView)
    }
    
    @available(*, unavailable)
    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupCaptureMonitoring()
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateProtection()
    }
    
    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        removeOverlay()
    }
    
    // MARK: - Setup
    
    private func setupCaptureMonitoring() {
        monitor.$captureState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateProtection()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Protection
    
    private func updateProtection() {
        let action = policyEngine.resolvePolicy(
            policy,
            condition: condition,
            screenIdentifier: screenIdentifier,
            userRole: userRole
        )
        
        if action.requiresAction {
            showOverlay(for: action)
        } else {
            removeOverlay()
        }
    }
    
    private func showOverlay(for action: ResolvedAction) {
        // Remove existing overlay
        removeOverlay()
        
        let overlay: UIView
        
        switch action {
        case .none:
            return
            
        case .obscure(let style):
            overlay = createObscureOverlay(style: style)
            
        case .block(let reason):
            overlay = createBlockingOverlay(reason: reason)
            
        case .logout:
            overlay = createBlockingOverlay(reason: "Session ended for security")
        }
        
        overlay.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(overlay)
        
        NSLayoutConstraint.activate([
            overlay.topAnchor.constraint(equalTo: view.topAnchor),
            overlay.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            overlay.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            overlay.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // Animate in
        overlay.alpha = 0
        UIView.animate(withDuration: 0.2) {
            overlay.alpha = 1
        }
        
        self.overlayView = overlay
    }
    
    private func removeOverlay() {
        guard let overlay = overlayView else { return }
        
        UIView.animate(withDuration: 0.2) {
            overlay.alpha = 0
        } completion: { _ in
            overlay.removeFromSuperview()
        }
        
        overlayView = nil
    }
    
    private func createObscureOverlay(style: ObscureStyle) -> UIView {
        switch style {
        case .blur(let radius):
            let blurStyle: UIBlurEffect.Style = radius < 15 ? .systemThinMaterial : .systemThickMaterial
            let blurEffect = UIBlurEffect(style: blurStyle)
            let blurView = UIVisualEffectView(effect: blurEffect)
            return blurView
            
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
        container.backgroundColor = .black
        
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        let iconConfig = UIImage.SymbolConfiguration(pointSize: 48, weight: .medium)
        let icon = UIImageView(image: UIImage(systemName: "lock.shield.fill", withConfiguration: iconConfig))
        icon.tintColor = .white
        
        let titleLabel = UILabel()
        titleLabel.text = "Content Protected"
        titleLabel.font = .systemFont(ofSize: 20, weight: .semibold)
        titleLabel.textColor = .white
        
        stack.addArrangedSubview(icon)
        stack.addArrangedSubview(titleLabel)
        
        if let reason = reason {
            let messageLabel = UILabel()
            messageLabel.text = reason
            messageLabel.font = .systemFont(ofSize: 14)
            messageLabel.textColor = UIColor.white.withAlphaComponent(0.8)
            messageLabel.textAlignment = .center
            messageLabel.numberOfLines = 0
            stack.addArrangedSubview(messageLabel)
        }
        
        container.addSubview(stack)
        
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            stack.leadingAnchor.constraint(greaterThanOrEqualTo: container.leadingAnchor, constant: 32),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: container.trailingAnchor, constant: -32)
        ])
        
        return container
    }
}
