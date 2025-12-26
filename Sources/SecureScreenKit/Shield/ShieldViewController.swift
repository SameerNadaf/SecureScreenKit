//
//  ShieldViewController.swift
//  SecureScreenKit
//
//  Enterprise-grade screen capture protection for iOS
//

import UIKit

/// View controller managing the visual content of the shield overlay.
///
/// `ShieldViewController` is responsible for rendering the appropriate
/// obscuring content based on the configured style (blur, blackout, custom,
/// or blocking message).
///
/// ## Architecture
/// This controller is owned by `ShieldWindow` and should not be used directly.
/// It receives commands from `ShieldCoordinator` through the window.
@MainActor
internal final class ShieldViewController: UIViewController {
    
    // MARK: - UI Components
    
    /// Visual effect view for blur styles.
    private lazy var blurEffectView: UIVisualEffectView = {
        let view = UIVisualEffectView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    /// Solid overlay view for blackout style.
    private lazy var blackoutView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .black
        return view
    }()
    
    /// Container for custom views.
    private lazy var customViewContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    /// Stack view for blocking message.
    private lazy var messageStackView: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 16
        return stack
    }()
    
    /// Icon for blocking message.
    private lazy var lockImageView: UIImageView = {
        let config = UIImage.SymbolConfiguration(pointSize: 48, weight: .medium)
        let image = UIImage(systemName: "lock.shield.fill", withConfiguration: config)
        let imageView = UIImageView(image: image)
        imageView.tintColor = .white
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    /// Title label for blocking message.
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Content Protected"
        label.font = .systemFont(ofSize: 20, weight: .semibold)
        label.textColor = .white
        label.textAlignment = .center
        return label
    }()
    
    /// Message label for blocking reason.
    private lazy var messageLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = UIColor.white.withAlphaComponent(0.8)
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    // MARK: - State
    
    private var currentStyle: ObscureStyle?
    private var isShowingBlockMessage = false
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        setupViews()
    }
    
    // MARK: - Setup
    
    private func setupViews() {
        // Add all possible overlay views
        view.addSubview(blurEffectView)
        view.addSubview(blackoutView)
        view.addSubview(customViewContainer)
        view.addSubview(messageStackView)
        
        // Setup message stack
        messageStackView.addArrangedSubview(lockImageView)
        messageStackView.addArrangedSubview(titleLabel)
        messageStackView.addArrangedSubview(messageLabel)
        
        // Constraints for full-screen coverage
        NSLayoutConstraint.activate([
            blurEffectView.topAnchor.constraint(equalTo: view.topAnchor),
            blurEffectView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            blurEffectView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            blurEffectView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            blackoutView.topAnchor.constraint(equalTo: view.topAnchor),
            blackoutView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            blackoutView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            blackoutView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            customViewContainer.topAnchor.constraint(equalTo: view.topAnchor),
            customViewContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            customViewContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            customViewContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            messageStackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            messageStackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            messageStackView.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 32),
            messageStackView.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -32)
        ])
        
        // Start with everything hidden
        hideAllContent()
    }
    
    // MARK: - Content Management
    
    /// Applies the specified obscure style.
    ///
    /// - Parameter style: The style to display.
    func applyStyle(_ style: ObscureStyle) {
        hideAllContent()
        currentStyle = style
        isShowingBlockMessage = false
        
        switch style {
        case .blur(let radius):
            showBlur(radius: radius)
            
        case .blackout:
            showBlackout()
            
        case .custom(let viewProvider):
            showCustomView(viewProvider())
        }
    }
    
    /// Shows a blocking message.
    ///
    /// - Parameter reason: Optional reason to display.
    func showBlockingMessage(reason: String?) {
        hideAllContent()
        currentStyle = nil
        isShowingBlockMessage = true
        
        blackoutView.isHidden = false
        messageStackView.isHidden = false
        
        if let reason = reason {
            messageLabel.text = reason
            messageLabel.isHidden = false
        } else {
            messageLabel.isHidden = true
        }
    }
    
    /// Clears all shield content.
    func clearContent() {
        hideAllContent()
        currentStyle = nil
        isShowingBlockMessage = false
        
        // Remove any custom views
        customViewContainer.subviews.forEach { $0.removeFromSuperview() }
    }
    
    // MARK: - Private Methods
    
    private func hideAllContent() {
        blurEffectView.isHidden = true
        blurEffectView.effect = nil
        blackoutView.isHidden = true
        customViewContainer.isHidden = true
        messageStackView.isHidden = true
    }
    
    private func showBlur(radius: CGFloat) {
        // Map radius to blur effect style
        // iOS doesn't allow custom blur radii, so we approximate
        let style: UIBlurEffect.Style
        
        if radius < 10 {
            style = .systemThinMaterial
        } else if radius < 25 {
            style = .systemMaterial
        } else {
            style = .systemThickMaterial
        }
        
        blurEffectView.effect = UIBlurEffect(style: style)
        blurEffectView.isHidden = false
    }
    
    private func showBlackout() {
        blackoutView.isHidden = false
    }
    
    private func showCustomView(_ customView: UIView) {
        // Remove existing custom views
        customViewContainer.subviews.forEach { $0.removeFromSuperview() }
        
        // Add the new custom view
        customView.translatesAutoresizingMaskIntoConstraints = false
        customViewContainer.addSubview(customView)
        
        NSLayoutConstraint.activate([
            customView.topAnchor.constraint(equalTo: customViewContainer.topAnchor),
            customView.leadingAnchor.constraint(equalTo: customViewContainer.leadingAnchor),
            customView.trailingAnchor.constraint(equalTo: customViewContainer.trailingAnchor),
            customView.bottomAnchor.constraint(equalTo: customViewContainer.bottomAnchor)
        ])
        
        customViewContainer.isHidden = false
    }
    
    // MARK: - Status Bar
    
    override var prefersStatusBarHidden: Bool {
        return false
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
}
