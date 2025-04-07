//
//  CameraPreviewRepresentable.swift
//  Simple QR
//
//  Created by Stéphane PAQUET on 4/7/25.
//

import SwiftUI
import AVFoundation

/// Camera preview representable using UIViewControllerRepresentable
struct CameraPreviewRepresentable: UIViewControllerRepresentable {
    let session: AVCaptureSession
    
    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = UIViewController()
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.name = "cameraPreviewLayer" // Add a name for debugging
        
        DispatchQueue.main.async {
            // Configure the preview layer
            previewLayer.frame = viewController.view.bounds
            
            // Add as the bottom-most layer
            viewController.view.layer.insertSublayer(previewLayer, at: 0)
            
            // Add debugging info
            print("Preview layer frame: \(previewLayer.frame)")
            print("View controller bounds: \(viewController.view.bounds)")
        }
        
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        if let previewLayer = uiViewController.view.layer.sublayers?.first(where: { $0.name == "cameraPreviewLayer" }) {
            previewLayer.frame = uiViewController.view.bounds
        }
    }
}
