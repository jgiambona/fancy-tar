# 📦 Changelog

All notable changes to **fancy-tar** are documented here.

---

## [v1.4.0] - 2025-03-30

### Added
- ✅ Support for `.7z` archives with AES encryption
- 🧠 `--encrypt=7z` flag now supported
- 🔐 Password-protected 7z archives with `7z a -p`
- 🔍 Detects if `7z`/`p7zip` is missing and warns user
- 📦 Automatically changes output extension to `.7z` if 7z encryption is used

### Improved
- 🎯 Better password prompt integration for all encryption methods
- 🔄 Maintains compatibility with previous `--zip`, `--encrypt=gpg`, and `--encrypt=openssl` flows
