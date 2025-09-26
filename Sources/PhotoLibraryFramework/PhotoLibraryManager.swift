import AVFoundation
import Foundation
import Photos
import PhotosUI
import UIKit
import UniformTypeIdentifiers

// MARK: - Public Configuration
@objc public enum MediaType: Int, CaseIterable {
  case images
  case videos
  case livePhotos
  case imagesAndVideos

  @available(iOS 14.0, *)
  internal var phPickerFilter: PHPickerFilter? {
    switch self {
    case .images:
      return .images
    case .videos:
      return .videos
    case .livePhotos:
      return .livePhotos
    case .imagesAndVideos:
      return .any(of: [.images, .videos])
    }
  }
}

// MARK: - Framework Messages
public struct Messages {
  public struct Errors {
    public static var cameraPermission = "Please enable camera permission in settings"
    public static var photoLibraryDenied = "Please enable photo library permission in settings"
    public static var cameraUnavailable = "Camera not found"
    public static var selectionLimit = "Selection limit must be greater than 0!"
    public static var iCloudAuthenticationRequired =
      "iCloud authentication is required to download this photo. Please sign in to iCloud in Settings."
    public static var iCloudDownloadFailed =
      "Failed to download photo from iCloud. Please check your internet connection and try again."
    public static var iCloudNotSignedIn =
      "Please sign in to iCloud in Settings to access your photo library."
  }

  public struct Actions {
    public static var camera = "Take photo"
    public static var gallery = "Import from gallery"
    public static var cancel = "Cancel"
    public static var settings = "Settings"
    public static var ok = "Ok"
    public static var retry = "Retry"
  }

  public struct Prompts {
    public static var chooseSource = "Select photo from"
  }
}

// MARK: - Public Delegate Protocol
@objc public protocol PhotoLibraryDelegate: AnyObject {
  /// Called when user takes a photo from camera
  func photoLibrary(didCaptureImage image: UIImage)

  /// Called when user selects photos from library (preferred method with PHAssets)
  func photoLibrary(didSelectAssets assets: [PHAsset])

  /// Called when user cancels the picker
  func photoLibraryDidCancel()

  // Optional fallback method for when PHAssets are not available (limited access, external sources)
  @objc optional func photoLibrary(didSelectImages images: [UIImage])

  // Optional iCloud support methods
  @objc optional func photoLibrary(didStartDownloadingFromCloud asset: PHAsset)
  @objc optional func photoLibrary(downloadProgress progress: Double, for asset: PHAsset)
  @objc optional func photoLibrary(
    didFinishDownloading image: UIImage?, for asset: PHAsset, error: Error?)
  @objc optional func photoLibrary(
    iCloudAuthenticationRequired asset: PHAsset, retryHandler: @escaping () -> Void)
}

// MARK: - Internal Helper for Delegate Method Detection
internal extension PhotoLibraryDelegate {
  /// Check if the delegate implements the didSelectImages method
  var implementsDidSelectImages: Bool {
    // Convert to NSObject to use responds(to:) if possible
    if let objcDelegate = self as? NSObject {
      return objcDelegate.responds(to: #selector(PhotoLibraryDelegate.photoLibrary(didSelectImages:)))
    }
    // For pure Swift objects, we can't detect implementation
    // So we assume it might be implemented and try to call it
    return true
  }
}

// MARK: - Main Manager Class
@objc public final class PhotoLibraryManager: NSObject {

  // MARK: - Public Properties
  @objc public static let shared = PhotoLibraryManager()

  // MARK: - Private Properties
  private weak var delegate: PhotoLibraryDelegate?
  private weak var presentingViewController: UIViewController?
  private var imagePicker: UIImagePickerController?
  private var sourceView: UIView?
  private var sourceRect: CGRect = .zero

  private var currentMediaType: MediaType = .imagesAndVideos
  private var currentSelectionLimit: Int = 1

  private override init() {
    super.init()
  }

  // MARK: - Public Methods

  /// Open photo picker with camera and gallery options
  /// - Parameters:
  ///   - viewController: View controller to present from (must conform to PhotoLibraryDelegate)
  ///   - mediaType: Type of media to select
  ///   - selectionLimit: Maximum number of items to select (1 for single selection)
  ///   - sourceView: Source view for iPad popover presentation
  ///   - sourceRect: Source rect for iPad popover presentation
  @objc public static func openPicker(
    from viewController: UIViewController & PhotoLibraryDelegate,
    mediaType: MediaType = .imagesAndVideos,
    selectionLimit: Int = 1,
    sourceView: UIView? = nil,
    sourceRect: CGRect = .zero
  ) {
    shared.presentPhotoPicker(
      delegate: viewController,
      from: viewController,
      mediaType: mediaType,
      selectionLimit: selectionLimit,
      sourceView: sourceView,
      sourceRect: sourceRect
    )
  }

  /// Open photo picker with custom delegate (for advanced use cases)
  /// - Parameters:
  ///   - delegate: Custom delegate to receive callbacks
  ///   - viewController: View controller to present from
  ///   - mediaType: Type of media to select
  ///   - selectionLimit: Maximum number of items to select (1 for single selection)
  ///   - sourceView: Source view for iPad popover presentation
  ///   - sourceRect: Source rect for iPad popover presentation
  @objc public static func openPicker(
    delegate: PhotoLibraryDelegate,
    from viewController: UIViewController,
    mediaType: MediaType = .imagesAndVideos,
    selectionLimit: Int = 1,
    sourceView: UIView? = nil,
    sourceRect: CGRect = .zero
  ) {
    shared.presentPhotoPicker(
      delegate: delegate,
      from: viewController,
      mediaType: mediaType,
      selectionLimit: selectionLimit,
      sourceView: sourceView,
      sourceRect: sourceRect
    )
  }

  /// Internal method to present photo picker
  private func presentPhotoPicker(
    delegate: PhotoLibraryDelegate,
    from viewController: UIViewController,
    mediaType: MediaType = .imagesAndVideos,
    selectionLimit: Int = 1,
    sourceView: UIView? = nil,
    sourceRect: CGRect = .zero
  ) {
    guard selectionLimit > 0 else {
      assertionFailure(Messages.Errors.selectionLimit)
      return
    }

    self.delegate = delegate
    self.presentingViewController = viewController
    self.currentMediaType = mediaType
    self.currentSelectionLimit = selectionLimit
    self.sourceView = sourceView ?? viewController.view
    self.sourceRect = sourceRect

    presentSourceSelectionAlert()
  }

  /// Convert PHAsset to UIImage asynchronously with iCloud support (async/await version)
  /// - Parameters:
  ///   - asset: PHAsset to convert
  ///   - size: Target size (nil for full resolution)
  /// - Returns: UIImage if successful
  @available(iOS 13.0, *)
  public func getImage(from asset: PHAsset, targetSize size: CGSize? = nil) async -> UIImage? {
    return await withCheckedContinuation { continuation in
      getImage(from: asset, targetSize: size) { image, _ in
        continuation.resume(returning: image)
      }
    }
  }

  /// Convert PHAsset to UIImage asynchronously with iCloud support
  /// - Parameters:
  ///   - asset: PHAsset to convert
  ///   - size: Target size (nil for full resolution)
  ///   - completion: Completion handler with image and info
  public func getImage(
    from asset: PHAsset,
    targetSize size: CGSize? = nil,
    completion: @escaping (UIImage?, [AnyHashable: Any]?) -> Void
  ) {
    let manager = PHImageManager.default()
    let options = PHImageRequestOptions()

    options.isNetworkAccessAllowed = true
    options.deliveryMode = .highQualityFormat
    options.resizeMode = .exact
    options.isSynchronous = false

    options.progressHandler = { [weak self] progress, error, stop, info in
      DispatchQueue.main.async {
        self?.delegate?.photoLibrary?(downloadProgress: progress, for: asset)

        if let error = error {
          if self?.isICloudAuthenticationError(error) == true {
            stop.pointee = true
            self?.delegate?.photoLibrary?(iCloudAuthenticationRequired: asset) {
              self?.getImage(from: asset, targetSize: size, completion: completion)
            }
            return
          }
        }
      }
    }

    let targetSize = size ?? CGSize(width: asset.pixelWidth, height: asset.pixelHeight)

    manager.requestImage(
      for: asset, targetSize: targetSize, contentMode: .aspectFit, options: options
    ) { [weak self] image, info in
      DispatchQueue.main.async {
        if let error = info?[PHImageErrorKey] as? Error {
          if self?.isICloudAuthenticationError(error) == true {
            self?.delegate?.photoLibrary?(iCloudAuthenticationRequired: asset) {
              self?.getImage(from: asset, targetSize: size, completion: completion)
            }
            return
          }
        }

        self?.delegate?.photoLibrary?(
          didFinishDownloading: image, for: asset, error: info?[PHImageErrorKey] as? Error)
        completion(image, info)
      }
    }
  }

  /// Check if PHAsset is stored in iCloud
  /// - Parameters:
  ///   - asset: PHAsset to check
  ///   - completion: Completion handler with boolean result
  @objc public func isAssetInCloud(_ asset: PHAsset, completion: @escaping (Bool) -> Void) {
    let manager = PHImageManager.default()
    let options = PHImageRequestOptions()
    options.isNetworkAccessAllowed = false
    options.isSynchronous = false

    manager.requestImage(
      for: asset, targetSize: CGSize(width: 1, height: 1), contentMode: .aspectFit, options: options
    ) { _, info in
      DispatchQueue.main.async {
        let isInCloud = (info?[PHImageResultIsInCloudKey] as? Bool) ?? false
        completion(isInCloud)
      }
    }
  }

  /// Process multiple PHAssets with progress tracking
  /// - Parameters:
  ///   - assets: Array of PHAssets to process
  ///   - targetSize: Target size for images
  ///   - completion: Completion handler with array of processed images
  public func processAssets(
    _ assets: [PHAsset],
    targetSize: CGSize? = nil,
    completion: @escaping ([UIImage]) -> Void
  ) {
    var processedImages: [UIImage] = []
    let group = DispatchGroup()

    for asset in assets {
      group.enter()

      isAssetInCloud(asset) { [weak self] isInCloud in
        if isInCloud {
          self?.delegate?.photoLibrary?(didStartDownloadingFromCloud: asset)
        }

        self?.getImage(from: asset, targetSize: targetSize) { image, info in
          defer { group.leave() }

          if let image = image {
            processedImages.append(image)
          }
        }
      }
    }

    group.notify(queue: .main) {
      completion(processedImages)
    }
  }
  
  /// Check if user has limited photo library access
  /// - Returns: True if user has limited access (iOS 14+)
  @available(iOS 14.0, *)
  @objc public static func hasLimitedPhotoAccess() -> Bool {
    return PHPhotoLibrary.authorizationStatus(for: .readWrite) == .limited
  }
  
  /// Get current photo library authorization status
  /// - Returns: Current authorization status
  @objc public static func photoLibraryAuthorizationStatus() -> PHAuthorizationStatus {
    if #available(iOS 14.0, *) {
      return PHPhotoLibrary.authorizationStatus(for: .readWrite)
    } else {
      return PHPhotoLibrary.authorizationStatus()
    }
  }
  
  /// Request full photo library access (shows system settings)
  /// - Parameter completion: Completion handler with new status
  @available(iOS 14.0, *)
  @objc public static func requestFullPhotoAccess(completion: @escaping (PHAuthorizationStatus) -> Void) {
    PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
      DispatchQueue.main.async {
        completion(status)
      }
    }
  }
}

// MARK: - Private Methods
extension PhotoLibraryManager {

  fileprivate func presentSourceSelectionAlert() {
    let alert = UIAlertController(
      title: nil,
      message: Messages.Prompts.chooseSource,
      preferredStyle: .actionSheet
    )

    // Camera action
    alert.addAction(
      UIAlertAction(title: Messages.Actions.camera, style: .default) { [weak self] _ in
        self?.checkCameraPermission()
      })

    // Gallery action
    alert.addAction(
      UIAlertAction(title: Messages.Actions.gallery, style: .default) { [weak self] _ in
        self?.checkPhotoLibraryPermission()
      })

    // Cancel action
    alert.addAction(
      UIAlertAction(title: Messages.Actions.cancel, style: .cancel) { [weak self] _ in
        self?.delegate?.photoLibraryDidCancel()
      })

    // Configure popover for iPad
    if let popoverController = alert.popoverPresentationController {
      popoverController.sourceView = sourceView
      popoverController.sourceRect = sourceRect.isEmpty ? sourceView?.bounds ?? .zero : sourceRect
    }

    // Apply theme
    let themeStyle = ThemeManager.shared.currentUserInterfaceStyle
    if themeStyle != .unspecified {
      alert.overrideUserInterfaceStyle = themeStyle
    }

    presentingViewController?.present(alert, animated: true)
  }

  fileprivate func checkCameraPermission() {
    switch AVCaptureDevice.authorizationStatus(for: .video) {
    case .authorized:
      openCamera()
    case .denied, .restricted:
      showPermissionAlert(for: .camera)
    case .notDetermined:
      AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
        DispatchQueue.main.async {
          if granted {
            self?.openCamera()
          } else {
            self?.showPermissionAlert(for: .camera)
          }
        }
      }
    @unknown default:
      showPermissionAlert(for: .camera)
    }
  }

  fileprivate func checkPhotoLibraryPermission() {
    if #available(iOS 14.0, *) {
      switch PHPhotoLibrary.authorizationStatus(for: .readWrite) {
      case .authorized:
        openPhotoLibrary()
      case .limited:
        openPhotoLibrary()
      case .denied, .restricted:
        showPermissionAlert(for: .photoLibrary)
      case .notDetermined:
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { [weak self] status in
          DispatchQueue.main.async {
            switch status {
            case .authorized, .limited:
              self?.openPhotoLibrary()
            default:
              self?.showPermissionAlert(for: .photoLibrary)
            }
          }
        }
      @unknown default:
        showPermissionAlert(for: .photoLibrary)
      }
    } else {
      // iOS 13 fallback
      switch PHPhotoLibrary.authorizationStatus() {
      case .authorized:
        openPhotoLibrary()
      case .denied, .restricted:
        showPermissionAlert(for: .photoLibrary)
      case .notDetermined:
        PHPhotoLibrary.requestAuthorization { [weak self] status in
          DispatchQueue.main.async {
            switch status {
            case .authorized:
              self?.openPhotoLibrary()
            default:
              self?.showPermissionAlert(for: .photoLibrary)
            }
          }
        }
      @unknown default:
        showPermissionAlert(for: .photoLibrary)
      }
    }
  }

  fileprivate func openCamera() {
    guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
      showAlert(
        title: "Error",
        message: Messages.Errors.cameraUnavailable,
        actions: [Messages.Actions.ok]
      )
      return
    }

    let picker = UIImagePickerController()
    picker.delegate = self
    picker.sourceType = .camera
    picker.cameraCaptureMode = .photo

    // Apply theme
    let themeStyle = ThemeManager.shared.currentUserInterfaceStyle
    if themeStyle != .unspecified {
      picker.overrideUserInterfaceStyle = themeStyle
    }

    imagePicker = picker
    presentingViewController?.present(picker, animated: true)
  }

  fileprivate func openPhotoLibrary() {
    print("PhotoLibrary: Opening photo library")
    print("PhotoLibrary: Selection limit: \(currentSelectionLimit)")
    print("PhotoLibrary: Media type: \(currentMediaType)")
    
    if #available(iOS 14.0, *) {
      // Check current authorization status
      let authStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
      print("PhotoLibrary: Authorization status: \(authStatus.rawValue)")
      
      // Handle limited access specifically
      if authStatus == .limited {
        print("PhotoLibrary: Limited access detected - PHPicker will show system picker")
        print("PhotoLibrary: Note: Selected photos may not have PHAsset identifiers")
        print("PhotoLibrary: Framework will automatically fallback to UIImage handling")
      }
      
      var config = PHPickerConfiguration(photoLibrary: .shared())
      config.selectionLimit = currentSelectionLimit
      config.filter = currentMediaType.phPickerFilter
      
      // For limited access, we need to handle the fact that asset identifiers might be nil
      // Set preferredAssetRepresentationMode to current for best compatibility
      config.preferredAssetRepresentationMode = .current
      
      // For limited access, the system picker allows access to all photos
      // but the selected photos won't have proper asset identifiers
      if authStatus == .limited {
        print("PhotoLibrary: Configuring for limited access - expecting UIImage fallback")
      }

      if #available(iOS 15.0, *) {
        config.selection = .ordered
      }

      let picker = PHPickerViewController(configuration: config)
      picker.delegate = self

      // Apply theme
      let themeStyle = ThemeManager.shared.currentUserInterfaceStyle
      if themeStyle != .unspecified {
        picker.overrideUserInterfaceStyle = themeStyle
      }

      print("PhotoLibrary: Presenting PHPickerViewController")
      presentingViewController?.present(picker, animated: true)
    } else {
      // Fallback to UIImagePickerController for iOS 13
      print("PhotoLibrary: Using UIImagePickerController fallback for iOS 13")
      let picker = UIImagePickerController()
      picker.delegate = self
      picker.sourceType = .photoLibrary
      picker.mediaTypes = getMediaTypes()

      // Apply theme
      let themeStyle = ThemeManager.shared.currentUserInterfaceStyle
      if themeStyle != .unspecified {
        picker.overrideUserInterfaceStyle = themeStyle
      }

      presentingViewController?.present(picker, animated: true)
    }
  }

  private func getMediaTypes() -> [String] {
    switch currentMediaType {
    case .images:
      return ["public.image"]
    case .videos:
      return ["public.movie"]
    case .livePhotos:
      return ["public.image"]
    case .imagesAndVideos:
      return ["public.image", "public.movie"]
    }
  }

  fileprivate enum PermissionType {
    case camera
    case photoLibrary

    var errorMessage: String {
      switch self {
      case .camera:
        return Messages.Errors.cameraPermission
      case .photoLibrary:
        return Messages.Errors.photoLibraryDenied
      }
    }
  }

  fileprivate func showPermissionAlert(for type: PermissionType) {
    showAlert(
      title: "Permission Required",
      message: type.errorMessage,
      actions: [Messages.Actions.settings, Messages.Actions.cancel]
    ) { [weak self] action in
      if action == Messages.Actions.settings {
        self?.openSettings()
      } else {
        self?.delegate?.photoLibraryDidCancel()
      }
    }
  }

  fileprivate func showAlert(
    title: String?,
    message: String?,
    actions: [String],
    completion: ((String) -> Void)? = nil
  ) {
    let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)

    for actionTitle in actions {
      let style: UIAlertAction.Style = actionTitle == Messages.Actions.cancel ? .cancel : .default
      alert.addAction(
        UIAlertAction(title: actionTitle, style: style) { _ in
          completion?(actionTitle)
        })
    }

    // Apply theme
    let themeStyle = ThemeManager.shared.currentUserInterfaceStyle
    if themeStyle != .unspecified {
      alert.overrideUserInterfaceStyle = themeStyle
    }

    presentingViewController?.present(alert, animated: true)
  }

  fileprivate func openSettings() {
    if let settingsURL = URL(string: UIApplication.openSettingsURLString),
      UIApplication.shared.canOpenURL(settingsURL)
    {
      UIApplication.shared.open(settingsURL)
    }
  }

  fileprivate func isICloudAuthenticationError(_ error: Error?) -> Bool {
    guard let error = error as NSError? else { return false }

    // Check for CloudPhotoLibraryErrorDomain with code 1006 (authentication failure)
    if error.domain == "CloudPhotoLibraryErrorDomain" && error.code == 1006 {
      return true
    }

    // Check for CKErrorDomain with code 9 (user rejected authentication)
    if error.domain == "CKErrorDomain" && error.code == 9 {
      return true
    }

    // Check underlying errors
    if let underlyingError = error.userInfo[NSUnderlyingErrorKey] as? NSError {
      return isICloudAuthenticationError(underlyingError)
    }

    return false
  }
}

// MARK: - UIImagePickerControllerDelegate
extension PhotoLibraryManager: UIImagePickerControllerDelegate, UINavigationControllerDelegate {

  public func imagePickerController(
    _ picker: UIImagePickerController,
    didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
  ) {
    picker.dismiss(animated: true)

    if let image = info[.originalImage] as? UIImage {
      delegate?.photoLibrary(didCaptureImage: image)
    }
  }

  public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
    picker.dismiss(animated: true)
    delegate?.photoLibraryDidCancel()
  }
}

// MARK: - PHPickerViewControllerDelegate
@available(iOS 14.0, *)
extension PhotoLibraryManager: PHPickerViewControllerDelegate {

  public func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
    picker.dismiss(animated: true)

    guard !results.isEmpty else {
      delegate?.photoLibraryDidCancel()
      return
    }

    print("PHPicker: Received \(results.count) results")
    
    // Check current authorization status to understand the context
    let authStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
    print("PHPicker: Current auth status: \(authStatus.rawValue)")
    
    if authStatus == .limited {
      print("PHPicker: Limited access - system picker was shown, asset identifiers likely unavailable")
    }
    
    // Check if we have asset identifiers
    let identifiers = results.compactMap { result -> String? in
      let identifier = result.assetIdentifier
      print("PHPicker: Asset identifier: \(identifier ?? "nil")")
      return identifier
    }
    
    print("PHPicker: Found \(identifiers.count) valid identifiers out of \(results.count) results")
    
    // For limited access, we expect most/all identifiers to be nil
    if authStatus == .limited && identifiers.isEmpty {
      print("PHPicker: Expected behavior for limited access - no asset identifiers available")
      print("PHPicker: Converting to UIImages directly")
      handlePickerResultsWithoutAssets(results)
      return
    }
    
    if identifiers.isEmpty {
      // Handle case where no asset identifiers are available
      // This can happen with limited photo library access or external sources
      print("PHPicker: No asset identifiers available, handling results directly")
      handlePickerResultsWithoutAssets(results)
      return
    }

    var assets: [PHAsset] = []

    for identifier in identifiers {
      let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [identifier], options: nil)
      if let asset = fetchResult.firstObject {
        assets.append(asset)
        print("PHPicker: Successfully fetched asset for identifier: \(identifier)")
      } else {
        print("PHPicker: Failed to fetch asset for identifier: \(identifier)")
      }
    }
    
    print("PHPicker: Final assets count: \(assets.count)")

    if assets.isEmpty {
      // Fallback to handling results without PHAssets
      print("PHPicker: No valid PHAssets found, falling back to UIImage conversion")
      handlePickerResultsWithoutAssets(results)
    } else {
      // We have some valid PHAssets
      if assets.count < results.count {
        print("PHPicker: Warning - only \(assets.count) of \(results.count) results have valid PHAssets")
        print("PHPicker: This is common with limited photo access")
      }
      delegate?.photoLibrary(didSelectAssets: assets)
    }
  }
  
  private func handlePickerResultsWithoutAssets(_ results: [PHPickerResult]) {
    print("PHPicker: Handling results without PHAssets - converting to UIImages")
    
    var processedImages: [UIImage] = []
    let group = DispatchGroup()
    
    for result in results {
      group.enter()
      
      if result.itemProvider.canLoadObject(ofClass: UIImage.self) {
        result.itemProvider.loadObject(ofClass: UIImage.self) { object, error in
          defer { group.leave() }
          
          if let error = error {
            print("PHPicker: Error loading image: \(error)")
            return
          }
          
          if let image = object as? UIImage {
            processedImages.append(image)
            print("PHPicker: Successfully loaded image")
          }
        }
      } else {
        group.leave()
        print("PHPicker: Cannot load object as UIImage")
      }
    }
    
    group.notify(queue: .main) {
      print("PHPicker: Processed \(processedImages.count) images without PHAssets")
      
      if processedImages.isEmpty {
        self.delegate?.photoLibraryDidCancel()
      } else {
        // Create temporary PHAssets or handle differently
        // For now, we'll need to modify the delegate to handle UIImages directly
        self.handleImagesWithoutAssets(processedImages)
      }
    }
  }
  
  private func handleImagesWithoutAssets(_ images: [UIImage]) {
    print("PHPicker: Handling \(images.count) images without PHAssets")
    
    guard let delegate = delegate else {
      print("PHPicker: No delegate available")
      return
    }
    
    // Check if delegate implements the didSelectImages method
    if delegate.implementsDidSelectImages {
      print("PHPicker: Delegate supports didSelectImages - calling with \(images.count) images")
      delegate.photoLibrary?(didSelectImages: images)
    } else {
      print("PHPicker: Delegate doesn't implement didSelectImages")
      print("PHPicker: Calling didSelectAssets with empty array as fallback")
      print("PHPicker: Consider implementing photoLibrary(didSelectImages:) for better limited access support")
      delegate.photoLibrary(didSelectAssets: [])
    }
  }
}
