#!/bin/bash
set -e

# 在 macOS 上原生编译 aapt2（Mach-O 格式，可直接在 Mac 上运行）
# 用法: ./build_host.sh
# 依赖: cmake, ninja, protoc 21.12

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="$SCRIPT_DIR/build-host"
PROTOC_PATH="${PROTOC_PATH:-/tmp/protoc-21.12/bin/protoc}"

if [[ ! -x "$PROTOC_PATH" ]]; then
    echo "Error: protoc not found at: $PROTOC_PATH"
    echo "Install: curl -LO https://github.com/protocolbuffers/protobuf/releases/download/v21.12/protoc-21.12-osx-aarch_64.zip"
    echo "         unzip protoc-21.12-osx-aarch_64.zip bin/protoc -d /tmp/protoc-21.12"
    exit 1
fi

echo "=== Building aapt2 for macOS host ==="
echo "  protoc: $PROTOC_PATH"
echo "  arch: $(uname -m)"

# 使用 host 专用的 CMakeLists（临时替换，编译后恢复）
cp "$SCRIPT_DIR/CMakeLists.txt" "$SCRIPT_DIR/CMakeLists.txt.bak"
cp "$SCRIPT_DIR/CMakeLists_host.txt" "$SCRIPT_DIR/CMakeLists.txt"

# 确保编译后恢复原始 CMakeLists.txt
cleanup() {
    mv "$SCRIPT_DIR/CMakeLists.txt.bak" "$SCRIPT_DIR/CMakeLists.txt" 2>/dev/null || true
}
trap cleanup EXIT

cmake -GNinja \
  -B "$BUILD_DIR" \
  -DCMAKE_BUILD_TYPE=Release \
  -DProtobuf_PROTOC_EXECUTABLE="$PROTOC_PATH"

ninja -C "$BUILD_DIR" aapt2

# 复制到统一输出目录
mkdir -p "$SCRIPT_DIR/build/bin"
cp "$BUILD_DIR/bin/aapt2" "$SCRIPT_DIR/build/bin/aapt2"

echo "=== Done: build/bin/aapt2 ==="
file "$SCRIPT_DIR/build/bin/aapt2"
"$SCRIPT_DIR/build/bin/aapt2" version 2>&1 || true
