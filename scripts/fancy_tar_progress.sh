#!/bin/bash
VERSION="1.6.4"

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
  run_test "7z archive" --7z "$TMPFILE1"
  run_test "7z with password" --7z --password "$TMPFILE2"
  run_test "Hash generation" --hash "$TMPFILE2"
  run_test "OpenSSL encryption" --encrypt=openssl "$TMPFILE1"
  run_test "GPG symmetric encryption" --encrypt=gpg "$TMPFILE1"
  run_test "Tree view + no-recursion" --tree --no-recursion "$TMPFILE1" "$TMPFILE2"

  echo ""
  echo "🧪 Self-test summary: $((TESTS - FAILS)) passed, $FAILS failed"
  exit $FAILS
fi

# Default values
output=""
input_files=()
use_zip=false
use_7z=false
no_recurse=false
show_tree=false
password=""
verify=false
split_size=""
compression_level="5"  # Default 7z compression level (0-9)

# Store terminal settings for password prompts
stty_settings=""

# Cleanup function
cleanup() {
  # Restore terminal settings if they were changed
  if [[ -n "$stty_settings" ]]; then
    stty "$stty_settings" 2>/dev/null
  fi
}

# Set up cleanup trap
trap cleanup EXIT INT TERM

# Parse arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    -o|--output) output="$2"; shift 2 ;;
    -n) gzip=false; shift ;;
    -s) slow=true; shift ;;
    -x) open_after=true; shift ;;
    -t|--tree) show_tree=true; shift ;;
    --no-recurse) no_recurse=true; shift ;;
    --hash) hash_output=true; shift ;;
    --encrypt=*) encrypt_method="${1#*=}"; shift ;;
    --encrypt) encrypt_method="gpg"; shift ;;
    --recipient=*) recipient="${1#*=}"; shift ;;
    --recipient) recipient="$2"; shift 2 ;;
    --password) password="$2"; shift 2 ;;
    --verify) verify=true; shift ;;
    --split-size=*) split_size="${1#*=}"; shift ;;
    --zip) use_zip=true; shift ;;
    --7z) use_7z=true; shift ;;
    --compression=*) compression_level="${1#*=}"; shift ;;
    -h|--help) show_help ;;
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

# Validate compression level
if [[ "$compression_level" != [0-9] ]]; then
  echo "❌ Invalid compression level: $compression_level"
  echo "   Please use a number between 0 and 9"
  exit 1
fi

# Warn about high compression levels
if [[ "$use_7z" = true && "$compression_level" -gt 7 ]]; then
  echo ""
  echo "⚠️ Warning: Using high compression level ($compression_level) with 7z."
  echo "   • This will be very slow"
  echo "   • Consider using a lower level (5-7) for better speed"
  echo ""
fi

confirm_password() {
  # If password is already set, use it
  if [[ -n "$password" ]]; then
    return 0
  fi
  
  local p1 p2
  # Save current terminal settings
  stty_settings=$(stty -g)
  # Disable echo
  stty -echo
  
  while true; do
    # Read passwords with error handling
    if ! read -p "Enter password: " p1; then
      stty "$stty_settings"
      echo "❌ Error reading password"
      return 1
    fi
    echo
    
    if ! read -p "Confirm password: " p2; then
      stty "$stty_settings"
      echo "❌ Error reading password"
      return 1
    fi
    echo
    
    # Restore terminal settings
    stty "$stty_settings"
    
    # Only validate password strength in interactive mode
    if [[ -z "$password" ]]; then
      # Validate password length
      if [[ ${#p1} -lt 8 ]]; then
        echo "❌ Password must be at least 8 characters long"
        continue
      fi
      
      # Basic password strength check
      if [[ ! "$p1" =~ [A-Z] || ! "$p1" =~ [a-z] || ! "$p1" =~ [0-9] ]]; then
        echo "❌ Password should contain at least one uppercase letter, one lowercase letter, and one number"
        continue
      fi
    fi
    
    if [[ "$p1" != "$p2" ]]; then
      echo "❌ Passwords do not match. Please try again."
      continue
    fi
    
    password="$p1"
    break
  done
}

# Handle ZIP password interaction
if [[ "$use_zip" == true && "$encrypt_method" == "zip" && -z "$password" ]]; then
  confirm_password
fi

# Handle encryption password interaction
if [[ -n "$encrypt_method" && "$encrypt_method" != "zip" && -z "$password" ]]; then
  confirm_password
fi

# Function to handle file name conflicts
handle_file_conflict() {
  local original_file="$1"
  local base_name="${original_file%.*}"
  local extension="${original_file##*.}"
  local counter=1
  local new_file
  
  while true; do
    new_file="${base_name}_${counter}.${extension}"
    if [[ ! -e "$new_file" ]]; then
      break
    fi
    counter=$((counter + 1))
  done
  
  while true; do
    echo ""
    echo "⚠️ Warning: File '$original_file' already exists."
    echo "   • Press Enter to use suggested name: $new_file"
    echo "   • Or type a new name and press Enter"
    echo "   • Press Ctrl+C to cancel"
    echo ""
    read -p "New file name [$new_file]: " user_input
    
    if [[ -z "$user_input" ]]; then
      echo "$new_file"
      break
    elif [[ -e "$user_input" ]]; then
      echo "⚠️ Warning: File '$user_input' already exists."
      echo "   • Please choose a different name"
      continue
    else
      echo "$user_input"
      break
    fi
  done
}

# Determine archive name
if [ -z "$output" ]; then
  if [ "$use_zip" = true ]; then
    output="archive.zip"
  elif [ "$use_7z" = true ]; then
    output="archive.7z"
  else
    output="archive.tar.gz"
  fi
fi

# Check if output file exists and handle conflict
if [[ -e "$output" ]]; then
  output=$(handle_file_conflict "$output")
  if [[ -z "$output" ]]; then
    echo "❌ Operation cancelled by user"
    exit 1
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

# Determine 7z encryption warning
if [[ "$use_7z" = true && -z "$password" ]]; then
  echo ""
  echo "🔐 Warning: Creating unencrypted 7z archive."
  echo "   • Consider using --password for encryption"
  echo "   • 7z supports strong AES-256 encryption"
  echo ""
fi

# Function to calculate human-readable size
human_readable_size() {
  local size=$1
  local units=("B" "K" "M" "G" "T")
  local unit=0
  while [[ $size -ge 1024 && $unit -lt ${#units[@]} ]]; do
    size=$((size / 1024))
    unit=$((unit + 1))
  done
  echo "${size}${units[$unit]}"
}

# Function to verify archive
verify_archive() {
  local archive="$1"
  echo "🔍 Verifying archive..."
  
  if [[ "$archive" == *.zip ]]; then
    if ! unzip -t "$archive" >/dev/null 2>&1; then
      echo "❌ Archive verification failed"
      return 1
    fi
  elif [[ "$archive" == *.7z ]]; then
    if ! 7z t "$archive" >/dev/null 2>&1; then
      echo "❌ Archive verification failed"
      return 1
    fi
  else
    if ! gzip -t "$archive" >/dev/null 2>&1; then
      echo "❌ Archive verification failed"
      return 1
    fi
  fi
  
  echo "✅ Archive verified successfully"
  return 0
}

# Function to create split archive
create_split_archive() {
  local input="$1"
  local output="$2"
  local split_size="$3"
  
  echo "📦 Creating split archive..."
  echo "   • Split size: $split_size"
  
  if [[ "$output" == *.zip ]]; then
    zip -s "$split_size" "$output" "${input_files[@]}"
  elif [[ "$output" == *.7z ]]; then
    7z a -v"$split_size" "$output" "${input_files[@]}"
  else
    tar -czf - "${input_files[@]}" | split -b "$split_size" - "$output."
  fi
}

# Function to show enhanced progress
show_enhanced_progress() {
  local total_size=$1
  local current_size=0
  local start_time=$(date +%s)
  local last_update=0
  local file_count=0
  
  # Count total files
  for file in "${input_files[@]}"; do
    if [[ -d "$file" ]]; then
      file_count=$((file_count + $(find "$file" -type f | wc -l)))
    else
      file_count=$((file_count + 1))
    fi
  done
  
  echo "📊 Progress Information:"
  echo "   • Total files: $file_count"
  echo "   • Total size: $(human_readable_size $total_size)"
  
  while read -r line; do
    current_size=$(du -sb "${input_files[@]}" 2>/dev/null | awk '{sum += $1} END {print sum}')
    [ -z "$current_size" ] && current_size=0
    
    local elapsed=$(( $(date +%s) - start_time ))
    local speed=$(( current_size / elapsed ))
    local remaining=$(( (total_size - current_size) / speed ))
    
    if [[ $elapsed -gt $last_update ]]; then
      echo -ne "\r   • Progress: $(human_readable_size $current_size)/$(human_readable_size $total_size)"
      echo -ne " ($((current_size * 100 / total_size))%)"
      echo -ne " | Speed: $(human_readable_size $speed)/s"
      echo -ne " | ETA: $((remaining / 60))m$((remaining % 60))s"
      last_update=$elapsed
    fi
  done
}

# Create archive
start_time=$(date +%s)

if [ "$use_7z" = true ]; then
  echo "📦 Creating 7z archive..."
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
  
  # Calculate total size for progress bar
  total_size=$(du -sb "${input_files[@]}" 2>/dev/null | awk '{sum += $1} END {print sum}')
  [ -z "$total_size" ] && total_size=0
  
  # Build 7z command with compression level and progress
  if [ -n "$password" ]; then
    if command -v pv >/dev/null 2>&1; then
      # Use pv for progress if available
      tar -cf - "${input_files[@]}" | pv -s "$total_size" | 7z a -si -p"$password" -mhe=on -mx="$compression_level" "$output"
    else
      # Fallback without progress
      7z a -p"$password" -mhe=on -mx="$compression_level" "$output" "${input_files[@]}"
    fi
  else
    if command -v pv >/dev/null 2>&1; then
      # Use pv for progress if available
      tar -cf - "${input_files[@]}" | pv -s "$total_size" | 7z a -si -mx="$compression_level" "$output"
    else
      # Fallback without progress
      7z a -mx="$compression_level" "$output" "${input_files[@]}"
    fi
  fi
  
  # Wait for 7z to finish and ensure file exists before getting size
  sleep 1
  # Get 7z file size using stat command
  if command -v stat >/dev/null 2>&1; then
    archive_size=$(stat -f %z "$output" 2>/dev/null | awk '{printf "%.1fK", $1/1024}')
  else
    archive_size=$(ls -l "$output" 2>/dev/null | awk '{printf "%.1fK", $5/1024}')
  fi
  [ -z "$archive_size" ] && archive_size="?"
  
  if [ -n "$split_size" ]; then
    create_split_archive "${input_files[@]}" "$output" "$split_size"
  fi
elif [ "$use_zip" = true ]; then
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
  
  # Calculate total size for progress bar
  total_size=$(du -sb "${input_files[@]}" 2>/dev/null | awk '{sum += $1} END {print sum}')
  [ -z "$total_size" ] && total_size=0
  
  # Build zip command with progress if pv is available
  zip_cmd="zip -r"
  [ "$no_recurse" = true ] && zip_cmd="zip"
  if [ -n "$password" ]; then
    zip_cmd="$zip_cmd -P $password"
  fi
  
  if command -v pv >/dev/null 2>&1; then
    # Use pv for progress if available
    tar -cf - "${input_files[@]}" | pv -s "$total_size" | $zip_cmd "$output" -
  else
    # Fallback without progress
    $zip_cmd "$output" "${input_files[@]}"
  fi
  
  # Wait for zip to finish and ensure file exists before getting size
  sleep 1
  # Get ZIP file size using stat command
  if command -v stat >/dev/null 2>&1; then
    archive_size=$(stat -f %z "$output" 2>/dev/null | awk '{printf "%.1fK", $1/1024}')
  else
    archive_size=$(ls -l "$output" 2>/dev/null | awk '{printf "%.1fK", $5/1024}')
  fi
  [ -z "$archive_size" ] && archive_size="?"
  
  if [ -n "$split_size" ]; then
    create_split_archive "${input_files[@]}" "$output" "$split_size"
  fi
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

  if [ -n "$split_size" ]; then
    create_split_archive "${input_files[@]}" "$output" "$split_size"
  fi
fi

# Verify archive if requested
if [ "$verify" = true ]; then
  if [ -n "$split_size" ]; then
    echo "⚠️ Verification not supported for split archives"
  else
    verify_archive "$output" || exit 1
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

show_help() {
  echo "Usage: fancy-tar [options] <files...>"
  echo ""
  echo "Options:"
  echo "  -o, --output <file>    Specify output file name"
  echo "  -n                     Do not use gzip compression"
  echo "  -s                     Use slower but better compression"
  echo "  -x                     Open the output folder when done"
  echo "  -t, --tree            Show hierarchical file structure before archiving"
  echo "  --no-recurse          Do not include directory contents (shallow archive)"
  echo "  --hash                Output SHA256 hash file alongside the archive"
  echo "  --encrypt[=method]    Encrypt archive with gpg (default) or openssl"
  echo "  --recipient <id>      Recipient ID for GPG public key encryption"
  echo "  --password <pass>     Password to use for encryption (if supported)"
  echo "  --verify              Verify the archive after creation"
  echo "  --split-size=<size>   Split the archive into smaller parts (e.g., 100M, 1G)"
  echo "  --zip                 Create a .zip archive (with optional password)"
  echo "  --7z                  Create a .7z archive (with optional password)"
  echo "                       • Uses AES-256 encryption when password is provided"
  echo "                       • Encrypts both file contents and headers"
  echo "                       • Supports solid compression"
  echo "  --compression=<0-9>   Set 7z compression level (0=store, 9=ultra)"
  echo "                       • 0: Store (no compression)"
  echo "                       • 1: Fastest"
  echo "                       • 5: Normal (default)"
  echo "                       • 9: Ultra (very slow)"
  echo "  -h, --help            Show this help message"
  echo "  --version             Show version information"
  echo ""
  echo "Examples:"
  echo "  fancy-tar file1.txt file2.txt -o archive.tar.gz"
  echo "  fancy-tar --zip --password secret -o archive.zip folder/"
  echo "  fancy-tar --7z --compression=9 -o archive.7z large_folder/"
  echo "  fancy-tar --split-size=100M -o archive.tar.gz huge_folder/"
  echo "  fancy-tar --verify -o archive.tar.gz important_files/"
  echo ""
  echo "Note: When using --split-size, the archive will be split into multiple parts"
  echo "      with the specified size. For example, with --split-size=100M, a 500MB"
  echo "      archive would be split into 5 parts of 100MB each."
  exit 0
}