complete -c fancy-tar -s o -l output -d 'Specify output file name' -r
complete -c fancy-tar -s n -d 'Create uncompressed tar archive'
complete -c fancy-tar -s s -d 'Use slower but better compression'
complete -c fancy-tar -s x -d 'Open the output folder when done'
complete -c fancy-tar -s t -l tree -d 'Show hierarchical file structure before archiving'
complete -c fancy-tar -l no-recursion -d 'Do not include directory contents'
complete -c fancy-tar -l hash -d 'Output SHA256 hash file alongside the archive'
complete -c fancy-tar -l encrypt -d 'Encrypt archive with gpg or openssl' -r -a "gpg openssl"
complete -c fancy-tar -l recipient -d 'Recipient ID for GPG public key encryption' -r
complete -c fancy-tar -l password -d 'Password to use for encryption' -r
complete -c fancy-tar -l zip -d 'Create a .zip archive'
complete -c fancy-tar -l print-filename -d 'Output only the final archive filename'
complete -c fancy-tar -l version -d 'Show version information'
complete -c fancy-tar -l help -d 'Show help message'

# Add completions for aliases
complete -c fancytar -s o -l output -d 'Specify output file name' -r
complete -c fancytar -s n -d 'Create uncompressed tar archive'
complete -c fancytar -s s -d 'Use slower but better compression'
complete -c fancytar -s x -d 'Open the output folder when done'
complete -c fancytar -s t -l tree -d 'Show hierarchical file structure before archiving'
complete -c fancytar -l no-recursion -d 'Do not include directory contents'
complete -c fancytar -l hash -d 'Output SHA256 hash file alongside the archive'
complete -c fancytar -l encrypt -d 'Encrypt archive with gpg or openssl' -r -a "gpg openssl"
complete -c fancytar -l recipient -d 'Recipient ID for GPG public key encryption' -r
complete -c fancytar -l password -d 'Password to use for encryption' -r
complete -c fancytar -l zip -d 'Create a .zip archive'
complete -c fancytar -l print-filename -d 'Output only the final archive filename'
complete -c fancytar -l version -d 'Show version information'
complete -c fancytar -l help -d 'Show help message'

complete -c ftar -s o -l output -d 'Specify output file name' -r
complete -c ftar -s n -d 'Create uncompressed tar archive'
complete -c ftar -s s -d 'Use slower but better compression'
complete -c ftar -s x -d 'Open the output folder when done'
complete -c ftar -s t -l tree -d 'Show hierarchical file structure before archiving'
complete -c ftar -l no-recursion -d 'Do not include directory contents'
complete -c ftar -l hash -d 'Output SHA256 hash file alongside the archive'
complete -c ftar -l encrypt -d 'Encrypt archive with gpg or openssl' -r -a "gpg openssl"
complete -c ftar -l recipient -d 'Recipient ID for GPG public key encryption' -r
complete -c ftar -l password -d 'Password to use for encryption' -r
complete -c ftar -l zip -d 'Create a .zip archive'
complete -c ftar -l print-filename -d 'Output only the final archive filename'
complete -c ftar -l version -d 'Show version information'
complete -c ftar -l help -d 'Show help message'
