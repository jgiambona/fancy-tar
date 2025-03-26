# 📦 Changelog

All notable changes to **fancy-tar** are documented here.

---

## [v1.3.10] - 2025-03-26

### Fixed
- 🧠 Proper argument parsing for `--recipient`, `--encrypt`, `--password`, etc.
  - Supports both `--flag=value` and `--flag value`
- 🛡 Prevents flags from being passed to `find` or `tar`
- 🧼 No pre-renaming before encryption (fixes GPG errors)
- ❌ Displays error only if encryption truly fails
- ✅ SHA256 hash is created only after successful encryption

### Changed
- 🧾 Encrypted files are now saved separately as `.gpg` or `.enc`
- 🧹 Unencrypted archive is deleted after successful encryption
- 🔐 Updated logic ensures secure, accurate archive creation

---

## [v1.3.9] - 2025-03-26

### Added
- 📦 Smart file extension handling for `.gpg` and `.enc`
- 🛡 Extension auto-appending and validation
- 📘 Updated docs and completions

### Changed
- 🔐 Encryption no longer overwrites the input archive

---

## [v1.3.8] - Not Tagged (merged into 1.3.9)

### Fixed
- ✅ `--hash` now runs after encryption
- ❌ Incomplete files are cleaned on error

### Added
- 🧠 Validates `--recipient`
- 🔑 Password prompt fallback
