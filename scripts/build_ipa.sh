#!/usr/bin/env bash
#
# Build an unsigned-but-ad-hoc-signed IPA suitable for sideloading tools.
# A distributable App Store IPA still requires an Apple signing certificate and
# provisioning profile; GitHub Actions intentionally does not receive either.

set -Eeuo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT_PATH="${PROJECT_PATH:-$PROJECT_ROOT/lara.xcodeproj}"
SCHEME="${SCHEME:-lara}"
CONFIGURATION="${CONFIGURATION:-Release}"
PRODUCT_NAME="${PRODUCT_NAME:-Eagle}"
ARTIFACT_NAME="${ARTIFACT_NAME:-P1CK4X3}"
BUILD_DIR="${BUILD_DIR:-$PROJECT_ROOT/build}"
DERIVED_DATA="${DERIVED_DATA:-$BUILD_DIR/DerivedData}"
VERIFY_MATRIX_SCRIPT="$PROJECT_ROOT/scripts/verify_prepare_matrices.sh"
VERIFY_POINTER_GUARDS_SCRIPT="$PROJECT_ROOT/scripts/verify_kernel_pointer_guards.sh"
RUN_VERIFIERS=true

usage() {
  cat <<'EOF'
Usage: ./scripts/build_ipa.sh [options]

Options:
  --configuration <name>  Xcode build configuration (default: Release)
  --artifact-name <name>  IPA filename without .ipa (default: P1CK4X3)
  --skip-verification     Skip the repository's static safety verifiers
  -h, --help              Show this help

Environment overrides:
  PROJECT_PATH, SCHEME, CONFIGURATION, PRODUCT_NAME, ARTIFACT_NAME,
  BUILD_DIR, DERIVED_DATA

The output is build/<artifact-name>.ipa. It uses ad-hoc signatures so a
sideloading tool can re-sign it; it is not an App Store distribution archive.
EOF
}

while (($#)); do
  case "$1" in
    --configuration)
      CONFIGURATION="${2:?Missing configuration name}"
      shift 2
      ;;
    --artifact-name)
      ARTIFACT_NAME="${2:?Missing artifact name}"
      shift 2
      ;;
    --skip-verification)
      RUN_VERIFIERS=false
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "ERROR: unknown option: $1" >&2
      usage >&2
      exit 64
      ;;
  esac
done

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "ERROR: IPA builds require macOS with Xcode. Run this script locally on a Mac or through GitHub Actions." >&2
  exit 69
fi

for command in xcodebuild codesign xattr zip; do
  if ! command -v "$command" >/dev/null 2>&1; then
    echo "ERROR: required macOS build tool is unavailable: $command" >&2
    exit 69
  fi
done

if [[ ! -d "$PROJECT_PATH" ]]; then
  echo "ERROR: Xcode project not found: $PROJECT_PATH" >&2
  exit 66
fi

if [[ "$RUN_VERIFIERS" == true ]]; then
  for verifier in "$VERIFY_MATRIX_SCRIPT" "$VERIFY_POINTER_GUARDS_SCRIPT"; do
    if [[ ! -x "$verifier" ]]; then
      echo "ERROR: verifier is missing or not executable: $verifier" >&2
      exit 66
    fi
    "$verifier"
  done
fi

STAGING_DIR="$(mktemp -d "${TMPDIR:-/tmp}/p1ck4x3-ipa.XXXXXX")"
cleanup() {
  rm -rf "$STAGING_DIR"
}
trap cleanup EXIT

mkdir -p "$BUILD_DIR"
if [ "${EAGLE_REUSE_DERIVED_DATA:-0}" != "1" ]; then
  rm -rf "$DERIVED_DATA"
fi
rm -f "$BUILD_DIR/xcodebuild.log" "$BUILD_DIR/$ARTIFACT_NAME.ipa"

echo "Building $PRODUCT_NAME ($CONFIGURATION) for generic iOS..."
xcodebuild \
  -project "$PROJECT_PATH" \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
  -destination "generic/platform=iOS" \
  -derivedDataPath "$DERIVED_DATA" \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  build 2>&1 | tee "$BUILD_DIR/xcodebuild.log"

BUILT_APP="$DERIVED_DATA/Build/Products/$CONFIGURATION-iphoneos/$PRODUCT_NAME.app"
if [[ ! -d "$BUILT_APP" ]]; then
  echo "ERROR: expected app bundle was not produced: $BUILT_APP" >&2
  exit 65
fi

PAYLOAD_DIR="$STAGING_DIR/Payload"
PACKAGED_APP="$PAYLOAD_DIR/$PRODUCT_NAME.app"
mkdir -p "$PAYLOAD_DIR"
cp -R -X "$BUILT_APP" "$PACKAGED_APP"

# Finder metadata is not part of the app bundle and can make later re-signing
# fail, particularly when source files come from a cloud-backed folder.
xattr -cr "$PACKAGED_APP" 2>/dev/null || true

codesign --remove-signature "$PACKAGED_APP" 2>/dev/null || true

# The app includes two dylibs. They must be signed before the app bundle is
# signed, otherwise dyld rejects the IPA before it can launch.
for binary in \
  "$PACKAGED_APP/Frameworks/libgrabkernel2.dylib" \
  "$PACKAGED_APP/Frameworks/libxpf.dylib"; do
  if [[ ! -f "$binary" ]]; then
    echo "ERROR: expected embedded binary was not produced: $binary" >&2
    exit 65
  fi
  codesign --remove-signature "$binary" 2>/dev/null || true
  codesign --force --sign - --timestamp=none "$binary"
  codesign --verify --strict --verbose=2 "$binary"
done

codesign \
  --force \
  --sign - \
  --entitlements "$PROJECT_ROOT/Config/lara.entitlements" \
  --generate-entitlement-der \
  --timestamp=none \
  "$PACKAGED_APP"
codesign --verify --deep --strict --verbose=2 "$PACKAGED_APP"

(cd "$STAGING_DIR" && /usr/bin/zip -qryX "$BUILD_DIR/$ARTIFACT_NAME.ipa" Payload)

if command -v shasum >/dev/null 2>&1; then
  shasum -a 256 "$BUILD_DIR/$ARTIFACT_NAME.ipa"
fi
echo "IPA ready: $BUILD_DIR/$ARTIFACT_NAME.ipa"
