## [1.6.4] - 2024-03-30
### Added
- Progress indication for ZIP operations using `pv`
- Enhanced progress reporting for all archive types
- Improved error handling for progress bar calculations

### Changed
- Optimized progress bar size calculations
- Enhanced file size detection for all archive types
- Improved cleanup of temporary files

## [1.6.3] - 2024-03-30
### Added
- Progress indication for 7z and ZIP operations using `pv`
- Compression level warnings for 7z archives
- Enhanced help text with detailed compression level information
- Improved documentation for 7z features

### Changed
- Default 7z compression level set to 5 (normal)
- Updated README with compression level details
- Enhanced progress reporting for all archive types

## [1.6.2] - 2024-03-30
- ✅ Updated documentation

## [1.6.1] - 2024-03-30
- ✅ Fixed ZIP password prompts to only trigger when encryption is requested

## [1.6.0] - 2024-03-30
- ✅ Improved self-test with interactive password prompts
- ✅ Added automatic cleanup of temporary files
- ✅ Enhanced ZIP archive size detection
- ✅ Fixed password handling in test cases
- ✅ Improved error handling and output formatting

## [1.4.8] - 2025-03-30
- ✅ Fully rebuilt from verified v1.3.13 base
- ✅ All features restored (zip, encryption, hashing, trees, etc.)
- ✅ `--version`, `--self-test` re-enabled
- ✅ Permission, password, and error handling fixed
- ✅ Desktop notification and `-x` folder opening
