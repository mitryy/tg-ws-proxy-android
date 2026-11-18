#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
sdk_root="${ANDROID_SDK_ROOT:-${ANDROID_HOME:-$HOME/Android/Sdk}}"
ndk_root="${ANDROID_NDK_ROOT:-$sdk_root/ndk/27.2.12479018}"
android_cc="$ndk_root/toolchains/llvm/prebuilt/linux-x86_64/bin/armv7a-linux-androideabi26-clang"
if [[ ! -x "$android_cc" ]]; then
  echo "Android NDK clang not found: $android_cc" >&2
  exit 1
fi

output_dir="$repo_root/app/src/main/jniLibs/armeabi-v7a"
artifact_dir="$repo_root/artifacts/native/armeabi-v7a"
mkdir -p "$output_dir" "$artifact_dir"
cd "$repo_root/native/tgwsproxy"
GOOS=android GOARCH=arm GOARM=7 CGO_ENABLED=1 CC="$android_cc" \
  go build -buildmode=c-shared -trimpath -o "$artifact_dir/libtgwsproxy.so" .
cp "$artifact_dir/libtgwsproxy.so" "$output_dir/libtgwsproxy.so"
