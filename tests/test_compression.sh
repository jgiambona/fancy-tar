#!/bin/bash

# Create test directory and files
mkdir -p test_dir
echo "Test file 1" > test_dir/file1.txt
echo "Test file 2" > test_dir/file2.txt
mkdir -p test_dir/subdir
echo "Test file 3" > test_dir/subdir/file3.txt

# Cleanup function
cleanup() {
    rm -rf test_dir
    rm -f test.tar.gz test.tar.bz2 test.tar.xz test.zip test.7z
    rm -f test_no_recurse.tar.gz test_verify.tar.gz
    rm -f *.gpg *.enc
}

# Set up trap to clean up on exit
trap cleanup EXIT

# Helper function to run test and check result
run_test() {
    local test_name="$1"
    local command="$2"
    local expected_exit="$3"
    local expected_output="$4"
    
    echo "Running test: $test_name"
    echo "Command: $command"
    
    output=$(eval "$command" 2>&1)
    exit_code=$?
    
    if [ $exit_code -ne $expected_exit ]; then
        echo "❌ Test failed: $test_name"
        echo "Expected exit code: $expected_exit"
        echo "Actual exit code: $exit_code"
        echo "Output:"
        echo "$output"
        return 1
    fi
    
    if [ -n "$expected_output" ] && [[ ! "$output" =~ $expected_output ]]; then
        echo "❌ Test failed: $test_name"
        echo "Expected output to contain: $expected_output"
        echo "Actual output:"
        echo "$output"
        return 1
    fi
    
    echo "✅ Test passed: $test_name"
    return 0
}

# Test 1: Version check
run_test "Version check" \
    "./scripts/fancy_tar_progress.sh --version" \
    0 \
    "fancy-tar"

# Test 2: Basic tar.gz creation
run_test "Basic tar.gz creation" \
    "./scripts/fancy_tar_progress.sh test_dir -o test.tar.gz" \
    0 \
    "Archiving files"

# Test 3: Gzip compression level
run_test "Gzip compression level" \
    "./scripts/fancy_tar_progress.sh test_dir -o test.tar.gz --compression=9" \
    0 \
    "Archiving files"

# Test 4: Bzip2 compression
run_test "Bzip2 compression" \
    "./scripts/fancy_tar_progress.sh test_dir -o test.tar.bz2" \
    0 \
    "Archiving files"

# Test 5: XZ compression
run_test "XZ compression" \
    "./scripts/fancy_tar_progress.sh test_dir -o test.tar.xz" \
    0 \
    "Archiving files"

# Test 6: 7z creation
run_test "7z creation" \
    "./scripts/fancy_tar_progress.sh test_dir --7z --debug" \
    0 \
    "Archiving files"

# Test 7: GPG encryption
run_test "GPG encryption" \
    "./scripts/fancy_tar_progress.sh test_dir --encrypt=gpg --password test" \
    0 \
    "Archiving files"

# Test 8: OpenSSL encryption
run_test "OpenSSL encryption" \
    "./scripts/fancy_tar_progress.sh test_dir --encrypt=openssl --password test" \
    0 \
    "Archiving files"

# Test 9: Tree view
run_test "Tree view" \
    "./scripts/fancy_tar_progress.sh test_dir --tree" \
    0 \
    "Archiving files"

# Test 10: No recursion
run_test "No recursion" \
    "./scripts/fancy_tar_progress.sh test_dir --no-recursion -o test_no_recurse.tar.gz --no-prompt" \
    0 \
    "Archiving files"

echo "All tests completed!"

if [ -f /tmp/fancy_tar_debug.log ]; then
    echo "==== DEBUG LOG ===="
    cat /tmp/fancy_tar_debug.log
fi
if [ -f /tmp/fancy_tar_7z.log ]; then
    echo "==== 7Z LOG ===="
    cat /tmp/fancy_tar_7z.log
fi
if [ -f /tmp/fancy_tar_zip.log ]; then
    echo "==== ZIP LOG ===="
    cat /tmp/fancy_tar_zip.log
fi

exit 0 