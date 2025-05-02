# Split Archive Handling Improvements (Planned)

The following enhancements are planned for future versions of fancy-tar to improve split archive support:

1. **Consistent Naming and Output**
   - Print a summary of all split parts created, not just the first.
   - Allow the user to specify a custom prefix for split parts.
   - Document the naming convention in the help/README.

2. **Verification of All Parts**
   - For split archives, verify all parts (where possible), or at least check that all expected parts exist and are non-empty.
   - For 7z, use `7z t` on the first part (it will check the whole set if all parts are present).

3. **Reassembly Instructions**
   - After splitting, print clear instructions for the user on how to reassemble and extract the archive (e.g., `cat archive.tar.gz.* | tar xz` or `7z x archive.7z.001`).
   - Add this info to the README and man page.

4. **Support for More Split Formats**
   - Consider supporting split for other formats if needed (e.g., plain gzip, bzip2, xz).

5. **Error Handling and Cleanup**
   - On failure, clean up all split parts to avoid confusion.
   - Warn the user if any part is missing or incomplete.

6. **User Prompts and Automation**
   - If split parts already exist, prompt to overwrite, rename, or cancel (like for the main output).
   - Optionally, add a `--force` flag to overwrite all parts without prompting.

7. **Cross-Platform Compatibility**
   - Check for required tools before starting, and provide actionable error messages if missing.

8. **Documentation**
   - Add a dedicated section in the README and man page about split archives, including:
     - How to use the feature
     - How to reassemble/extract
     - Limitations and caveats

9. **Optional: Split After Encryption**
   - Allow the user to choose whether to split before or after encryption (splitting after encryption is more secure for distribution, but may not be supported by all formats).

10. **Optional: Progress Feedback**
    - Show progress for each split part, or at least indicate which part is being written. 