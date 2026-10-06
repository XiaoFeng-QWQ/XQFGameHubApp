#!/usr/bin/env bash
# ============================================================================
# XQFGameHub —— Android 构建脚本
# ----------------------------------------------------------------------------
# 背景：本工程位于含中文的路径下（…/共享文件1/AndroidApp/XQFGameHub）。
#       Gradle / Kotlin 在向编译器传递 source / classpath 参数时，会把非 ASCII
#       字符转义成 uXXXX（"共享文件1" → "u5171u4EABu6587u4EF61"），
#       于是 Kotlin 报错：
#         error: source file or directory not found: /media/…/u5171u4EABu6587u4EF61/…
#         error: plugin classpath entry points to a non-existent location: …
#       这是 Gradle/Kotlin 对非 ASCII 路径的已知缺陷，无法通过编码参数绕过。
#
# 方案：把工程镜像到纯 ASCII 的构建根目录（默认 ~/.xqf-build）后再构建，
#       产物再拷回工程目录，源码始终保持在你放的位置。
#
# 用法：
#   tools/build_android.sh                 # 构建 debug APK
#   tools/build_android.sh release         # 构建 release APK
#   tools/build_android.sh debug --clean   # 先清空镜像再构建
#
# 可用环境变量覆盖：
#   XQF_BUILD_ROOT    镜像构建根目录（默认 $HOME/.xqf-build）
#   XQF_FLUTTER_SDK   Flutter SDK 路径
#   XQF_ANDROID_SDK   Android SDK 路径
# ============================================================================
set -euo pipefail

MODE="${1:-debug}"
shift || true

# 其余参数：--clean 交给本脚本处理，其它原样透传给 `flutter build apk`
CLEAN=""
EXTRA_ARGS=()
for arg in "$@"; do
  if [[ "$arg" == "--clean" ]]; then
    CLEAN="--clean"
  else
    EXTRA_ARGS+=("$arg")
  fi
done

SRC_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_ROOT="${XQF_BUILD_ROOT:-$HOME/.xqf-build}"
DEST="$BUILD_ROOT/XQFGameHub"

# ---- 定位 Flutter SDK -------------------------------------------------------
if [[ -n "${XQF_FLUTTER_SDK:-}" && -x "$XQF_FLUTTER_SDK/bin/flutter" ]]; then
  FLUTTER_BIN="$XQF_FLUTTER_SDK/bin/flutter"
elif command -v flutter >/dev/null 2>&1; then
  FLUTTER_BIN="$(command -v flutter)"
elif [[ -x "$HOME/flutter-sdk/flutter/bin/flutter" ]]; then
  FLUTTER_BIN="$HOME/flutter-sdk/flutter/bin/flutter"
elif [[ -x "$HOME/development/flutter/bin/flutter" ]]; then
  FLUTTER_BIN="$HOME/development/flutter/bin/flutter"
else
  echo "✗ 未找到 Flutter SDK，请设置 XQF_FLUTTER_SDK 或把 flutter 加入 PATH" >&2
  exit 1
fi
FLUTTER_SDK="$(cd "$(dirname "$FLUTTER_BIN")/.." && pwd -P)"

# ---- 定位 Android SDK -------------------------------------------------------
ANDROID_SDK="${XQF_ANDROID_SDK:-${ANDROID_SDK_ROOT:-${ANDROID_HOME:-$HOME/Android}}}"
if [[ ! -d "$ANDROID_SDK/platforms" ]]; then
  echo "✗ 未找到 Android SDK（$ANDROID_SDK），请设置 XQF_ANDROID_SDK" >&2
  exit 1
fi

echo "▸ 源码目录 : $SRC_ROOT"
echo "▸ 构建镜像 : $DEST"
echo "▸ Flutter  : $FLUTTER_SDK"
echo "▸ Android  : $ANDROID_SDK"

# ---- 路径自检：非 ASCII 一律走镜像 ------------------------------------------
case "$SRC_ROOT$BUILD_ROOT$FLUTTER_SDK$ANDROID_SDK" in
  *[!\ -~]*) : ;;   # 含非 ASCII，正常，走镜像
esac

mkdir -p "$BUILD_ROOT"
if [[ "$CLEAN" == "--clean" ]]; then
  echo "▸ 清理镜像目录"
  rm -rf "$DEST"
fi

# ---- 镜像源码（排除构建产物与本地工具链） ----------------------------------
echo "▸ 同步源码到镜像目录…"
if command -v rsync >/dev/null 2>&1; then
  mkdir -p "$DEST"
  rsync -a --delete \
    --exclude 'build/' \
    --exclude '.dart_tool/' \
    --exclude '.git/' \
    --exclude '.gradle/' \
    --exclude '.tooling/' \
    --exclude 'android/.gradle/' \
    --exclude 'android/local.properties' \
    "$SRC_ROOT/" "$DEST/"
else
  rm -rf "$DEST"
  mkdir -p "$DEST"
  tar -C "$SRC_ROOT" \
    --exclude='./build' --exclude='./.dart_tool' --exclude='./.git' \
    --exclude='./.gradle' --exclude='./.tooling' --exclude='./android/.gradle' \
    -cf - . | tar -C "$DEST" -xf -
fi

# ---- 构建 -------------------------------------------------------------------
export ANDROID_SDK_ROOT="$ANDROID_SDK"
export ANDROID_HOME="$ANDROID_SDK"
export GRADLE_USER_HOME="$BUILD_ROOT/gradle-home"
export PUB_CACHE="${PUB_CACHE:-$HOME/.pub-cache}"
export PATH="$(dirname "$FLUTTER_BIN"):$PATH"
export JAVA_HOME="${JAVA_HOME:-/usr/lib/jvm/java-21-openjdk-amd64}"

cd "$DEST"
echo "▸ flutter pub get"
flutter pub get

echo "▸ flutter build apk --$MODE ${EXTRA_ARGS[*]:-}"
if [[ ${#EXTRA_ARGS[@]} -gt 0 ]]; then
  flutter build apk "--$MODE" "${EXTRA_ARGS[@]}"
else
  flutter build apk "--$MODE"
fi

# ---- 产物回拷 ---------------------------------------------------------------
# 只回拷本次构建模式对应的 APK，避免把镜像里上一次构建的另一种模式也拷回来。
OUT_DIR="$SRC_ROOT/build/app/outputs/flutter-apk"
mkdir -p "$OUT_DIR"
shopt -s nullglob
copied=0
for f in "$DEST"/build/app/outputs/flutter-apk/app-"$MODE"*.apk; do
  cp -f "$f" "$OUT_DIR/"
  copied=1
done
shopt -u nullglob

if [[ "$copied" == "1" ]]; then
  echo "✓ 构建完成，APK 已回拷到："
  ls -lh "$OUT_DIR"/app-"$MODE"*.apk
else
  echo "✗ 未找到 APK 产物" >&2
  exit 1
fi
