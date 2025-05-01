# Changelog

## [1.7.3] - 2024-04-30

### Added
- Added `--print-filename` flag to output only the final archive filename
  - Useful for scripting and piping to other commands
  - Suppresses all other output except the filename
  - Can be combined with other options
- Added `fancytar` and `ftar` command aliases
  - Alternative command names for easier typing
  - Full shell completion support for all aliases
  - Automatically created during installation

## [1.7.2] - 2024-04-29

### Fixed
- Fixed GPG encrypted output files to properly maintain .gpg extension
- Fixed OpenSSL encrypted output files to properly maintain .enc extension

## [1.7.1] - 2024-04-29

### Added
- Added `--use` option to force specific compression tools
- Added proper split archive support for all formats (tar, zip, 7z)
- Added support for compression tool selection in split archives

### Changed
- Updated documentation to clarify compression level behavior
- Removed password strength validation (not implemented)
- Clarified 7z encryption behavior in documentation
- Improved error handling for split archives
- Fixed compression tool selection logic

### Fixed
- Fixed `--recipient` option for GPG public key encryption
- Fixed split archive naming conventions
- Fixed compression handling in split archives
- Fixed documentation inconsistencies

## [1.7.0] - 2024-03-26

### Changed
- Modified compression behavior to respect explicit compression method choices
  - When a compression method is explicitly specified (e.g., gzip, bzip2, xz), the tool will use that exact method without attempting to use parallel versions
  - This allows for consistent behavior when specific compression tools are required
- Updated documentation to clarify compression behavior
- Removed implemented features from future features list
- Changed version management to source from VERSION file

### Fixed
- Fixed Debian package installation paths
- Fixed RPM package build process
- Fixed man page formatting and content

## [1.6.6] - 2024-03-25
### Added
- Added support for parallel compression tools (pigz, pbzip2, pxz)
- Added automatic detection and use of parallel compression tools
- Added progress reporting for parallel compression
- Added documentation for parallel compression support

### Changed
- Improved compression performance by utilizing multiple CPU cores
- Updated man page to document parallel compression support
- Updated README with parallel compression information

## [1.6.5] - 2024-03-24
### Added
- Added support for split archives
- Added archive verification
- Added SHA256 hash generation
- Added tree view for file hierarchy

### Changed
- Improved error handling
- Updated documentation
- Fixed various bugs

## [1.6.4] - 2024-03-23
### Added
- Added support for 7z archives
- Added support for OpenSSL encryption
- Added support for GPG encryption
- Added support for ZIP archives

### Changed
- Improved security features
- Updated documentation
- Fixed various bugs

## [1.6.3] - 2024-03-22
### Added
- Added support for progress bars
- Added support for desktop notifications
- Added support for folder opening
- Added support for automatic cleanup

### Changed
- Improved user experience
- Updated documentation
- Fixed various bugs

## [1.6.2] - 2024-03-21
### Added
- Added support for man pages
- Added support for shell completions
- Added support for version checking
- Added support for self-testing

### Changed
- Improved installation process
- Updated documentation
- Fixed various bugs

## [1.6.1] - 2024-03-20
### Added
- Added support for Homebrew
- Added support for Debian packages
- Added support for RPM packages
- Added support for manual installation

### Changed
- Improved packaging
- Updated documentation
- Fixed various bugs

## [1.6.0] - 2024-03-19
### Added
- Initial release
- Basic tar functionality
- Basic compression support
- Basic encryption support

### Changed
- Improved error handling
- Updated documentation
- Fixed various bugs

## [1.4.8] - 2025-03-30
- ✅ Fully rebuilt from verified v1.3.13 base
- ✅ All features restored (zip, encryption, hashing, trees, etc.)
- ✅ `--version`, `--self-test` re-enabled
- ✅ Permission, password, and error handling fixed
- ✅ Desktop notification and `-x` folder opening
