#compdef fancy-tar
_arguments -s \
  '-o[Set output filename]:output file:_files' \
  '-n[No gzip]' \
  '-s[Slow mode]' \
  '-x[Open folder after]' \
  '-h[Show help]' \
  '*:files:_files'