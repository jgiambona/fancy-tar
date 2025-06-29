# Changelog

## [Unreleased]


## [1.8.3] - 2025-07-01

### Added
- **--verbose option**: New option to show each file being processed with file count display [001/234]. When not used, only the progress bar is shown (default behavior).
- **File count display**: Shows current file number and total files when --verbose is enabled, making it easier to track progress for large archives.

### Fixed
- **Tar command construction**: Fixed "Cannot stat" errors by replacing string-based command construction with proper array-based arguments. This prevents issues with file paths containing spaces and special characters.
- **File path handling**: Improved file path resolution to use `realpath` when available, with a robust fallback for systems without it. This prevents malformed absolute paths that could cause tar to fail.
- **Command execution**: Replaced `eval` usage with direct command execution using arrays, improving security and reliability when handling complex file paths.
- **Path handling in archives**: Fixed issue where archiving directories would include the full absolute path structure (e.g., `/Users/me/Downloads/somedirectory/sub1`) instead of just the relative path from the current directory. Now uses tar's `-C` option to ensure only relative paths are preserved in the archive.

## [1.8.2] - 2025-06-29

### Fixed
- **Default filename generation**: Fixed issue where archiving the current directory (`.`) would result in an invalid filename like `..tar.gz`. Now properly uses the current directory name as the base filename.
- **Tar command construction**: Fixed "Cannot stat" errors when processing files with spaces and special characters in their names. Simplified tar command construction to use tar's native file handling instead of complex `-C` directory changes.
- **File path handling**: Improved handling of file paths with spaces, parentheses, and other special characters to prevent tar command failures.

## [1.8.1] - 2025-06-28

### Added
- **Multiple easy installation options for less tech-savvy users:**
  - One-liner curl installer: `curl -fsSL https://raw.githubusercontent.com/jgiambona/fancy-tar/main/install-curl.sh | bash`
  - macOS-specific installer with multiple options (Homebrew, user directory, Applications folder, standalone bundle)
  - Interactive installer with dependency detection and automatic installation
  - Quick installer for minimal user interaction
  - All installers preserve existing installation methods and don't break current functionality
  - **macOS installers work without requiring Xcode or Homebrew installation** - they use system tools or provide clear alternatives
- File selection options for all archive types (tar, zip, 7z) with unified pattern syntax:
  - `--exclude <pattern>`: Exclude files matching the given pattern (can be used multiple times)
  - `--include <pattern>`: Include only files matching the given pattern (can be used multiple times)
  - `--files-from <file>`: Read list of files to include from a file (one per line; supports glob patterns; blank lines and lines starting with # are ignored)
- All file selection is now handled by the script using consistent shell glob patterns, ensuring the same syntax works across all archive formats.
- Enhanced `--debug` option: now shows all commands being executed (compression, encryption, splitting, verification, etc.) for educational and debugging purposes.

### Changed
- Updated FUTURE.md to eliminate many considered features that are low value to users and add unnecessary complexity.
- **Documentation improvements**: Clarified the different behaviors between `--password` and `--encrypt` options for different archive types:
  - ZIP: `--password` uses native zip password protection, `--encrypt` creates zip then encrypts with GPG
  - 7z: Both `--password` and `--encrypt` use 7z's built-in AES-256 encryption
  - tar/tar.gz: `--encrypt` specifies GPG or OpenSSL method, `--password` provides the password
- Added comprehensive examples and explanations for all encryption scenarios in README and man page.
- **Installation documentation**: Reorganized installation section with clear options for different user skill levels, added installation options summary table, and highlighted the easiest methods for beginners.

### Fixed
- **Shell syntax error**: Fixed eval command failure when processing filenames containing special characters like parentheses `()`. The tar command construction now properly quotes file paths to handle any filename safely.

## [1.8.0] - 2024-06-11

### Added
- `--force` flag for split archives: Automatically overwrite all existing split parts without prompting when using `--split-size`. Useful for scripting or automation.
- For 7z split archives, if `--verify` is set, fancy-tar now automatically runs `7z t` on the first part after creation to verify the whole set.
- Every time an archive is split, a <output>.parts.txt file is created listing all split parts and their sizes (in bytes).
- When --hash is used with split archives, a <output>.parts.sha256 file is created with SHA256 hashes for each part, and a warning is printed that these are for individual parts, not the reassembled archive. To verify the full archive, reassemble all parts and hash the combined file.
- Manifest improvements: Add `--manifest csvhash`, add file type and depth to CSV, use streaming hash with sha256sum/shasum/openssl, update docs and completions for all manifest formats, optimize for portability and security.
- Added and documented macOS Quick Actions (Automator workflows) for drag-and-drop archiving and custom user actions.
- Debian changelog version matches v1.8.0 tag.

### Fixed
- Progress display: Fixed 'invalid number' errors in archive size formatting during progress display. The size formatting is now robust for all file and directory inputs.

### Changed
- Changed `--print-filename` behavior: for split archives, it now outputs all split part filenames (one per line) to stdout, making scripting easier and more robust. For non-split archives, it still outputs the single filename.

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
- Fixed `--recipient`