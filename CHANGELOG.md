# Changelog

All notable changes to PhotoLibraryFramework will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2024-12-19

### Added
- Initial release of PhotoLibraryFramework
- Camera capture with permission handling
- Photo library selection with multiple media types
- iCloud photo download support with progress tracking
- Theme support (light/dark mode)
- iPad popover support
- Comprehensive permission management
- Utility functions for image processing
- Async/await support for modern Swift concurrency
- Version-based dependency management

### API
- `PhotoLibraryManager.openPicker()` - Simplified API for opening photo picker
- `PhotoLibraryManager.shared.getImage()` - Async/await and completion handler support
- `PhotoUtilities` - Image processing utilities
- `PermissionManager` - Permission handling utilities
- `ThemeProvider` - Theme management protocol

### Framework Structure
- Clean API without PLF prefixes
- Semantic versioning support
- Comprehensive documentation
- Example usage and integration guides

## [1.2.0] - 2024-12-19

### Added
- **SelectedAssetsViewController**: Complete custom photo picker for limited access scenarios
- **Automatic picker selection**: Framework automatically chooses the right picker based on access level
- **Perfect limited access handling**: Eliminates empty assets array issue completely
- **Native iOS design**: Custom picker matches system photo picker appearance

### Fixed
- **Camera/Gallery selection**: Restored proper camera/gallery alert functionality
- **Limited access flow**: Fixed issue where camera/gallery choice was bypassed
- **Empty assets issue**: Completely resolved with SelectedAssetsViewController
- **User experience**: Maintains intuitive flow for all permission levels

### Enhanced
- **Built-in UI components**: SelectedAssetsCell with iCloud support and loading indicators
- **Video support**: Duration display and proper video handling
- **Selection management**: Multi-selection with limits and visual feedback
- **Photo library observer**: Real-time updates when photo library changes
- **Manage photos integration**: Easy access to photo permissions management

### Technical Improvements
- **Programmatic UI**: No storyboards/xibs required
- **Memory efficient**: Proper image loading and cell reuse
- **Thread safety**: Proper queue management for UI updates
- **Error handling**: Comprehensive iCloud and permission error handling

## [1.1.0] - 2024-12-19

### Added
- **Simplified API**: New `openPicker(from:)` method that automatically uses the presenting view controller as delegate
- **Type Safety**: View controller parameter now requires conformance to `PhotoLibraryDelegate`
- **Cleaner Extension Method**: Updated `presentPhotoLibrary()` to work without explicit delegate parameter
- **Comprehensive Documentation**: Added extensive examples for multiple selection, iCloud handling, and real-world usage patterns

### Changed
- **BREAKING**: Primary `openPicker` method now takes `from: UIViewController & PhotoLibraryDelegate` instead of separate delegate parameter
- **API Improvement**: Reduced boilerplate code - no need to pass `delegate: self` in most cases
- **Better Examples**: Updated all documentation examples to show simplified API usage

### Backward Compatibility
- **Maintained**: Advanced `openPicker(delegate:from:)` method still available for custom delegate scenarios
- **Migration**: Simple change from `openPicker(delegate: self, from: self)` to `openPicker(from: self)`

### Documentation
- Added multiple selection examples with progress tracking
- Added comprehensive iCloud download handling examples
- Added image processing and validation examples
- Added permission management examples
- Added real-world implementation patterns

## [1.0.0] - 2024-12-19

### Added
- Initial release of PhotoLibraryFramework
- Camera capture with permission handling
- Photo library selection with multiple media types
- iCloud photo download support with progress tracking
- Theme support (light/dark mode)
- iPad popover support
- Comprehensive permission management
- Utility functions for image processing
- Async/await support for modern Swift concurrency
- Version-based dependency management

### API
- `PhotoLibraryManager.openPicker()` - Simplified API for opening photo picker
- `PhotoLibraryManager.shared.getImage()` - Async/await and completion handler support
- `PhotoUtilities` - Image processing utilities
- `PermissionManager` - Permission handling utilities
- `ThemeProvider` - Theme management protocol

### Framework Structure
- Clean API without PLF prefixes
- Semantic versioning support
- Comprehensive documentation
- Example usage and integration guides

## [Unreleased]

### Planned
- Video processing utilities
- Advanced image filters
- Batch processing improvements
- Performance optimizations