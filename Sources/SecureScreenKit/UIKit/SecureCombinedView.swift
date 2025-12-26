//
//  SecureCombinedView.swift
//  SecureScreenKit
//
//  Complete protection: hides content from BOTH screenshots AND recordings (UIKit)
//

import UIKit
import Combine

/// A UIView container that provides COMPLETE protection for its content.
///
/// `SecureCombinedView` combines two protection techniques:
/// 1. **Screenshot Protection**: Uses `isSecureTextEntry` trick to make content invisible in screenshots
/// 2. **Recording Protection**: Shows overlay during screen recording
///
/// ## Example Usage
/// ```swift
/// let secureView = SecureCombinedView()
/// secureView.addSecureContent(sensitiveView)
/// view.addSubview(secureView)
/// ```
///
/// - Important: Content inside this view will be hidden from BOTH screenshots AND screen recordings.
@available(iOS 14.0, *)
@MainActor
public class SecureCombinedView: UIView {
    
    // MARK: - Properties
    
    /// The protection policy for recording overlay.
    public var policy: CapturePolicy {
        didSet {
            updateRecordingProtection()
        }
    }
    
    // MARK: - Private Properties
    
    private let secureTextField = UITextField()
    private var contentContainer: UIView?
    private var secureLayer: CALayer?
    
    private var cancellables = Set<AnyCancellable>()
    private let monitor = CaptureMonitor.shared
    private var overlayView: UIView?
    private var isMonitoring = false
    
    // MARK: - Initialization
    
    /// Creates a combined secure view with default blur policy.
    public convenience init() {
        self.init(policy: .obscure(style: .blur(radius: 25)))
    }
    
    /// Creates a combined secure view with a custom policy.
    ///
    /// - Parameter policy: The policy to apply during screen recording.
    public init(policy: CapturePolicy) {
        self.policy = policy
        super.init(frame: .zero)
        setup()
    }
    
    required init?(coder: NSCoder) {
        self.policy = .obscure(style: .blur(radius: 25))
        super.init(coder: coder)
        setup()
    }
    
    deinit {
        cancellables.removeAll()
    }
    
    // MARK: - Setup
    
    private func setup() {
        backgroundColor = .clear
        clipsToBounds = true
        
        // Setup secure text field for screenshot protection
        setupSecureTextField()
    }
    
    private func setupSecureTextField() {
        // Configure the text field to be secure (this creates the secure layer)
        secureTextField.isSecureTextEntry = true
        secureTextField.isUserInteractionEnabled = false
        secureTextField.translatesAutoresizingMaskIntoConstraints = false
        
        // Add to view hierarchy
        insertSubview(secureTextField, at: 0)
        
        // Make text field invisible but present
        NSLayoutConstraint.activate([
            secureTextField.widthAnchor.constraint(equalToConstant: 0),
            secureTextField.heightAnchor.constraint(equalToConstant: 0),
            secureTextField.centerXAnchor.constraint(equalTo: centerXAnchor),
            secureTextField.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
        
        // Trigger layout to create secure layer
        secureTextField.layoutIfNeeded()
        
        // Find the secure layer
        DispatchQueue.main.async { [weak self] in
            self?.findAndStoreSecureLayer()
        }
    }
    
    private func findAndStoreSecureLayer() {
        // Search for secure layer in text field subviews
        for subview in secureTextField.subviews {
            if let layer = subview.layer.sublayers?.first {
                self.secureLayer = layer
                
                // If content was already added, move it to secure layer
                if let content = contentContainer {
                    moveContentToSecureLayer(content)
                }
                return
            }
        }
        
        // Fallback: check layer sublayers
        if let layer = secureTextField.layer.sublayers?.first {
            self.secureLayer = layer
            
            if let content = contentContainer {
                moveContentToSecureLayer(content)
            }
        }
    }
    
    // MARK: - Public Methods
    
    /// Adds content that will be protected from both screenshots and recordings.
    ///
    /// - Parameter view: The view to protect.
    public func addSecureContent(_ view: UIView) {
        // Remove existing content
        contentContainer?.removeFromSuperview()
        
        view.translatesAutoresizingMaskIntoConstraints = false
        addSubview(view)
        
        // Set constraints
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: topAnchor),
            view.leadingAnchor.constraint(equalTo: leadingAnchor),
            view.trailingAnchor.constraint(equalTo: trailingAnchor),
            view.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        contentContainer = view
        
        // Move to secure layer if available (for screenshot protection)
        if let secureLayer = secureLayer {
            moveContentToSecureLayer(view)
        }
        
        // Start recording monitoring
        startMonitoring()
    }
    
    private func moveContentToSecureLayer(_ view: UIView) {
        guard let secureLayer = secureLayer else { return }
        
        // Move the view's layer to secure layer for screenshot protection
        view.layer.removeFromSuperlayer()
        secureLayer.addSublayer(view.layer)
    }
    
    // MARK: - Recording Protection
    
    private func startMonitoring() {
        guard !isMonitoring else { return }
        isMonitoring = true
        
        monitor.$isRecording
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isRecording in
                if isRecording {
                    self?.showRecordingOverlay()
                } else {
                    self?.removeRecordingOverlay()
                }
            }
            .store(in: &cancellables)
        
        // Check initial state
        if monitor.isRecording {
            showRecordingOverlay()
        }
    }
    
    private func stopMonitoring() {
        isMonitoring = false
        cancellables.removeAll()
        removeRecordingOverlay()
    }
    
    private func updateRecordingProtection() {
        if monitor.isRecording {
            showRecordingOverlay()
        }
    }
    
    private func showRecordingOverlay() {
        // Remove existing overlay
        removeRecordingOverlay()
        
        let overlay: UIView
        
        switch policy {
        case .allow:
            return
            
        case .obscure(let style):
            overlay = createObscureOverlay(style: style)
            
        case .block(let reason):
            overlay = createBlockingOverlay(reason: reason)
            
        case .logout:
            overlay = createBlockingOverlay(reason: "Session ended for security")
        }
        
        overlay.translatesAutoresizingMaskIntoConstraints = false
        addSubview(overlay)
        
        NSLayoutConstraint.activate([
            overlay.topAnchor.constraint(equalTo: topAnchor),
            overlay.leadingAnchor.constraint(equalTo: leadingAnchor),
            overlay.trailingAnchor.constraint(equalTo: trailingAnchor),
            overlay.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        self.overlayView = overlay
    }
    
    private func removeRecordingOverlay() {
        overlayView?.removeFromSuperview()
        overlayView = nil
    }
    
    private func createObscureOverlay(style: ObscureStyle) -> UIView {
        switch style {
        case .blur(let radius):
            let blurStyle: UIBlurEffect.Style
            if radius < 10 {
                blurStyle = .systemThinMaterial
            } else if radius < 25 {
                blurStyle = .systemMaterial
            } else {
                blurStyle = .systemThickMaterial
            }
            return UIVisualEffectView(effect: UIBlurEffect(style: blurStyle))
            
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
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        let iconConfig = UIImage.SymbolConfiguration(pointSize: 32, weight: .medium)
        let icon = UIImageView(image: UIImage(systemName: "lock.shield.fill", withConfiguration: iconConfig))
        icon.tintColor = .white
        
        let titleLabel = UILabel()
        titleLabel.text = "Content Protected"
        titleLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        titleLabel.textColor = .white
        
        stack.addArrangedSubview(icon)
        stack.addArrangedSubview(titleLabel)
        
        if let reason = reason {
            let messageLabel = UILabel()
            messageLabel.text = reason
            messageLabel.font = .systemFont(ofSize: 13)
            messageLabel.textColor = UIColor.white.withAlphaComponent(0.8)
            messageLabel.textAlignment = .center
            messageLabel.numberOfLines = 0
            stack.addArrangedSubview(messageLabel)
        }
        
        container.addSubview(stack)
        
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            stack.leadingAnchor.constraint(greaterThanOrEqualTo: container.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: container.trailingAnchor, constant: -16)
        ])
        
        return container
    }
    
    // MARK: - Layout
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        // Ensure content layer stays properly sized in secure layer
        if let secureLayer = secureLayer {
            secureLayer.sublayers?.forEach { sublayer in
                sublayer.frame = bounds
            }
        }
    }
    
    // MARK: - Lifecycle
    
    public override func willMove(toWindow newWindow: UIWindow?) {
        super.willMove(toWindow: newWindow)
        
        if newWindow != nil && contentContainer != nil {
            startMonitoring()
        }
    }
    
    public override func removeFromSuperview() {
        stopMonitoring()
        super.removeFromSuperview()
    }
}
