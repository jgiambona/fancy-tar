#!/bin/bash

show_help() {
  echo "Usage: fancy-tar [options] <files...>"
  echo ""
  echo "Options:"
  echo "  -o <file>    Set output archive name (default: archive.tar.gz)"
  echo "  -n           No gzip compression (create .tar instead of .tar.gz)"
  echo "  -s           Enable slow mode (simulate slower compression)"
  echo "  -x           Open the output folder after archiving"
  echo "  -h           Show this help message"
  exit 0
}

# Default values
output="archive.tar.gz"
gzip=true
slow=false
open_after=false

# Parse options
while getopts ":o:nsxh" opt; do
  case ${opt} in
    o ) output=$OPTARG ;;
    n ) gzip=false ;;
    s ) slow=true ;;
    x ) open_after=true ;;
    h ) show_help ;;
    \? ) echo "Invalid option: -$OPTARG" >&2; show_help ;;
    : ) echo "Option -$OPTARG requires an argument." >&2; show_help ;;
  esac
done
shift $((OPTIND -1))

# Input check
if [ $# -eq 0 ]; then
  echo "No input files specified."
  show_help
fi

# Determine tar extension
extension=".tar.gz"
if [ "$gzip" = false ]; then
  extension=".tar"
fi

# Sanitize output name
[[ $output != *"$extension" ]] && output="${output}${extension}"

# Count and size
echo "📦 Calculating total size..."
total_files=$#
total_size=$(du -ch "$@" 2>/dev/null | grep total | awk '{print $1}')
[ -z "$total_size" ] && total_size="?"

echo "📁 Total files: $total_files"
echo "📦 Total size: $total_size"
echo "🗃  Output file: $output"
echo "🔧 Compression: $([ "$gzip" = true ] && echo "gzip (.tar.gz)" || echo "none (.tar)")"
echo ""

# Archive with progress
tmpfile="fancy-tar-tmp.tar"
rm -f "$tmpfile"

start_time=$(date +%s)
count=0

(
  for file in "$@"; do
    count=$((count + 1))
    echo "[$count/$total_files] $file"
    [ "$slow" = true ] && sleep 0.25
  done
) | tar -cvf "$tmpfile" --files-from=<(for f in "$@"; do echo "$f"; done) --no-recursion >/dev/null

# Compress if needed
if [ "$gzip" = true ]; then
  echo "🗜 Compressing archive..."
  pv "$tmpfile" | gzip > "$output"
  rm -f "$tmpfile"
else
  mv "$tmpfile" "$output"
fi

end_time=$(date +%s)
elapsed=$((end_time - start_time))

echo ""
echo "✅ Done! Archive created: $output"
echo "🕒 Total time elapsed: $((elapsed / 60))m $((elapsed % 60))s"

# Notifications
if command -v notify-send >/dev/null 2>&1; then
  notify-send "fancy-tar" "Archive created: $output"
elif command -v osascript >/dev/null 2>&1; then
  osascript -e "display notification \"Archive created: $output\" with title \"fancy-tar\""
fi

# Open folder if requested
if [ "$open_after" = true ]; then
  folder=$(dirname "$output")
  if command -v open >/dev/null; then open "$folder"
  elif command -v xdg-open >/dev/null; then xdg-open "$folder"
  fi
fi

