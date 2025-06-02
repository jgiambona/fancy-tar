# Future Features and Improvements

This document tracks features and improvements to consider and/or implement for future versions of fancy-tar.

## File Selection and Management

1. **Advanced File Selection**
   - Add `--exclude` option for file/pattern exclusion
   - Add `--include` option for selective inclusion
   - Add `--exclude-dir` for directory exclusion
   - Add support for `.gitignore` style patterns
   - Add support for file size limits
   - Add auto-generated file lists:
     - CSV format with file name, size, and relative path
     - Text file with hierarchical folder structure
     - Interactive file selection interface
   - Add support for file list import/export

2. **Archive Management**
   - Add support for archive repair
   - Add support for decrypting archives:
     - Support for all encryption methods
     - Password and key file decryption
     - Batch decryption of multiple archives
     - Progress reporting during decryption

## Security and Encryption

3. **Security Enhancements**
    - Add key file support for encryption
    - Add support for encrypted file names
    - Add support for encrypted metadata

## User Experience

4. **Configuration Options**
    - Add support for configuration files
    - Add support for environment variables
    - Add support for command aliases
    - Add support for default options
    - Add support for user preferences
    - Add default.config file with well-documented options
    - Add configuration option naming consistency with CLI
    - Add configuration validation and error checking


5. **Interactive Mode**
    - Add file selection interface with checkboxes
    - Add compression options selection menu
    - Add encryption settings configuration
    - Add progress visualization with detailed stats
    - Add interactive help and documentation
    - Add keyboard shortcuts for common operations
    - Add mouse support for file selection
    - Add multi-step wizard for complex operations
    - Add interactive file extraction with individual file selection
    - Add manifest generation with multiple output formats
      - Tree view
      - Text file
      - CSV file

6. **Archive Inspection**
    - Add `--manifest` option to generate detailed file listings
      - List all files in archive with paths
      - Show compressed and uncompressed sizes
      - Show compression ratios
      - Show file attributes and timestamps
      - Support multiple output formats:
        - Tree view (`--manifest=tree`)
        - Text file (`--manifest=text`)
        - CSV file (`--manifest=csv`)
        - CSV with SHA256 hash (`--manifest=csvhash`)
      - CSV columns: Path, Compressed Size, Uncompressed Size, Compression Ratio, File Type, Depth, Attributes, Timestamp
      - CSVHASH columns: All CSV columns plus SHA256 hash per file
      - Include warnings or information in the manifest output file, such as split archive reassembly instructions, a list of split parts, etc.

## Per-File Archiving Rules via Config File

### Overview

Introduce a configuration system that allows users to specify rules for handling files based on their names or patterns when creating archives. This enables automatic application of settings such as encryption, recipient selection, archive format, and compression options for specific files or file types.

---

### Use Case Examples

- **Encrypt all `.sql` files for a specific recipient.**
- **Use a different archive format for files named `ABC123.txt`.**
- **Apply custom compression settings to log files.**

---

### Proposed Config File Format

Use a YAML (or JSON) file to define rules. Each rule includes:
- A filename pattern (glob or regex).
- Settings to apply when a file matches the pattern.

**Example (`.fancytar.yml`):**
```yaml
rules:
  - pattern: "*.sql"
    encrypt: true
    recipient: "alice@example.com"
    format: "tar.gz"
    compression: "xz"
  - pattern: "ABC123.txt"
    encrypt: true
    recipient: "bob@example.com"
    format: "zip"
    compression: "deflate"
```

---

### Implementation Plan

1. **Config File Loading**
   - On archive creation, load a config file (default: `.fancytar.yml` in the working directory, or as specified by CLI).

2. **Rule Matching**
   - For each file to be archived, check if its name matches any rule's pattern using glob or regex matching.
   - If multiple rules match, apply the first match or allow for rule priority/merging.

3. **Settings Application**
   - Apply the matched rule's settings (encryption, recipient, format, compression, etc.) when processing the file.
   - If no rule matches, use default/global settings.

4. **CLI Integration**
   - Allow CLI options to override config file settings if specified.

5. **Feedback and Logging**
   - Optionally, log or display which rules were applied to which files for transparency.

---

### Extensibility

- **Additional Criteria:** Support matching on file size, directory, or other attributes.
- **More Actions:** Add support for exclusion, custom metadata, or post-processing hooks.
- **Rule Priority:** Allow users to specify rule order or explicit priorities.

---

### Example Workflow

1. User runs:
   ```
   fancytar create archive.tar file1.sql ABC123.txt notes.txt
   ```
2. The tool loads `.fancytar.yml`.
3. It matches `file1.sql` to the first rule, `ABC123.txt` to the second, and `notes.txt` to none (uses defaults).
4. It applies the specified settings for each file as it adds them to the archive.

---

### Technical Notes

- **YAML Parsing:** Use a library such as PyYAML (Python) or equivalent.
- **Pattern Matching:** Use `fnmatch` or `glob` for glob patterns, or regex for advanced matching.
- **Backward Compatibility:** If no config file is present, fall back to current behavior.

---

### Open Questions

- Should rules be allowed to merge, or is first-match sufficient?
- Should there be a dry-run or verbose mode to preview rule application?
- How should errors in the config file be handled?

---

### Status

**Planned** — Not yet implemented.

## Implementation Priority

Features are listed in rough order of priority, but actual implementation order may vary based on:
- User demand
- Technical feasibility
- Dependencies between features
- Available development resources

## Version Planning

Future versions will focus on implementing these features in logical groups:

- v1.7.x: Bug fixes and improvements to core features.
- v1.8.x: Focus on file selection and management features
- v1.9.x: Focus on security and encryption enhancements
- v2.0.x: Focus on user experience and integration features

## Contributing

If you'd like to contribute to any of these features, please:
1. Open an issue to discuss the feature
2. Create a pull request with your implementation
3. Include tests and documentation
4. Follow the existing code style and conventions
