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
        
        // Example: Log to analytics
        // Analytics.log("screenshot_taken", screen: currentScreen)
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
        "Basic SecureViewController",
        "View Extension Protection",
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
        cell.accessoryType = .disclosureIndicator
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let viewController: UIViewController
        
        switch indexPath.row {
        case 0:
            viewController = BasicSecureExampleVC()
        case 1:
            viewController = ViewExtensionExampleVC()
        case 2:
            viewController = PolicyComparisonVC()
        case 3:
            viewController = BankingExampleVC()
        default:
            return
        }
        
        navigationController?.pushViewController(viewController, animated: true)
    }
}

// MARK: - Example 2: Basic SecureViewController Subclass

/// Example of subclassing SecureViewController for automatic protection
class BasicSecureExampleVC: SecureViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "SecureViewController"
        view.backgroundColor = .systemBackground
        
        // Configure protection policy
        policy = .obscure(style: .blur(radius: 25))
        
        // Add content
        setupUI()
    }
    
    private func setupUI() {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 16
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        let iconView = UIImageView(image: UIImage(systemName: "lock.shield.fill"))
        iconView.tintColor = .systemBlue
        iconView.contentMode = .scaleAspectFit
        iconView.heightAnchor.constraint(equalToConstant: 60).isActive = true
        
        let titleLabel = UILabel()
        titleLabel.text = "Protected Content"
        titleLabel.font = .systemFont(ofSize: 24, weight: .bold)
        
        let descLabel = UILabel()
        descLabel.text = "This view controller is protected.\nStart screen recording to see the blur effect."
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

// MARK: - Example 3: Using View/ViewController Extension

/// Example of using the secure() extension on a regular UIViewController
class ViewExtensionExampleVC: UIViewController {
    
    private let sensitiveView = UIView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Extension Example"
        view.backgroundColor = .systemBackground
        
        setupUI()
        
        // Apply protection using the extension
        // Option 1: Protect the entire view controller
        secure(policy: .obscure(style: .blackout))
        
        // Option 2: Protect a specific view
        // sensitiveView.enableCaptureProtection(policy: .block(reason: "Protected"))
    }
    
    private func setupUI() {
        sensitiveView.backgroundColor = .systemPurple.withAlphaComponent(0.1)
        sensitiveView.layer.cornerRadius = 12
        sensitiveView.translatesAutoresizingMaskIntoConstraints = false
        
        let label = UILabel()
        label.text = "Sensitive Data: ****-****-****-1234"
        label.font = .monospacedSystemFont(ofSize: 16, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        
        sensitiveView.addSubview(label)
        view.addSubview(sensitiveView)
        
        NSLayoutConstraint.activate([
            sensitiveView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            sensitiveView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            sensitiveView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            sensitiveView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            sensitiveView.heightAnchor.constraint(equalToConstant: 100),
            
            label.centerXAnchor.constraint(equalTo: sensitiveView.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: sensitiveView.centerYAnchor)
        ])
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Clean up protection when leaving
        removeSecure()
    }
}

// MARK: - Example 4: Policy Comparison

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
            description: "Content is blurred",
            policy: .obscure(style: .blur(radius: 20)),
            color: .systemBlue
        ))
        
        stack.addArrangedSubview(createPolicyCard(
            title: "Blackout",
            description: "Content is completely hidden",
            policy: .obscure(style: .blackout),
            color: .systemGray
        ))
        
        stack.addArrangedSubview(createPolicyCard(
            title: "Block",
            description: "Shows blocking message",
            policy: .block(reason: "Recording not allowed"),
            color: .systemRed
        ))
        
        stack.addArrangedSubview(createPolicyCard(
            title: "Allow",
            description: "No protection",
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
        
        // Apply protection to this card
        card.enableCaptureProtection(policy: policy)
        
        return card
    }
}

// MARK: - Example 5: Banking Screen

/// Realistic banking screen example
class BankingExampleVC: SecureViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "My Accounts"
        view.backgroundColor = .systemGroupedBackground
        
        // Block with reason for banking data
        policy = .block(reason: "Banking information is protected from screen capture")
        
        setupUI()
    }
    
    private func setupUI() {
        let tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
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
        "Start screen recording to see protection in action"
    }
}
