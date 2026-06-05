# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 项目概述

交叉编译 Android aapt2 二进制文件的构建系统。源码来自 AOSP platform-tools 35.0.2，以 git submodule 形式引入 `submodules/` 目录，通过 CMake + Android NDK 交叉编译为 4 种架构的静态链接可执行文件。

## 构建流程

完整构建需三步：克隆子模块 → 打补丁 → 编译。

```bash
# 1. 克隆（含子模块）
git clone --recurse-submodules --shallow-submodules --depth 1 <repo-url>

# 2. 打补丁（修改 proto import 路径、应用 apktool/protobuf/32b 兼容补丁）
./patch.sh

# 3. 构建指定架构（armeabi-v7a | arm64-v8a | x86 | x86_64）
ANDROID_NDK=/path/to/ndk ./build.sh arm64-v8a
```

产物位于 `build/bin/aapt2-<arch>`。

## 外部依赖

- **Android NDK r27c**：通过 `ANDROID_NDK` 环境变量指定路径
- **protoc 21.12**：必须提前安装，用于在 CMake configure 阶段生成 `.pb.cc/.pb.h`
- **CMake ≥ 3.14.2** + **Ninja**

## 构建架构

```
CMakeLists.txt          # 顶层：设置 C++20、静态链接、引入第三方库和 cmake/ 子目录
cmake/CMakeLists.txt    # 包含所有 .cmake 模块
cmake/aapt2.cmake       # aapt2 主目标：protoc 生成、libaapt2 静态库、aapt2 可执行文件
cmake/lib*.cmake        # 各 AOSP 依赖库的编译定义
```

关键编译选项：`-static` 全静态链接、`-Wl,-z,max-page-size=16384`（16KB ELF 对齐）、C++20、API level 30。

## 补丁系统

`patch.sh` 在编译前执行以下修改：
1. 复制 `misc/` 中的预生成头文件到 submodule 对应位置
2. `sed` 修改 `.proto` 文件中的 import 路径（从 `frameworks/base/tools/aapt2/` 改为相对路径）
3. `git apply` 三个补丁：apktool 兼容、protobuf 修复、32 位 armv8 BusError 修复

新增补丁放在 `patches/` 目录，在 `patch.sh` 中添加 `git apply` 语句。

## macOS 本地编译

原始 `patch.sh` 和 `build.sh` 仅适配 Linux，macOS 上有两个兼容性问题：
1. `sed -i` 语法不同（macOS BSD sed 需要 `sed -i ''`）
2. NDK prebuilt 工具链目录名为 `darwin-x86_64`（非 `linux-x86_64`）

已提供 macOS 兼容脚本：

```bash
# 安装依赖（仅首次）
brew install cmake ninja
# protoc 必须是 21.12 版本（brew 默认版本过新不兼容）
curl -LO https://github.com/protocolbuffers/protobuf/releases/download/v21.12/protoc-21.12-osx-aarch_64.zip
unzip protoc-21.12-osx-aarch_64.zip bin/protoc -d /tmp/protoc-21.12

# 初始化子模块（克隆后仅需一次，base 仓库较大需耐心等待）
git submodule update --init --recursive --force

# 打补丁（macOS 兼容版）
./patch_local.sh

# 编译单个架构
ANDROID_NDK=/Users/liufukang.11/Android/ndk/android-ndk-r27 \
PROTOC_PATH=/tmp/protoc-21.12/bin/protoc \
./build_local.sh arm64-v8a

# 编译全部 4 个架构
for arch in arm64-v8a armeabi-v7a x86_64 x86; do
  ANDROID_NDK=/Users/liufukang.11/Android/ndk/android-ndk-r27 \
  PROTOC_PATH=/tmp/protoc-21.12/bin/protoc \
  ./build_local.sh $arch
done
```

`build_local.sh` 与原 `build.sh` 的区别：
- 自动检测主机平台，使用正确的 `llvm-strip` 路径
- 每个架构使用独立 build 目录（`build-<arch>/`），支持并行编译
- 默认 NDK 路径指向本机位置，protoc 路径可通过环境变量覆盖
- 最终产物统一复制到 `build/bin/aapt2-<arch>`

## CI/CD

- PR 构建：push 或 PR 到 `dev` 分支触发，4 架构矩阵并行编译
- Release：push 到 `main`/`dev` 触发，构建后通过 semantic-release 发版（npm 生态）
- 发版规则：conventional commits，`main` 正式版，`dev` 预发布版
