#!/bin/bash
set -e

# 在 host 上原生编译 aapt2（macOS / Linux / Windows MSYS2）
# 用法: ./build_host.sh          # 编译当前架构
#       ./build_host.sh universal # macOS: 编译 universal binary (arm64 + x86_64)
# 依赖: cmake, ninja, protoc 21.12

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROTOC_PATH="${PROTOC_PATH:-/tmp/protoc-21.12/bin/protoc}"
UNIVERSAL="${1:-}"

# Windows (MSYS2) 上 protoc 可能叫 protoc.exe
if [[ ! -x "$PROTOC_PATH" ]]; then
    if command -v protoc &>/dev/null; then
        PROTOC_PATH="$(command -v protoc)"
    else
        echo "Error: protoc not found at: $PROTOC_PATH"
        echo "Install protoc 21.12 or set PROTOC_PATH"
        exit 1
    fi
fi

# 检测 Windows
IS_WINDOWS=false
EXE_SUFFIX=""
if [[ "$(uname -s)" == MINGW* ]] || [[ "$(uname -s)" == MSYS* ]] || [[ "$(uname -s)" == CLANG* ]]; then
    IS_WINDOWS=true
    EXE_SUFFIX=".exe"
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

    echo "=== Building aapt2 for $arch ==="

    local cmake_extra_args=()
    if [[ "$IS_WINDOWS" == "true" ]]; then
        # MSYS2 CLANG64 环境：使用 clang 工具链
        cmake_extra_args+=(-DCMAKE_C_COMPILER=clang -DCMAKE_CXX_COMPILER=clang++)
    elif [[ "$(uname -s)" == "Darwin" ]]; then
        cmake_extra_args+=(-DCMAKE_OSX_ARCHITECTURES="$arch")
    fi

    cmake -GNinja \
      -B "$build_dir" \
      -DCMAKE_BUILD_TYPE=Release \
      -DProtobuf_PROTOC_EXECUTABLE="$PROTOC_PATH" \
      "${cmake_extra_args[@]}"

    ninja -C "$build_dir" aapt2
}

mkdir -p "$SCRIPT_DIR/build/bin"

if [[ "$UNIVERSAL" == "universal" ]]; then
    # macOS: 分别编译 arm64 和 x86_64，再用 lipo 合并
    build_arch arm64
    build_arch x86_64

    lipo -create \
      "$SCRIPT_DIR/build-host-arm64/bin/aapt2" \
      "$SCRIPT_DIR/build-host-x86_64/bin/aapt2" \
      -output "$SCRIPT_DIR/build/bin/aapt2"

    echo "=== Done: build/bin/aapt2 (universal) ==="
else
    # 编译当前架构
    ARCH="$(uname -m)"
    build_arch "$ARCH"
    cp "$SCRIPT_DIR/build-host-$ARCH/bin/aapt2${EXE_SUFFIX}" "$SCRIPT_DIR/build/bin/aapt2${EXE_SUFFIX}"

    echo "=== Done: build/bin/aapt2${EXE_SUFFIX} ($ARCH) ==="
fi

file "$SCRIPT_DIR/build/bin/aapt2${EXE_SUFFIX}"
"$SCRIPT_DIR/build/bin/aapt2${EXE_SUFFIX}" version 2>&1 || true
