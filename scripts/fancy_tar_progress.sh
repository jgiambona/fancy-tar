#!/bin/bash

show_help() {
  echo "Usage: fancy-tar [options] <files...>"
  echo ""
  echo "Options:"
  echo "  -o <file>         Set output archive name (default: archive.tar.gz)"
  echo "  -n                No gzip compression (create .tar instead of .tar.gz)"
  echo "  -s                Enable slow mode (simulate slower compression)"
  echo "  -x                Open the output folder when done"
  echo "  -h, --help        Show this help message"
  echo "  -t, --tree        Show hierarchical file structure before archiving"
  echo "  --no-recursion    Do not include directory contents (shallow archive)"
  exit 0
}

# Default values
output="archive.tar.gz"
gzip=true
slow=false
open_after=false
no_recurse=false
show_tree=false

# First parse long options
for arg in "$@"; do
  shift
  case "$arg" in
    --no-recursion) set -- "$@" "-R" ;;
    --tree) set -- "$@" "-T" ;;
    --help) show_help ;;
    *) set -- "$@" "$arg" ;;
  esac
done

# Parse short options
while getopts ":o:nsxhRTt" opt; do
  case ${opt} in
    o ) output=$OPTARG ;;
    n ) gzip=false ;;
    s ) slow=true ;;
    x ) open_after=true ;;
    R ) no_recurse=true ;;
    T | t ) show_tree=true ;;
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
total_files=$(find "$@" | wc -l | tr -d ' ')
total_size=$(du -ch "$@" 2>/dev/null | grep total | awk '{print $1}')
[ -z "$total_size" ] && total_size="?"

echo "📁 Total files: $total_files"
echo "📦 Total size: $total_size"
echo "🗃  Output file: $output"
echo "🔧 Compression: $([ "$gzip" = true ] && echo "gzip (.tar.gz)" || echo "none (.tar)")"
echo "📂 Recursion: $([ "$no_recurse" = true ] && echo "disabled" || echo "enabled")"
echo ""

# Show tree structure
if [ "$show_tree" = true ]; then
  echo "📂 File hierarchy:"
  for file in "$@"; do
    find "$file" | awk -v base="$file" '
    {
      rel=substr($0, length(base)+2);
      depth=gsub("/", "/");
      indent=""; for(i=1;i<depth;i++) indent=indent "│   ";
      if (rel != "") print indent "├── " rel;
    }'
  done
  echo ""
fi

# Archive with progress
tmpfile="fancy-tar-tmp.tar"
rm -f "$tmpfile"

start_time=$(date +%s)
count=0
tar_opts=""
[ "$no_recurse" = true ] && tar_opts="--no-recursion"

# Generate full list of files
file_list=$(find "$@" -type f)

# Archive using numbered progress
echo "📦 Archiving files..."
echo "$file_list" > filelist.txt
count=0
while IFS= read -r file; do
  count=$((count + 1))
  echo "[$count/$total_files] Adding: $file"
  [ "$slow" = true ] && sleep 0.25
done < filelist.txt
tar -cvf "$tmpfile" $tar_opts --files-from=filelist.txt >/dev/null
rm -f filelist.txt

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
archive_size=$(du -h "$output" | cut -f1)

echo ""
echo "✅ Done! Archive created: $output"
echo "📏 Archive size: $archive_size"
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
