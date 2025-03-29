# 📦 Changelog

All notable changes to **fancy-tar** are documented here.

---

## [v1.3.13] - 2025-03-27

### Added
- `--version` flag to show current version (e.g. fancy-tar 1.3.13)
- Interactive password prompt now asks for confirmation

### Fixed
- `--encrypt=gpg --recipient` without a value now errors and shows available GPG keys
- `--zip --encrypt` now correctly prompts for password
- `--zip --password` no longer hangs or prompts twice
- Incomplete archive files are properly cleaned up on any error

