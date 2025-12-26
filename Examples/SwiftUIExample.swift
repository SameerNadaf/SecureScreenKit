//
//  SwiftUIExample.swift
//  SecureScreenKit Examples
//
//  Example usage of SecureScreenKit with SwiftUI
//

import SwiftUI
import SecureScreenKit

// MARK: - App Configuration

/// Example App entry point showing SDK initialization
@main
struct SecureExampleApp: App {
    
    init() {
        // Configure SecureScreenKit at app launch
        configureSecureScreenKit()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
    
    private func configureSecureScreenKit() {
        // Enable protection globally
        SecureScreenConfiguration.shared.isProtectionEnabled = true
        
        // Set default policy for unspecified protection
        SecureScreenConfiguration.shared.defaultPolicy = .obscure(style: .blur(radius: 20))
        
        // Setup violation handler for logging/analytics
        SecureScreenConfiguration.shared.violationHandler = BlockViolationHandler(
            onCaptureStarted: {
                print("📹 Screen recording started!")
                // Add your analytics here
            },
            onCaptureStopped: {
                print("⏹ Screen recording stopped")
            },
            onScreenshot: {
                print("📸 Screenshot taken!")
                // Note: Screenshot already captured at this point
            }
        )
        
        // Start the global shield coordinator
        SecureScreenConfiguration.shared.startProtection()
    }
}

// MARK: - Basic Usage

/// Main content view demonstrating different protection approaches
struct ContentView: View {
    var body: some View {
        NavigationView {
            List {
                NavigationLink("Basic Protection") {
                    BasicProtectionExample()
                }
                NavigationLink("Policy Examples") {
                    PolicyExamplesView()
                }
                NavigationLink("Conditional Protection") {
                    ConditionalProtectionExample()
                }
                NavigationLink("Banking Example") {
                    BankingScreenExample()
                }
            }
            .navigationTitle("SecureScreenKit Demo")
        }
    }
}

// MARK: - Example 1: Basic Protection

struct BasicProtectionExample: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("Basic Protection Example")
                .font(.headline)
            
            // Option 1: SecureContainer
            SecureContainer {
                VStack {
                    Text("🔒 Protected Content")
                        .font(.title)
                    Text("This content is protected using SecureContainer")
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)
            }
            
            // Option 2: View Modifier
            Text("Also Protected via Modifier")
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(8)
                .secureContent() // Uses default policy
        }
        .padding()
        .navigationTitle("Basic")
    }
}

// MARK: - Example 2: Different Policies

struct PolicyExamplesView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                
                // Blur Policy
                Text("Blur Protection")
                    .font(.headline)
                SecureContainer(policy: .obscure(style: .blur(radius: 15))) {
                    SensitiveCard(
                        title: "Account Balance",
                        value: "$12,345.67",
                        color: .blue
                    )
                }
                
                // Blackout Policy
                Text("Blackout Protection")
                    .font(.headline)
                SecureContainer(policy: .obscure(style: .blackout)) {
                    SensitiveCard(
                        title: "Social Security",
                        value: "XXX-XX-1234",
                        color: .purple
                    )
                }
                
                // Block Policy
                Text("Block with Message")
                    .font(.headline)
                SecureContainer(policy: .block(reason: "This content cannot be screen recorded")) {
                    SensitiveCard(
                        title: "Medical Records",
                        value: "Confidential",
                        color: .red
                    )
                }
                
                // Allow Policy (for comparison)
                Text("Allowed Content")
                    .font(.headline)
                SecureContainer(policy: .allow) {
                    SensitiveCard(
                        title: "Public Info",
                        value: "Visible in recordings",
                        color: .green
                    )
                }
            }
            .padding()
        }
        .navigationTitle("Policies")
    }
}

struct SensitiveCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.title2.weight(.semibold))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Example 3: Conditional Protection

struct ConditionalProtectionExample: View {
    @State private var isAdmin = false
    
    var body: some View {
        VStack(spacing: 20) {
            Toggle("Simulate Admin User", isOn: $isAdmin)
                .padding()
            
            // Role-based protection - admins are exempt
            SecureContainer(
                policy: .obscure(style: .blur(radius: 20)),
                condition: RoleBasedCondition(exemptRoles: ["admin"]),
                screenIdentifier: "conditional_demo",
                userRole: isAdmin ? "admin" : "user"
            ) {
                VStack {
                    Image(systemName: isAdmin ? "person.badge.shield.checkmark" : "person.fill")
                        .font(.system(size: 48))
                    Text(isAdmin ? "Admin View (Unprotected)" : "User View (Protected)")
                        .font(.headline)
                    Text("Admins are exempt from screen capture protection")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(12)
            }
            
            Text("Try toggling admin mode and starting screen recording")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .navigationTitle("Conditional")
    }
}

// MARK: - Example 4: Banking App Simulation

struct BankingScreenExample: View {
    let accounts = [
        ("Checking", "$5,432.10"),
        ("Savings", "$12,890.00"),
        ("Investment", "$45,678.90")
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Header (not protected)
            HStack {
                Text("My Accounts")
                    .font(.largeTitle.weight(.bold))
                Spacer()
            }
            .padding()
            
            // Account List (protected)
            SecureContainer(
                policy: .block(reason: "Banking information is protected from screen capture")
            ) {
                VStack(spacing: 12) {
                    ForEach(accounts, id: \.0) { account in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(account.0)
                                    .font(.headline)
                                Text("Available Balance")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Text(account.1)
                                .font(.title2.weight(.semibold))
                                .foregroundColor(.green)
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.1), radius: 2, y: 1)
                    }
                }
                .padding()
            }
            
            Spacer()
            
            // Footer info
            Text("Start screen recording to see protection in action")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Banking")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Preview

#Preview {
    ContentView()
}
