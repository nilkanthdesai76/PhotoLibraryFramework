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

## [Unreleased]

### Planned
- Video processing utilities
- Advanced image filters
- Batch processing improvements
- Performance optimizations