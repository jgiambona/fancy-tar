#!/bin/bash
VERSION="1.6.0"

# Version flag (exit early)
if [[ "$1" == "--version" || "$1" == "-v" ]]; then
  echo "fancy-tar $VERSION"
  exit 0
fi

# Self-test flag (exit early)
if [[ "$1" == "--self-test" && -z "$FANCY_TAR_SELFTEST" ]]; then
  export FANCY_TAR_SELFTEST=1
  echo "🧪 Running comprehensive self-test..."
  
  # Get absolute path to this script
  SCRIPT_PATH="$(realpath "$0")"
  
  # Create temporary test directory
  tmpdir=$(mktemp -d)
  
  # Ensure cleanup on script exit (including errors)
  cleanup() {
    rm -rf "$tmpdir"
  }
  trap cleanup EXIT
  
  cd "$tmpdir"
  
  # Create test files
  echo "Test content 1" > file1.txt
  echo "Test content 2" > file2.txt
  echo "Test content 3" > file3.txt
  
  # Store full paths
  TMPFILE1="$tmpdir/file1.txt"
  TMPFILE2="$tmpdir/file2.txt"
  TMPFILE3="$tmpdir/file3.txt"
  
  TESTS=0
  FAILS=0

  run_test() {
    desc="$1"
    shift
    out="$tmpdir/out$TESTS"
    echo "[Test $((++TESTS))] $desc"
    
    # Run the test with interactive password prompts
    if [[ "$desc" == *"password"* || "$desc" == *"encryption"* ]]; then
      echo "🔑 This test requires password input. Press Enter to continue..."
      read
      "$SCRIPT_PATH" "$@" -o "$out"
    else
      "$SCRIPT_PATH" "$@" -o "$out"
    fi
    
    # Check for output file with various possible extensions
    if ls "$out"* 1> /dev/null 2>&1; then
      echo "   ✅ Passed"
    else
      echo "   ❌ Failed"
      FAILS=$((FAILS+1))
    fi
  }

  # Run tests
  run_test "Basic tar.gz" "$TMPFILE1"
  run_test "No compression tar" -n "$TMPFILE2"
  run_test "ZIP archive" --zip "$TMPFILE3"
  run_test "ZIP with password" --zip --encrypt "$TMPFILE3"
  run_test "Hash generation" --hash "$TMPFILE2"
  run_test "OpenSSL encryption" --encrypt=openssl "$TMPFILE1"
  run_test "GPG symmetric encryption" --encrypt=gpg "$TMPFILE1"
  run_test "Tree view + no-recursion" --tree --no-recursion "$TMPFILE1" "$TMPFILE2"

  echo ""
  echo "🧪 Self-test summary: $((TESTS - FAILS)) passed, $FAILS failed"
  exit $FAILS
fi

# Defaults
output=""
gzip=true
slow=false
open_after=false
no_recurse=false
show_tree=false
hash_output=false
encrypt_method=""
recipient=""
password=""
use_zip=false
input_files=()

# Argument parser
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
    --zip) use_zip=true; shift ;;
    -h|--help)
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
      echo "  --password <pass>    Password to use for encryption (if supported)"
      echo "  --zip                Create a .zip archive (with optional password)"
      echo "  -h, --help           Show this help message"
      exit 0 ;;
    -*)
      echo "❌ Unknown option: $1"
      exit 1 ;;
    *) input_files+=("$1"); shift ;;
  esac
done

if [ ${#input_files[@]} -eq 0 ]; then
  echo "❌ No input files specified."
  exit 1
fi

confirm_password() {
  # If password is already set, use it
  if [[ -n "$password" ]]; then
    return 0
  fi
  
  local p1 p2
  read -s -p "Enter password: " p1; echo
  read -s -p "Confirm password: " p2; echo
  if [[ "$p1" != "$p2" ]]; then
    echo "❌ Passwords do not match. Please try again."
    confirm_password
  else
    password="$p1"
  fi
}

# Handle ZIP password interaction
if [[ "$use_zip" == true && "$encrypt_method" == "zip" && -z "$password" ]]; then
  confirm_password
fi

# Handle encryption password interaction
if [[ -n "$encrypt_method" && "$encrypt_method" != "zip" && -z "$password" ]]; then
  confirm_password
fi

# Determine archive name
if [ -z "$output" ]; then
  if [ "$use_zip" = true ]; then
    output="archive.zip"
  else
    output="archive.tar.gz"
  fi
fi

# Determine zip encryption warning
if [[ "$use_zip" = true && -n "$password" ]]; then
  echo ""
  echo "🔐 Warning: Classic ZIP encryption is insecure."
  echo "   • Easily broken with modern tools"
  echo "   • No integrity or authenticity protection"
  echo "   • Not suitable for confidential data"
  echo ""
  echo "💡 Use --encrypt=gpg or --encrypt=openssl for stronger encryption."
  echo ""
fi

# Create archive
start_time=$(date +%s)

if [ "$use_zip" = true ]; then
  zip_cmd="zip -r"
  [ "$no_recurse" = true ] && zip_cmd="zip"
  if [ -n "$password" ]; then
    zip_cmd="$zip_cmd -P $password"
  fi
  echo "📦 Creating ZIP archive..."
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
  $zip_cmd "$output" "${input_files[@]}"
  # Wait for zip to finish and ensure file exists before getting size
  sleep 1
  # Get ZIP file size using stat command
  if command -v stat >/dev/null 2>&1; then
    archive_size=$(stat -f %z "$output" 2>/dev/null | awk '{printf "%.1fK", $1/1024}')
  else
    archive_size=$(ls -l "$output" 2>/dev/null | awk '{printf "%.1fK", $5/1024}')
  fi
  [ -z "$archive_size" ] && archive_size="?"
else
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

  tmpfile="fancy-tar-tmp.tar"
  rm -f "$tmpfile"
  tar_opts=""
  [ "$no_recurse" = true ] && tar_opts="--no-recursion"
  file_list=$(find "${input_files[@]}" -type f)
  echo "$file_list" > filelist.txt

  echo "📦 Archiving files..."
  count=0
  while IFS= read -r file; do
    count=$((count + 1))
    echo "[$count/$total_files] Adding: $file"
    [ "$slow" = true ] && sleep 0.25
  done < filelist.txt

  # Use -P to handle absolute paths properly
  tar -P -cf "$tmpfile" $tar_opts --files-from=filelist.txt 2>/dev/null || { echo "❌ Tar failed. Cleaning up."; rm -f "$tmpfile"; exit 1; }
  rm -f filelist.txt

  if [ "$gzip" = true ]; then
    echo "🗜 Compressing archive..."
    pv "$tmpfile" | gzip > "$output" || { echo "❌ Compression failed. Cleaning up."; rm -f "$output" "$tmpfile"; exit 1; }
    rm -f "$tmpfile"
  else
    mv "$tmpfile" "$output"
  fi

  # Get archive size for tar archives
  archive_size=$(du -h "$output" 2>/dev/null | cut -f1 || echo "?")

  # Encryption (tar path)
  if [ -n "$encrypt_method" ]; then
    case "$encrypt_method" in
      gpg)
        encrypted="${output}.gpg"
        if [ -n "$recipient" ]; then
          gpg --output "$encrypted" --encrypt --recipient "$recipient" "$output" || { echo "❌ GPG encryption failed"; rm -f "$encrypted"; exit 1; }
        else
          if [ -z "$password" ]; then
            confirm_password
          fi
          echo "$password" | gpg --batch --yes --passphrase-fd 0 --symmetric --cipher-algo AES256 --output "$encrypted" "$output" || { echo "❌ GPG symmetric encryption failed"; rm -f "$encrypted"; exit 1; }
        fi
        rm -f "$output"
        output="$encrypted"
        ;;
      openssl)
        encrypted="${output}.enc"
        if [ -z "$password" ]; then
          confirm_password
        fi
        # Use pbkdf2 to avoid the deprecation warning
        openssl enc -aes-256-cbc -pbkdf2 -salt -in "$output" -out "$encrypted" -pass pass:"$password" || { echo "❌ OpenSSL encryption failed"; rm -f "$encrypted"; exit 1; }
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
fi

# Hash output
if [ "$hash_output" = true ]; then
  shasum -a 256 "$output" > "$output.sha256"
  echo "🔐 SHA256 hash saved to: $output.sha256"
fi

end_time=$(date +%s)
elapsed=$((end_time - start_time))

# Get final archive size if not already set
if [ -z "$archive_size" ]; then
  archive_size=$(du -h "$output" 2>/dev/null | cut -f1 || echo "?")
fi

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