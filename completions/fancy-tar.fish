complete -c fancy-tar -s o -d "Set output archive name" -r
complete -c fancy-tar -s n -d "No gzip compression"
complete -c fancy-tar -s s -d "Enable slow mode"
complete -c fancy-tar -s x -d "Open folder after archiving"
complete -c fancy-tar -s t -l tree -d "Show tree view before archiving"
complete -c fancy-tar -l no-recursion -d "Disable recursive archiving"
complete -c fancy-tar -l hash -d "Output SHA256 hash file"
complete -c fancy-tar -l encrypt -d "Encryption method (gpg or openssl)" -r
complete -c fancy-tar -l recipient -d "GPG recipient public key"
complete -c fancy-tar -l password -d "Password for encryption" -r
complete -c fancy-tar -s h -l help -d "Show help"
