# 📦 Changelog

All notable changes to **fancy-tar** are documented here.

---

## [v1.3.13] - 2025-03-30

### Added
- `--version` flag to show current version
- Password confirmation prompt for interactive encryption

### Fixed
- `--recipient` with no value now triggers an error and lists available GPG keys
- `--zip --encrypt` now correctly prompts for password
- `--zip --password` no longer hangs or double-prompts
- Incomplete archive files are deleted automatically on failure
