//
//  SimpleCloudKitChecker.swift
//  Simple QR
//
//  Created by Stéphane PAQUET on 4/5/25.
//


import CloudKit
import SwiftUI

class SimpleCloudKitChecker {
    
    static func checkAccountStatus(completion: @escaping (Bool, String?) -> Void) {
        CKContainer.default().accountStatus { status, error in
            switch status {
            case .available:
                completion(true, nil)
            case .noAccount:
                completion(false, "No iCloud account available")
            case .restricted:
                completion(false, "iCloud access is restricted")
            case .couldNotDetermine:
                completion(false, "Could not determine iCloud status")
            case .temporarilyUnavailable:
                completion(false, "iCloud is temporarily unavailable")
            @unknown default:
                completion(false, "Unknown iCloud status")
            }
        }
    }
    
    static func checkContainerAccess(completion: @escaping (Bool, String?) -> Void) {
        let container = CKContainer.default()
        
        // Attempt to fetch user record ID as a simple test
        container.fetchUserRecordID { recordID, error in
            if let error = error {
                let errorMessage = "Container access error: \(error.localizedDescription)"
                print(errorMessage)
                completion(false, errorMessage)
                return
            }
            
            if recordID != nil {
                completion(true, nil)
            } else {
                completion(false, "Could not fetch user record ID")
            }
        }
    }
    
    // Add this to your ContentView to check CloudKit status
    static func addCloudKitStatusChecks() {
        print("Checking CloudKit status...")
        
        SimpleCloudKitChecker.checkAccountStatus { isAvailable, errorMessage in
            if isAvailable {
                print("iCloud account is available")
                
                // Now check container access
                SimpleCloudKitChecker.checkContainerAccess { hasAccess, containerError in
                    if hasAccess {
                        print("CloudKit container access confirmed")
                    } else {
                        print("CloudKit container access failed: \(containerError ?? "Unknown error")")
                    }
                }
            } else {
                print("iCloud account status issue: \(errorMessage ?? "Unknown error")")
            }
        }
    }
}