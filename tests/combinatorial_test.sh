#!/bin/bash
set -e

# Output directory for logs
LOGDIR="$(dirname "$0")/combinatorial_logs"
mkdir -p "$LOGDIR"

# Create dummy files and directories for testing
TMPDIR="$(dirname "$0")/combo_tmp"
rm -rf "$TMPDIR"
mkdir -p "$TMPDIR/dir1"
echo "test1" > "$TMPDIR/file1.txt"
echo "test2" > "$TMPDIR/file2.txt"
echo "dirfile" > "$TMPDIR/dir1/file3.txt"

# Define option sets
ARCHIVES=( "" "--zip" "--7z" )
ENCRYPTS=( "" "--password testpass" ) # Removed "--encrypt" (without password) to avoid interactive GPG prompt that hangs tests
SPLITS=( "" "--split-size=2K" )
HASHES=( "" "--hash" )
TREES=( "" "--tree" )
FORCES=( "--force" ) # Always force to avoid prompts

# Test counter
count=0
failures=0

# Loop over combinations
for archive in "${ARCHIVES[@]}"; do
  for encrypt in "${ENCRYPTS[@]}"; do
    for split in "${SPLITS[@]}"; do
      for hash in "${HASHES[@]}"; do
        for tree in "${TREES[@]}"; do
          for force in "${FORCES[@]}"; do
            # Build output/log file names
            outbase="combo_${count}"
            logfile="$LOGDIR/${outbase}.log"
            outfile="$LOGDIR/${outbase}.out"
            # Build command
            cmd="../scripts/fancy_tar_progress.sh $archive $encrypt $split $hash $tree $force $TMPDIR/file1.txt $TMPDIR/file2.txt $TMPDIR/dir1 -o $outfile"
            echo "[$(date)] Running: $cmd" | tee "$logfile"
            # Run and log output
            if eval $cmd >> "$logfile" 2>&1; then
              echo "✅ PASS: $cmd" | tee -a "$logfile"
            else
              echo "❌ FAIL: $cmd" | tee -a "$logfile"
              failures=$((failures+1))
            fi
            count=$((count+1))
          done
        done
      done
    done
  done
done

echo
if [ "$failures" -eq 0 ]; then
  echo "✅ All $count combinatorial tests passed! Logs in $LOGDIR."
else
  echo "⚠️ $failures out of $count tests failed. See $LOGDIR for details."
fi

# Cleanup test files
echo "Cleaning up test files..."
rm -rf "$TMPDIR" 