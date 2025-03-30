#compdef fancy-tar

_arguments \
  '-o+[Output filename]:file:_files' \
  '-n[No compression]' \
  '-s[Slow mode]' \
  '-x[Open output folder]' \
  '-t[Tree preview]' \
  '--tree[Tree preview]' \
  '--no-recursion[Do not include subfolders]' \
  '--hash[Generate SHA256 checksum]' \
  '--encrypt=[Encryption method]:method:(gpg openssl 7z)' \
  '--recipient[Recipient GPG key]' \
  '--password[Password for encryption]' \
  '--zip[Create ZIP archive]' \
  '--version[Show version]' \
  '-h[Show help]' \
  '--help[Show help]'
