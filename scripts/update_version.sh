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

# Update debian/changelog if it exists
if [ -f debian/changelog ]; then
    # Get current date in RFC format
    CURRENT_DATE=$(date -R)
    
    # Create new changelog entry
    cat > debian/changelog.new << EOF
fancy-tar ($VERSION-1) unstable; urgency=medium

  * Release v$VERSION
  * Update version and changelog

 -- $(git config user.name) <$(git config user.email)>  $CURRENT_DATE

EOF
    
    # Append existing changelog entries (skip the first entry)
    tail -n +2 debian/changelog >> debian/changelog.new
    
    # Replace the original file
    mv debian/changelog.new debian/changelog
    echo "✓ Updated debian/changelog"
else
    echo "⚠ Skipping debian/changelog update (file not found)"
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

# Verify version consistency
echo ""
echo "🔍 Verifying version consistency..."
VERSION_FILES=(
    "VERSION:$VERSION"
    "fancy-tar.spec:$(grep '^Version:' fancy-tar.spec | awk '{print $2}' 2>/dev/null || echo 'not found')"
    "debian/changelog:$(head -n1 debian/changelog | cut -d' ' -f2 | tr -d '()' | cut -d'-' -f1 2>/dev/null || echo 'not found')"
    "docs/fancy-tar.1:$(grep '\.TH FANCY-TAR' docs/fancy-tar.1 | awk '{print $6}' | tr -d '"' 2>/dev/null || echo 'not found')"
    "scripts/fancy_tar_progress.sh:$(grep '^VERSION=' scripts/fancy_tar_progress.sh | cut -d'"' -f2 2>/dev/null || echo 'not found')"
)

for file_version in "${VERSION_FILES[@]}"; do
    file="${file_version%:*}"
    found_version="${file_version#*:}"
    
    if [ "$found_version" = "not found" ]; then
        echo "⚠  $file: $found_version"
    elif [ "$found_version" = "$VERSION" ]; then
        echo "✅ $file: $found_version"
    else
        echo "❌ $file: expected $VERSION, found $found_version"
    fi
done

echo ""
echo "Version update complete!" 