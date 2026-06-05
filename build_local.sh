#!/bin/bash
set -e

# 本地编译脚本，适配 macOS 和 Linux
# 用法: ANDROID_NDK=/path/to/ndk ./build_local.sh <arch>
# 支持架构: armeabi-v7a, arm64-v8a, x86, x86_64

API="30"
ARCHITECTURES=("armeabi-v7a" "arm64-v8a" "x86" "x86_64")

# 检测主机平台，确定 prebuilt 目录名
case "$(uname -s)" in
    Darwin) HOST_TAG="darwin-x86_64" ;;
    Linux)  HOST_TAG="linux-x86_64" ;;
    *)      echo "Error: Unsupported OS"; exit 1 ;;
esac

ANDROID_NDK="${ANDROID_NDK:-/Users/liufukang.11/Android/ndk/android-ndk-r27}"

if [[ ! -d "${ANDROID_NDK}" ]]; then
    echo "Error: ANDROID_NDK not found at: $ANDROID_NDK"
    exit 1
fi

architecture="$1"

if [[ ! " ${ARCHITECTURES[@]} " =~ " $architecture " ]]; then
    echo "Error: '$architecture' is not in the allowed archs: ${ARCHITECTURES[*]}"
    exit 1
fi

NDK_TOOLCHAIN="$ANDROID_NDK/build/cmake/android.toolchain.cmake"
PROTOC_PATH="${PROTOC_PATH:-/tmp/protoc-21.12/bin/protoc}"

if [[ ! -x "$PROTOC_PATH" ]]; then
    echo "Error: protoc not found at: $PROTOC_PATH"
    exit 1
fi

echo "=== Building aapt2 for $architecture ==="
echo "  NDK: $ANDROID_NDK"
echo "  protoc: $PROTOC_PATH"
echo "  Host: $HOST_TAG"

# 使用独立的 build 目录
BUILD_DIR="build-$architecture"

cmake -GNinja \
  -B "$BUILD_DIR" \
  -DANDROID_NDK="$ANDROID_NDK" \
  -DCMAKE_TOOLCHAIN_FILE="$NDK_TOOLCHAIN" \
  -DANDROID_PLATFORM="android-$API" \
  -DCMAKE_ANDROID_ARCH_ABI="$architecture" \
  -DANDROID_ABI="$architecture" \
  -DCMAKE_SYSTEM_NAME=Android \
  -DANDROID_ARM_NEON=ON \
  -DCMAKE_BUILD_TYPE=Release \
  -DPNG_SHARED=OFF \
  -DZLIB_USE_STATIC_LIBS=ON \
  -DProtobuf_PROTOC_EXECUTABLE="$PROTOC_PATH"

ninja -C "$BUILD_DIR" aapt2

# Strip 调试符号
STRIP="$ANDROID_NDK/toolchains/llvm/prebuilt/$HOST_TAG/bin/llvm-strip"
OUTPUT="$BUILD_DIR/bin/aapt2-$architecture"

if [[ -x "$STRIP" && -f "$OUTPUT" ]]; then
    "$STRIP" --strip-unneeded "$OUTPUT"
    echo "=== Done: $OUTPUT (stripped) ==="
else
    echo "=== Done: $OUTPUT ==="
fi

# 复制到统一输出目录
mkdir -p build/bin
cp "$OUTPUT" build/bin/
echo "=== Copied to build/bin/aapt2-$architecture ==="
