#compdef fancy-tar

_arguments \
  '-o+[Set output archive name]:output:_files' \
  '-n[No gzip compression]' \
  '-s[Enable slow mode]' \
  '-x[Open folder after archiving]' \
  '-t[Show tree view before archiving]' \
  '--tree[Show tree view before archiving]' \
  '--no-recursion[Disable recursive archiving]' \
  '--hash[Output SHA256 hash file]' \
  '--encrypt[Encryption method: gpg or openssl]' \
  '--recipient[Recipient public key for GPG encryption]' \
  '--password[Password for encryption]' \
  '-h[Show help]' \
  '--help[Show help]'
