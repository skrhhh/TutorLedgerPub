#!/bin/zsh
set -euo pipefail

IPHONE_UDID="BBACF5C4-D242-49CF-92AF-B6EBFB1DBB1F"
IPAD_UDID="2D80CE7B-2DDD-48A6-BD1D-98D5CD94CD7C"
BUNDLE="com.Davy.TutorLedger"
APP="/tmp/TutorLedgerDerived/Build/Products/Debug-iphonesimulator/TutorLedger.app"
ROOT="/Users/admin/Desktop/project/game/apps/TutorLedgerPub/promo"

LANG_CODE="${1:-all}"
DEVICE="${2:-all}"

boot() {
  local udid="$1"
  xcrun simctl boot "$udid" >/dev/null 2>&1 || true
  xcrun simctl bootstatus "$udid" -b
  open -a Simulator --args -CurrentDeviceUDID "$udid"
  if [[ -d "$APP" ]]; then
    xcrun simctl install "$udid" "$APP" >/dev/null
  fi
}

status_bar() {
  xcrun simctl status_bar "$1" override \
    --time "9:41" \
    --batteryLevel 100 \
    --batteryState charged \
    --cellularMode active \
    --cellularBars 4 \
    --wifiMode active \
    --wifiBars 3 \
    --dataNetwork wifi
}

launch_shot() {
  local udid="$1"
  local dest="$2"
  local wait="$3"
  shift 3
  xcrun simctl terminate "$udid" "$BUNDLE" >/dev/null 2>&1 || true
  sleep 0.35
  xcrun simctl launch --terminate-running-process "$udid" "$BUNDLE" -- "$@" >/dev/null
  sleep "$wait"
  xcrun simctl io "$udid" screenshot "$dest" >/dev/null
  echo "captured $dest"
}

capture_lang() {
  local device="$1"
  local lang="$2"
  local udid raw languages locale extra=()
  if [[ "$device" == "ipad" ]]; then
    udid="$IPAD_UDID"
    raw="$ROOT/raw/ipad/$lang"
  else
    udid="$IPHONE_UDID"
    raw="$ROOT/raw/iphone/$lang"
  fi
  mkdir -p "$raw"

  if [[ "$lang" == "en" ]]; then
    languages="en"
    locale="en_US"
    extra=(-TLEnglish)
  else
    languages="zh-Hans"
    locale="zh_CN"
    extra=()
  fi

  boot "$udid"
  status_bar "$udid"

  if [[ "$lang" == "en" ]]; then
    xcrun simctl spawn "$udid" defaults write "$BUNDLE" currencySymbol '$' >/dev/null
  else
    xcrun simctl spawn "$udid" defaults write "$BUNDLE" currencySymbol '¥' >/dev/null
  fi
  xcrun simctl spawn "$udid" defaults write "$BUNDLE" AppleLanguages -array "$languages" >/dev/null
  xcrun simctl spawn "$udid" defaults write "$BUNDLE" AppleLocale -string "$locale" >/dev/null
  xcrun simctl spawn "$udid" defaults write "$BUNDLE" hasCompletedOnboarding -bool true >/dev/null
  echo "===== $device $lang ====="

  local common=(-TLResetDemo -TLSkipLaunch -TLSkipOnboarding -AppleLanguages "($languages)" -AppleLocale "$locale")
  common+=("${extra[@]}")

  launch_shot "$udid" "$raw/home.png" 2.6 "${common[@]}" -TLTab=home
  launch_shot "$udid" "$raw/lessons.png" 2.4 -TLSkipLaunch -TLSkipOnboarding "${extra[@]}" -TLTab=home -TLOpenLessons -AppleLanguages "($languages)" -AppleLocale "$locale"
  launch_shot "$udid" "$raw/bills.png" 2.4 -TLSkipLaunch -TLSkipOnboarding "${extra[@]}" -TLTab=bills -AppleLanguages "($languages)" -AppleLocale "$locale"
  launch_shot "$udid" "$raw/stats.png" 2.4 -TLSkipLaunch -TLSkipOnboarding "${extra[@]}" -TLTab=stats -AppleLanguages "($languages)" -AppleLocale "$locale"
  launch_shot "$udid" "$raw/students.png" 2.4 -TLSkipLaunch -TLSkipOnboarding "${extra[@]}" -TLTab=students -AppleLanguages "($languages)" -AppleLocale "$locale"

  local student
  if [[ "$lang" == "en" ]]; then
    student="Mia · G8 Math"
  else
    student="小雨妈-初二数学"
  fi
  launch_shot "$udid" "$raw/student.png" 2.6 -TLSkipLaunch -TLSkipOnboarding "${extra[@]}" -TLTab=students -TLOpenStudent "$student" -AppleLanguages "($languages)" -AppleLocale "$locale"
}

run_device() {
  local device="$1"
  case "$LANG_CODE" in
    zh|en) capture_lang "$device" "$LANG_CODE" ;;
    all)
      capture_lang "$device" zh
      capture_lang "$device" en
      ;;
    *)
      echo "usage: $0 [zh|en|all] [iphone|ipad|all]"
      exit 1
      ;;
  esac
}

case "$DEVICE" in
  iphone|ipad) run_device "$DEVICE" ;;
  all)
    run_device iphone
    run_device ipad
    ;;
  *)
    echo "usage: $0 [zh|en|all] [iphone|ipad|all]"
    exit 1
    ;;
esac
