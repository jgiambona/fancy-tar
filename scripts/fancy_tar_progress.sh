#!/bin/bash
VERSION="1.8.5"

# Pre-scan for --debug flag to enable debug output as early as possible
for arg in "$@"; do
    if [[ "$arg" == "--debug" ]]; then
        DEBUG=1
        break
    fi
done

# Help function - must be defined before argument parsing
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
  echo "  --recipient <id>      Recipient ID for GPG public key encryption (can be specified multiple times)"
  echo "  --password <pass>     Password to use for encryption (if supported)"
  echo "  --key-file <file>     Read encryption password from file (if supported)"
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
  echo "  --manifest <format>   Generate a manifest file listing the contents of the archive. Formats:"
  echo "                       • tree: Hierarchical tree view (.txt)"
  echo "                       • text: Flat list of all files (.txt)"
  echo "                       • csv: CSV with columns: Path, Compressed Size, Uncompressed Size, Compression Ratio, File Type, Depth, Attributes, Timestamp (.csv)"
  echo "                       • csvhash: Like csv, but also includes a SHA256 hash per file (.csv)"
  echo "  --exclude <pattern>   Exclude files matching the pattern (can be used multiple times)"
  echo "  --include <pattern>   Include only files matching the pattern (can be used multiple times)"
  echo "  --files-from <file>   Read list of files to include from the specified file"
  echo "  --verbose             Show each file being processed with file count [001/234]"
  echo "  -f, --force           Automatically overwrite any existing output file or split parts without prompting"
  echo "  -h, --help            Show this help message"
  echo "  --version             Show version information"
  echo ""
  echo "Examples:"
  echo "  fancy-tar file1.txt file2.txt -o archive.tar.gz"
  echo "  fancy-tar --zip --password secret -o archive.zip folder/"
  echo "  fancy-tar --7z --compression=9 -o archive.7z large_folder/"
  echo "  fancy-tar --split-size=100M -o archive.tar.gz huge_folder/"
  echo "  fancy-tar --verify -o archive.tar.gz important_files/"
  echo "  fancy-tar --use=gzip -o archive.tar.gz files/"  # Force gzip instead of pigz"
  echo "  fancy-tar --manifest csvhash -o archive.tar.gz files/"  # Generate CSV with SHA256 hashes"
  echo ""
  echo "Note: When using --split-size, the archive will be split into multiple parts"
  echo "      with the specified size. For example, with --split-size=100M, a 500MB"
  echo "      archive would be split into 5 parts of 100MB each."
  exit 0
}

# Debug logging function
# Usage: debug_log "message"
debug_log() {
    if [ -n "$DEBUG" ]; then
        echo "DEBUG: $*" | tee -a /tmp/fancy_tar_debug.log
    fi
}

# Function to show commands being executed
# Usage: show_command "description" "command" [args...]
show_command() {
    local description="$1"
    shift
    local cmd=("$@")
    
    if [ -n "$DEBUG" ]; then
        echo "🔧 $description:"
        echo "   ${cmd[*]}"
        echo
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
        if [ "$force_overwrite" = true ]; then
            echo "--force specified: Overwriting all existing split parts..."
            rm -f $part_glob
        else
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
        show_command "Creating split ZIP archive" zip -s "$split_size" "$output" "${input_files[@]}"
        if zip -s "$split_size" "$output" "${input_files[@]}"; then
            split_success=true
        fi
    elif [[ "$output" == *.7z ]]; then
        show_command "Creating split 7z archive" 7z a -v"$split_size" "$output" "${input_files[@]}"
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
            show_command "Creating split tar archive with compression" tar -cf - "${input_files[@]}" "|" $compression_cmd "|" split -b "$split_size" - "$output."
            if tar -cf - "${input_files[@]}" | $compression_cmd | split -b "$split_size" - "$output."; then
                split_success=true
            fi
        else
            show_command "Creating split tar archive without compression" tar -cf - "${input_files[@]}" "|" split -b "$split_size" - "$output."
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
    # Add main file
    if [ -f "$output" ]; then
        parts+=("$output")
    fi
    # Add split parts based on archive type
    if [[ "$output" == *.7z ]]; then
        for f in "$output".???; do
            [[ "$f" =~ \.([0-9][0-9][0-9])$ ]] && parts+=("$f")
        done
    elif [[ "$output" == *.zip ]]; then
        for f in "$output".z??; do
            [[ "$f" =~ \.z[0-9][0-9]$ ]] && parts+=("$f")
        done
    else
        for f in "$output".[a-z][a-z]; do
            [[ "$f" =~ \.([a-z][a-z])$ ]] && parts+=("$f")
        done
    fi
    shopt -u nullglob
    for f in "${parts[@]}"; do
        size=$(ls -l "$f" 2>/dev/null | awk '{print $5}')
        if [ ! -s "$f" ]; then
            echo "   ⚠️  $f (empty!)"
        else
            echo "   $f ($(human_readable_size $size))"
        fi
    done
    # Write split parts file
    parts_file="${output}.parts.txt"
    : > "$parts_file"
    for f in "${parts[@]}"; do
        size=$(ls -l "$f" 2>/dev/null | awk '{print $5}')
        echo "$f $size" >> "$parts_file"
    done
    echo "ℹ️  Split parts list saved to: $parts_file"

    # If --hash is set, generate a SHA256 hash for each part
    if [ "$hash_output" = true ]; then
        parts_hash_file="${output}.parts.sha256"
        : > "$parts_hash_file"
        for f in "${parts[@]}"; do
            shasum -a 256 "$f" >> "$parts_hash_file"
        done
        echo "⚠️  SHA256 hashes for split parts saved to: $parts_hash_file"
        echo "⚠️  These hashes are for individual parts, not the reassembled archive. To verify the full archive, reassemble all parts and hash the combined file."
    fi

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

    # After split archive creation, if 7z and --verify, run 7z t on the first part:
    if [[ "$output" == *.7z ]] && [ "$verify" = true ]; then
        first_part="${output}.001"
        if [ -f "$first_part" ]; then
            echo "🔍 Verifying 7z split archive using: 7z t $first_part"
            if 7z t "$first_part"; then
                echo "✅ 7z split archive verified successfully."
            else
                echo "❌ 7z split archive verification failed."
            fi
        fi
    fi

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
key_file=""
verify=false
split_size=""
compression_level="5"  # Default 7z compression level (0-9)
force_compression_tool=""  # User-specified compression tool
gzip=true             # Enable compression by default
encrypt_method=""
hash_output=false
open_after=false
compression_tool=""  # Will be set after argument parsing
force_overwrite=false
manifest_format=""

# Set no_prompt to true by default in non-interactive mode
if [ ! -t 0 ]; then
    no_prompt=true
else
    no_prompt=false
fi

# Store terminal settings for password prompts
stty_settings=""

# Manifest generation function and helpers
write_manifest() {
    local archive="$1"
    local format="$2"
    local manifest_file="$3"
    local split_parts_file="${archive}.parts.txt"
    local split_info=""
    local files=()
    local tempdir
    tempdir=$(mktemp -d)

    # Extract file list depending on archive type
    if [[ "$archive" == *.zip ]]; then
        unzip -l "$archive" > "$tempdir/list.txt"
        files=( $(awk 'NR>3 {print $4}' "$tempdir/list.txt" | sed '/^$/d' | head -n -2) )
    elif [[ "$archive" == *.7z ]]; then
        7z l "$archive" > "$tempdir/list.txt"
        files=( $(awk '/^----/{p=1;next}/^----/{p=0}p{print $6}' "$tempdir/list.txt" | sed '/^$/d') )
    else
        tar -tf "$archive" > "$tempdir/list.txt"
        files=()
        while IFS= read -r line; do
            files+=("$line")
        done < "$tempdir/list.txt"
    fi

    # Helper to get file type and depth
    get_file_type() {
        local f="$1"
        if [[ "$archive" == *.zip ]]; then
            # No direct way, guess by trailing slash
            [[ "$f" == */ ]] && echo "directory" || echo "file"
        elif [[ "$archive" == *.7z ]]; then
            # No direct way, guess by trailing slash
            [[ "$f" == */ ]] && echo "directory" || echo "file"
        else
            # Use tar -tvf for type
            local info=$(tar -tvf "$archive" "$f" 2>/dev/null | head -n1)
            [[ "$info" =~ ^d ]] && echo "directory" || ([[ "$info" =~ ^l ]] && echo "symlink" || echo "file")
        fi
    }
    get_depth() {
        local f="$1"
        awk -F'/' '{print NF-1}' <<< "$f"
    }

    # Function to get SHA256 hash using the first available tool
    get_sha256() {
        if command -v sha256sum >/dev/null 2>&1; then
            sha256sum | awk '{print $1}'
        elif command -v shasum >/dev/null 2>&1; then
            shasum -a 256 | awk '{print $1}'
        elif command -v openssl >/dev/null 2>&1; then
            openssl dgst -sha256 | awk '{print $2}'
        else
            echo "NO_HASH_TOOL_FOUND"
        fi
    }

    # CSV and CSVHASH
    if [[ "$format" == "csv" || "$format" == "csvhash" ]]; then
        local header="Path,Compressed Size,Uncompressed Size,Compression Ratio,File Type,Depth,Attributes,Timestamp"
        [[ "$format" == "csvhash" ]] && header="$header,SHA256"
        echo "$header" > "$manifest_file"
        for f in "${files[@]}"; do
            local type=$(get_file_type "$f")
            local depth=$(get_depth "$f")
            local attr date time usize csize ratio sha256
            if [[ "$archive" == *.zip ]]; then
                local line=$(unzip -l "$archive" | awk -v file="$f" '$4==file {print $0}')
                usize=$(echo "$line" | awk '{print $1}')
                date=$(echo "$line" | awk '{print $2}')
                time=$(echo "$line" | awk '{print $3}')
                csize="N/A"; ratio="N/A"; attr="N/A"
            elif [[ "$archive" == *.7z ]]; then
                local line=$(7z l "$archive" | awk '/^----/{p=1;next}/^----/{p=0}p && $6==f' f="$f" )
                date=$(echo "$line" | awk '{print $1}')
                time=$(echo "$line" | awk '{print $2}')
                attr=$(echo "$line" | awk '{print $3}')
                usize=$(echo "$line" | awk '{print $4}')
                csize=$(echo "$line" | awk '{print $5}')
                ratio="N/A"; [[ "$usize" != "0" && "$usize" != "" && "$csize" != "" ]] && ratio=$(awk -v c="$csize" -v u="$usize" 'BEGIN{if(u>0){printf "%.2f", c/u}else{print "N/A"}}')
            else
                local line=$(tar -tvf "$archive" "$f" 2>/dev/null | head -n1)
                attr=$(echo "$line" | awk '{print $1}')
                usize=$(echo "$line" | awk '{print $5}')
                date=$(echo "$line" | awk '{print $6 " " $7 " " $8}')
                # Extract filename robustly (handles spaces)
                filename=$(echo "$line" | awk '{for(i=9;i<=NF;++i) printf $i (i<NF?" ":"\\n")}')
                csize="N/A"; ratio="N/A"
            fi
            # Replace commas in attr with semicolons
            attr=$(echo "$attr" | tr ',' ';')
            if [[ "$format" == "csvhash" ]]; then
                if [[ "$archive" == *.zip ]]; then
                    sha256=$(unzip -p "$archive" "$f" 2>/dev/null | get_sha256)
                elif [[ "$archive" == *.7z ]]; then
                    sha256=$(7z e "$archive" "$f" -so 2>/dev/null | get_sha256)
                else
                    sha256=$(tar -xOf "$archive" "$f" 2>/dev/null | get_sha256)
                fi
            fi

            # Use robust filename for tar, otherwise $f
            if [[ "$archive" == *.tar* || "$archive" == *.tgz || "$archive" == *.tar.gz ]]; then
                row="$filename,$csize,$usize,$ratio,$type,$depth,$attr,$date"
            else
                row="$f,$csize,$usize,$ratio,$type,$depth,$attr,$date $time"
            fi

            [[ "$format" == "csvhash" ]] && row="$row,$sha256"
            echo "$row" >> "$manifest_file"
        done
    elif [[ "$format" == "tree" ]]; then
        echo "Archive Tree View:" > "$manifest_file"
        for f in "${files[@]}"; do
            indent=$(echo "$f" | awk -F'/' '{print NF-1}')
            printf '%*s' $((indent*2)) '' >> "$manifest_file"
            echo "- $(basename "$f")" >> "$manifest_file"
        done
        echo >> "$manifest_file"
        echo "(Compressed/uncompressed sizes not shown in tree view)" >> "$manifest_file"
    else
        echo "Archive File List:" > "$manifest_file"
        for f in "${files[@]}"; do
            echo "$f" >> "$manifest_file"
        done
        echo >> "$manifest_file"
        echo "(Compressed/uncompressed sizes not shown in text view)" >> "$manifest_file"
    fi

    if [ -f "$split_parts_file" ]; then
        echo >> "$manifest_file"
        echo "Split archive parts:" >> "$manifest_file"
        cat "$split_parts_file" >> "$manifest_file"
        echo >> "$manifest_file"
        echo "To reassemble: cat ${archive}* > combined && [extract as usual]" >> "$manifest_file"
    fi
    rm -rf "$tempdir"
}

# Add variable for print-filename flag
declare print_filename=false

# File selection variables
exclude_patterns=()
include_patterns=()
files_from=""

# Parse command line arguments
recipients=()
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
        --key-file)
            if [[ -z "$2" || "$2" == -* ]]; then
                echo "Error: --key-file requires a file path"
                exit 1
            fi
            key_file="$2"
            shift 2
            ;;
        --key-file=*)
            key_file="${1#*=}"
            shift
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
            if [[ -z "$2" || "$2" == -* ]]; then
                echo "Error: --recipient requires a value"
                exit 1
            fi
            recipients+=("$2")
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
        --force|-f)
            force_overwrite=true
            shift
            ;;
        -h|--help)
            show_help
            ;;
        --debug)
            DEBUG=1
            shift
            ;;
        --manifest)
            manifest_format="$2"
            shift 2
            ;;
        --print-filename)
            print_filename=true
            shift
            ;;
        --verbose)
            verbose=true
            shift
            ;;
        --exclude)
            if [[ -z "$2" || "$2" == -* ]]; then
                echo "Error: --exclude requires a pattern"
                exit 1
            fi
            exclude_patterns+=("$2")
            shift 2
            ;;
        --exclude=*)
            exclude_patterns+=("${1#*=}")
            shift
            ;;
        --include)
            if [[ -z "$2" || "$2" == -* ]]; then
                echo "Error: --include requires a pattern"
                exit 1
            fi
            include_patterns+=("$2")
            shift 2
            ;;
        --include=*)
            include_patterns+=("${1#*=}")
            shift
            ;;
        --files-from)
            if [[ -z "$2" || "$2" == -* ]]; then
                echo "Error: --files-from requires a file path"
                exit 1
            fi
            files_from="$2"
            shift 2
            ;;
        --files-from=*)
            files_from="${1#*=}"
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
    if [ ${#input_files[@]} -eq 1 ]; then
        input_name="${input_files[0]}"
        # Remove trailing slash for directories
        input_name="${input_name%/}"
        if [ -d "$input_name" ]; then
            # Directory: use full directory name (even if it contains dots)
            base_name="$(basename "$input_name")"
            # Handle special case where basename returns "." (current directory)
            if [ "$base_name" = "." ]; then
                base_name="$(basename "$(pwd)")"
            fi
        else
            # File or symlink
            file_base="$(basename "$input_name")"
            if [[ "$file_base" == .* && "$file_base" != *.* ]]; then
                # Hidden file with no extension: use full name
                base_name="$file_base"
            elif [[ "$file_base" == .* && "$file_base" == *.* ]]; then
                # Hidden file with extension: use full name
                base_name="$file_base"
            elif [[ "$file_base" == *.* ]]; then
                # Regular file with extension(s): strip only the last extension
                base_name="${file_base%.*}"
            else
                # Regular file with no extension
                base_name="$file_base"
            fi
        fi
        if [ "$use_7z" = true ]; then
            output="${base_name}.7z"
        elif [ "$use_zip" = true ]; then
            output="${base_name}.zip"
        else
            case "$compression_tool" in
                pigz|gzip) output="${base_name}.tar.gz" ;;
                bzip2|pbzip2|lbzip2) output="${base_name}.tar.bz2" ;;
                xz|pxz) output="${base_name}.tar.xz" ;;
                "") output="${base_name}.tar" ;;
                *) output="${base_name}.tar" ;;
            esac
        fi
        echo "ℹ️  No output file specified, using '$output' as the archive name."
    else
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
    local formatted
    
    # Use bc for floating point arithmetic
    size=$bytes
    while [ $(echo "$size >= $base" | bc -l) -eq 1 ] && [ $unit -lt $((${#units[@]} - 1)) ]; do
        size=$(echo "scale=$precision; $size / $base" | bc -l)
        unit=$((unit + 1))
    done
    
    # Sanitize $size to ensure it's a valid float
    size=$(echo "$size" | awk '{printf "%f", $0}')
    
    # Format with exactly one decimal place for consistency with Finder
    if [ $unit -gt 0 ]; then
        # Force one decimal place for units larger than bytes
        formatted=$(awk -v val="$size" 'BEGIN {printf "%.1f", val}')
    else
        # For bytes, show as integer
        formatted=$(awk -v val="$size" 'BEGIN {printf "%d", val}')
    fi
    
    echo "${formatted}${units[$unit]}"
}

# Function to calculate total size using ls for accuracy
calculate_total_size() {
    local total=0
    for file in "${FILTERED_FILES[@]}"; do
        # For filtered files, use ls directly since they're already individual files
        size=$(ls -l "$file" 2>/dev/null | awk '{print $5}')
        total=$((total + size))
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

# Function to filter files based on --exclude, --include, and --files-from patterns
filter_files() {
    local input_files=("$@")
    local filtered_files=()
    local temp_dir
    temp_dir=$(mktemp -d)
    
    # Create a temporary file to store all candidate files
    local all_files_list="$temp_dir/all_files.txt"
    : > "$all_files_list"
    
    # Get current directory for path conversion
    local current_dir=$(pwd)
    
    # Collect all files from input sources
    for source in "${input_files[@]}"; do
        # For path resolution, we need to handle both relative and absolute paths
        # but preserve the original path structure for tar
        local resolved_source=""
        local original_source="$source"
        
        # Resolve the path for existence checks, but preserve original for tar
        if command -v realpath >/dev/null 2>&1; then
            resolved_source=$(realpath "$source")
        else
            # Fallback: resolve relative paths properly
            if [[ "$source" == /* ]]; then
                # Already absolute
                resolved_source="$source"
            else
                # Convert to absolute for existence check
                resolved_source="$(pwd)/$source"
            fi
        fi
        
        if [ -d "$resolved_source" ]; then
            if [ "$no_recurse" = true ]; then
                # Only files in current directory
                find "$resolved_source" -maxdepth 1 -type f | while read -r file; do
                    # Convert absolute path to relative path
                    if [[ "$file" == "$current_dir"/* ]]; then
                        echo "${file#$current_dir/}" >> "$all_files_list"
                    else
                        echo "$file" >> "$all_files_list"
                    fi
                done
            else
                # All files recursively
                find "$resolved_source" -type f | while read -r file; do
                    # Convert absolute path to relative path
                    if [[ "$file" == "$current_dir"/* ]]; then
                        echo "${file#$current_dir/}" >> "$all_files_list"
                    else
                        echo "$file" >> "$all_files_list"
                    fi
                done
            fi
        else
            # Single file - use the original source path for tar
            echo "$original_source" >> "$all_files_list"
        fi
    done
    
    # If --files-from is specified, use that instead of input files
    if [ -n "$files_from" ]; then
        if [ ! -f "$files_from" ]; then
            echo "Error: File list '$files_from' does not exist"
            rm -rf "$temp_dir"
            return 1
        fi
        
        # Create a new list from the files-from file
        : > "$all_files_list"
        while IFS= read -r line; do
            # Skip blank lines and comments
            [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
            
            # Expand glob patterns if any
            if [[ "$line" == *"*"* || "$line" == *"?"* ]]; then
                # Handle glob patterns
                for file in $line; do
                    if [ -f "$file" ]; then
                        # Use the original file path as provided
                        echo "$file" >> "$all_files_list"
                    fi
                done
            else
                # Direct file path
                if [ -f "$line" ]; then
                    # Use the original file path as provided
                    echo "$line" >> "$all_files_list"
                fi
            fi
        done < "$files_from"
    fi
    
    # Apply --exclude patterns
    if [ ${#exclude_patterns[@]} -gt 0 ]; then
        local exclude_list="$temp_dir/exclude_list.txt"
        : > "$exclude_list"
        
        for pattern in "${exclude_patterns[@]}"; do
            echo "$pattern" >> "$exclude_list"
        done
        
        # Filter out excluded files
        local temp_list="$temp_dir/temp_list.txt"
        : > "$temp_list"
        
        while IFS= read -r file; do
            local excluded=false
            while IFS= read -r pattern; do
                # Use glob matching for exclude
                if [[ $(basename "$file") == $pattern ]]; then
                    excluded=true
                    break
                fi
            done < "$exclude_list"
            if [ "$excluded" = false ]; then
                echo "$file" >> "$temp_list"
            fi
        done < "$all_files_list"
        
        mv "$temp_list" "$all_files_list"
    fi
    
    # Apply --include patterns (if specified, only include matching files)
    if [ ${#include_patterns[@]} -gt 0 ]; then
        local include_list="$temp_dir/include_list.txt"
        : > "$include_list"
        
        for pattern in "${include_patterns[@]}"; do
            echo "$pattern" >> "$include_list"
        done
        
        # Filter to only included files
        local temp_list="$temp_dir/temp_list.txt"
        : > "$temp_list"
        
        while IFS= read -r file; do
            local included=false
            while IFS= read -r pattern; do
                # Use glob matching for include
                if [[ $(basename "$file") == $pattern ]]; then
                    included=true
                    break
                fi
            done < "$include_list"
            if [ "$included" = true ]; then
                echo "$file" >> "$temp_list"
            fi
        done < "$all_files_list"
        
        mv "$temp_list" "$all_files_list"
    fi
    
    # Read filtered files into array
    while IFS= read -r file; do
        if [ -n "$file" ]; then
            filtered_files+=("$file")
        fi
    done < "$all_files_list"
    
    # Clean up
    rm -rf "$temp_dir"
    
    # Return filtered files via global variable
    FILTERED_FILES=("${filtered_files[@]}")
    
    if [ -n "$DEBUG" ]; then
        echo "Debug: Filtered files (${#filtered_files[@]}):"
        for file in "${filtered_files[@]}"; do
            echo "Debug:   - $file"
        done
    fi
}

# Function to create archive
create_archive() {
    local output="$1"
    local compression="$2"
    local no_recurse="$3"
    shift 3  # Remove the first three arguments
    local filtered_files=("$@")  # Remaining arguments are filtered files
    
    if [ -n "$DEBUG" ]; then
        echo "Debug: create_archive received ${#filtered_files[@]} files:"
        for file in "${filtered_files[@]}"; do
            echo "Debug:   - $file"
        done
    fi
    
    # Get total size for progress indicator
    local total_size=0
    for file in "${filtered_files[@]}"; do
        size=$(ls -l "$file" 2>/dev/null | awk '{print $5}')
        total_size=$((total_size + size))
    done
    
    # Build the base tar command
    local tar_args=("-c")
    local file_counter=0
    local total_files=${#filtered_files[@]}

    # Add all filtered files to tar command
    for file in "${filtered_files[@]}"; do
        file_counter=$((file_counter + 1))
        
        if [ "$verbose" = true ]; then
            printf "[%03d/%03d] Processing: %s (%s)\n" "$file_counter" "$total_files" "$(basename "$file")" "$(human_readable_size $(ls -l "$file" 2>/dev/null | awk '{print $5}'))"
        fi
        
        if [ -n "$DEBUG" ]; then
            echo "Debug: Adding to tar command: $file"
        fi
        
        # Add file to tar command array
        tar_args+=("$file")
    done
    
    if [ -n "$DEBUG" ]; then
        echo "Debug: Final tar command: tar ${tar_args[*]}"
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
            show_command "Creating tar archive with compression and progress" "tar" "${tar_args[@]}" "|" pv -s "$total_size" "|" "$compression_tool" ">" "$output"
            if [ -n "$DEBUG" ]; then
                echo "Debug: executing: tar ${tar_args[*]} | pv -s $total_size | $compression_tool > $output" >&2
            fi
            tar "${tar_args[@]}" | pv -s "$total_size" | "$compression_tool" > "$output" &
        else
            # No compression
            show_command "Creating tar archive with progress" "tar" "${tar_args[@]}" "|" pv -s "$total_size" ">" "$output"
            if [ -n "$DEBUG" ]; then
                echo "Debug: executing: tar ${tar_args[*]} | pv -s $total_size > $output" >&2
            fi
            tar "${tar_args[@]}" | pv -s "$total_size" > "$output" &
        fi
        archive_pid=$!
    else
        # Fall back to regular tar with appropriate compression
        if [ -n "$compression_tool" ]; then
            case "$compression_tool" in
                bzip2|pbzip2|lbzip2)
                    tar_args+=("-j")
                    ;;
                xz|pxz)
                    tar_args+=("-J")
                    ;;
                pigz|gzip)
                    tar_args+=("-z")
                    ;;
            esac
        fi
        
        # Add output file
        tar_args+=("-f" "$output")
        
        show_command "Creating tar archive" "tar" "${tar_args[@]}"
        if [ -n "$DEBUG" ]; then
            echo "Debug: executing: tar ${tar_args[*]}" >&2
        fi
        tar "${tar_args[@]}" &
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

# Apply file filtering for all archive types
filter_files "${input_files[@]}"
if [ $? -ne 0 ]; then
    echo "Error: File filtering failed"
    exit 1
fi

# Use filtered files for all operations
if [ ${#FILTERED_FILES[@]} -eq 0 ]; then
    echo "Error: No files match the specified patterns."
    exit 1
fi

# Calculate total size and file count using filtered files
total_size=$(calculate_total_size)
file_count=0
if [ -n "$DEBUG" ]; then
    echo "Debug: Calculating file count..."
fi
for file in "${FILTERED_FILES[@]}"; do
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

# Function to read password from key file
read_key_file() {
    local file="$1"
    if [ ! -f "$file" ]; then
        echo "Error: Key file '$file' does not exist"
        exit 1
    fi
    if [ ! -r "$file" ]; then
        echo "Error: Key file '$file' is not readable"
        exit 1
    fi
    # Read the first line and strip whitespace
    password=$(head -n 1 "$file" | tr -d '\r\n\t ')
    if [ -z "$password" ]; then
        echo "Error: Key file '$file' is empty or contains only whitespace"
        exit 1
    fi
    echo "🔑 Using password from key file: $file"
}

# Handle key file if specified
if [ -n "$key_file" ]; then
    if [ -n "$password" ]; then
        echo "Warning: Both --password and --key-file specified, using key file"
    fi
    read_key_file "$key_file"
fi

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
    # Gather all associated files: main output, split parts, and metadata
    part_glob="$output*"
    found_parts=( )
    shopt -s nullglob
    for f in $part_glob; do
        # Only match real split parts and metadata, not unrelated files
        if [[ "$f" == "$output" || "$f" =~ \.(aa|ab|ac|ad|ae|af|ag|ah|ai|aj|ak|al|am|an|ao|ap|aq|ar|as|at|au|av|aw|ax|ay|az|ba|bb|bc|bd|be|bf|bg|bh|bi|bj|bk|bl|bm|bn|bo|bp|bq|br|bs|bt|bu|bv|bw|bx|by|bz|z[0-9][0-9]|[0-9][0-9][0-9])$ || "$f" == "${output}.parts.txt" || "$f" == "${output}.parts.sha256" || "$f" == "${output}.sha256" ]]; then
            found_parts+=("$f")
        fi
    done
    shopt -u nullglob
    if [ "$force_overwrite" = true ]; then
        echo "--force specified: Overwriting existing file(s): ${found_parts[*]}"
        rm -f "${found_parts[@]}"
    elif [ "$no_prompt" = true ]; then
        # In non-interactive mode, automatically rename
        output=$(get_next_filename "$output")
        echo "⚠️  Output file exists, using: $output"
    else
        echo "⚠️  Output file '$output' or associated split parts already exist."
        if [ ${#found_parts[@]} -gt 1 ]; then
            echo "    The following files will be affected:"
            for f in "${found_parts[@]}"; do
                echo "    $f"
            done
        fi
        echo "    Choose an action:"
        echo "    [O]verwrite all"
        echo "    [R]ename automatically (default)"
        echo "    [C]ancel"
        read -r -t 30 choice || choice="r"  # Default to rename after 30 seconds
        choice=$(echo "$choice" | tr '[:upper:]' '[:lower:]')
        case "$choice" in
            o|overwrite)
                echo "Overwriting existing file(s)..."
                rm -f "${found_parts[@]}"
                ;;
            r|rename|"")
                output=$(get_next_filename "$output")
                echo "Using new filename: $output"
                ;;
            c|cancel)
                echo "Operation cancelled."
                exit 0
                ;;
            *)
                output=$(get_next_filename "$output")
                echo "Invalid choice. Using new filename: $output"
                ;;
        esac
    fi
fi

# Show tree view if requested
if [ "$show_tree" = true ]; then
    echo "📂 File structure:"
    for file in "${FILTERED_FILES[@]}"; do
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
    create_split_archive "$output" "$split_size" "${FILTERED_FILES[@]}" > "$split_output_file" &
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
    cmd_7z=(7z a -mx="$compression_level" "$output" "${FILTERED_FILES[@]}")
    if [ -n "$password" ]; then
        cmd_7z=(7z a -p"$password" -mx="$compression_level" "$output" "${FILTERED_FILES[@]}")
    fi
    show_command "Creating 7z archive" "${cmd_7z[@]}"
    debug_log "7z command: ${cmd_7z[*]} > $sevenz_log 2>&1 &"
    "${cmd_7z[@]}" > "$sevenz_log" 2>&1 &
    archive_pid=$!
    debug_log "7z started with archive_pid: $archive_pid"
    spinner_with_timer "$archive_pid" "Compressing with 7z..."
    end_time=$(date +%s.%N)
elif [ "$use_zip" = true ]; then
    start_time=$(date +%s.%N)
    debug_log "Launching zip with parent PID: $$"
    if [ -n "$password" ]; then
        cmd_zip=(zip -e -P "$password" "$output" "${FILTERED_FILES[@]}")
    else
        cmd_zip=(zip "$output" "${FILTERED_FILES[@]}")
    fi
    show_command "Creating ZIP archive" "${cmd_zip[@]}"
    debug_log "zip command: ${cmd_zip[*]} > $zip_log 2>&1 &"
    "${cmd_zip[@]}" > "$zip_log" 2>&1 &
    archive_pid=$!
    debug_log "zip started with archive_pid: $archive_pid"
    spinner_with_timer "$archive_pid" "Compressing with zip..."
    end_time=$(date +%s.%N)
else
    create_archive "$output" "$compression_tool" "$no_recurse" "${FILTERED_FILES[@]}"
    archive_status=$?
fi

# Only wait if archive_pid is set (i.e., for backgrounded cases)
if [ -n "$archive_pid" ]; then
    wait $archive_pid
    archive_status=$?
fi

# Clean up progress monitoring
cleanup_progress

# Move manifest generation to after archive creation but before encryption
if [ "${archive_status:-1}" -eq 0 ]; then
    # Get final archive size using ls for more accurate size
    archive_size=$(ls -l "$output" 2>/dev/null | awk '{print $5}')
    archive_size_human=$(human_readable_size $archive_size)

    # Generate manifest if requested (before encryption)
    if [ -n "$manifest_format" ]; then
        case "$manifest_format" in
            tree|text)
                manifest_ext="txt" ;;
            csv|csvhash)
                manifest_ext="csv" ;;
            *)
                manifest_ext="txt" ;;
        esac
        manifest_file="${output}.${manifest_ext}"
        write_manifest "$output" "$manifest_format" "$manifest_file"
        echo "Manifest written to $manifest_file"
    fi

    # Verify archive if requested (before encryption, except for 7z)
    if [ "$verify" = true ] && [ "$use_7z" != true ]; then
        if [ -n "$split_size" ]; then
            echo "⚠️  Verification skipped: Archive was split into multiple parts."
            echo "   To verify integrity, first reassemble all parts (e.g., cat $output* > combined.tar.gz) and then run:"
            echo "   gzip -t combined.tar.gz   or   tar -tf combined.tar.gz"
        else
            show_command "Verifying archive" verify_archive "$output"
            verify_archive "$output"
        fi
    fi

    # Handle encryption if requested
    if [ -n "$encrypt_method" ]; then
        echo "🔒 Encrypting archive..."
        if [ "$encrypt_method" = "gpg" ]; then
            # Store original output name
            original_output="$output"
            # Determine final GPG output name
            if [[ "$output" == *.gpg ]]; then
                # Output already has .gpg extension, use as-is
                gpg_output="$output"
                # Create temporary name for the archive before encryption
                temp_output="${output%.gpg}.tmp"
                # Move the archive to temporary name
                mv "$output" "$temp_output"
                original_output="$temp_output"
            else
                # Add .gpg extension
                gpg_output="${output}.gpg"
            fi
            
            if [ ${#recipients[@]} -gt 0 ]; then
                # Public key encryption (multiple recipients supported)
                gpg_args=(--encrypt)
                for r in "${recipients[@]}"; do
                    gpg_args+=(--recipient "$r")
                done
                gpg_args+=(--output "$gpg_output" "$original_output")
                show_command "Encrypting with GPG public key(s)" gpg "${gpg_args[@]}"
                # shellcheck disable=SC2068
                if ! eval gpg ${gpg_args[@]}; then
                    echo "Error: Failed to encrypt with GPG public key(s)"
                    exit 1
                fi
                # Remove original file
                rm "$original_output"
                # Update output variable to final name
                output="$gpg_output"
            else
                # Symmetric encryption
                if [ -z "$password" ]; then
                    prompt_password
                fi
                show_command "Encrypting with GPG symmetric" gpg --symmetric --cipher-algo AES256 --batch --passphrase "$password" --output "$gpg_output" "$original_output"
                if ! gpg --symmetric --cipher-algo AES256 --batch --passphrase "$password" --output "$gpg_output" "$original_output"; then
                    echo "Error: Failed to encrypt with GPG"
                    exit 1
                fi
                # Remove original file
                rm "$original_output"
                # Update output variable to final name
                output="$gpg_output"
            fi
        elif [ "$encrypt_method" = "openssl" ]; then
            if [ -z "$password" ]; then
                prompt_password
            fi
            show_command "Encrypting with OpenSSL" openssl enc -aes-256-cbc -salt -pbkdf2 -in "$output" -out "${output}.enc" -pass pass:"$password"
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
            show_command "Verifying 7z archive with password" 7z t -p"$password" "$output"
            7z t -p"$password" "$output"
        else
            show_command "Verifying 7z archive" verify_archive "$output"
            verify_archive "$output"
        fi
    fi

    # Generate hash if requested
    if [ "$hash_output" = true ]; then
        show_command "Generating SHA256 hash" shasum -a 256 "$output" ">" "$output.sha256"
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

    # After archive creation and all processing, before exit 0:
    if [ "$print_filename" = true ]; then
        if [ -n "$split_size" ]; then
            # Output all split part filenames, one per line
            parts_file="${output}.parts.txt"
            if [ -f "$parts_file" ]; then
                awk '{print $1}' "$parts_file"
            else
                # Fallback: try to glob
                for f in "$output"*; do
                    [ -f "$f" ] && echo "$f"
                done
            fi
        else
            echo "$output"
        fi
        exit 0
    fi

    exit 0
else
    echo "❌ Compression failed."
    rm -f "$output"
    exit 1
fi

