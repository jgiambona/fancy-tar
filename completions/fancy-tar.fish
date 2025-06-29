complete -c fancy-tar -s o -l output -d 'Specify output file name (for split archives, a .parts.txt file will also be created)' -r
complete -c fancy-tar -s n -d 'Create uncompressed tar archive'
complete -c fancy-tar -s s -d 'Use slower but better compression'
complete -c fancy-tar -s x -l open-after -d 'Open the output folder when done (macOS/Linux)'
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
complete -c fancy-tar -l use -d 'Force specific compression tool' -r -a "gzip pigz bzip2 pbzip2 lbzip2 xz pxz"
complete -c fancy-tar -s f -l force -d 'Automatically overwrite any existing output file or split parts without prompting'
complete -c fancy-tar -l manifest -d 'Generate a manifest file listing the contents of the archive' -r -a "tree text csv csvhash"
complete -c fancy-tar -l exclude -d 'Exclude files matching pattern' -r
complete -c fancy-tar -l include -d 'Include only files matching pattern' -r
complete -c fancy-tar -l files-from -d 'Read list of files to include from file' -r -a "(ls)"
complete -c fancy-tar -l verbose -d 'Show each file being processed with file count display'

# Add completions for aliases
complete -c fancytar -s o -l output -d 'Specify output file name (for split archives, a .parts.txt file will also be created)' -r
complete -c fancytar -s n -d 'Create uncompressed tar archive'
complete -c fancytar -s s -d 'Use slower but better compression'
complete -c fancytar -s x -l open-after -d 'Open the output folder when done (macOS/Linux)'
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
complete -c fancytar -s f -l force -d 'Automatically overwrite any existing output file or split parts without prompting'
complete -c fancytar -l manifest -d 'Generate a manifest file listing the contents of the archive' -r -a "tree text csv csvhash"
complete -c fancytar -l exclude -d 'Exclude files matching pattern' -r
complete -c fancytar -l include -d 'Include only files matching pattern' -r
complete -c fancytar -l files-from -d 'Read list of files to include from file' -r -a "(ls)"
complete -c fancytar -l verbose -d 'Show each file being processed with file count display'

complete -c ftar -s o -l output -d 'Specify output file name (for split archives, a .parts.txt file will also be created)' -r
complete -c ftar -s n -d 'Create uncompressed tar archive'
complete -c ftar -s s -d 'Use slower but better compression'
complete -c ftar -s x -l open-after -d 'Open the output folder when done (macOS/Linux)'
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
complete -c ftar -s f -l force -d 'Automatically overwrite any existing output file or split parts without prompting'
complete -c ftar -l manifest -d 'Generate a manifest file listing the contents of the archive' -r -a "tree text csv csvhash"
complete -c ftar -l exclude -d 'Exclude files matching pattern' -r
complete -c ftar -l include -d 'Include only files matching pattern' -r
complete -c ftar -l files-from -d 'Read list of files to include from file' -r -a "(ls)"
complete -c ftar -l verbose -d 'Show each file being processed with file count display'
