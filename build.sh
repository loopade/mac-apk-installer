#!/bin/zsh

set -euo pipefail
cd "$(dirname "$0")"

APP="/Applications/APK安装器.app"
BIN_NAME="APK安装器"

if [[ "${1:-}" == "--build-only" ]]; then
  mkdir -p dist
  swiftc -framework AppKit -o "dist/$BIN_NAME" APKInstaller.swift
  echo "已编译: $PWD/dist/$BIN_NAME"
  exit 0
fi

if [[ ! -d "$APP" ]]; then
  echo "未找到 $APP，请先创建应用包骨架（Contents/MacOS + Info.plist）" >&2
  exit 1
fi

swiftc -framework AppKit -o "$APP/Contents/MacOS/$BIN_NAME" APKInstaller.swift
plutil -replace CFBundleExecutable -string "$BIN_NAME" "$APP/Contents/Info.plist"
LSREGISTER="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"
"$LSREGISTER" -f "$APP"
killall "$BIN_NAME" 2>/dev/null || true
echo "已安装: $APP"
