import XCTest
@testable import PhotoLibraryFramework

final class PhotoLibraryFrameworkTests: XCTestCase {
    
    func testFrameworkVersion() {
        // Test that the framework version is accessible
        XCTAssertEqual(PLFFramework.frameworkVersion, "1.0.0")
    }
    
    func testFrameworkInitialization() {
        // Test that the framework singleton initializes
        let framework = PLFFramework.shared
        XCTAssertNotNil(framework)
    }
    
    func testManagerInitialization() {
        // Test that the manager singleton initializes
        let manager = PLFPhotoLibraryManager.shared
        XCTAssertNotNil(manager)
    }
    
    #if os(iOS)
    func testPermissionManager() {
        // Test permission manager methods (iOS only)
        let photoStatus = PLFPermissionManager.photoLibraryAuthorizationStatus()
        let cameraStatus = PLFPermissionManager.cameraAuthorizationStatus()
        
        // Just test that these don't crash and return valid values
        XCTAssertTrue(photoStatus.rawValue >= 0)
        XCTAssertTrue(cameraStatus.rawValue >= 0)
    }
    
    func testPhotoUtilities() {
        // Test image resizing with a simple 1x1 image (iOS only)
        let image = UIImage(systemName: "photo") ?? UIImage()
        let resized = PLFPhotoUtilities.resizeImage(image, to: CGSize(width: 100, height: 100))
        XCTAssertNotNil(resized)
    }
    #endif
}