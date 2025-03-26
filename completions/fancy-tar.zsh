#compdef fancy-tar

_arguments \
  '-o+[Output archive name]:output:_files' \
  '-n[No gzip compression]' \
  '-s[Simulate slow mode]' \
  '-x[Open output folder]' \
  '-t[Tree view]' \
  '--tree[Tree view]' \
  '--no-recursion[Shallow archive only]' \
  '--hash[Generate SHA256 file]' \
  '--encrypt=[Encryption method]:method:(gpg openssl)' \
  '--recipient[Public key ID/email]' \
  '--password[Password for encryption]' \
  '-h[Show help]' \
  '--help[Show help]'
