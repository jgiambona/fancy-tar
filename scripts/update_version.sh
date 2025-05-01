#!/bin/bash

# Exit on error
set -e

# Get version from VERSION file
VERSION=$(cat VERSION)

echo "Updating version to $VERSION..."

# Update fancy-tar.spec if it exists
if [ -f fancy-tar.spec ]; then
    sed -i '' "s/^Version:.*/Version:        $VERSION/" fancy-tar.spec
    echo "✓ Updated fancy-tar.spec"
fi

# Update debian/changelog if dch is available
if command -v dch >/dev/null 2>&1 && [ -f debian/changelog ]; then
    dch --newversion "$VERSION-1" "Update version to $VERSION" --distribution stable
    echo "✓ Updated debian/changelog"
else
    echo "⚠ Skipping debian/changelog update (dch not found)"
fi

# Update docs/fancy-tar.1 if it exists
if [ -f docs/fancy-tar.1 ]; then
    sed -i '' "s/\.TH FANCY-TAR 1 \"[^\"]*\" \"[^\"]*\" \"fancy-tar [0-9.]*\"/.TH FANCY-TAR 1 \"$(date +%Y-%m-%d)\" \"$VERSION\" \"fancy-tar $VERSION\"/" docs/fancy-tar.1
    echo "✓ Updated docs/fancy-tar.1"
fi

# Update scripts/fancy_tar_progress.sh
if [ -f scripts/fancy_tar_progress.sh ]; then
    sed -i '' "s/^VERSION=.*/VERSION=\"$VERSION\"/" scripts/fancy_tar_progress.sh
    echo "✓ Updated scripts/fancy_tar_progress.sh"
fi

# Update docs/FUTURE.md if it exists
if [ -f docs/FUTURE.md ]; then
    sed -i '' "s/^## \[Unreleased\].*/## \[Unreleased\]\n\n## \[$VERSION\] - $(date +%Y-%m-%d)/" docs/FUTURE.md
    echo "✓ Updated docs/FUTURE.md"
fi

# Update version in README.md
if [ -f README.md ]; then
    sed -i '' -e "s/version-[0-9]\+\.[0-9]\+\.[0-9]\+/version-$VERSION/g" \
              -e "s/v[0-9]\+\.[0-9]\+\.[0-9]\+\/fancy-tar_[0-9]\+\.[0-9]\+\.[0-9]\+/v$VERSION\/fancy-tar_$VERSION/g" \
              -e "s/v[0-9]\+\.[0-9]\+\.[0-9]\+\/fancy-tar-[0-9]\+\.[0-9]\+\.[0-9]\+/v$VERSION\/fancy-tar-$VERSION/g" \
              -e "s/fancy-tar_[0-9]\+\.[0-9]\+\.[0-9]\+/fancy-tar_$VERSION/g" \
              -e "s/fancy-tar-[0-9]\+\.[0-9]\+\.[0-9]\+/fancy-tar-$VERSION/g" \
              -e "s/\[version [0-9]\+\.[0-9]\+\.[0-9]\+\]/[version $VERSION]/g" \
              README.md
    echo "✓ Updated README.md"
fi

echo "Version update complete!" 