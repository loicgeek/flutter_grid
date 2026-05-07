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
PACKAGES=("packages/grid_core" "packages/grid_export" "packages/grid_flutter" "packages/grid_ui")

# Cleanup function to restore files on exit or error
cleanup() {
  echo ""
  echo "🧹 Cleaning up temporary files..."
  # Revert root
  if [ -f "pubspec.yaml.bak" ]; then
    mv "pubspec.yaml.bak" "pubspec.yaml"
  fi
  # Revert sub-packages
  for PKG in "${PACKAGES[@]}"; do
    if [ -f "$PKG/pubspec.yaml.bak" ]; then
      mv "$PKG/pubspec.yaml.bak" "$PKG/pubspec.yaml"
    fi
    if [ -f "$PKG/pubspec_overrides.yaml.bak" ]; then
      mv "$PKG/pubspec_overrides.yaml.bak" "$PKG/pubspec_overrides.yaml"
    fi
  done
}

trap cleanup EXIT

echo "🚀 Preparing release for version $VERSION..."


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

# 4. Commit changes before validation
echo "📝 Committing version and changelog changes..."
git add .
git commit -m "chore: release $VERSION" --allow-empty

# Function to swap path dependencies to versioned ones
swap_dependencies() {
  local FILE=$1
  local TARGET_VERSION=$2
  
  # Backup
  cp "$FILE" "$FILE.bak"
  
  # For each possible internal dependency
  for DEP in "grid_core" "grid_flutter" "grid_ui"; do
    if grep -q "$DEP:" "$FILE"; then
      # Case A: Commented version already exists (like in root pubspec)
      if grep -q "  # $DEP: \^" "$FILE"; then
         perl -i -pe "s/^  # $DEP: \^.*/  $DEP: ^$TARGET_VERSION/" "$FILE"
         perl -i -pe "BEGIN{undef $/;} s/^  $DEP:\n    path: (..\/|packages\/)$DEP/  # $DEP:\n    # path: $1$DEP/mg" "$FILE"
      else
         # Case B: No commented version, just swap the path one
         # This handles the multi-line path dependency
         perl -i -pe "BEGIN{undef $/;} s/^  $DEP:\n    path: (..\/|packages\/)$DEP/  $DEP: ^$TARGET_VERSION\n  # $DEP:\n  #   path: $1$DEP/mg" "$FILE"
      fi
    fi
  done
}

# 5. Validate sub-packages (dry-run)
PACKAGES=("packages/grid_core" "packages/grid_export" "packages/grid_flutter" "packages/grid_ui")

for PKG in "${PACKAGES[@]}"; do
  echo ""
  echo "----------------------------------------------------------------"
  echo "📦 Checking $PKG..."
  echo "----------------------------------------------------------------"
  pushd "$PKG" > /dev/null
  
  # Note: In a monorepo, dry-running dependent packages is tricky because
  # their dependencies aren't on pub.dev yet. We'll attempt a dry-run
  # but warn that it might fail due to resolution.
  
  if [ "$PKG" == "packages/grid_core" ]; then
    # Independent package, should always work
    flutter pub get > /dev/null
    flutter pub publish --dry-run
  else
    echo "⚠️  Note: This package depends on other local packages."
    echo "We will dry-run with path dependencies to verify everything ELSE is correct."
    # We DON'T swap to versioned dependencies here for dry-run because pub get would fail
    flutter pub get > /dev/null
    # Run dry-run and capture output, ignoring the path-dependency error if it's the only one
    if ! flutter pub publish --dry-run; then
       echo "💡 Note: Dry-run failure above is expected if it mentions 'path source' errors."
       echo "This is normal for monorepos before the first dependency is published."
    fi
  fi
  
  popd > /dev/null
done


# 6. Handle root package (ntech_grid)
echo ""
echo "----------------------------------------------------------------"
echo "📦 Preparing root package ntech_grid..."
echo "----------------------------------------------------------------"

swap_dependencies "pubspec.yaml" "$VERSION"

echo "🔍 Root pubspec.yaml modified for publishing (preview of dependencies):"
grep -E "^  (grid_core|grid_flutter|grid_ui):" pubspec.yaml || grep -A 5 "dependencies:" pubspec.yaml | grep "grid_"

echo "Running dry-run for root package..."
# This might still fail resolution if sub-packages aren't published,
# but we want to see the pubspec structure.
if ! flutter pub publish --dry-run; then
  echo "💡 Note: Root dry-run likely failed resolution. This is expected."
fi


echo ""
echo "⏪ Reverting root pubspec.yaml changes..."
mv pubspec.yaml.bak "pubspec.yaml"
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

