#!/bin/bash
set -e

echo "🔧 Running fancy-tar test suite..."

FAILED=0
TMP=test-tmp
SCRIPT=./scripts/fancy_tar_progress.sh

mkdir -p "$TMP"
echo "Test file" > "$TMP/sample.txt"

# 1. Test --version
if ! $SCRIPT --version | grep -q "fancy-tar"; then
  echo "❌ Version test failed"
  FAILED=1
fi

# 2. Test tar.gz archive
$SCRIPT "$TMP/sample.txt" -o "$TMP/test.tar.gz"
if [ ! -f "$TMP/test.tar.gz" ]; then
  echo "❌ Archive creation failed"
  FAILED=1
fi

# 3. Test --hash
$SCRIPT "$TMP/sample.txt" -o "$TMP/test2.tar.gz" --hash
if [ ! -f "$TMP/test2.tar.gz.sha256" ]; then
  echo "❌ Hash generation failed"
  FAILED=1
fi

# 4. Test --self-test
if ! $SCRIPT --self-test; then
  echo "❌ Self-test failed"
  FAILED=1
fi

rm -rf "$TMP"
echo
[ "$FAILED" -eq 0 ] && echo "✅ All tests passed!" || echo "⚠️ Some tests failed"
exit "$FAILED"
