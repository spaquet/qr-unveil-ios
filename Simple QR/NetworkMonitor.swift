//
//  NetworkMonitor.swift
//  QR Unveil
//
//  Created by Stéphane PAQUET on 3/15/25.
//

import Network
import Foundation
import Combine

/// A class that monitors network connectivity status throughout the application.
/// This singleton class uses Apple's Network framework to track internet connection status
/// and connection type, providing real-time updates via Combine publishers.
///
/// Key features:
/// - Detects whether the device has an active internet connection
/// - Identifies the connection type (WiFi, cellular, ethernet)
/// - Publishes state changes for reactive UI updates
/// - Provides convenience properties for common connection checks
public final class NetworkMonitor: ObservableObject {
    /// Shared instance for app-wide use
    /// Use this singleton to access network status throughout the app
    public static let shared = NetworkMonitor()
    
    /// Published property that indicates if the device is connected to the internet
    /// This property can be observed using Combine to react to connectivity changes
    @Published public private(set) var isConnected = false
    
    /// Published property that provides the current connection type
    /// Updates whenever the connection type changes (e.g., from cellular to WiFi)
    @Published public private(set) var connectionType: ConnectionType = .unknown
    
    /// NWPathMonitor instance to monitor network changes
    /// The core Apple Network framework component that detects connectivity changes
    private let monitor = NWPathMonitor()
    
    /// Queue for network monitoring operations
    /// Uses a background queue to avoid blocking the main thread
    private let queue = DispatchQueue(label: "NetworkMonitorQueue", qos: .background)
    
    /// Connection types that can be detected by the NetworkMonitor
    public enum ConnectionType {
        /// Device is connected via WiFi
        case wifi
        
        /// Device is connected via cellular network (3G, 4G, 5G, etc.)
        case cellular
        
        /// Device is connected via wired ethernet (rare on iOS devices, common on macOS)
        case ethernet
        
        /// Connection type cannot be determined or is not one of the above types
        case unknown
    }
    
    /// Private initializer to enforce singleton pattern
    /// Starts monitoring network status upon initialization
    private init() {
        startMonitoring()
    }
    
    /// Cleanup when this instance is deallocated
    /// Ensures the network monitoring is properly stopped
    deinit {
        stopMonitoring()
    }
    
    /// Starts monitoring network status changes
    /// Call this method to begin tracking network connectivity if monitoring was stopped
    public func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self = self else { return }
            
            // Check connectivity status on the main thread since we'll update published properties
            // which may trigger UI updates that must happen on the main thread
            DispatchQueue.main.async {
                self.isConnected = path.status == .satisfied
                self.determineConnectionType(path)
            }
        }
        
        // Start monitoring on the background queue
        monitor.start(queue: queue)
    }
    
    /// Stops monitoring network status changes
    /// Call this method when network monitoring is no longer needed
    /// to free up system resources
    public func stopMonitoring() {
        monitor.cancel()
    }
    
    /// Determines the type of network connection from the provided path
    /// This method analyzes the NWPath to identify the specific interface type being used
    ///
    /// - Parameter path: The network path to analyze
    private func determineConnectionType(_ path: NWPath) {
        if path.usesInterfaceType(.wifi) {
            connectionType = .wifi
        } else if path.usesInterfaceType(.cellular) {
            connectionType = .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            connectionType = .ethernet
        } else {
            connectionType = .unknown
        }
    }
    
    // MARK: - Convenience Accessors
    
    /// Convenience property to check if the network is currently reachable
    /// Equivalent to checking isConnected directly
    public var isReachable: Bool {
        return isConnected
    }
    
    /// Convenience property to check if the current connection is via WiFi
    /// Useful for determining when to perform bandwidth-intensive operations
    public var isWiFi: Bool {
        return connectionType == .wifi
    }
    
    /// Convenience property to check if the current connection is via cellular
    /// Useful for showing data usage warnings or limiting bandwidth usage
    public var isCellular: Bool {
        return connectionType == .cellular
    }
}

// MARK: - Example Usage
/*
 How to use NetworkMonitor in your app:
 
 // SwiftUI View example:
 // This example shows how to observe network status changes in a SwiftUI view
 // and update the UI accordingly
 struct ContentView: View {
     @ObservedObject private var networkMonitor = NetworkMonitor.shared
     
     var body: some View {
         VStack {
             if networkMonitor.isConnected {
                 Text("Connected to the internet")
                     .foregroundColor(.green)
             } else {
                 Text("No internet connection")
                     .foregroundColor(.red)
             }
             
             Text("Connection type: \(connectionTypeString)")
         }
     }
     
     private var connectionTypeString: String {
         switch networkMonitor.connectionType {
         case .wifi:
             return "WiFi"
         case .cellular:
             return "Cellular"
         case .ethernet:
             return "Ethernet"
         case .unknown:
             return "Unknown"
         }
     }
 }
 
 // UIKit usage example:
 // This example shows how to subscribe to network status changes using Combine
 // in a UIKit view controller
 class SomeViewController: UIViewController {
     private var cancellables = Set<AnyCancellable>()
     
     override func viewDidLoad() {
         super.viewDidLoad()
         
         // Subscribe to connectivity changes
         NetworkMonitor.shared.$isConnected
             .sink { [weak self] isConnected in
                 self?.updateUI(isConnected: isConnected)
             }
             .store(in: &cancellables)
     }
     
     private func updateUI(isConnected: Bool) {
         if isConnected {
             // Handle connected state
         } else {
             // Handle disconnected state, show alert, etc.
         }
     }
 }
 */
