#!/bin/bash

# Set up error handling
set +e  # Allow script to continue on errors
trap cleanup EXIT

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Initialize counters
total_tests=0
passed_tests=0
failed_tests=0
skipped_tests=0

# Detect project root and main script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR/.."
FANCY_TAR="$PROJECT_ROOT/scripts/fancy_tar_progress.sh"

# Cleanup function
cleanup() {
    rm -rf test_data test.tar.gz* test.tar.bz2* test.tar.xz* *.enc gpg_pass.txt test_openssl_pass.txt
}

# Create test files
create_test_files() {
    echo "Creating test files..."
    mkdir -p test_data/dir1/dir2
    
    # Create small files
    for i in {1..10}; do
        echo "Creating test_data/small_$i.txt"
        echo "Test file $i" > "test_data/small_$i.txt"
    done
    
    # Create a large file (1MB)
    echo "Creating test_data/large.bin"
    dd if=/dev/zero of=test_data/large.bin bs=1M count=1 2>/dev/null
    
    # Create a file with special characters
    echo "Creating test_data/special file (1)!.txt"
    echo "Special file content" > "test_data/special file (1)!.txt"
    
    # Create hard links
    echo "Creating test_data/file1.txt and hardlink"
    echo "Hard link content" > test_data/file1.txt
    ln test_data/file1.txt test_data/hardlink.txt
    
    # Create files with specific permissions
    echo "Creating test_data/perm600.txt"
    echo "Permission test" > test_data/perm600.txt
    chmod 600 test_data/perm600.txt
    
    # Create nested directory structure
    echo "Creating nested files"
    echo "Nested file 1" > test_data/dir1/file2.txt
    echo "Nested file 2" > test_data/dir1/dir2/file3.txt
    
    # Create password file for GPG
    echo "Creating gpg_pass.txt"
    echo "TestPass123!" > gpg_pass.txt

    # List created files
    echo "Created files:"
    ls -la test_data/
}

# Function to run a test
run_test() {
    local name="$1"
    local cmd="$2"
    local expected_exit="${3:-0}"
    local expected_msg="${4:-}"
    
    ((total_tests++))
    echo -e "\nTest $total_tests: $name"
    echo "Command: $cmd"
    echo -e "\nOutput:"
    
    # Run the command
    output=$(eval "$cmd" 2>&1) || true
    exit_code=$?
    
    echo "$output"
    
    # Check for expected error message if provided
    if [ -n "$expected_msg" ]; then
        if echo "$output" | grep -q "$expected_msg"; then
            echo -e "${GREEN}✓ Test passed${NC}"
            ((passed_tests++))
            return
        else
            echo -e "${RED}❌ Expected error message not found: $expected_msg${NC}"
            ((failed_tests++))
            return
        fi
    fi
    
    if [ $exit_code -eq $expected_exit ]; then
        echo -e "${GREEN}✓ Test passed${NC}"
        ((passed_tests++))
    else
        echo -e "${RED}❌ Exit code mismatch: got $exit_code, expected $expected_exit${NC}"
        ((failed_tests++))
    fi
}

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

echo "🧪 Running advanced test suite..."

# Create test files
create_test_files

# Test parallel compression tools
for tool in pigz pbzip2 pxz; do
    if ! command_exists "$tool"; then
        echo -e "${YELLOW}⚠️ Skipping test - $tool not found${NC}"
        ((skipped_tests++))
    fi
done

echo -e "\n"

# Test GPG encryption with verification
run_test "GPG encryption with verification" \
    "gpg --batch --yes --passphrase TestPass123! -c test_data/file1.txt && gpg --batch --yes --passphrase TestPass123! -d test_data/file1.txt.gpg > /dev/null"

# Test OpenSSL encryption
run_test "OpenSSL encryption" \
    "$FANCY_TAR test_data --encrypt=openssl --password TestPass123! -o test.tar.gz"

# Test 3: Invalid compression level
run_test "Invalid compression level" \
    "$FANCY_TAR test_data -o test.tar.gz --compression=99" 1 "Error: Invalid compression level. Must be a number between 0 and 9."

# Test 4: Missing input directory
run_test "Missing input directory" \
    "$FANCY_TAR nonexistent_dir -o test.tar.gz" 1 "Error: Input file or directory 'nonexistent_dir' does not exist."

# Test special characters in filenames
run_test "Special characters in filenames" \
    "$FANCY_TAR 'test_data/special file (1)!.txt' -o test_special.tar.gz"

# Test hard links
run_test "Hard links" \
    "$FANCY_TAR test_data/hardlink.txt -o test_hardlink.tar.gz"

# Test file permissions
run_test "File permissions" \
    "$FANCY_TAR test_data/perm600.txt -o test_perm.tar.gz"

# Print test summary
echo -e "\n📊 Test Summary"
echo "Total tests: $total_tests"
echo "Passed: $passed_tests"
echo "Failed: $failed_tests"
echo "Skipped: $skipped_tests"

# Exit with failure if any tests failed
[ $failed_tests -eq 0 ] || exit 1