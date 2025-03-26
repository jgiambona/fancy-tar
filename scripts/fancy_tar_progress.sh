#!/bin/bash

show_help() {
  echo "Usage: fancy-tar [options] <files...>"
  echo ""
  echo "Options:"
  echo "  -o <file>            Set output archive name (default: archive.tar.gz)"
  echo "  -n                   No gzip compression (create .tar instead of .tar.gz)"
  echo "  -s                   Enable slow mode (simulate slower compression)"
  echo "  -x                   Open the output folder when done"
  echo "  -t, --tree           Show hierarchical file structure before archiving"
  echo "  --no-recursion       Do not include directory contents (shallow archive)"
  echo "  --hash               Output SHA256 hash file alongside the archive"
  echo "  --encrypt[=method]   Encrypt archive with gpg (default) or openssl"
  echo "  --recipient <id>     Recipient ID for GPG public key encryption"
  echo "  --password <pass>    Password to use for symmetric encryption"
  echo "  -h, --help           Show this help message"
  exit 0
}

# Defaults
output="archive.tar.gz"
gzip=true
slow=false
open_after=false
no_recurse=false
show_tree=false
hash_output=false
encrypt_method=""
recipient=""
password=""
input_files=()

# Custom arg parsing loop
while [[ $# -gt 0 ]]; do
  case "$1" in
    -o) output="$2"; shift 2 ;;
    -n) gzip=false; shift ;;
    -s) slow=true; shift ;;
    -x) open_after=true; shift ;;
    -t|--tree) show_tree=true; shift ;;
    --no-recursion) no_recurse=true; shift ;;
    --hash) hash_output=true; shift ;;
    --encrypt=*) encrypt_method="${1#*=}"; shift ;;
    --encrypt) encrypt_method="gpg"; shift ;;
    --recipient=*) recipient="${1#*=}"; shift ;;
    --recipient) recipient="$2"; shift 2 ;;
    --password=*) password="${1#*=}"; shift ;;
    --password) password="$2"; shift 2 ;;
    -h|--help) show_help ;;
    -*)
      echo "❌ Unknown option: $1"
      show_help
      ;;
    *) input_files+=("$1"); shift ;;
  esac
done

if [ ${#input_files[@]} -eq 0 ]; then
  echo "No input files specified."
  show_help
fi

# Validate recipient
if [[ -n "$encrypt_method" && "$encrypt_method" == "gpg" && -z "$password" && -z "$recipient" ]]; then
  echo "❌ --recipient requires a value (email, fingerprint, or key ID) for public key encryption"
  echo "🔑 Available recipients:"
  gpg --list-keys --with-colons | grep '^uid' | cut -d: -f10
  exit 1
fi

extension=".tar.gz"
[ "$gzip" = false ] && extension=".tar"
[[ "$output" != *"$extension" ]] && output="${output}${extension}"

echo "📦 Calculating total size..."
total_files=$(find "${input_files[@]}" -type f | wc -l | tr -d ' ')
total_size=$(du -ch "${input_files[@]}" 2>/dev/null | grep total | awk '{print $1}')
[ -z "$total_size" ] && total_size="?"

echo "📁 Total files: $total_files"
echo "📦 Total size: $total_size"
echo "🗃  Output file: $output"
echo "🔧 Compression: $([ "$gzip" = true ] && echo "gzip (.tar.gz)" || echo "none (.tar)")"
echo "🔐 Encryption: $([ -n "$encrypt_method" ] && echo "$encrypt_method" || echo "none")"
echo "📂 Recursion: $([ "$no_recurse" = true ] && echo "disabled" || echo "enabled")"
echo ""

if [ "$show_tree" = true ]; then
  echo "📂 File hierarchy:"
  for file in "${input_files[@]}"; do
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

tmpfile="fancy-tar-tmp.tar"
rm -f "$tmpfile"

start_time=$(date +%s)
count=0
tar_opts=""
[ "$no_recurse" = true ] && tar_opts="--no-recursion"

file_list=$(find "${input_files[@]}" -type f)
echo "$file_list" > filelist.txt

echo "📦 Archiving files..."
while IFS= read -r file; do
  count=$((count + 1))
  echo "[$count/$total_files] Adding: $file"
  [ "$slow" = true ] && sleep 0.25
done < filelist.txt

tar -cf "$tmpfile" $tar_opts --files-from=filelist.txt 2>&1 | tee /dev/stderr || { echo "❌ Tar failed. Cleaning up."; rm -f "$tmpfile"; exit 1; }
rm -f filelist.txt

if [ "$gzip" = true ]; then
  echo "🗜 Compressing archive..."
  pv "$tmpfile" | gzip > "$output" || { echo "❌ Compression failed. Cleaning up."; rm -f "$output" "$tmpfile"; exit 1; }
  rm -f "$tmpfile"
else
  mv "$tmpfile" "$output"
fi

# Encryption (output saved separately)
if [ -n "$encrypt_method" ]; then
  case "$encrypt_method" in
    gpg)
      encrypted="${output}.gpg"
      if [ -n "$recipient" ]; then
        if ! gpg --list-keys "$recipient" >/dev/null 2>&1; then
          echo "❌ No public key found for recipient: $recipient"
          echo "🔑 Available recipients:"
          gpg --list-keys --with-colons | grep '^uid' | cut -d: -f10
          echo "💡 Import with: gpg --import public.asc"
          rm -f "$output"
          exit 1
        fi
        gpg --output "$encrypted" --encrypt --recipient "$recipient" "$output" || { echo "❌ GPG encryption failed"; rm -f "$encrypted"; exit 1; }
      else
        if [ -z "$password" ]; then
          read -s -p "Enter password: " password
          echo
        fi
        echo "$password" | gpg --batch --yes --passphrase-fd 0 --symmetric --cipher-algo AES256 --output "$encrypted" "$output" || { echo "❌ GPG symmetric encryption failed"; rm -f "$encrypted"; exit 1; }
      fi
      rm -f "$output"
      output="$encrypted"
      ;;
    openssl)
      encrypted="${output}.enc"
      if [ -z "$password" ]; then
        read -s -p "Enter password: " password
        echo
      fi
      openssl enc -aes-256-cbc -salt -in "$output" -out "$encrypted" -pass pass:"$password" || { echo "❌ OpenSSL encryption failed"; rm -f "$encrypted"; exit 1; }
      rm -f "$output"
      output="$encrypted"
      ;;
    *)
      echo "❌ Unsupported encryption method: $encrypt_method"
      rm -f "$output"
      exit 1
      ;;
  esac
  echo "🔐 Encrypted archive saved: $output"
fi

# Hash
if [ "$hash_output" = true ]; then
  shasum -a 256 "$output" > "$output.sha256"
  echo "🔐 SHA256 hash saved to: $output.sha256"
fi

end_time=$(date +%s)
elapsed=$((end_time - start_time))
archive_size=$(du -h "$output" | cut -f1)

echo ""
echo "✅ Done! Archive created: $output"
echo "📏 Archive size: $archive_size"
echo "🕒 Total time elapsed: $((elapsed / 60))m $((elapsed % 60))s"

if command -v notify-send >/dev/null 2>&1; then
  notify-send "fancy-tar" "Archive created: $output"
elif command -v osascript >/dev/null 2>&1; then
  osascript -e "display notification \"Archive created: $output\" with title \"fancy-tar\""
fi

if [ "$open_after" = true ]; then
  folder=$(dirname "$output")
  if command -v open >/dev/null; then open "$folder"
  elif command -v xdg-open >/dev/null; then xdg-open "$folder"
  fi
fi
