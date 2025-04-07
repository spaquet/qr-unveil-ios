//
//  PhotoManager.swift
//  Simple QR
//
//  Created by Stéphane PAQUET on 4/4/25.
//

import UIKit
import Photos
import SwiftUI
import Combine

/// Manages photo library access and saving images
class PhotoManager: NSObject, ObservableObject {
    // Published properties to observe in SwiftUI
    @Published var authorizationStatus: PHAuthorizationStatus = .notDetermined
    @Published var lastSavedImageId: String?
    
    // Album name for saving QR codes
    private let albumName = "QR Unveil Scans"
    
    // Singleton instance
    static let shared = PhotoManager()
    
    override init() {
        super.init()
        updateAuthorizationStatus()
    }
    
    /// Updates the current authorization status
    func updateAuthorizationStatus() {
        // Request full access instead of addOnly to ensure we can read images back
        authorizationStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
    }
    
    /// Requests full authorization to access the photo library
    func requestPhotoLibraryAccess(completion: @escaping (Bool) -> Void) {
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { [weak self] status in
            DispatchQueue.main.async {
                self?.authorizationStatus = status
                
                switch status {
                case .authorized:
                    print("Full photo library access granted")
                    completion(true)
                case .limited:
                    print("Limited photo library access granted - QR code viewing may be limited")
                    completion(true)
                case .denied, .restricted:
                    print("Photo library access denied")
                    completion(false)
                case .notDetermined:
                    print("Photo library access not determined")
                    completion(false)
                @unknown default:
                    print("Unknown photo library access status")
                    completion(false)
                }
            }
        }
    }
    
    /// Requests authorization to access the photo library
    func requestAuthorization(completion: (() -> Void)? = nil) {
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { [weak self] status in
            DispatchQueue.main.async {
                self?.authorizationStatus = status
                
                switch status {
                case .authorized:
                    print("Full photo library access granted")
                case .limited:
                    print("Limited photo library access granted - some features may be restricted")
                case .denied, .restricted:
                    print("Photo library access denied")
                case .notDetermined:
                    print("Photo library access not determined")
                @unknown default:
                    print("Unknown photo library access status")
                }
                
                completion?()
            }
        }
    }
    
    /// Saves a QR code image to the app's album
    /// - Parameters:
    ///   - image: The UIImage to save
    ///   - qrCodeId: The ID of the associated QR code for reference
    ///   - completion: Callback with success status and optional error
    func saveQRCodeImage(_ image: UIImage, qrCodeId: UUID, completion: @escaping (Bool, Error?) -> Void) {
        // Check authorization status first
        if authorizationStatus != .authorized && authorizationStatus != .limited {
            completion(false, NSError(domain: "com.qrunveil.photolib", code: 401, userInfo: [NSLocalizedDescriptionKey: "Photo library access not authorized"]))
            return
        }
        
        // Ensure album exists first
        ensureAlbumExists { [weak self] albumResult in
            switch albumResult {
            case .success(let album):
                // Now save the image to the album
                self?.saveImageToAlbum(image, album: album, qrCodeId: qrCodeId, completion: completion)
            case .failure(let error):
                completion(false, error)
            }
        }
    }
    
    /// Ensures the QR Unveil album exists
    /// - Parameter completion: Completion handler with result of album fetch or creation
    private func ensureAlbumExists(completion: @escaping (Result<PHAssetCollection, Error>) -> Void) {
        // Fetch existing albums
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "title = %@", albumName)
        let existingAlbums = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)
        
        // If album exists, return it
        if let existingAlbum = existingAlbums.firstObject {
            completion(.success(existingAlbum))
            return
        }
        
        // Album doesn't exist, create it
        PHPhotoLibrary.shared().performChanges {
            PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: self.albumName)
        } completionHandler: { success, error in
            if success {
                // Refetch the newly created album
                let refetchOptions = PHFetchOptions()
                refetchOptions.predicate = NSPredicate(format: "title = %@", self.albumName)
                let albums = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: refetchOptions)
                
                if let album = albums.firstObject {
                    completion(.success(album))
                } else {
                    completion(.failure(NSError(domain: "com.qrunveil.photolib", code: 404, userInfo: [NSLocalizedDescriptionKey: "Could not find or create album"])))
                }
            } else {
                completion(.failure(error ?? NSError(domain: "com.qrunveil.photolib", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to create album"])))
            }
        }
    }
    
    /// Saves an image to a specific album
    /// - Parameters:
    ///   - image: The image to save
    ///   - album: The album to save the image to
    ///   - qrCodeId: The associated QR code ID
    ///   - completion: Completion handler with save result
    private func saveImageToAlbum(_ image: UIImage, album: PHAssetCollection, qrCodeId: UUID, completion: @escaping (Bool, Error?) -> Void) {
        PHPhotoLibrary.shared().performChanges {
            // Create asset from image
            let assetChangeRequest = PHAssetChangeRequest.creationRequestForAsset(from: image)
            assetChangeRequest.creationDate = Date()
            
            // Add the asset to our album
            guard let assetPlaceholder = assetChangeRequest.placeholderForCreatedAsset,
                  let albumChangeRequest = PHAssetCollectionChangeRequest(for: album) else {
                return
            }
            
            albumChangeRequest.addAssets([assetPlaceholder] as NSFastEnumeration)
            
            // Store the asset ID for later reference
            self.lastSavedImageId = assetPlaceholder.localIdentifier
        } completionHandler: { success, error in
            DispatchQueue.main.async {
                completion(success, error)
            }
        }
    }
    
    /// Fetches the QR code image for a given QR code ID
    /// - Parameters:
    ///   - qrCodeAssetId: The asset ID of the image
    ///   - completion: Callback with the image or nil if not found
    func fetchQRCodeImage(assetId: String, completion: @escaping (UIImage?) -> Void) {
        let fetchOptions = PHFetchOptions()
        let assets = PHAsset.fetchAssets(withLocalIdentifiers: [assetId], options: fetchOptions)
        
        guard let asset = assets.firstObject else {
            completion(nil)
            return
        }
        
        let options = PHImageRequestOptions()
        options.version = .current
        options.isSynchronous = false
        options.deliveryMode = .highQualityFormat
        
        PHImageManager.default().requestImage(
            for: asset,
            targetSize: PHImageManagerMaximumSize,
            contentMode: .aspectFit,
            options: options
        ) { image, _ in
            DispatchQueue.main.async {
                completion(image)
            }
        }
    }
}
