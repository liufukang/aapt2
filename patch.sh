#!/bin/bash

mkdir -p "submodules/incremental_delivery/sysprop/include/"
cp "misc/IncrementalProperties.sysprop.h" "submodules/incremental_delivery/sysprop/include/"
cp "misc/IncrementalProperties.sysprop.cpp" "submodules/incremental_delivery/sysprop/"

cp "misc/platform_tools_version.h" "submodules/soong/cc/libbuildversion/include"

# protobuf CMake 兼容性修复
git apply "patches/protobuf.patch"

# Fix map_ptr const_iterator missing operator-- for libstdc++
git -C "submodules/incremental_delivery" apply "../../patches/map_ptr_iterator.patch"

# Fix ZipStringOffset20 bitfield packing on Windows (MSVC ABI)
git -C "submodules/libziparchive" apply "../../patches/ziparchive_bitfield.patch"

ln -sf "submodules/googletest" "submodules/boringssl/src/third_party/googletest" 2>/dev/null || true
