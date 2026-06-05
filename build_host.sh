#!/bin/bash
set -e

# 在 macOS 上原生编译 aapt2（Mach-O 格式，可直接在 Mac 上运行）
# 用法: ./build_host.sh          # 编译当前架构
#       ./build_host.sh universal # 编译 universal binary (arm64 + x86_64)
# 依赖: cmake, ninja, protoc 21.12

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROTOC_PATH="${PROTOC_PATH:-/tmp/protoc-21.12/bin/protoc}"
UNIVERSAL="${1:-}"

if [[ ! -x "$PROTOC_PATH" ]]; then
    echo "Error: protoc not found at: $PROTOC_PATH"
    echo "Install: curl -LO https://github.com/protocolbuffers/protobuf/releases/download/v21.12/protoc-21.12-osx-aarch_64.zip"
    echo "         unzip protoc-21.12-osx-aarch_64.zip bin/protoc -d /tmp/protoc-21.12"
    exit 1
fi

# 使用 host 专用的 CMakeLists（临时替换，编译后恢复）
cp "$SCRIPT_DIR/CMakeLists.txt" "$SCRIPT_DIR/CMakeLists.txt.bak"
cp "$SCRIPT_DIR/CMakeLists_host.txt" "$SCRIPT_DIR/CMakeLists.txt"

cleanup() {
    mv "$SCRIPT_DIR/CMakeLists.txt.bak" "$SCRIPT_DIR/CMakeLists.txt" 2>/dev/null || true
}
trap cleanup EXIT

# 编译单个架构的函数
build_arch() {
    local arch="$1"
    local build_dir="$SCRIPT_DIR/build-host-$arch"

    echo "=== Building aapt2 for macOS $arch ==="
    cmake -GNinja \
      -B "$build_dir" \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_OSX_ARCHITECTURES="$arch" \
      -DProtobuf_PROTOC_EXECUTABLE="$PROTOC_PATH"

    ninja -C "$build_dir" aapt2
}

mkdir -p "$SCRIPT_DIR/build/bin"

if [[ "$UNIVERSAL" == "universal" ]]; then
    # 分别编译 arm64 和 x86_64，再用 lipo 合并
    build_arch arm64
    build_arch x86_64

    lipo -create \
      "$SCRIPT_DIR/build-host-arm64/bin/aapt2" \
      "$SCRIPT_DIR/build-host-x86_64/bin/aapt2" \
      -output "$SCRIPT_DIR/build/bin/aapt2"

    echo "=== Done: build/bin/aapt2 (universal) ==="
else
    # 仅编译当前架构
    ARCH="$(uname -m)"
    build_arch "$ARCH"
    cp "$SCRIPT_DIR/build-host-$ARCH/bin/aapt2" "$SCRIPT_DIR/build/bin/aapt2"

    echo "=== Done: build/bin/aapt2 ($ARCH) ==="
fi

file "$SCRIPT_DIR/build/bin/aapt2"
"$SCRIPT_DIR/build/bin/aapt2" version 2>&1 || true
