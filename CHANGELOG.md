# 📦 Changelog

All notable changes to **fancy-tar** are documented here.

---

## [v1.4.1] - 2025-03-30

### Fixed
- Ensure `fancy-tar` script is marked executable during install
- Homebrew formula sets executable permissions (`chmod +x`)
- Installer script now warns if a conflicting `fancy-tar` binary is found earlier in the user's `$PATH`
