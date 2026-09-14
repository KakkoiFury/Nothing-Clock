#!/data/data/com.termux/files/usr/bin/bash

set -e

VERSION="10.7.0"
PACKAGE="font_awesome_flutter"

ROOT="$(pwd)"
PACKAGE_DIR="$ROOT/$PACKAGE"
TMP_DIR="$ROOT/.fontawesome_patch_tmp"
ARCHIVE="$TMP_DIR/$PACKAGE-$VERSION.tar.gz"

echo
echo "=============================================="
echo " Nothing-Clock Font Awesome 10.7.0 Patch"
echo "=============================================="
echo

if [ ! -f "pubspec.yaml" ]; then
    echo "ERROR: pubspec.yaml not found."
    exit 1
fi

echo "[1/7] Cleaning previous attempt..."

rm -rf "$PACKAGE_DIR"
rm -rf "$TMP_DIR"

mkdir -p "$TMP_DIR/extracted"

echo "[2/7] Downloading Font Awesome $VERSION..."

curl -L --fail \
    "https://pub.dev/api/archives/$PACKAGE-$VERSION.tar.gz" \
    -o "$ARCHIVE"

echo "[3/7] Extracting archive..."

tar -xzf "$ARCHIVE" -C "$TMP_DIR/extracted"

echo "      Archive contents:"
find "$TMP_DIR/extracted" -maxdepth 2 -type f | head -20

echo
echo "[4/7] Locating package..."

# Find the directory containing pubspec.yaml.
PACKAGE_SOURCE="$(find "$TMP_DIR/extracted" -type f -name pubspec.yaml -print -quit)"

if [ -z "$PACKAGE_SOURCE" ]; then
    echo
    echo "ERROR: Could not find pubspec.yaml inside downloaded archive."
    echo
    echo "Archive listing:"
    find "$TMP_DIR/extracted" -maxdepth 3 -print
    exit 1
fi

PACKAGE_SOURCE="$(dirname "$PACKAGE_SOURCE")"

echo "      Found package at:"
echo "      $PACKAGE_SOURCE"

mv "$PACKAGE_SOURCE" "$PACKAGE_DIR"

MAIN_FILE="$PACKAGE_DIR/lib/font_awesome_flutter.dart"
ICON_DATA_FILE="$PACKAGE_DIR/lib/src/icon_data.dart"

if [ ! -f "$MAIN_FILE" ]; then
    echo "ERROR: font_awesome_flutter.dart not found."
    exit 1
fi

if [ ! -f "$ICON_DATA_FILE" ]; then
    echo "ERROR: icon_data.dart not found."
    exit 1
fi

echo "[5/7] Patching FontAwesomeIcons..."

# Brands
perl -pi -e \
's/IconDataBrands\((0x[0-9a-fA-F]+)\)/IconData($1, fontFamily: '\''FontAwesomeBrands'\'', fontPackage: '\''font_awesome_flutter'\'')/g' \
"$MAIN_FILE"

# Solid
perl -pi -e \
's/IconDataSolid\((0x[0-9a-fA-F]+)\)/IconData($1, fontFamily: '\''FontAwesomeSolid'\'', fontPackage: '\''font_awesome_flutter'\'')/g' \
"$MAIN_FILE"

# Regular
perl -pi -e \
's/IconDataRegular\((0x[0-9a-fA-F]+)\)/IconData($1, fontFamily: '\''FontAwesomeRegular'\'', fontPackage: '\''font_awesome_flutter'\'')/g' \
"$MAIN_FILE"

# Light
perl -pi -e \
's/IconDataLight\((0x[0-9a-fA-F]+)\)/IconData($1, fontFamily: '\''FontAwesomeLight'\'', fontPackage: '\''font_awesome_flutter'\'')/g' \
"$MAIN_FILE"

# Thin
perl -pi -e \
's/IconDataThin\((0x[0-9a-fA-F]+)\)/IconData($1, fontFamily: '\''FontAwesomeThin'\'', fontPackage: '\''font_awesome_flutter'\'')/g' \
"$MAIN_FILE"

echo "[6/7] Removing illegal IconData subclasses..."

cat > "$ICON_DATA_FILE" <<'DART'
library font_awesome_flutter;

import 'package:flutter/widgets.dart';

/// Compatibility file for modern Flutter.
///
/// font_awesome_flutter 10.7.0 originally implemented
/// IconDataBrands, IconDataSolid, IconDataRegular,
/// IconDataLight and IconDataThin by extending IconData.
///
/// Modern Flutter declares IconData as final.
///
/// The generated FontAwesomeIcons file has been patched to
/// construct ordinary IconData objects directly.
DART

# Verify that no illegal subclasses remain anywhere.
if grep -R "extends IconData" "$PACKAGE_DIR/lib" >/dev/null 2>&1; then
    echo
    echo "ERROR: extends IconData still exists:"
    grep -R "extends IconData" "$PACKAGE_DIR/lib"
    exit 1
fi

echo "      No IconData subclasses remain."

echo "[7/7] Updating pubspec.yaml..."

cat >> pubspec.yaml <<'YAML'

# Local compatibility patch for modern Flutter.
dependency_overrides:
  font_awesome_flutter:
    path: font_awesome_flutter
YAML

rm -rf "$TMP_DIR"

echo
echo "=============================================="
echo " SUCCESS"
echo "=============================================="
echo
echo "Patched package:"
echo "  ./font_awesome_flutter"
echo
echo "Updated:"
echo "  ./pubspec.yaml"
echo
echo "Now run:"
echo
echo "  git add pubspec.yaml font_awesome_flutter"
echo "  git commit -m \"Fix Font Awesome IconData compatibility\""
echo "  git push"
echo
