# 📦 Changelog

All notable changes to **fancy-tar** will be documented in this file.

---

## [v1.3.9] - 2025-03-26

### Added
- 📦 Smart file extension handling:
  - `.gpg` is appended when using GPG encryption
  - `.enc` is appended when using OpenSSL encryption
- 🛡 Clear warning if user-supplied `-o` already ends in `.gpg` or `.enc`
- 📘 Documentation and completions updated accordingly

### Changed
- 🔐 Encrypted output is now renamed for clarity
- 🔄 Maintains final archive name for hashing and completion

---

## [v1.3.8] - Not Tagged (included in 1.3.9)

### Fixed
- ✅ `--hash` now runs after encryption to ensure integrity of final archive
- ✅ Deletes incomplete `.tar`, `.gz`, or encrypted files on any error

### Added
- 🧠 Validates `--recipient` input:
  - Graceful error if no recipient provided
  - Lists available GPG keys on failure
- 🔒 Prompts interactively for password if `--password` is not provided
- 🧼 Improved fail-safety and output accuracy

---

## [v1.3.7] - 2025-03-25

### Added
- 🔐 `--encrypt=gpg` and `--encrypt=openssl`
- 🔐 `--recipient` for public key encryption
- 🔑 `--password` for symmetric encryption
- 🧠 Intelligent fallback to prompt if no password is passed

### Docs & Shell
- 📘 Updated man page and README with encryption details
- 🐚 Updated completions (Bash, Zsh, Fish)

---

## [v1.3.6] - Pre-release

- 💡 Added `--hash` to output a SHA256 file
- 🌳 Added `--tree` to show hierarchical file listing
- ⌛ Displays time elapsed, ETA, and total files
