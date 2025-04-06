//
//  CloudKitSchemaAlertView.swift
//  Simple QR
//
//  Created by Stéphane PAQUET on 4/5/25.
//

import SwiftUI

struct CloudKitSchemaAlertView: View {
    @Binding var isPresented: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.icloud")
                .font(.system(size: 60))
                .foregroundColor(.orange)
            
            Text("iCloud Sync Update Required")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("We've updated how your data syncs with iCloud. Please restart the app to continue syncing properly.")
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button {
                // Force app to exit - this will prompt a restart
                exit(0)
            } label: {
                Text("Restart Now")
                    .fontWeight(.bold)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
            
            Button {
                isPresented = false
            } label: {
                Text("Later")
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(15)
        .shadow(radius: 10)
        .padding(.horizontal, 30)
    }
}
