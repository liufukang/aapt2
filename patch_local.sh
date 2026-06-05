#!/bin/bash
set -e

# macOS 兼容版 patch.sh
# 解决 sed -i 语法差异和路径问题

# 检测 sed 类型（macOS BSD sed vs GNU sed）
if sed --version 2>/dev/null | grep -q GNU; then
    SED_INPLACE="sed -i"
else
    # macOS BSD sed 需要 -i '' 语法
    SED_INPLACE="sed -i ''"
fi

mkdir -p "submodules/incremental_delivery/sysprop/include/"
cp "misc/IncrementalProperties.sysprop.h" "submodules/incremental_delivery/sysprop/include/"
cp "misc/IncrementalProperties.sysprop.cpp" "submodules/incremental_delivery/sysprop/"

mkdir -p "submodules/soong/cc/libbuildversion/include"
cp "misc/platform_tools_version.h" "submodules/soong/cc/libbuildversion/include"

# 替换 proto import 路径
configPattern="s#frameworks/base/tools/aapt2/Configuration.proto#Configuration.proto#g"
ressourcesPattern="s#frameworks/base/tools/aapt2/Resources.proto#Resources.proto#g"

eval $SED_INPLACE '"$configPattern"' "submodules/base/tools/aapt2/Resources.proto"
eval $SED_INPLACE '"$configPattern"' "submodules/base/tools/aapt2/ResourcesInternal.proto"
eval $SED_INPLACE '"$ressourcesPattern"' "submodules/base/tools/aapt2/ApkInfo.proto"
eval $SED_INPLACE '"$ressourcesPattern"' "submodules/base/tools/aapt2/ResourcesInternal.proto"

# 应用 apktool 补丁
git apply "patches/apktool_ibotpeaches.patch" || echo "WARNING: apktool_ibotpeaches.patch failed (may already be applied)"
git apply "patches/protobuf.patch" || echo "WARNING: protobuf.patch failed (may already be applied)"
git apply "patches/32bsystem_on_armv8.patch" || echo "WARNING: 32bsystem_on_armv8.patch failed (may already be applied)"

# 创建符号链接
ln -sf "$(pwd)/submodules/googletest" "submodules/boringssl/src/third_party/googletest" 2>/dev/null || true

echo "=== Patches applied successfully ==="
