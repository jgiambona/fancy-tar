# 📦 Changelog

All notable changes to **fancy-tar** are documented here.

---

## [v1.3.11] - 2025-03-26

### Fixed
- 🔐 GPG encryption now defaults to symmetric mode if `--recipient` is not provided
- ✅ No longer shows an error when `--encrypt=gpg` is used without `--recipient`
- 🔑 Prompts for password automatically if `--password` not provided
- 🧠 More intuitive behavior with clean fallback logic

---

## [v1.3.10] - 2025-03-26

### Fixed
- Proper argument parsing for all long-form flags
- Removed accidental passing of flags to `find`/`tar`
- Encryption works cleanly with `.gpg` or `.enc`
- Only shows success if encryption truly succeeds

### Changed
- Encrypted files created as new files, original tar.gz removed
- SHA256 only created for final file after encryption

---

## [v1.3.9] - 2025-03-26

- Smart `.gpg` / `.enc` file extension handling
- Updated documentation and completions

## [v1.3.8] - Not Tagged

- Added `--hash`
- Added encryption and key validation
- Cleanup of incomplete files
