#!/bin/bash

# release.sh - Helper script to release ntech_grid and its sub-packages.
# Usage: ./release.sh <version>

# Exit on error
set -e

if [ -z "$1" ]; then
  echo "Usage: ./release.sh <version>"
  echo "Example: ./release.sh 0.1.3"
  exit 1
fi

VERSION=$1
DATE=$(date +%Y-%m-%d)

echo "🚀 Preparing release for version $VERSION..."

# 0. Check for clean git state
if [ -n "$(git status --porcelain)" ]; then
  echo "⚠️  Warning: You have uncommitted changes. It's recommended to release from a clean state."
  echo "Modified files:"
  git status --short
  echo "----------------------------------------------------------------"
fi

# 1. Update pubspec versions in all packages
echo "📝 Updating versions in all pubspec.yaml files to $VERSION..."
find . -name "pubspec.yaml" -not -path "*/.*" -not -path "./flutter_grid_example/*" -exec perl -i -pe "s/^version: .*/version: $VERSION/" {} +

# 2. Update CHANGELOG.md in all packages
echo "📝 Updating CHANGELOG.md files..."
CHANGELOGS=$(find . -name "CHANGELOG.md" -not -path "*/.*" -not -path "./flutter_grid_example/*")

for CL in $CHANGELOGS; do
  if ! grep -q "## $VERSION" "$CL"; then
    echo "  - Adding $VERSION to $CL"
    # Prepend the new version to the top (after the first line if it's a header, but usually it's the first line)
    # Using perl to prepend
    perl -i -pe "BEGIN{undef $/;} s/^(## .*)/## $VERSION - $DATE\n\n* Internal release bump.\n\n\$1/m" "$CL"
  else
    echo "  - Updating date for $VERSION in $CL"
    perl -i -pe "s/^## $VERSION .*/## $VERSION - $DATE/" "$CL"
  fi
done

# 3. Ensure build/ is in .pubignore
if ! grep -q "build/" .pubignore; then
  echo "📝 Adding build/ to .pubignore..."
  echo "build/" >> .pubignore
fi

# 4. Validate sub-packages (dry-run)
PACKAGES=("packages/grid_core" "packages/grid_export" "packages/grid_flutter" "packages/grid_ui")

for PKG in "${PACKAGES[@]}"; do
  echo ""
  echo "----------------------------------------------------------------"
  echo "📦 Checking $PKG..."
  echo "----------------------------------------------------------------"
  pushd "$PKG" > /dev/null
  flutter pub get > /dev/null
  # We use --no-codesign for macOS if needed, but for pub it shouldn't matter
  flutter pub publish --dry-run
  popd > /dev/null
done

# 5. Handle root package (ntech_grid)
echo ""
echo "----------------------------------------------------------------"
echo "📦 Preparing root package ntech_grid..."
echo "----------------------------------------------------------------"

# Backup pubspec.yaml
cp pubspec.yaml pubspec.yaml.bak

# Step A: Uncomment the versioned dependencies and set them to the new version
perl -i -pe "s/^  # (grid_core|grid_flutter|grid_ui): \^.*/  \$1: ^$VERSION/" pubspec.yaml

# Step B: Comment out the path dependencies
perl -i -pe 'BEGIN{undef $/;} s/^  (grid_core|grid_flutter|grid_ui):\n    path: packages\/\1/  # $1:\n    # path: packages\/$1/mg' pubspec.yaml

echo "🔍 Root pubspec.yaml modified for publishing (preview of dependencies):"
grep -A 10 "dependencies:" pubspec.yaml

echo "Running dry-run for root package..."
flutter pub get > /dev/null
flutter pub publish --dry-run

echo ""
echo "⏪ Reverting root pubspec.yaml changes..."
mv pubspec.yaml.bak pubspec.yaml
flutter pub get > /dev/null

echo ""
echo "================================================================"
echo "✅ Preparation complete for version $VERSION!"
echo "================================================================"
echo "Next steps:"
echo "1. Commit the changes: git commit -am \"chore: release $VERSION\""
echo "2. Tag the release: git tag v$VERSION"
echo "3. Push: git push origin main --tags"
echo "4. Publish each sub-package in order:"
echo "   (cd packages/grid_core && flutter pub publish)"
echo "   (cd packages/grid_export && flutter pub publish)"
echo "   (cd packages/grid_flutter && flutter pub publish)"
echo "   (cd packages/grid_ui && flutter pub publish)"
echo "5. Finally, publish the main package: flutter pub publish"

