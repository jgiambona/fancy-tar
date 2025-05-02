#!/bin/bash
VERSION="1.7.5"

# Pre-scan for --debug flag to enable debug output as early as possible
for arg in "$@"; do
    if [[ "$arg" == "--debug" ]]; then
        DEBUG=1
        break
    fi
done

# Debug logging function
# Usage: debug_log "message"
debug_log() {
    if [ -n "$DEBUG" ]; then
        echo "DEBUG: $*" | tee -a /tmp/fancy_tar_debug.log
    fi
}

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
  elif [[ "$archive" == *.tar.bz2 || "$archive" == *.tbz2 || "$archive" == *.bz2 ]]; then
    if ! bzip2 -t "$archive" >/dev/null 2>&1; then
      echo "❌ Archive verification failed (bzip2)"
      return 1
    fi
  elif [[ "$archive" == *.tar.xz || "$archive" == *.txz || "$archive" == *.xz ]]; then
    if ! xz -t "$archive" >/dev/null 2>&1; then
      echo "❌ Archive verification failed (xz)"
      return 1
    fi
  elif [[ "$archive" == *.tar ]]; then
    if ! tar -tf "$archive" >/dev/null 2>&1; then
      echo "❌ Archive verification failed (tar)"
      return 1
    fi
  else
    if ! gzip -t "$archive" >/dev/null 2>&1; then
      echo "❌ Archive verification failed (gzip)"
      return 1
    fi
  fi

  echo "✅ Archive verified successfully"
  return 0
}

# Function to create split archive
create_split_archive() {
    local output="$1"
    local split_size="$2"
    shift 2
    local input_files=("$@")
    echo "📦 Creating split archive..."
    echo "   • Split size: $split_size"

    # Check for required tools
    if [[ "$output" == *.zip ]]; then
        if ! command -v zip >/dev/null 2>&1; then
            echo "Error: 'zip' is required for split zip archives. Please install it."
            return 1
        fi
    elif [[ "$output" == *.7z ]]; then
        if ! command -v 7z >/dev/null 2>&1; then
            echo "Error: '7z' is required for split 7z archives. Please install it."
            return 1
        fi
    else
        if ! command -v split >/dev/null 2>&1; then
            echo "Error: 'split' is required for split tar archives. Please install it."
            return 1
        fi
    fi

    # Check for existing split parts and prompt user
    local part_glob="$output*"
    local found_parts=( )
    shopt -s nullglob
    for f in $part_glob; do
        if [[ "$f" != "$output" ]]; then
            found_parts+=("$f")
        fi
    done
    shopt -u nullglob
    if [ ${#found_parts[@]} -gt 0 ]; then
        echo "⚠️  Split parts matching '$output*' already exist:"
        for f in "${found_parts[@]}"; do
            echo "   $f"
        done
        echo "    Choose an action:"
        echo "    [O]verwrite all"
        echo "    [R]ename output (default)"
        echo "    [C]ancel"
        read -r -t 30 choice || choice="r"
        choice=$(echo "$choice" | tr '[:upper:]' '[:lower:]')
        case "$choice" in
            o|overwrite)
                echo "Overwriting existing split parts..."
                rm -f $part_glob
                ;;
            r|rename|"")
                local base="$output"
                local counter=1
                while ls "${base}_$counter"* 1> /dev/null 2>&1; do
                    counter=$((counter + 1))
                done
                output="${base}_$counter"
                echo "Using new output base: $output"
                ;;
            c|cancel)
                echo "Operation cancelled."
                return 1
                ;;
            *)
                output="${output}_renamed"
                echo "Invalid choice. Using new output base: $output"
                ;;
        esac
    fi

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

    # Trap for cleanup on failure
    cleanup_split_parts() {
        echo "Cleaning up split parts..."
        rm -f "$output"* 2>/dev/null
    }
    trap cleanup_split_parts ERR

    local split_success=false
    if [[ "$output" == *.zip ]]; then
        if zip -s "$split_size" "$output" "${input_files[@]}"; then
            split_success=true
        fi
    elif [[ "$output" == *.7z ]]; then
        if 7z a -v"$split_size" "$output" "${input_files[@]}"; then
            split_success=true
        fi
    else
        local compression_cmd=""
        if [[ "$output" == *.gz ]]; then
            compression_cmd="gzip -c"
        elif [[ "$output" == *.bz2 ]]; then
            compression_cmd="bzip2 -c"
        elif [[ "$output" == *.xz ]]; then
            compression_cmd="xz -c"
        fi
        if [ -n "$compression_cmd" ]; then
            if tar -cf - "${input_files[@]}" | $compression_cmd | split -b "$split_size" - "$output."; then
                split_success=true
            fi
        else
            if tar -cf - "${input_files[@]}" | split -b "$split_size" - "$output."; then
                split_success=true
            fi
        fi
        if [ -f "${output}.aa" ]; then
            mv "${output}.aa" "$output"
        fi
    fi

    if ! $split_success; then
        echo "Error: Failed to create split archive."
        cleanup_split_parts
        trap - ERR
        return 1
    fi
    trap - ERR

    # List all split parts
    echo "✅ Split archive created successfully. Parts:"
    local parts=( )
    shopt -s nullglob
    for f in "$output"*; do
        if [[ "$f" != "$output" ]]; then
            parts+=("$f")
        fi
    done
    shopt -u nullglob
    for f in "${parts[@]}"; do
        size=$(ls -l "$f" 2>/dev/null | awk '{print $5}')
        if [ ! -s "$f" ]; then
            echo "   ⚠️  $f (empty!)"
        else
            echo "   $f ($(human_readable_size $size))"
        fi
    done
    # Warn if any part is missing or empty
    local missing=false
    for f in "${parts[@]}"; do
        if [ ! -s "$f" ]; then
            echo "   ⚠️  Warning: $f is empty!"
            missing=true
        fi
    done
    if [ "$missing" = true ]; then
        echo "⚠️  Warning: Some split parts are missing or empty. Archive may be incomplete."
    fi

    # Print reassembly instructions
    echo ""
    echo "To reassemble and verify your split archive:"
    if [[ "$output" == *.7z ]]; then
        echo "   7z x ${output}.001"
        echo "   (Make sure all .7z.0* parts are present in the same directory)"
    else
        echo "   cat $output* > combined_archive"
        if [[ "$output" == *.gz ]]; then
            echo "   gzip -t combined_archive   # or   tar -tf combined_archive"
        elif [[ "$output" == *.bz2 ]]; then
            echo "   bzip2 -t combined_archive   # or   tar -tf combined_archive"
        elif [[ "$output" == *.xz ]]; then
            echo "   xz -t combined_archive   # or   tar -tf combined_archive"
        else
            echo "   tar -tf combined_archive"
        fi
    fi
    echo ""
    return 0
}

# Version and help flags (exit early)
if [[ "$1" == "--version" || "$1" == "-v" ]]; then
  echo "fancy-tar $VERSION"
  exit 0
fi
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
  show_help
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
  run_test "7z with password" "$TMPFILE2" --7z --password=test
  run_test "Hash generation" --hash "$TMPFILE2"
  run_test "OpenSSL encryption" --encrypt=openssl "$TMPFILE1"
  run_test "GPG symmetric encryption" --encrypt=gpg "$TMPFILE1"
  run_test "Tree view + no-recursion" --tree --no-recursion "$TMPFILE1" "$TMPFILE2"

  echo ""
  echo "🧪 Self-test summary: $((TESTS - FAILS)) passed, $FAILS failed"
  exit $FAILS
fi

# Function to get compression display string
get_compression_display() {
    local tool="$1"
    case "$tool" in
        pigz) echo "pigz (.tar.gz)" ;;
        gzip) echo "gzip (.tar.gz)" ;;
        bzip2) echo "bzip2 (.tar.bz2)" ;;
        pbzip2|lbzip2) echo "$tool (.tar.bz2)" ;;
        xz) echo "xz (.tar.xz)" ;;
        pxz) echo "pxz (.tar.xz)" ;;
        *) echo "$tool" ;;
    esac
}

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
force_compression_tool=""  # User-specified compression tool
gzip=true             # Enable compression by default
encrypt_method=""
hash_output=false
open_after=false
compression_tool=""  # Will be set after argument parsing

# Set no_prompt to true by default in non-interactive mode
if [ ! -t 0 ]; then
    no_prompt=true
else
    no_prompt=false
fi

# Store terminal settings for password prompts
stty_settings=""

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
        -x|--open-after)
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
            if [[ "$force_compression_tool" != "gzip" && "$force_compression_tool" != "pigz" && \
                  "$force_compression_tool" != "bzip2" && "$force_compression_tool" != "pbzip2" && \
                  "$force_compression_tool" != "lbzip2" && "$force_compression_tool" != "xz" && \
                  "$force_compression_tool" != "pxz" ]]; then
                echo "Error: Invalid compression tool. Must be one of: gzip, pigz, bzip2, pbzip2, lbzip2, xz, pxz"
                exit 1
            fi
            shift
            ;;
        -h|--help)
            show_help
            ;;
        --debug)
            DEBUG=1
            shift
            ;;
        -*)
            echo "Error: Unknown option $1"
            exit 1
            ;;
        *)
            # Always add to input files
            input_files+=("$1")
            shift
            ;;
  esac
done

# Debug output for input files
if [ -n "$DEBUG" ]; then
    echo "Debug: Number of input files: ${#input_files[@]}"
    echo "Debug: Input files:"
    for file in "${input_files[@]}"; do
        echo "Debug:   - $file"
    done
fi

# After argument parsing, determine compression tool
if [ -n "$force_compression_tool" ]; then
    if ! command -v "$force_compression_tool" >/dev/null 2>&1; then
        echo "Error: Requested compression tool '$force_compression_tool' is not available."
        echo "       Please install it or use a different compression tool."
        exit 1
    fi
    compression_tool="$force_compression_tool"
elif [ "$gzip" = true ]; then
    # Only check for parallel tools if not explicitly set and compression is enabled
    if command -v pigz >/dev/null 2>&1 && [ -z "$force_compression_tool" ]; then
        compression_tool="pigz"
    elif command -v lbzip2 >/dev/null 2>&1; then
        compression_tool="lbzip2"
    elif command -v pbzip2 >/dev/null 2>&1; then
        compression_tool="pbzip2"
    elif command -v pxz >/dev/null 2>&1; then
        compression_tool="pxz"
    # Fall back to standard tools
    elif command -v gzip >/dev/null 2>&1; then
        compression_tool="gzip"
    elif command -v bzip2 >/dev/null 2>&1; then
        compression_tool="bzip2"
    elif command -v xz >/dev/null 2>&1; then
        compression_tool="xz"
    else
        compression_tool="gzip"  # Default fallback
    fi
fi

# Set default output name if not specified (must be after compression_tool is set)
if [ -z "$output" ]; then
    if [ "$use_7z" = true ]; then
        output="archive.7z"
    elif [ "$use_zip" = true ]; then
        output="archive.zip"
    else
        case "$compression_tool" in
            pigz|gzip) output="archive.tar.gz" ;;
            bzip2|pbzip2|lbzip2) output="archive.tar.bz2" ;;
            xz|pxz) output="archive.tar.xz" ;;
            "") output="archive.tar" ;;
            *) output="archive.tar" ;;
        esac
    fi
fi

# Debug output for compression tool
if [ -n "$DEBUG" ] && [ "$use_zip" != true ] && [ "$use_7z" != true ]; then
    echo "Debug: Selected compression tool: $compression_tool" >&2
fi

# After argument parsing, if --7z is used and --encrypt or --password is set, set encrypt_method to 7z unless explicitly set
if [ "$use_7z" = true ] && [ -n "$password" -o "$encrypt_method" = "gpg" -o "$encrypt_method" = "openssl" ]; then
    if [ -z "$encrypt_method" ] || [ "$encrypt_method" = "gpg" ] || [ "$encrypt_method" = "openssl" ]; then
        encrypt_method="7z"
    fi
fi

# Function to get next available filename
get_next_filename() {
    local base="$1"
    
    # Handle special cases for .tar.* files
    if [[ "$base" == *.tar.* ]]; then
        local main_name="${base%.tar.*}"
        local ext=".tar.${base##*.tar.}"
    else
        local main_name="${base%.*}"
        local ext=".${base##*.}"
    fi
    
    local counter=1
    local new_name="$base"
    
    while [ -e "$new_name" ]; do
        if [[ "$base" == *.tar.* ]]; then
            new_name="${main_name}_${counter}.tar.${base##*.tar.}"
        else
            new_name="${main_name}_${counter}${ext}"
        fi
        counter=$((counter + 1))
    done
    
    echo "$new_name"
}

# Function to convert bytes to human readable format
human_readable_size() {
    local bytes=$1
    local precision=${2:-1}  # Default to 1 decimal place like Finder
    local base=1000  # Use 1000 instead of 1024 to match Finder
    local units=("B" "KB" "MB" "GB" "TB" "PB")
    local unit=0
    local size
    
    # Use bc for floating point arithmetic
    size=$bytes
    while [ $(echo "$size >= $base" | bc -l) -eq 1 ] && [ $unit -lt $((${#units[@]} - 1)) ]; do
        size=$(echo "scale=$precision; $size / $base" | bc -l)
        unit=$((unit + 1))
    done
    
    # Format with exactly one decimal place for consistency with Finder
    if [ $unit -gt 0 ]; then
        # Force one decimal place for units larger than bytes
        formatted=$(printf "%.1f" $size)
    else
        # For bytes, show as integer
        formatted=$(printf "%.0f" $size)
    fi
    
    echo "${formatted}${units[$unit]}"
}

# Function to calculate total size using ls for accuracy
calculate_total_size() {
    local total=0
    for file in "${input_files[@]}"; do
        if [ -d "$file" ]; then
            if [ "$no_recurse" = true ]; then
                # Only count files in current directory
                while IFS= read -r -d '' f; do
                    size=$(ls -l "$f" 2>/dev/null | awk '{print $5}')
                    total=$((total + size))
                done < <(find "$file" -maxdepth 1 -type f -print0)
            else
                # Count all files recursively
                while IFS= read -r -d '' f; do
                    size=$(ls -l "$f" 2>/dev/null | awk '{print $5}')
                    total=$((total + size))
                done < <(find "$file" -type f -print0)
            fi
        else
            # For single files, use ls
            size=$(ls -l "$file" 2>/dev/null | awk '{print $5}')
            total=$((total + size))
        fi
    done
    
    # Debug output
    if [ -n "$DEBUG" ]; then
        echo "Debug: Raw size in bytes: $total" >&2
        echo "Debug: Size in MB: $(echo "scale=2; $total / 1048576" | bc -l)" >&2
    fi
    
    echo "$total"
}

# Function to safely subtract two numbers using bc, defaulting to 0 if invalid
safe_bc_subtract() {
    local a="$1"
    local b="$2"
    if [[ -z "$a" || -z "$b" ]]; then
        echo 0
    elif [[ "$a" =~ ^[0-9]+(\.[0-9]+)?$ && "$b" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
        echo "scale=3; $a - $b" | bc
    else
        echo 0
    fi
}

# Function to safely divide two numbers using bc, defaulting to 0 if invalid
safe_bc_divide() {
    local a="$1"
    local b="$2"
    if [[ -z "$a" || -z "$b" || "$b" == "0" ]]; then
        echo 0
    elif [[ "$a" =~ ^[0-9]+(\.[0-9]+)?$ && "$b" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
        echo "scale=3; $a / $b" | bc
    else
        echo 0
    fi
}

# Function to show enhanced progress with more accurate size display
show_enhanced_progress() {
    local total_size="$1"
    local current_size=0
    local start_time=""
    local last_update=0
    local file_count=0

    echo "📊 Progress Information:"
    echo "   • Total size: $(human_readable_size "$total_size")"

    while true; do
        if [ -f "$output" ]; then
            current_size=$(ls -l "$output" 2>/dev/null | awk '{print $5}')
            current_size="${current_size:-0}"
            if [ -z "$start_time" ] && [ "$current_size" -gt 0 ]; then
                start_time=$(date +%s.%N)
                last_update="$start_time"
            fi
            if [ -n "$start_time" ]; then
                local now=$(date +%s.%N)
                local elapsed=$(safe_bc_subtract "$now" "$start_time")
                [ "$elapsed" = "0" ] && elapsed=0.001
                local speed=$(safe_bc_divide "$current_size" "$elapsed")
                local percent=0
                if [[ "$total_size" != "0" ]]; then
                    percent=$((current_size * 100 / total_size))
                fi
                local remaining=$(safe_bc_divide "$((total_size - current_size))" "$speed")
                if [[ "$elapsed" > "$last_update" ]]; then
                    printf "\r   • Progress: %s/%s (%d%%)" \
                        "$(human_readable_size "$current_size")" \
                        "$(human_readable_size "$total_size")" \
                        "$percent"
                    printf " | Speed: %s/s" "$(human_readable_size "$speed")"
                    printf " | ETA: %dm %ds" "$((remaining / 60))" "$((remaining % 60))"
                    last_update="$elapsed"
                fi
            fi
        fi
        if ! ps -p "$archive_pid" > /dev/null 2>&1; then
            break
        fi
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
    local output="$1"
    local compression="$2"
    local no_recurse="$3"
    shift 3  # Remove the first three arguments
    local input_files=("$@")  # Remaining arguments are input files
    
    if [ -n "$DEBUG" ]; then
        echo "Debug: create_archive received ${#input_files[@]} files:"
        for file in "${input_files[@]}"; do
            echo "Debug:   - $file"
        done
    fi
    
    # Get total size for progress indicator
    local total_size=0
    for source in "${input_files[@]}"; do
        # Convert source to absolute path
        local abs_source=$(cd "$(dirname "$source")" && pwd)/$(basename "$source")
        
        if [ -d "$abs_source" ]; then
            if [ "$no_recurse" = true ]; then
                # Only count files in current directory
                while IFS= read -r -d '' f; do
                    size=$(ls -l "$f" 2>/dev/null | awk '{print $5}')
                    total_size=$((total_size + size))
                done < <(find "$abs_source" -maxdepth 1 -type f -print0)
            else
                # Count all files recursively
                while IFS= read -r -d '' f; do
                    size=$(ls -l "$f" 2>/dev/null | awk '{print $5}')
                    total_size=$((total_size + size))
                done < <(find "$abs_source" -type f -print0)
            fi
        else
            size=$(ls -l "$abs_source" 2>/dev/null | awk '{print $5}')
            total_size=$((total_size + size))
        fi
    done
    
    # Build the base tar command
    local tar_cmd="tar -c"
    
    # Add all sources to tar command
    for source in "${input_files[@]}"; do
        local abs_source=$(cd "$(dirname "$source")" && pwd)/$(basename "$source")
        local base_dir=$(dirname "$abs_source")
        local file_name=$(basename "$abs_source")
        
        echo "Processing: $file_name ($(human_readable_size $(ls -l "$abs_source" 2>/dev/null | awk '{print $5}')))"
        
        if [ -n "$DEBUG" ]; then
            echo "Debug: Adding to tar command:"
            echo "Debug:   base_dir: $base_dir"
            echo "Debug:   file_name: $file_name"
        fi
        
        if [ -d "$abs_source" ]; then
            if [ "$no_recurse" = true ]; then
                # Only add files in current directory
                tar_cmd="$tar_cmd -C $base_dir $file_name"
            else
                # Add all files recursively
                tar_cmd="$tar_cmd -C $base_dir $file_name"
            fi
        else
            # For single files, add them directly
            tar_cmd="$tar_cmd -C $base_dir $file_name"
        fi
    done
    
    if [ -n "$DEBUG" ]; then
        echo "Debug: Final tar command: $tar_cmd"
    fi
    
    # Check for pv availability
    have_pv=false
    if command -v pv >/dev/null 2>&1; then
        have_pv=true
    fi
    
    # Start timing just before compression begins
    start_time=$(date +%s.%N)
    
    if [ "$have_pv" = true ]; then
        # Use pv for progress monitoring
        if [ -n "$compression_tool" ]; then
            if [ -n "$DEBUG" ]; then
                echo "Debug: executing: $tar_cmd | pv -s $total_size | $compression_tool > $output" >&2
            fi
            eval "$tar_cmd" | pv -s "$total_size" | "$compression_tool" > "$output" &
        else
            # No compression
            if [ -n "$DEBUG" ]; then
                echo "Debug: executing: $tar_cmd | pv -s $total_size > $output" >&2
            fi
            eval "$tar_cmd" | pv -s "$total_size" > "$output" &
        fi
        archive_pid=$!
    else
        # Fall back to regular tar with appropriate compression
        if [ -n "$compression_tool" ]; then
            case "$compression_tool" in
                bzip2|pbzip2|lbzip2)
                    tar_cmd="$tar_cmd -j"
                    ;;
                xz|pxz)
                    tar_cmd="$tar_cmd -J"
                    ;;
                pigz|gzip)
                    tar_cmd="$tar_cmd -z"
                    ;;
            esac
        fi
        
        if [ -n "$DEBUG" ]; then
            echo "Debug: executing: $tar_cmd -f $output" >&2
        fi
        eval "$tar_cmd -f $output" &
        archive_pid=$!
    fi
    
    # Wait for the archive process to complete
    wait $archive_pid
    archive_status=$?
    
    if [ "${archive_status:-1}" -eq 0 ]; then
        # Get final archive size
        local output_size=$(ls -l "$output" 2>/dev/null | awk '{print $5}')
        return 0
    else
        echo "Failed to create archive"
        return 1
    fi
}

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

# Calculate total size and file count
total_size=$(calculate_total_size)
file_count=0
if [ -n "$DEBUG" ]; then
    echo "Debug: Calculating file count..."
fi
for file in "${input_files[@]}"; do
    if [ -d "$file" ]; then
        if [ "$no_recurse" = true ]; then
            count=$(find "$file" -maxdepth 1 -type f | wc -l)
            if [ -n "$DEBUG" ]; then
                echo "Debug:   Directory $file (no-recurse): $count files"
            fi
        else
            count=$(find "$file" -type f | wc -l)
            if [ -n "$DEBUG" ]; then
                echo "Debug:   Directory $file (recursive): $count files"
            fi
        fi
    else
        count=1
        if [ -n "$DEBUG" ]; then
            echo "Debug:   File $file: 1 file"
        fi
    fi
    file_count=$((file_count + count))
done
if [ -n "$DEBUG" ]; then
    echo "Debug: Total file count: $file_count"
fi

if [ $file_count -eq 0 ]; then
    echo "Error: No files found in input directory."
    exit 1
fi

# Convert total size to human readable format for display with higher precision
human_total_size=$(human_readable_size $total_size 3)

# Display initial information
echo "📁 Total files: $file_count"
echo "📦 Total size: $human_total_size"
echo "📄 Output file: $output"
if [ "$use_7z" = true ]; then
    echo "🔧 Compression: 7z"
elif [ "$use_zip" = true ]; then
    echo "🔧 Compression: zip"
else
    echo "🔧 Compression: $(get_compression_display "$compression_tool")"
fi

# When prompting for a password interactively, always ask for confirmation
prompt_password() {
    local pass1 pass2
    if [ ! -t 0 ]; then
        # Non-interactive: use default password or fail
        password="test"
        echo "[Non-interactive: using default password]"
        return
    fi
    while true; do
        read -s -p "Enter encryption password: " pass1
        echo
        read -s -p "Confirm password: " pass2
        echo
        if [ "$pass1" = "$pass2" ]; then
            password="$pass1"
            break
        else
            echo "Passwords do not match. Please try again."
        fi
    done
}

# Replace all interactive password prompts with prompt_password
# For GPG/OpenSSL/7z interactive password entry, use prompt_password
# In the summary, display the correct encryption method
if [ "$use_7z" = true ] && [ "$encrypt_method" = "7z" ]; then
    encryption_display="7z AES-256"
elif [ "$use_zip" = true ] && [ -n "$password" ]; then
    encryption_display="zip password"
elif [ "$encrypt_method" = "gpg" ]; then
    encryption_display="gpg"
elif [ "$encrypt_method" = "openssl" ]; then
    encryption_display="openssl"
else
    encryption_display="none"
fi

echo "🔒 Encryption: $encryption_display"
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
        read -r -t 30 choice || choice="r"  # Default to rename after 30 seconds
        
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

# Create archive
echo "Archiving files"
echo "🗜️  Compressing archive..."

# Create a temporary file for progress monitoring
if [ -n "$DEBUG" ]; then
    progress_file="/tmp/fancy_tar_progress.log"
    sevenz_log="/tmp/fancy_tar_7z.log"
    zip_log="/tmp/fancy_tar_zip.log"
else
    progress_file=$(mktemp)
    sevenz_log=$(mktemp)
    zip_log=$(mktemp)
fi

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

# Spinner function for zip/7z with timer
spinner_with_timer() {
    # Disable spinner if DEBUG is set
    if [ -n "$DEBUG" ]; then
        wait "$1"
        return
    fi
    local pid=$1
    local label="$2"
    local start_time=$(date +%s.%N)
    local spin_chars='|/-\\'
    local i=0
    debug_log "spinner_with_timer waiting on PID: $pid"
    while kill -0 "$pid" 2>/dev/null; do
        local now=$(date +%s.%N)
        local elapsed=$(echo "$now - $start_time" | bc -l)
        local mins=$(echo "$elapsed/60" | bc)
        local secs=$(echo "$elapsed-($mins*60)" | bc -l)
        local secs_fmt=$(printf "%.1f" "$secs")
        local spin_char=${spin_chars:i%4:1}
        printf "\r%s %s ⏳ %dm %04.1fs" "$label" "$spin_char" "$mins" "$secs_fmt"
        i=$((i + 1))
        sleep 0.2
    done
    # Print final time
    local now=$(date +%s.%N)
    local elapsed=$(echo "$now - $start_time" | bc -l)
    local mins=$(echo "$elapsed/60" | bc)
    local secs=$(echo "$elapsed-($mins*60)" | bc -l)
    local secs_fmt=$(printf "%.1f" "$secs")
    printf "\r%s   ⏳ %dm %04.1fs\n" "$label" "$mins" "$secs_fmt"
}

# Enable shell tracing if debug is set
if [ -n "$DEBUG" ]; then
    set -x
fi

if [ -n "$split_size" ]; then
    split_output_file=$(mktemp)
    create_split_archive "$output" "$split_size" "${input_files[@]}" > "$split_output_file" &
    archive_pid=$!
    wait $archive_pid
    cat "$split_output_file"
    rm -f "$split_output_file"
elif [ "$use_7z" = true ]; then
    if [ "$encrypt_method" = "7z" ] && [ -z "$password" ]; then
        prompt_password
    fi
    start_time=$(date +%s.%N)
    debug_log "Launching 7z with parent PID: $$"
    cmd_7z=(7z a -mx="$compression_level" "$output" "${input_files[@]}")
    if [ -n "$password" ]; then
        cmd_7z=(7z a -p"$password" -mx="$compression_level" "$output" "${input_files[@]}")
    fi
    debug_log "7z command: ${cmd_7z[*]} > $sevenz_log 2>&1 &"
    "${cmd_7z[@]}" > "$sevenz_log" 2>&1 &
    archive_pid=$!
    debug_log "7z started with archive_pid: $archive_pid"
    spinner_with_timer "$archive_pid" "Compressing with 7z..."
    end_time=$(date +%s.%N)
elif [ "$use_zip" = true ]; then
    start_time=$(date +%s.%N)
    debug_log "Launching zip with parent PID: $$"
    cmd_zip=(zip -e -P "$password" "$output" "${input_files[@]}")
    if [ -z "$password" ]; then
        prompt_password
        cmd_zip=(zip -e -P "$password" "$output" "${input_files[@]}")
    fi
    debug_log "zip command: ${cmd_zip[*]} > $zip_log 2>&1 &"
    "${cmd_zip[@]}" > "$zip_log" 2>&1 &
    archive_pid=$!
    debug_log "zip started with archive_pid: $archive_pid"
    spinner_with_timer "$archive_pid" "Compressing with zip..."
    end_time=$(date +%s.%N)
else
    create_archive "$output" "$compression_tool" "$no_recurse" "${input_files[@]}"
    archive_status=$?
fi

# Only wait if archive_pid is set (i.e., for backgrounded cases)
if [ -n "$archive_pid" ]; then
    wait $archive_pid
    archive_status=$?
fi

# Clean up progress monitoring
cleanup_progress

if [ "${archive_status:-1}" -eq 0 ]; then
    # Get final archive size using ls for more accurate size
    archive_size=$(ls -l "$output" 2>/dev/null | awk '{print $5}')
    archive_size_human=$(human_readable_size $archive_size)

    # Verify archive if requested (before encryption, except for 7z)
    if [ "$verify" = true ] && [ "$use_7z" != true ]; then
        if [ -n "$split_size" ]; then
            echo "⚠️  Verification skipped: Archive was split into multiple parts."
            echo "   To verify integrity, first reassemble all parts (e.g., cat $output* > combined.tar.gz) and then run:"
            echo "   gzip -t combined.tar.gz   or   tar -tf combined.tar.gz"
        else
            verify_archive "$output"
        fi
    fi

    # Handle encryption if requested
    if [ -n "$encrypt_method" ]; then
        echo "🔒 Encrypting archive..."
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
                    prompt_password
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
                prompt_password
            fi
            if ! openssl enc -aes-256-cbc -salt -pbkdf2 -in "$output" -out "${output}.enc" -pass pass:"$password"; then
                echo "Error: Failed to encrypt with OpenSSL"
                exit 1
            fi
            mv "${output}.enc" "$output"
        fi
        echo "✅ Encryption complete"
    fi

    # For 7z, verify after creation (with password if set)
    if [ "$verify" = true ] && [ "$use_7z" = true ]; then
        if [ -n "$password" ]; then
            7z t -p"$password" "$output"
        else
            verify_archive "$output"
        fi
    fi

    # Generate hash if requested
    if [ "$hash_output" = true ]; then
        shasum -a 256 "$output" > "$output.sha256"
        echo "🔒 SHA256 hash saved to: $output.sha256"
    fi

    # Calculate elapsed time with decimal precision
    if [ -z "$start_time" ]; then
        start_time=$end_time
    fi
    if [ -z "$end_time" ]; then
        end_time=$(date +%s.%N)
    fi
    elapsed=$(safe_bc_subtract "$end_time" "$start_time")
    # Ensure minutes is integer and seconds is float with one decimal
    minutes=$(echo "$elapsed/60" | bc)
    seconds=$(echo "$elapsed-($minutes*60)" | bc -l)
    seconds_fmt=$(printf "%.1f" "$seconds")

    # Debug output for timing
    if [ -n "$DEBUG" ]; then
        echo "Debug: Start time: $start_time" >&2
        echo "Debug: End time: $end_time" >&2
        echo "Debug: Raw elapsed: $elapsed" >&2
    fi

    echo "✅ Archive created successfully: $output"
    echo "📏 Archive size: $archive_size_human"
    printf "⏱️  Total time elapsed: %dm %.1fs\n" "$minutes" "$seconds_fmt"

    # Show desktop notification
    if command -v notify-send >/dev/null 2>&1; then
        notify-send "📦 fancy-tar" "Archive created: $output"
    elif command -v osascript >/dev/null 2>&1; then
        osascript -e "display notification \"Archive created: $output\" with title \"📦 fancy-tar\""
    fi

    # Open the output folder if requested
    if [ "$open_after" = true ]; then
        output_dir="$(dirname "$output")"
        if command -v open >/dev/null 2>&1; then
            open "$output_dir"
        elif command -v xdg-open >/dev/null 2>&1; then
            xdg-open "$output_dir"
        fi
    fi

    exit 0
else
    echo "❌ Compression failed."
    rm -f "$output"
    exit 1
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
  echo "  --use=<tool>          Force specific compression tool:"
  echo "                       • gzip/pigz: Use gzip or parallel gzip"
  echo "                       • bzip2/pbzip2/lbzip2: Use bzip2 or parallel variants"
  echo "                       • xz/pxz: Use xz or parallel xz"
  echo "                       • If not specified, automatically uses parallel tools when available"
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

