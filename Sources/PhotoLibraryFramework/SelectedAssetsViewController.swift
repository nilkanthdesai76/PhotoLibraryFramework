import UIKit
import Photos
import PhotosUI

// MARK: - Selected Assets Cell
public class SelectedAssetsCell: UICollectionViewCell {
    
    // MARK: - UI Elements
    private lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private lazy var selectionIndicator: UIImageView = {
        let imageView = UIImageView()
        imageView.backgroundColor = .systemBlue
        imageView.layer.cornerRadius = 12
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.isHidden = true
        
        if #available(iOS 13.0, *) {
            let checkmark = UIImageView(image: UIImage(systemName: "checkmark"))
            checkmark.tintColor = .white
            checkmark.translatesAutoresizingMaskIntoConstraints = false
            imageView.addSubview(checkmark)
            NSLayoutConstraint.activate([
                checkmark.centerXAnchor.constraint(equalTo: imageView.centerXAnchor),
                checkmark.centerYAnchor.constraint(equalTo: imageView.centerYAnchor)
            ])
        }
        
        return imageView
    }()
    
    private lazy var durationLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12, weight: .bold)
        label.textColor = .white
        label.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        label.textAlignment = .center
        label.layer.cornerRadius = 4
        label.clipsToBounds = true
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isHidden = true
        return label
    }()
    
    private lazy var activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.hidesWhenStopped = true
        return indicator
    }()
    
    private lazy var iCloudIcon: UIImageView = {
        let imageView = UIImageView()
        if #available(iOS 13.0, *) {
            imageView.image = UIImage(systemName: "icloud.and.arrow.down")
        }
        imageView.tintColor = .systemBlue
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.isHidden = true
        return imageView
    }()
    
    // MARK: - Properties
    public static let identifier = "SelectedAssetsCell"
    private var currentAsset: PHAsset?
    private var imageRequestID: PHImageRequestID?
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    // MARK: - Setup
    private func setupUI() {
        contentView.addSubview(imageView)
        contentView.addSubview(selectionIndicator)
        contentView.addSubview(durationLabel)
        contentView.addSubview(activityIndicator)
        contentView.addSubview(iCloudIcon)
        
        NSLayoutConstraint.activate([
            // Image view
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            // Selection indicator
            selectionIndicator.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            selectionIndicator.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            selectionIndicator.widthAnchor.constraint(equalToConstant: 24),
            selectionIndicator.heightAnchor.constraint(equalToConstant: 24),
            
            // Duration label
            durationLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            durationLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            durationLabel.heightAnchor.constraint(equalToConstant: 20),
            durationLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 40),
            
            // Activity indicator
            activityIndicator.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            
            // iCloud icon
            iCloudIcon.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            iCloudIcon.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            iCloudIcon.widthAnchor.constraint(equalToConstant: 20),
            iCloudIcon.heightAnchor.constraint(equalToConstant: 20)
        ])
    }
    
    // MARK: - Configuration
    public func configure(with asset: PHAsset, isSelected: Bool) {
        currentAsset = asset
        cancelImageRequest()
        
        // Setup selection state
        selectionIndicator.isHidden = !isSelected
        
        // Setup duration for videos
        if asset.mediaType == .video {
            durationLabel.isHidden = false
            durationLabel.text = formatDuration(asset.duration)
        } else {
            durationLabel.isHidden = true
        }
        
        // Load image
        loadImage(for: asset)
    }
    
    private func loadImage(for asset: PHAsset) {
        activityIndicator.startAnimating()
        
        // Check if in iCloud
        PhotoLibraryManager.shared.isAssetInCloud(asset) { [weak self] isInCloud in
            DispatchQueue.main.async {
                guard let self = self, self.currentAsset == asset else { return }
                self.iCloudIcon.isHidden = !isInCloud
            }
        }
        
        let manager = PHImageManager.default()
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .opportunistic
        options.resizeMode = .exact
        
        let targetSize = CGSize(width: 200, height: 200)
        
        imageRequestID = manager.requestImage(
            for: asset,
            targetSize: targetSize,
            contentMode: .aspectFill,
            options: options
        ) { [weak self] image, info in
            DispatchQueue.main.async {
                guard let self = self, self.currentAsset == asset else { return }
                
                let isDegraded = (info?[PHImageResultIsDegradedKey] as? Bool) ?? false
                
                if let image = image {
                    self.imageView.image = image
                    if !isDegraded {
                        self.activityIndicator.stopAnimating()
                        self.iCloudIcon.isHidden = true
                    }
                } else if !isDegraded {
                    self.activityIndicator.stopAnimating()
                }
            }
        }
    }
    
    private func cancelImageRequest() {
        if let requestID = imageRequestID {
            PHImageManager.default().cancelImageRequest(requestID)
            imageRequestID = nil
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .positional
        formatter.allowedUnits = [.minute, .second]
        formatter.zeroFormattingBehavior = .pad
        return formatter.string(from: duration) ?? "00:00"
    }
    
    public override func prepareForReuse() {
        super.prepareForReuse()
        cancelImageRequest()
        imageView.image = nil
        activityIndicator.stopAnimating()
        iCloudIcon.isHidden = true
        selectionIndicator.isHidden = true
        durationLabel.isHidden = true
        currentAsset = nil
    }
}

// MARK: - Selected Assets View Controller
public class SelectedAssetsViewController: UIViewController {
    
    // MARK: - UI Elements
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 2
        layout.minimumLineSpacing = 2
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .systemBackground
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(SelectedAssetsCell.self, forCellWithReuseIdentifier: SelectedAssetsCell.identifier)
        return collectionView
    }()
    
    private lazy var navigationBar: UINavigationBar = {
        let navBar = UINavigationBar()
        navBar.translatesAutoresizingMaskIntoConstraints = false
        
        let navItem = UINavigationItem(title: "Select Photos")
        
        let cancelButton = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(cancelTapped)
        )
        
        let doneButton = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: self,
            action: #selector(doneTapped)
        )
        
        let manageButton = UIBarButtonItem(
            title: "Manage",
            style: .plain,
            target: self,
            action: #selector(manageTapped)
        )
        
        navItem.leftBarButtonItem = cancelButton
        navItem.rightBarButtonItems = [doneButton, manageButton]
        
        navBar.setItems([navItem], animated: false)
        return navBar
    }()
    
    // MARK: - Properties
    private var fetchResult: PHFetchResult<PHAsset>?
    private var selectedAssets: [PHAsset] = []
    private let imageManager = PHCachingImageManager()
    private var downloadingAssets: Set<PHAsset> = []
    
    public var mediaType: MediaType = .images
    public var selectionLimit: Int = 1
    public var completion: (([PHAsset]) -> Void)?
    public var cancellation: (() -> Void)?
    
    // MARK: - Lifecycle
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadAssets()
        PHPhotoLibrary.shared().register(self)
    }
    
    deinit {
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        view.addSubview(navigationBar)
        view.addSubview(collectionView)
        
        NSLayoutConstraint.activate([
            navigationBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            navigationBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            navigationBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            collectionView.topAnchor.constraint(equalTo: navigationBar.bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func loadAssets() {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
        switch mediaType {
        case .images:
            fetchResult = PHAsset.fetchAssets(with: .image, options: options)
        case .videos:
            fetchResult = PHAsset.fetchAssets(with: .video, options: options)
        case .livePhotos:
            fetchResult = PHAsset.fetchAssets(with: .image, options: options)
        case .imagesAndVideos:
            fetchResult = PHAsset.fetchAssets(with: options)
        }
        
        collectionView.reloadData()
    }
    
    // MARK: - Actions
    @objc private func cancelTapped() {
        cancellation?()
        dismiss(animated: true)
    }
    
    @objc private func doneTapped() {
        completion?(selectedAssets)
        dismiss(animated: true)
    }
    
    @objc private func manageTapped() {
        if #available(iOS 14.0, *) {
            PHPhotoLibrary.shared().presentLimitedLibraryPicker(from: self)
        }
    }
    
    // MARK: - Selection Logic
    private func toggleSelection(for asset: PHAsset, at indexPath: IndexPath) {
        if downloadingAssets.contains(asset) {
            showDownloadingAlert()
            return
        }
        
        if selectedAssets.contains(asset) {
            selectedAssets.removeAll { $0 == asset }
        } else {
            if selectionLimit == 1 {
                selectedAssets.removeAll()
                selectedAssets.append(asset)
                completion?(selectedAssets)
                dismiss(animated: true)
                return
            } else if selectedAssets.count >= selectionLimit {
                showSelectionLimitAlert()
                return
            } else {
                selectedAssets.append(asset)
            }
        }
        
        collectionView.reloadItems(at: [indexPath])
    }
    
    private func showDownloadingAlert() {
        let alert = UIAlertController(
            title: "Downloading",
            message: "This photo is currently being downloaded from iCloud. Please wait.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func showSelectionLimitAlert() {
        let alert = UIAlertController(
            title: "Selection Limit",
            message: "You can select maximum \(selectionLimit) photos.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - Collection View Data Source & Delegate
extension SelectedAssetsViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return fetchResult?.count ?? 0
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SelectedAssetsCell.identifier, for: indexPath) as! SelectedAssetsCell
        
        if let asset = fetchResult?.object(at: indexPath.item) {
            let isSelected = selectedAssets.contains(asset)
            cell.configure(with: asset, isSelected: isSelected)
        }
        
        return cell
    }
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let asset = fetchResult?.object(at: indexPath.item) {
            toggleSelection(for: asset, at: indexPath)
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (collectionView.frame.width - 4) / 3 // 3 columns with 2px spacing
        return CGSize(width: width, height: width)
    }
}

// MARK: - Photo Library Change Observer
extension SelectedAssetsViewController: PHPhotoLibraryChangeObserver {
    
    public func photoLibraryDidChange(_ changeInstance: PHChange) {
        DispatchQueue.main.async {
            guard let fetchResult = self.fetchResult else { return }
            
            if let changeDetails = changeInstance.changeDetails(for: fetchResult) {
                self.fetchResult = changeDetails.fetchResultAfterChanges
                self.collectionView.reloadData()
            }
        }
    }
}