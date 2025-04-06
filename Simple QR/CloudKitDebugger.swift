//
//  CloudKitDebugger.swift
//  Simple QR
//
//  Created by Stéphane PAQUET on 4/5/25.
//

import Foundation
import CloudKit
import SwiftUI

/// CloudKit sync status enum
enum CloudSyncStatus {
    case available
    case unavailable
    case restricted
    case unknown
}

/// Types of CloudKit operations
enum CloudKitOperationType: String {
    case sync = "Sync"
    case save = "Save"
    case query = "Query"
    case delete = "Delete"
    case retry = "Retry"
    case accountStatus = "Account Status"
}

/// Status of CloudKit operations
enum CloudKitOperationStatus: String {
    case started = "Started"
    case succeeded = "Succeeded"
    case failed = "Failed"
    case retrying = "Retrying"
}

/// Represents a CloudKit operation log entry
struct CloudKitSyncLog: Identifiable {
    let id = UUID()
    let timestamp: Date
    let operationType: CloudKitOperationType
    let status: CloudKitOperationStatus
    let details: String?
    let error: String?
}

/// Enhanced CloudKit sync manager with debugging features
class CloudKitDebugger {
    // Shared instance
    static let shared = CloudKitDebugger()
    
    // Log entries for CloudKit operations
    @Published var syncLogs: [CloudKitSyncLog] = []
    
    // Maximum number of log entries to keep
    private let maxLogEntries = 100
    
    // Private init for singleton
    private init() {}
    
    /// Add a log entry for CloudKit operation
    func logOperation(type: CloudKitOperationType, status: CloudKitOperationStatus, details: String? = nil, error: Error? = nil) {
        let newLog = CloudKitSyncLog(
            timestamp: Date(),
            operationType: type,
            status: status,
            details: details,
            error: error?.localizedDescription
        )
        
        DispatchQueue.main.async {
            // Add to beginning of array to show most recent first
            self.syncLogs.insert(newLog, at: 0)
            
            // Trim array if it exceeds the maximum
            if self.syncLogs.count > self.maxLogEntries {
                self.syncLogs = Array(self.syncLogs.prefix(self.maxLogEntries))
            }
            
            // Post notification for UI updates
            NotificationCenter.default.post(name: .cloudKitOperationLogged, object: nil)
        }
    }
    
    /// Clear all logs
    func clearLogs() {
        DispatchQueue.main.async {
            self.syncLogs.removeAll()
            NotificationCenter.default.post(name: .cloudKitOperationLogged, object: nil)
        }
    }
    
    /// Check the account status
    func checkAccountStatus(completion: @escaping (CloudSyncStatus) -> Void) {
        CKContainer.default().accountStatus { status, error in
            var syncStatus: CloudSyncStatus = .unknown
            
            if let error = error {
                self.logOperation(
                    type: .accountStatus,
                    status: .failed,
                    details: "Failed to check account status",
                    error: error
                )
                completion(.unknown)
                return
            }
            
            switch status {
            case .available:
                syncStatus = .available
                self.logOperation(
                    type: .accountStatus,
                    status: .succeeded,
                    details: "iCloud account available"
                )
            case .noAccount:
                syncStatus = .unavailable
                self.logOperation(
                    type: .accountStatus,
                    status: .failed,
                    details: "No iCloud account"
                )
            case .restricted:
                syncStatus = .restricted
                self.logOperation(
                    type: .accountStatus,
                    status: .failed,
                    details: "iCloud account restricted"
                )
            case .couldNotDetermine:
                syncStatus = .unknown
                self.logOperation(
                    type: .accountStatus,
                    status: .failed,
                    details: "Could not determine iCloud status"
                )
            case .temporarilyUnavailable:
                syncStatus = .unavailable
                self.logOperation(
                    type: .accountStatus,
                    status: .failed,
                    details: "iCloud account temporarily unavailable"
                )
            @unknown default:
                syncStatus = .unknown
                self.logOperation(
                    type: .accountStatus,
                    status: .failed,
                    details: "Unknown iCloud status"
                )
            }
            
            completion(syncStatus)
        }
    }
}

// MARK: - Notification extension

extension Notification.Name {
    static let cloudKitOperationLogged = Notification.Name("CloudKitOperationLogged")
    static let cloudKitSchemaError = Notification.Name("CloudKitSchemaError")
    static let cloudKitSyncTriggered = Notification.Name("CloudKitSyncTriggered")
}

// MARK: - Observable proxy for CloudKitDebugger

class CloudKitDebuggerProxy: ObservableObject {
    @Published var syncLogs: [CloudKitSyncLog] = []
    
    init() {
        // Initialize with current logs
        syncLogs = CloudKitDebugger.shared.syncLogs
        
        // Listen for changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleLogsUpdated),
            name: .cloudKitOperationLogged,
            object: nil
        )
    }
    
    @objc private func handleLogsUpdated() {
        DispatchQueue.main.async {
            self.syncLogs = CloudKitDebugger.shared.syncLogs
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - CloudKit Debug View

struct CloudKitDebugView: View {
    @StateObject private var debuggerProxy = CloudKitDebuggerProxy()
    @State private var isRefreshing = false
    @State private var cloudStatus: CloudSyncStatus = .unknown
    
    var body: some View {
        List {
            Section("iCloud Status") {
                HStack {
                    Text("Account Status")
                    Spacer()
                    statusIndicator
                }
                
                Button {
                    refreshStatus()
                } label: {
                    Label("Refresh Status", systemImage: "arrow.clockwise")
                }
                .disabled(isRefreshing)
                
                Button {
                    triggerManualSync()
                } label: {
                    Label("Trigger Sync", systemImage: "arrow.triangle.2.circlepath.circle")
                }
                .disabled(cloudStatus != .available || isRefreshing)
            }
            
            Section("Sync Logs") {
                Button {
                    CloudKitDebugger.shared.clearLogs()
                } label: {
                    Label("Clear Logs", systemImage: "trash")
                }
                
                if debuggerProxy.syncLogs.isEmpty {
                    Text("No CloudKit operations logged")
                        .foregroundColor(.secondary)
                        .padding(.vertical, 10)
                } else {
                    ForEach(debuggerProxy.syncLogs) { log in
                        VStack(alignment: .leading, spacing: 5) {
                            HStack {
                                Text(log.operationType.rawValue)
                                    .font(.headline)
                                    .foregroundColor(statusColor(for: log.status))
                                
                                Spacer()
                                
                                Text(log.status.rawValue)
                                    .font(.subheadline)
                                    .foregroundColor(statusColor(for: log.status))
                            }
                            
                            Text(log.timestamp, style: .relative)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            if let details = log.details {
                                Text(details)
                                    .font(.caption)
                                    .foregroundColor(.primary)
                                    .padding(.top, 2)
                            }
                            
                            if let error = log.error {
                                Text("Error: \(error)")
                                    .font(.caption)
                                    .foregroundColor(.red)
                                    .padding(.top, 2)
                            }
                        }
                        .padding(.vertical, 5)
                    }
                }
            }
        }
        .navigationTitle("CloudKit Debug")
        .onAppear {
            refreshStatus()
        }
    }
    
    private var statusIndicator: some View {
        HStack(spacing: 4) {
            switch cloudStatus {
            case .available:
                Image(systemName: "checkmark.icloud")
                    .foregroundColor(.green)
                Text("Connected")
                    .foregroundColor(.green)
            case .unavailable:
                Image(systemName: "xmark.icloud")
                    .foregroundColor(.red)
                Text("Not Available")
                    .foregroundColor(.red)
            case .restricted:
                Image(systemName: "exclamationmark.icloud")
                    .foregroundColor(.orange)
                Text("Restricted")
                    .foregroundColor(.orange)
            case .unknown:
                Image(systemName: "exclamationmark.icloud")
                    .foregroundColor(.gray)
                Text("Checking...")
                    .foregroundColor(.gray)
            }
            
            if isRefreshing {
                ProgressView()
                    .scaleEffect(0.7)
                    .padding(.leading, 4)
            }
        }
    }
    
    private func statusColor(for status: CloudKitOperationStatus) -> Color {
        switch status {
        case .succeeded:
            return .green
        case .failed:
            return .red
        case .retrying:
            return .orange
        case .started:
            return .blue
        }
    }
    
    private func refreshStatus() {
        isRefreshing = true
        
        CloudKitDebugger.shared.checkAccountStatus { status in
            DispatchQueue.main.async {
                self.cloudStatus = status
                self.isRefreshing = false
            }
        }
    }
    
    private func triggerManualSync() {
        isRefreshing = true
        
        // Trigger sync with logging
        CloudKitSyncManager.shared.triggerSyncWithLogging()
        
        // Simulate sync completion after a reasonable delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.isRefreshing = false
        }
    }
}

// MARK: - Extension for CloudKitSyncManager

extension CloudKitSyncManager {
    /// Enhanced trigger sync with logging
    func triggerSyncWithLogging() {
        CloudKitDebugger.shared.logOperation(
            type: .sync,
            status: .started,
            details: "Manual sync triggered"
        )
        
        triggerSync()
    }
    
    /// Log an error with details
    func logError(_ error: Error, operation: CloudKitOperationType) {
        if let ckError = error as? CKError {
            let retryAfter = ckError.retryAfterSeconds ?? 0
            
            CloudKitDebugger.shared.logOperation(
                type: operation,
                status: .failed,
                details: "Error \(ckError.code.rawValue) with retry after \(retryAfter) seconds",
                error: ckError
            )
        } else {
            CloudKitDebugger.shared.logOperation(
                type: operation,
                status: .failed,
                details: nil,
                error: error
            )
        }
    }
}
