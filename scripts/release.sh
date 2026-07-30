#!/usr/bin/env bash
#
# Builds a distributable Explorer App.dmg.
#
# Full pipeline (needs an Apple Developer account):
#   build Release -> codesign (Developer ID) -> package .dmg -> codesign .dmg
#   -> notarytool submit --wait -> stapler staple
#
# Credentials are never read from this file. Two environment variables:
#
#   DEVELOPER_ID   Signing identity, exactly as `security find-identity -v`
#                  prints it, e.g.
#                  "Developer ID Application: Your Name (ABCDE12345)"
#
#   NOTARY_PROFILE Name of a keychain profile holding the notarization
#                  credentials. Create it once with:
#                    xcrun notarytool store-credentials "<name>" \
#                      --apple-id "<apple-id>" --team-id "<team>" \
#                      --password "<app-specific-password>"
#                  The app-specific password then lives in the keychain, not
#                  in the shell history, the environment, or CI logs.
#
# Pass --skip-signing to build and package an unsigned .dmg. Useful to
# exercise the build and packaging steps without an account; the result is
# NOT distributable — Gatekeeper will refuse it on another machine.

set -euo pipefail

readonly scheme="Explorer"
readonly app_name="Explorer App"
readonly project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly build_dir="${project_root}/.build/release"
readonly export_dir="${build_dir}/export"

skip_signing=false
[[ "${1:-}" == "--skip-signing" ]] && skip_signing=true

fail() {
  echo "error: $*" >&2
  exit 1
}

step() {
  echo
  echo "==> $*"
}

# --- preflight -------------------------------------------------------------
# Checked up front so a missing credential fails in seconds rather than after
# a full Release build.

command -v xcodebuild >/dev/null || fail "xcodebuild not found; install Xcode."

if [[ "${skip_signing}" == false ]]; then
  [[ -n "${DEVELOPER_ID:-}" ]] || fail \
    "DEVELOPER_ID is unset. Run 'security find-identity -v -p codesigning' and export the full identity string, or pass --skip-signing."
  [[ -n "${NOTARY_PROFILE:-}" ]] || fail \
    "NOTARY_PROFILE is unset. Create one with 'xcrun notarytool store-credentials', or pass --skip-signing."

  security find-identity -v -p codesigning | grep -qF "${DEVELOPER_ID}" || fail \
    "Signing identity not found in any keychain: ${DEVELOPER_ID}"
fi

version="$(
  xcodebuild -project "${project_root}/${scheme}.xcodeproj" \
    -scheme "${scheme}" -configuration Release \
    -showBuildSettings 2>/dev/null \
    | awk -F' = ' '/ MARKETING_VERSION =/ { print $2; exit }'
)"
[[ -n "${version}" ]] || fail "Could not read MARKETING_VERSION from the project."

readonly app_path="${export_dir}/${app_name}.app"
readonly dmg_path="${build_dir}/${app_name} ${version}.dmg"

# --- build -----------------------------------------------------------------

step "Building ${app_name} ${version} (Release)"
rm -rf "${build_dir}"
mkdir -p "${export_dir}"

# CODE_SIGNING_ALLOWED=NO because the signature is applied below with an
# explicit identity. Letting Xcode sign here would bake in whatever the
# project happens to be configured with.
xcodebuild build \
  -project "${project_root}/${scheme}.xcodeproj" \
  -scheme "${scheme}" \
  -configuration Release \
  -destination 'platform=macOS' \
  -derivedDataPath "${build_dir}/DerivedData" \
  CODE_SIGNING_ALLOWED=NO CODE_SIGN_IDENTITY="" \
  > "${build_dir}/build.log" 2>&1 \
  || { tail -30 "${build_dir}/build.log" >&2; fail "Build failed; full log at ${build_dir}/build.log"; }

built_app="${build_dir}/DerivedData/Build/Products/Release/${app_name}.app"
[[ -d "${built_app}" ]] || fail "Build succeeded but ${built_app} is missing."
cp -R "${built_app}" "${app_path}"

# --- sign ------------------------------------------------------------------

if [[ "${skip_signing}" == false ]]; then
  step "Signing the app"
  # --options runtime enables the hardened runtime, which notarization
  # rejects the submission without. --timestamp fetches a trusted timestamp
  # so the signature keeps validating after the certificate expires.
  codesign --force --options runtime --timestamp \
    --sign "${DEVELOPER_ID}" "${app_path}"
  codesign --verify --strict --verbose=2 "${app_path}"
fi

# --- package ---------------------------------------------------------------

step "Packaging the disk image"
hdiutil create \
  -volname "${app_name}" \
  -srcfolder "${app_path}" \
  -ov -format UDZO \
  "${dmg_path}" > /dev/null

# --- notarize --------------------------------------------------------------

if [[ "${skip_signing}" == false ]]; then
  step "Signing the disk image"
  codesign --force --timestamp --sign "${DEVELOPER_ID}" "${dmg_path}"

  step "Notarizing (this waits on Apple and can take several minutes)"
  xcrun notarytool submit "${dmg_path}" \
    --keychain-profile "${NOTARY_PROFILE}" --wait

  step "Stapling the ticket"
  # Stapling embeds the ticket so the first launch validates offline.
  xcrun stapler staple "${dmg_path}"
  xcrun stapler validate "${dmg_path}"
fi

echo
if [[ "${skip_signing}" == true ]]; then
  echo "Unsigned build at: ${dmg_path}"
  echo "NOT distributable — rerun without --skip-signing to ship."
else
  echo "Signed, notarized and stapled: ${dmg_path}"
fi
