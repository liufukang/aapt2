#!/bin/bash
set -e

# macOS 兼容版 patch.sh
# base 子模块已直接关联 fork 仓库（含全部 aapt2 定制补丁），无需再打 base 相关 patch

mkdir -p "submodules/incremental_delivery/sysprop/include/"
cp "misc/IncrementalProperties.sysprop.h" "submodules/incremental_delivery/sysprop/include/"
cp "misc/IncrementalProperties.sysprop.cpp" "submodules/incremental_delivery/sysprop/"

mkdir -p "submodules/soong/cc/libbuildversion/include"
cp "misc/platform_tools_version.h" "submodules/soong/cc/libbuildversion/include"

# protobuf CMake 兼容性修复
git apply "patches/protobuf.patch" || echo "WARNING: protobuf.patch failed (may already be applied)"

# map_ptr const_iterator 缺少 operator-- 导致 libstdc++ 编译失败
git -C "submodules/incremental_delivery" apply "../../patches/map_ptr_iterator.patch" || echo "WARNING: map_ptr_iterator.patch failed (may already be applied)"

# ZipStringOffset20 位域打包在 Windows MSVC ABI 下 sizeof !
git -C "submodules/libziparchive" apply "../../patches/ziparchive_bitfield.patch" || echo "WARNING: ziparchive_bitfield.patch failed (may already be applied)"

# 创建符号链接
ln -sf "$(pwd)/submodules/googletest" "submodules/boringssl/src/third_party/googletest" 2>/dev/null || true

echo "=== Patches applied successfully ==="
