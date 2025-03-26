complete -c fancy-tar -s o -d "Set output archive name" -r
complete -c fancy-tar -s n -d "No gzip compression"
complete -c fancy-tar -s s -d "Enable slow mode"
complete -c fancy-tar -s x -d "Open output folder"
complete -c fancy-tar -s t -l tree -d "Show file tree"
complete -c fancy-tar -l no-recursion -d "No recursion"
complete -c fancy-tar -l hash -d "Output SHA256 hash"
complete -c fancy-tar -l encrypt -d "Encrypt archive (gpg/openssl)" -r
complete -c fancy-tar -l recipient -d "Recipient for GPG" -r
complete -c fancy-tar -l password -d "Encryption password" -r
complete -c fancy-tar -l zip -d "Create ZIP archive"
complete -c fancy-tar -s h -l help -d "Show help"
