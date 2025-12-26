//
//  UIKitExample.swift
//  SecureScreenKit Examples
//
//  Example usage of SecureScreenKit with UIKit
//

import UIKit
import SecureScreenKit

// MARK: - AppDelegate Configuration

/// Example AppDelegate showing SDK initialization for UIKit apps
class ExampleAppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        
        // Configure SecureScreenKit
        configureSecureScreenKit()
        
        // Setup window
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = UINavigationController(
            rootViewController: ExampleMenuViewController()
        )
        window?.makeKeyAndVisible()
        
        return true
    }
    
    private func configureSecureScreenKit() {
        Task { @MainActor in
            // Enable protection
            SecureScreenConfiguration.shared.isProtectionEnabled = true
            
            // Set default policy
            SecureScreenConfiguration.shared.defaultPolicy = .obscure(style: .blur(radius: 20))
            
            // Setup custom violation handler
            SecureScreenConfiguration.shared.violationHandler = ExampleViolationHandler()
            
            // Start global protection
            SecureScreenConfiguration.shared.startProtection()
        }
    }
}

// MARK: - Custom Violation Handler

class ExampleViolationHandler: ViolationHandler {
    
    @MainActor
    func didStartScreenCapture() {
        print("🔴 [Security] Screen recording detected!")
        
        // Example: Show alert to user
        showSecurityAlert(
            title: "Screen Recording Detected",
            message: "Some content has been hidden for your security."
        )
    }
    
    @MainActor
    func didStopScreenCapture() {
        print("🟢 [Security] Screen recording stopped")
    }
    
    @MainActor
    func screenshotTaken() {
        print("📸 [Security] Screenshot captured")
    }
    
    @MainActor
    private func showSecurityAlert(title: String, message: String) {
        guard let topVC = UIApplication.shared.windows.first?.rootViewController else { return }
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        topVC.present(alert, animated: true)
    }
}

// MARK: - Example 1: Menu View Controller

class ExampleMenuViewController: UITableViewController {
    
    private let examples = [
        "Complete Protection (Screenshot + Recording)",
        "Screenshot Protection Only",
        "Recording Protection Only",
        "Policy Comparison",
        "Banking Screen Example"
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "UIKit Examples"
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        examples.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = examples[indexPath.row]
        cell.textLabel?.numberOfLines = 0
        cell.accessoryType = .disclosureIndicator
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let viewController: UIViewController
        
        switch indexPath.row {
        case 0:
            viewController = CompleteProtectionExampleVC()
        case 1:
            viewController = ScreenshotProtectionExampleVC()
        case 2:
            viewController = RecordingProtectionExampleVC()
        case 3:
            viewController = PolicyComparisonVC()
        case 4:
            viewController = BankingExampleVC()
        default:
            return
        }
        
        navigationController?.pushViewController(viewController, animated: true)
    }
}

// MARK: - Example 2: Complete Protection (Screenshot + Recording)

/// Example using ScreenProtectedUIView for complete protection
class CompleteProtectionExampleVC: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Complete Protection"
        view.backgroundColor = .systemBackground
        
        setupUI()
    }
    
    private func setupUI() {
        // Create the sensitive content
        let sensitiveView = createSensitiveContentView()
        
        // Wrap in ScreenProtectedUIView for BOTH screenshot AND recording protection
        let protectedView = ScreenProtectedUIView(policy: .obscure(style: .blur(radius: 25)))
        protectedView.translatesAutoresizingMaskIntoConstraints = false
        protectedView.addSecureContent(sensitiveView)
        
        view.addSubview(protectedView)
        
        NSLayoutConstraint.activate([
            protectedView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            protectedView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            protectedView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            protectedView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            protectedView.heightAnchor.constraint(equalToConstant: 150)
        ])
        
        // Add info label
        let infoLabel = UILabel()
        infoLabel.text = "This content is hidden from BOTH screenshots AND recordings"
        infoLabel.font = .systemFont(ofSize: 12)
        infoLabel.textColor = .secondaryLabel
        infoLabel.textAlignment = .center
        infoLabel.numberOfLines = 0
        infoLabel.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(infoLabel)
        
        NSLayoutConstraint.activate([
            infoLabel.topAnchor.constraint(equalTo: protectedView.bottomAnchor, constant: 16),
            infoLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            infoLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
    }
    
    private func createSensitiveContentView() -> UIView {
        let container = UIView()
        container.backgroundColor = .systemPurple.withAlphaComponent(0.1)
        container.layer.cornerRadius = 12
        
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        let iconView = UIImageView(image: UIImage(systemName: "lock.shield.fill"))
        iconView.tintColor = .systemPurple
        iconView.contentMode = .scaleAspectFit
        iconView.heightAnchor.constraint(equalToConstant: 40).isActive = true
        
        let titleLabel = UILabel()
        titleLabel.text = "Fully Protected Content"
        titleLabel.font = .systemFont(ofSize: 20, weight: .bold)
        
        let descLabel = UILabel()
        descLabel.text = "Hidden from screenshots AND recordings"
        descLabel.textColor = .secondaryLabel
        descLabel.font = .systemFont(ofSize: 14)
        
        stack.addArrangedSubview(iconView)
        stack.addArrangedSubview(titleLabel)
        stack.addArrangedSubview(descLabel)
        
        container.addSubview(stack)
        
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])
        
        return container
    }
}

// MARK: - Example 3: Screenshot Protection Only

/// Example using ScreenshotProofUIView for screenshot protection only
class ScreenshotProtectionExampleVC: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Screenshot Protection"
        view.backgroundColor = .systemBackground
        
        setupUI()
    }
    
    private func setupUI() {
        // Create the sensitive content
        let sensitiveView = createSensitiveContentView()
        
        // Wrap in ScreenshotProofUIView - invisible in screenshots
        let screenshotProofView = ScreenshotProofUIView()
        screenshotProofView.translatesAutoresizingMaskIntoConstraints = false
        screenshotProofView.addSecureSubview(sensitiveView)
        
        view.addSubview(screenshotProofView)
        
        NSLayoutConstraint.activate([
            screenshotProofView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            screenshotProofView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            screenshotProofView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            screenshotProofView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            screenshotProofView.heightAnchor.constraint(equalToConstant: 150)
        ])
        
        // Add info label
        let infoLabel = UILabel()
        infoLabel.text = "Take a screenshot - this content will be INVISIBLE!"
        infoLabel.font = .systemFont(ofSize: 12)
        infoLabel.textColor = .secondaryLabel
        infoLabel.textAlignment = .center
        infoLabel.numberOfLines = 0
        infoLabel.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(infoLabel)
        
        NSLayoutConstraint.activate([
            infoLabel.topAnchor.constraint(equalTo: screenshotProofView.bottomAnchor, constant: 16),
            infoLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            infoLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
    }
    
    private func createSensitiveContentView() -> UIView {
        let container = UIView()
        container.backgroundColor = .systemBlue.withAlphaComponent(0.1)
        container.layer.cornerRadius = 12
        
        let label = UILabel()
        label.text = "📸 Screenshot-Proof Content"
        label.font = .systemFont(ofSize: 18, weight: .semibold)
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

// MARK: - Example 4: Recording Protection Only

/// Example using RecordingProtectedViewController
class RecordingProtectionExampleVC: RecordingProtectedViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Recording Protection"
        view.backgroundColor = .systemBackground
        
        // Configure protection policy
        policy = .obscure(style: .blur(radius: 25))
        
        setupUI()
    }
    
    private func setupUI() {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 16
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        let iconView = UIImageView(image: UIImage(systemName: "video.fill"))
        iconView.tintColor = .systemGreen
        iconView.contentMode = .scaleAspectFit
        iconView.heightAnchor.constraint(equalToConstant: 60).isActive = true
        
        let titleLabel = UILabel()
        titleLabel.text = "Recording-Protected Content"
        titleLabel.font = .systemFont(ofSize: 24, weight: .bold)
        
        let descLabel = UILabel()
        descLabel.text = "An overlay appears during screen recording.\nStart recording to see the blur effect."
        descLabel.textAlignment = .center
        descLabel.numberOfLines = 0
        descLabel.textColor = .secondaryLabel
        
        stack.addArrangedSubview(iconView)
        stack.addArrangedSubview(titleLabel)
        stack.addArrangedSubview(descLabel)
        
        view.addSubview(stack)
        
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stack.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 32),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -32)
        ])
    }
}

// MARK: - Example 5: Policy Comparison

/// Shows different policies side by side
class PolicyComparisonVC: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Policy Comparison"
        view.backgroundColor = .systemGroupedBackground
        
        setupUI()
    }
    
    private func setupUI() {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 20
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        // Add policy examples
        stack.addArrangedSubview(createPolicyCard(
            title: "Blur",
            description: "Content is blurred during recording",
            policy: .obscure(style: .blur(radius: 20)),
            color: .systemBlue
        ))
        
        stack.addArrangedSubview(createPolicyCard(
            title: "Blackout",
            description: "Content is completely hidden during recording",
            policy: .obscure(style: .blackout),
            color: .systemGray
        ))
        
        stack.addArrangedSubview(createPolicyCard(
            title: "Block",
            description: "Shows blocking message during recording",
            policy: .block(reason: "Recording not allowed"),
            color: .systemRed
        ))
        
        stack.addArrangedSubview(createPolicyCard(
            title: "Allow",
            description: "No protection applied",
            policy: .allow,
            color: .systemGreen
        ))
        
        view.addSubview(scrollView)
        scrollView.addSubview(stack)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            stack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 20),
            stack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -20),
            stack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -20),
            stack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -40)
        ])
    }
    
    private func createPolicyCard(
        title: String,
        description: String,
        policy: CapturePolicy,
        color: UIColor
    ) -> UIView {
        let card = UIView()
        card.backgroundColor = color.withAlphaComponent(0.1)
        card.layer.cornerRadius = 12
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        
        let descLabel = UILabel()
        descLabel.text = description
        descLabel.font = .systemFont(ofSize: 14)
        descLabel.textColor = .secondaryLabel
        
        let stack = UIStackView(arrangedSubviews: [titleLabel, descLabel])
        stack.axis = .vertical
        stack.spacing = 4
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        card.addSubview(stack)
        
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16)
        ])
        
        // Apply recording protection to this card
        card.enableRecordingProtection(policy: policy)
        
        return card
    }
}

// MARK: - Example 6: Banking Screen

/// Realistic banking screen example with complete protection
class BankingExampleVC: UIViewController {
    
    private var protectedView: ScreenProtectedUIView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "My Accounts"
        view.backgroundColor = .systemGroupedBackground
        
        setupUI()
    }
    
    private func setupUI() {
        // Create table view content
        let tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        
        // Wrap in ScreenProtectedUIView for complete protection
        let protected = ScreenProtectedUIView(policy: .block(reason: "Banking information is protected"))
        protected.translatesAutoresizingMaskIntoConstraints = false
        protected.addSecureContent(tableView)
        
        view.addSubview(protected)
        self.protectedView = protected
        
        NSLayoutConstraint.activate([
            protected.topAnchor.constraint(equalTo: view.topAnchor),
            protected.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            protected.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            protected.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
}

extension BankingExampleVC: UITableViewDataSource {
    
    private var accounts: [(String, String)] {
        [
            ("Checking Account", "$5,432.10"),
            ("Savings Account", "$12,890.00"),
            ("Investment", "$45,678.90"),
            ("Credit Card", "-$1,234.56")
        ]
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        accounts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let account = accounts[indexPath.row]
        
        var config = cell.defaultContentConfiguration()
        config.text = account.0
        config.secondaryText = account.1
        config.secondaryTextProperties.font = .monospacedSystemFont(ofSize: 16, weight: .medium)
        config.secondaryTextProperties.color = account.1.hasPrefix("-") ? .systemRed : .systemGreen
        
        cell.contentConfiguration = config
        cell.accessoryType = .disclosureIndicator
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        "Available Balances"
    }
    
    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        "Protected from BOTH screenshots AND screen recordings"
    }
}
