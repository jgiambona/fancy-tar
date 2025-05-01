#compdef fancy-tar fancytar ftar

_arguments -s \
  '-o[Specify output file name]:output file:_files' \
  '-n[Create uncompressed tar archive]' \
  '-s[Use slower but better compression]' \
  '-x[Open the output folder when done]' \
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
  '*:files:_files'
