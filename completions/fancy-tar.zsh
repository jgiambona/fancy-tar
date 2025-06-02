#compdef fancy-tar fancytar ftar

_arguments -s \
  '-o[Specify output file name (for split archives, a .parts.txt file will also be created)]:output file:_files' \
  '-n[Create uncompressed tar archive]' \
  '-s[Use slower but better compression]' \
  '-x[Open the output folder when done (macOS/Linux)]' \
  '--open-after[Open the output folder when done (macOS/Linux)]' \
  '-t[Show hierarchical file structure before archiving]' \
  '--tree[Show hierarchical file structure before archiving]' \
  '--no-recursion[Do not include directory contents]' \
  '--hash[Output SHA256 hash file alongside the archive]' \
  '--encrypt=[Encrypt archive with gpg or openssl]:method:(gpg openssl)' \
  '--recipient=[Recipient ID for GPG public key encryption]:recipient:' \
  '--password=[Password to use for encryption]:password:' \
  '--zip[Create a .zip archive]' \
  '--print-filename[Output only the final archive filename]' \
  '--version[Show version information]' \
  '--help[Show help message]' \
  '--use=[Force specific compression tool]:tool:(gzip pigz bzip2 pbzip2 lbzip2 xz pxz)' \
  '-f[Automatically overwrite any existing output file or split parts without prompting]' \
  '--force[Automatically overwrite any existing output file or split parts without prompting]' \
  '--manifest=[Generate a manifest file listing the contents of the archive]:format:(tree text csv csvhash)' \
  '*:files:_files'
