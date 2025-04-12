#!/bin/bash

# Check if we're in the right directory
if [ ! -f "scripts/fancy_tar_progress.sh" ]; then
  echo "❌ Please run this script from the project root directory"
  exit 1
fi

# Check for required tools
for cmd in dpkg-buildpackage debhelper; do
  if ! command -v $cmd >/dev/null 2>&1; then
    echo "❌ Required tool not found: $cmd"
    echo "   Please install it with: sudo apt-get install $cmd"
    exit 1
  fi
done

# Clean any previous build
rm -rf debian/fancy-tar
rm -f ../fancy-tar_*.deb ../fancy-tar_*.changes ../fancy-tar_*.buildinfo

# Build the package
echo "📦 Building Debian package..."
dpkg-buildpackage -b -us -uc

if [ $? -eq 0 ]; then
  echo "✅ Package built successfully!"
  echo "📦 Package location: ../fancy-tar_1.6.4-1_all.deb"
else
  echo "❌ Package build failed"
  exit 1
fi 