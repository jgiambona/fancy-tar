# 📦 Changelog

All notable changes to **fancy-tar** are documented here.

---

## [v1.3.12] - 2025-03-26

### Added
- 📁 `--zip` option to create `.zip` archives
- 🔐 Optional password-based encryption for ZIP files
- ⚠️ Security warning shown for classic ZIP encryption (insecure)
- 🧠 Works with existing options: `--hash`, `--tree`, `--password`, `--no-recursion`
- 📂 ZIP archives use `zip -r` and fall back gracefully

### Installer Notes
- Will check for the `zip` CLI tool
- ZIP output is compatible with most archive tools

---

## [v1.3.11] - 2025-03-26

### Fixed
- GPG encryption defaults to symmetric mode if `--recipient` is omitted
- Password prompt shown when needed
- Clean fallback and secure encryption handling

---

## [v1.3.10] - 2025-03-26

- Fixed argument parsing and encryption file cleanup

## [v1.3.9] - 2025-03-26

- File extension logic for encrypted files

## [v1.3.8] - Not Tagged

- Initial encryption and hash support
