#!/bin/bash
VERSION="1.7.2"

# Function to get next available filename
get_next_filename() {
    local base="$1"
    local ext="${base##*.}"
    local name="${base%.*}"
    local counter=1
    local new_name="$base"
    
    while [ -e "$new_name" ]; do
        new_name="${name}_${counter}.${ext}"
        counter=$((counter + 1))
    done
    
    echo "$new_name"
}

# Function to convert bytes to human readable format
human_readable_size() {
    local bytes=$1
    local units=("B" "KB" "MB" "GB" "TB" "PB")
    local unit=0
    local size=$bytes
    
    while (( ${size%.*} > 1024 )) && ((unit < ${#units[@]} - 1)); do
        size=$(echo "scale=1; $size / 1024" | bc)
        unit=$((unit + 1))
    done
    
    # Round to one decimal place
    size=$(printf "%.1f" $size)
    echo "${size}${units[$unit]}"
}

# Function to calculate total size
calculate_total_size() {
    local total=0
    for file in "${input_files[@]}"; do
        if [ -d "$file" ]; then
            if [ "$no_recurse" = true ]; then
                # Only count files in current directory
                while IFS= read -r -d '' f; do
                    size=$(stat -f %z "$f" 2>/dev/null || stat --format=%s "$f" 2>/dev/null || echo 0)
                    if [ -n "$size" ] && [ "$size" -gt 0 ]; then
                        total=$((total + size))
                    fi
                done < <(find "$file" -maxdepth 1 -type f -print0)
            else
                # Count all files recursively
                while IFS= read -r -d '' f; do
                    size=$(stat -f %z "$f" 2>/dev/null || stat --format=%s "$f" 2>/dev/null || echo 0)
                    if [ -n "$size" ] && [ "$size" -gt 0 ]; then
                        total=$((total + size))
                    fi
                done < <(find "$file" -type f -print0)
            fi
        else
            # For single files, try both BSD and GNU stat formats
            size=$(stat -f %z "$file" 2>/dev/null || stat --format=%s "$file" 2>/dev/null || echo 0)
            if [ -n "$size" ] && [ "$size" -gt 0 ]; then
                total=$((total + size))
            fi
        fi
    done
    echo "$total"
}

# Function to show enhanced progress
show_enhanced_progress() {
    local total_size=$1
    local current_size=0
    local start_time=$(date +%s)
    local last_update=0
    local file_count=0
    
    echo "📊 Progress Information:"
    echo "   • Total size: $(human_readable_size $total_size)"
    
    while true; do
        # Get current archive size
        if [ -f "$output" ]; then
            current_size=$(stat -f %z "$output" 2>/dev/null || stat --format=%s "$output" 2>/dev/null)
            current_size=${current_size:-0}
            
            local elapsed=$(( $(date +%s) - start_time ))
            [ "$elapsed" -eq 0 ] && elapsed=1
            local speed=$(( current_size / elapsed ))
            local percent=$(( current_size * 100 / total_size ))
            local remaining=$(( (total_size - current_size) / (speed + 1) ))
            
            if [[ $elapsed -gt $last_update ]]; then
                printf "\r   • Progress: %s/%s (%d%%)" \
                    "$(human_readable_size $current_size)" \
                    "$(human_readable_size $total_size)" \
                    "$percent"
                printf " | Speed: %s/s" "$(human_readable_size $speed)"
                printf " | ETA: %dm %ds" "$((remaining / 60))" "$((remaining % 60))"
                last_update=$elapsed
            fi
        fi
        
        # Check if the archive process is still running
        if ! ps -p $archive_pid > /dev/null 2>&1; then
            break
        fi
        
        # Small sleep to prevent CPU hogging
        sleep 0.1
    done
    echo
}

# Function to get file list
get_file_list() {
    local dir="$1"
    local no_recurse="$2"
    
    # Convert relative path to absolute path
    local abs_dir=$(cd "$dir" && pwd)
    
    if [ "$no_recurse" = true ]; then
        # Only list files in the current directory, using absolute paths
        find "$abs_dir" -maxdepth 1 -type f
    else
        # List all files recursively, using absolute paths
        find "$abs_dir" -type f
    fi
}

# Function to check if file is binary
is_binary() {
    local file="$1"
    if file "$file" | grep -q "binary"; then
        return 0
    else
        return 1
    fi
}

# Function to create archive
create_archive() {
    local source="$1"
    local output="$2"
    local compression="$3"
    local no_recurse="$4"
    
    # Convert source to absolute path
    local abs_source=$(cd "$(dirname "$source")" && pwd)/$(basename "$source")
    
    # Get the base directory for tar
    local base_dir=$(dirname "$abs_source")
    local file_name=$(basename "$abs_source")
    
    # Check if source is a file
    if [ ! -f "$abs_source" ]; then
        echo "Error: Source file does not exist: $abs_source"
        return 1
    fi
    
    # Get file size for progress indicator
    local file_size=$(stat -f %z "$abs_source" 2>/dev/null || stat -c %s "$abs_source" 2>/dev/null)
    echo "Processing file: $file_name ($(human_readable_size $file_size))"
    
    # Build the tar command
    local tar_cmd="tar -cf -"
    
    # For single file, just add it directly
    tar_cmd="$tar_cmd -C $base_dir $file_name"
    
    # Add compression if specified
    case "$compression" in
        gzip) tar_cmd="$tar_cmd | gzip -c" ;;
        bzip2) tar_cmd="$tar_cmd | bzip2 -c" ;;
        xz) tar_cmd="$tar_cmd | xz -c" ;;
        *) tar_cmd="$tar_cmd | gzip -c" ;;  # Default to gzip
    esac
    
    # Execute the tar command with progress indicator
    echo "Creating archive..."
    if ! eval "$tar_cmd" > "$output" 2>/dev/null; then
        echo "Failed to create archive"
        return 1
    fi
    
    # Verify the output file exists and has content
    if [ ! -s "$output" ]; then
        echo "Archive creation failed - output file is empty"
        return 1
    fi
    
    local output_size=$(stat -f %z "$output" 2>/dev/null || stat -c %s "$output" 2>/dev/null)
    echo "Archive created successfully: $output ($(human_readable_size $output_size))"
    
    return 0
}

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
compression_tool=""    # Default to auto-detect parallel tools
force_compression_tool=""  # User-specified compression tool
gzip=true             # Enable compression by default
encrypt_method=""
hash_output=false
open_after=false
start_time=$(date +%s)

# Set no_prompt to true by default in non-interactive mode
if [ ! -t 0 ]; then
    no_prompt=true
else
    no_prompt=false
fi

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

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
        --compression=*)
            compression_level="${1#*=}"
            if ! [[ "$compression_level" =~ ^[0-9]+$ ]] || [ "$compression_level" -gt 9 ]; then
                echo "Error: Invalid compression level. Must be a number between 0 and 9."
                exit 1
            fi
            shift
            ;;
        -o|--output)
            output="$2"
            shift 2
            ;;
        --no-recursion|--no-recurse)
            no_recurse=true
            shift
            ;;
        --no-prompt)
            no_prompt=true
            shift
            ;;
        --tree)
            show_tree=true
            shift
            ;;
        --7z)
            use_7z=true
            shift
            ;;
        --zip)
            use_zip=true
            shift
            ;;
        --encrypt=*)
            encrypt_method="${1#*=}"
            if [[ "$encrypt_method" != "gpg" && "$encrypt_method" != "openssl" ]]; then
                echo "Error: Invalid encryption method. Must be 'gpg' or 'openssl'."
                exit 1
            fi
            shift
            ;;
        --encrypt)
            encrypt_method="gpg"  # Default to GPG
            shift
            ;;
        --password=*)
            password="${1#*=}"
            shift
            ;;
        --password)
            if [[ -z "$2" || "$2" == -* ]]; then
                echo "Error: --password requires a value"
                exit 1
            fi
            password="$2"
            shift 2
            ;;
        --verify)
            verify=true
            shift
            ;;
        --hash)
            hash_output=true
            shift
            ;;
        -x)
            open_after=true
            shift
            ;;
        --split-size=*)
            split_size="${1#*=}"
            shift
            ;;
        -n)
            gzip=false
            shift
            ;;
        --recipient)
            recipient="$2"
            shift 2
            ;;
        --use=*)
            force_compression_tool="${1#*=}"
            if [[ "$force_compression_tool" != "gzip" && "$force_compression_tool" != "bzip2" && "$force_compression_tool" != "xz" ]]; then
                echo "Error: Invalid compression tool. Must be 'gzip', 'bzip2', or 'xz'."
                exit 1
            fi
            shift
            ;;
        -h|--help)
            show_help
            ;;
        -*)
            echo "Error: Unknown option $1"
            exit 1
            ;;
        *)
            input_files+=("$1")
            shift
            ;;
  esac
done

# Check if input files exist
if [ ${#input_files[@]} -eq 0 ]; then
    echo "Error: No input files specified."
  exit 1
fi

for file in "${input_files[@]}"; do
    if [ ! -e "$file" ]; then
        echo "Error: Input file or directory '$file' does not exist."
        exit 1
      fi
done

# Set default output name if not specified
if [ -z "$output" ]; then
    if [ "$use_7z" = true ]; then
        output="archive.7z"
    elif [ "$use_zip" = true ]; then
    output="archive.zip"
  else
    output="archive.tar.gz"
  fi
fi

# Calculate total size and file count
total_size=$(calculate_total_size)
file_count=0
    for file in "${input_files[@]}"; do
    if [ -d "$file" ]; then
        if [ "$no_recurse" = true ]; then
            count=$(find "$file" -maxdepth 1 -type f | wc -l)
        else
            count=$(find "$file" -type f | wc -l)
  fi
else
        count=1
    fi
    file_count=$((file_count + count))
done

if [ $file_count -eq 0 ]; then
    echo "Error: No files found in input directory."
    exit 1
fi

# Convert total size to human readable format for display
human_total_size=$(human_readable_size $total_size)

# Display initial information
echo "📁 Total files: $file_count"
echo "📦 Total size: $human_total_size"
  echo "🗃  Output file: $output"
echo "🔧 Compression: $([ "$use_7z" = true ] && echo "7z" || ([ "$use_zip" = true ] && echo "zip" || echo "gzip (.tar.gz)"))"
  echo "🔐 Encryption: $([ -n "$encrypt_method" ] && echo "$encrypt_method" || echo "none")"
  echo "📂 Recursion: $([ "$no_recurse" = true ] && echo "disabled" || echo "enabled")"
echo

# Check if output file exists and handle conflicts
if [ -e "$output" ]; then
    if [ "$no_prompt" = true ]; then
        # In non-interactive mode, automatically rename
        output=$(get_next_filename "$output")
        echo "⚠️  Output file exists, using: $output"
    else
        echo "⚠️  Output file '$output' already exists."
        echo "    Choose an action:"
        echo "    [O]verwrite"
        echo "    [R]ename automatically (default)"
        echo "    [C]ancel"
        read -r choice
        
        # Convert to lowercase using tr
        choice=$(echo "$choice" | tr '[:upper:]' '[:lower:]')
        
        case "$choice" in
            o|overwrite)
                echo "Overwriting existing file..."
                ;;
            r|rename|"")  # Empty string (Enter key) now defaults to rename
                output=$(get_next_filename "$output")
                echo "Using new filename: $output"
                ;;
            c|cancel)
                echo "Operation cancelled."
                exit 0
                ;;
            *)
                # Default to rename on invalid input
                output=$(get_next_filename "$output")
                echo "Invalid choice. Using new filename: $output"
        ;;
    esac
    fi
fi

# Show tree view if requested
if [ "$show_tree" = true ]; then
    echo "📂 File structure:"
    for file in "${input_files[@]}"; do
        if [ -d "$file" ]; then
            if [ "$no_recurse" = true ]; then
                find "$file" -maxdepth 1 -type f | sed 's/[^/]*\//  /'
            else
                find "$file" -type f | sed 's/[^/]*\//  /g'
            fi
        else
            echo "  $(basename "$file")"
        fi
    done
    echo
fi

# Check for pv availability
have_pv=false
if command -v pv >/dev/null 2>&1; then
    have_pv=true
fi

# Check for parallel compression tools
if [ -n "$force_compression_tool" ]; then
    compression_tool="$force_compression_tool"
else
    if command -v pigz >/dev/null 2>&1; then
        compression_tool="pigz"
    elif command -v lbzip2 >/dev/null 2>&1; then
        compression_tool="lbzip2"
    elif command -v pbzip2 >/dev/null 2>&1; then
        compression_tool="pbzip2"
    elif command -v pxz >/dev/null 2>&1; then
        compression_tool="pxz"
    fi
fi

# Create archive
echo "🗜 Compressing archive..."

# Create a temporary file for progress monitoring
progress_file=$(mktemp)

# Start progress monitoring in background
show_enhanced_progress "$total_size" > "$progress_file" &
progress_pid=$!

# Function to cleanup progress monitoring
cleanup_progress() {
    if [ -n "$progress_pid" ]; then
        kill $progress_pid 2>/dev/null
    fi
    rm -f "$progress_file"
}
trap cleanup_progress EXIT

if [ -n "$split_size" ]; then
    create_split_archive "${input_files[@]}" "$output" "$split_size" > "$progress_file" &
    archive_pid=$!
elif [ "$use_7z" = true ]; then
    if [ -n "$password" ]; then
        7z a -p"$password" -mx="$compression_level" "$output" "${input_files[@]}" > "$progress_file" 2>&1 &
        archive_pid=$!
    else
        7z a -mx="$compression_level" "$output" "${input_files[@]}" > "$progress_file" 2>&1 &
        archive_pid=$!
    fi
elif [ "$use_zip" = true ]; then
    if [ -n "$password" ]; then
        zip -e -P "$password" "$output" "${input_files[@]}" > "$progress_file" 2>&1 &
        archive_pid=$!
    else
        zip -r "$output" "${input_files[@]}" > "$progress_file" 2>&1 &
        archive_pid=$!
    fi
else
    # Build tar command
    tar_cmd="tar"
    if [ "$gzip" = true ]; then
        if [ "$have_pv" = true ]; then
            # Use pv for progress monitoring
            tar_cmd="tar -c"
            for file in "${input_files[@]}"; do
                if [ -d "$file" ]; then
                    if [ "$no_recurse" = true ]; then
                        # For directories with no recursion, add files individually
                        find "$file" -maxdepth 1 -type f -print0 | while IFS= read -r -d '' f; do
                            tar_cmd="$tar_cmd -C \"$(dirname "$f")\" \"$(basename "$f")\""
                        done
                    else
                        # For directories with recursion, add the whole directory
                        tar_cmd="$tar_cmd -C \"$(dirname "$file")\" \"$(basename "$file")\""
                    fi
                else
                    # For single files, add them directly
                    tar_cmd="$tar_cmd -C \"$(dirname "$file")\" \"$(basename "$file")\""
                fi
            done
            if [ "$compression_tool" = "pigz" ]; then
                eval "$tar_cmd" 2>/dev/null | pv -s "$total_size" | pigz > "$output" &
            else
                eval "$tar_cmd" 2>/dev/null | pv -s "$total_size" | gzip > "$output" &
            fi
            archive_pid=$!
        else
            # Fall back to regular tar with gzip
            tar_cmd="$tar_cmd -cz"
            tar_cmd="$tar_cmd -f \"$output\""
    for file in "${input_files[@]}"; do
                if [ -d "$file" ]; then
                    if [ "$no_recurse" = true ]; then
                        # For directories with no recursion, add files individually
                        find "$file" -maxdepth 1 -type f -print0 | while IFS= read -r -d '' f; do
                            tar_cmd="$tar_cmd -C \"$(dirname "$f")\" \"$(basename "$f")\""
                        done
                    else
                        # For directories with recursion, add the whole directory
                        tar_cmd="$tar_cmd -C \"$(dirname "$file")\" \"$(basename "$file")\""
                    fi
                else
                    # For single files, add them directly
                    tar_cmd="$tar_cmd -C \"$(dirname "$file")\" \"$(basename "$file")\""
                fi
            done
            eval "$tar_cmd" > "$progress_file" 2>&1 &
            archive_pid=$!
        fi
    else
        # No compression
        tar_cmd="$tar_cmd -c -f \"$output\""
        for file in "${input_files[@]}"; do
            if [ -d "$file" ]; then
                if [ "$no_recurse" = true ]; then
                    # For directories with no recursion, add files individually
                    find "$file" -maxdepth 1 -type f -print0 | while IFS= read -r -d '' f; do
                        tar_cmd="$tar_cmd -C \"$(dirname "$f")\" \"$(basename "$f")\""
                    done
                else
                    # For directories with recursion, add the whole directory
                    tar_cmd="$tar_cmd -C \"$(dirname "$file")\" \"$(basename "$file")\""
                fi
            else
                # For single files, add them directly
                tar_cmd="$tar_cmd -C \"$(dirname "$file")\" \"$(basename "$file")\""
            fi
        done
        if [ "$have_pv" = true ]; then
            eval "$tar_cmd" 2>/dev/null | pv -s "$total_size" > "$output" &
            archive_pid=$!
        else
            eval "$tar_cmd" > "$progress_file" 2>&1 &
            archive_pid=$!
        fi
    fi
fi

# Wait for the archive process to complete
wait $archive_pid
archive_status=$?

# Clean up progress monitoring
cleanup_progress

if [ $archive_status -eq 0 ]; then
    # Handle encryption if requested
if [ -n "$encrypt_method" ]; then
        echo "🔐 Encrypting archive..."
        if [ "$encrypt_method" = "gpg" ]; then
            # Store original output name
            original_output="$output"
            # Update output to include .gpg extension
            output="${output}.gpg"
            
            if [ -n "$recipient" ]; then
                # Public key encryption
                if ! gpg --encrypt --recipient "$recipient" --output "$output" "$original_output"; then
                    echo "Error: Failed to encrypt with GPG public key"
                    exit 1
                fi
                # Remove original file
                rm "$original_output"
            else
                # Symmetric encryption
                if [ -z "$password" ]; then
                    read -s -p "Enter encryption password: " password
                    echo
                fi
                if ! gpg --symmetric --cipher-algo AES256 --batch --passphrase "$password" --output "$output" "$original_output"; then
                    echo "Error: Failed to encrypt with GPG"
                    exit 1
                fi
                # Remove original file
                rm "$original_output"
            fi
        elif [ "$encrypt_method" = "openssl" ]; then
            if [ -z "$password" ]; then
                read -s -p "Enter encryption password: " password
                echo
            fi
            if ! openssl enc -aes-256-cbc -salt -pbkdf2 -in "$output" -out "${output}.enc" -pass pass:"$password"; then
                echo "Error: Failed to encrypt with OpenSSL"
                exit 1
            fi
            mv "${output}.enc" "$output"
        fi
        echo "✅ Encryption complete"
    fi

    # Verify archive if requested
    if [ "$verify" = true ]; then
        verify_archive "$output"
    fi

    # Generate hash if requested
if [ "$hash_output" = true ]; then
  shasum -a 256 "$output" > "$output.sha256"
  echo "🔐 SHA256 hash saved to: $output.sha256"
fi

    # Get final archive size
    archive_size=$(du -h "$output" 2>/dev/null | cut -f1)
end_time=$(date +%s)
elapsed=$((end_time - start_time))

    echo "✅ Archive created successfully: $output"
echo "📏 Archive size: $archive_size"
echo "🕒 Total time elapsed: $((elapsed / 60))m $((elapsed % 60))s"

    # Show desktop notification
    if command -v notify-send >/dev/null 2>&1; then
        notify-send "fancy-tar" "Archive created: $output"
    elif command -v osascript >/dev/null 2>&1; then
        osascript -e "display notification \"Archive created: $output\" with title \"fancy-tar\""
    fi

    # Open containing folder if requested
if [ "$open_after" = true ]; then
  folder=$(dirname "$output")
  if command -v open >/dev/null; then
    open "$folder"
  elif command -v xdg-open >/dev/null; then
    xdg-open "$folder"
  fi
fi

    exit 0
else
    echo "❌ Compression failed."
    rm -f "$output"
    exit 1
fi

# Helper function to verify archive
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
    
    # Convert split size to bytes for tar
    local size_bytes
    if [[ "$split_size" =~ ^[0-9]+[KMG]$ ]]; then
        local unit=${split_size: -1}
        local size=${split_size%?}
        case "$unit" in
            K) size_bytes=$((size * 1024)) ;;
            M) size_bytes=$((size * 1024 * 1024)) ;;
            G) size_bytes=$((size * 1024 * 1024 * 1024)) ;;
        esac
    else
        echo "Error: Invalid split size format. Use K, M, or G suffix (e.g., 100M, 1G)"
        return 1
    fi
    
    if [[ "$output" == *.zip ]]; then
        if ! zip -s "$split_size" "$output" "${input_files[@]}"; then
            echo "Error: Failed to create split ZIP archive"
            return 1
        fi
    elif [[ "$output" == *.7z ]]; then
        if ! 7z a -v"$split_size" "$output" "${input_files[@]}"; then
            echo "Error: Failed to create split 7z archive"
            return 1
        fi
    else
        # For tar archives, we need to handle the compression
        local compression_cmd=""
        if [[ "$output" == *.gz ]]; then
            compression_cmd="gzip -c"
        elif [[ "$output" == *.bz2 ]]; then
            compression_cmd="bzip2 -c"
        elif [[ "$output" == *.xz ]]; then
            compression_cmd="xz -c"
        fi
        
        # Create the split archive
        if [ -n "$compression_cmd" ]; then
            if ! tar -cf - "${input_files[@]}" | $compression_cmd | split -b "$split_size" - "$output."; then
                echo "Error: Failed to create split compressed archive"
                return 1
            fi
        else
            if ! tar -cf - "${input_files[@]}" | split -b "$split_size" - "$output."; then
                echo "Error: Failed to create split tar archive"
                return 1
            fi
        fi
        
        # Rename the first part to match the output filename
        if [ -f "${output}.aa" ]; then
            mv "${output}.aa" "$output"
        fi
    fi
    
    echo "✅ Split archive created successfully"
    return 0
}

show_help() {
  echo "Usage: fancy-tar [options] <files...>"
  echo ""
  echo "Options:"
  echo "  -o, --output <file>    Specify output file name"
  echo "  -n                     Do not use gzip compression"
  echo "  -s                     Use slower but better compression"
  echo "  -x                     Open the output folder when done"
  echo "  -t, --tree            Show hierarchical file structure before archiving"
  echo "  --no-recursion|--no-recurse Do not include directory contents (shallow archive)"
  echo "  --no-prompt           Skip all interactive prompts (use defaults)"
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
  echo "  --use=<tool>          Force specific compression tool"
  echo "                       • gzip: Use gzip instead of pigz"
  echo "                       • bzip2: Use bzip2 instead of pbzip2"
  echo "                       • xz: Use xz instead of pxz"
  echo "  -h, --help            Show this help message"
  echo "  --version             Show version information"
  echo ""
  echo "Examples:"
  echo "  fancy-tar file1.txt file2.txt -o archive.tar.gz"
  echo "  fancy-tar --zip --password secret -o archive.zip folder/"
  echo "  fancy-tar --7z --compression=9 -o archive.7z large_folder/"
  echo "  fancy-tar --split-size=100M -o archive.tar.gz huge_folder/"
  echo "  fancy-tar --verify -o archive.tar.gz important_files/"
  echo "  fancy-tar --use=gzip -o archive.tar.gz files/"  # Force gzip instead of pigz
  echo ""
  echo "Note: When using --split-size, the archive will be split into multiple parts"
  echo "      with the specified size. For example, with --split-size=100M, a 500MB"
  echo "      archive would be split into 5 parts of 100MB each."
  exit 0
}

