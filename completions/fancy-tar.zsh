#compdef fancy-tar

_arguments \
  '-o+[Set output archive name]:output:_files' \
  '-n[No gzip compression]' \
  '-s[Enable slow mode]' \
  '-x[Open folder after archiving]' \
  '-t[Tree view]' \
  '--tree[Tree view]' \
  '--no-recursion[Disable recursive archiving]' \
  '--hash[Output SHA256 hash file]' \
  '--encrypt=[Method]:method:(gpg openssl)' \
  '--recipient[Recipient GPG key]' \
  '--password[Encryption password]' \
  '--zip[Create ZIP archive]' \
  '--version[Show version]' \
  '-h[Show help]' \
  '--help[Show help]'
