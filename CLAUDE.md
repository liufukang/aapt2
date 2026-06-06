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
3. `git apply` 补丁文件

新增补丁放在 `patches/` 目录，在 `patch.sh` 中添加 `git apply` 语句。

### patches/ 目录补丁清单

| 补丁文件 | 用途 |
|---------|------|
| `apktool_ibotpeaches.patch` | Apktool 兼容：放宽资源名校验、private attr 引用、package ID 范围等 |
| `search_all_include_packages.patch` | **Portal 跨包资源引用核心补丁**（详见下方） |
| `protobuf.patch` | protobuf 兼容性修复 |
| `32bsystem_on_armv8.patch` | 32 位 armv8 BusError 修复 |
| `map_ptr_iterator.patch` | map_ptr iterator 兼容修复 |
| `ziparchive_bitfield.patch` | ZipArchive 位域打包修复 |

### search_all_include_packages.patch 详解

这是 Portal bundle 方案的核心补丁，实现 aapt2 对 bundle 0x7F 资源的直接引用和 ID 位置固定。涉及 13 个文件，按功能分为 6 类：

**1. 构建适配（3 项）**

| # | 文件 | 改动 | 必要性 |
|---|------|------|--------|
| 1 | `ApkInfo.proto`、`Resources.proto`、`ResourcesInternal.proto` | `import "frameworks/base/tools/aapt2/xxx.proto"` → `import "xxx.proto"` | AOSP 源码树使用绝对路径，独立编译（CMake + ninja）需改为相对路径 |
| 2 | `Main.cpp` | `aapt2 version` 输出时打印 `[+] add --search-all-include-packages` 等标记 | 确认运行的是定制版 aapt2，避免排查问题时搞混二进制 |
| 3 | `Link.h` / `Link.cpp` | 新增 `-e <file>` 参数，从文件读取不压缩扩展名列表 | AGP 某些版本通过文件传入 no-compress 列表，标准 aapt2 只支持 `-0` 逐个指定 |

**2. Apktool 兼容（4 项）**

| # | 文件 | 改动 | 必要性 |
|---|------|------|--------|
| 4 | `ResourceTable.cpp` | 注释掉 `IsValidResourceEntryName` 的报错 + `return false` | bundle 中可能包含非标准命名资源（如反混淆后的名字），Portal 需要原样保留 |
| 5 | `ResourceUtils.cpp` | 注释掉 `ParseAttributeReference` 中 type != "attr" 时的 `return false` | bundle 中可能引用 `?attr/xxx` 形式的 private attribute，标准 aapt2 会拒绝 |
| 6 | `Link.cpp` | `package_id` 不在 0x7f-0xff 范围时从 `Error + return 1` 改为 `Warn` | bundle 包的 package ID 可能为非标准值（Aura 架构下各 bundle 有不同 packageId），加载 `-I` 包时不能因此失败 |
| 7 | `PrivateAttributeMover.cpp` | 注释掉 `CHECK(priv_attr_type->entries.empty())` | 预填充 bundle attr 后 `attr_private` type 可能已有条目，标准 aapt2 假定初始为空会 abort |

**3. 跨包资源引用（6 项）**

| # | 文件 | 改动 | 必要性 |
|---|------|------|--------|
| 8 | `Link.h` / `Link.cpp` | 新增 `--search-all-include-packages` CLI 标志 | 控制是否启用跨包回退搜索的总开关。只有 Portal 模式传入，普通编译不受影响 |
| 9 | `ReferenceLinker.cpp` | 非限定引用（无包名或包名==编译包名）查找失败时，遍历所有 include 包名尝试解析，记录解析到的 0x7F 资源 | Portal 宿主引用 `@drawable/xxx` 时默认查当前包，找不到时需回退到 bundle 包名。这是跨包资源引用能工作的关键 |
| 10 | `SymbolTable.cpp` / `SymbolTable.h` | 新增 `FindByNameNoMangle` 方法 | fallback 搜索时直接用 bundle 包名查找，不需要 mangle（mangle 会把 entry 名编码为 `pkg__name` 格式），直接查找才能正确匹配 bundle 中的原始资源名 |
| 11 | `SymbolTable.cpp` / `SymbolTable.h` | 新增 `GetAllPackageNames` 方法 | 多个 bundle 可能共享同一 packageId（如 0x7F）但有不同包名，需收集所有包名让 fallback 搜索覆盖全部 bundle |
| 12 | `SymbolTable.h` | 新增 `search_all_include_packages_`、`include_package_names_`、`fallback_resolved_entries_` 字段及 getter/setter | ReferenceLinker 通过 SymbolTable 获取配置和记录结果，这些字段是 fallback 机制的状态载体 |
| 13 | `Link.cpp` | 调用 `GetAllPackageNames()` 收集包名设置到 SymbolTable，保存 `asset_source_ptr_` 裸指针 | ReferenceLinker fallback 搜索需要知道有哪些包名可供尝试；`asset_source_ptr_` 用于后续预填充 |

**4. ID 稳定性 / 铁律保证（3 项）**

| # | 文件 | 改动 | 必要性 |
|---|------|------|--------|
| 14 | `Link.cpp` | IdAssigner 运行前，调用 `GetAll7fResources()` 取所有 bundle 0x7F 资源，逐条 `AddResource + SetId` 到 `final_table_`。区分"宿主已有同名"（pin existing）和"新增空条目"两种情况 | **铁律核心**：在 IdAssigner 前把 bundle 资源 pin 到正确 entry position → IdAssigner 跳过已预留 ID → 宿主同名资源获得一致 ID → 空条目占位供 MergeBundleResourcesTask index 对齐注入 |
| 15 | `SymbolTable.cpp` / `SymbolTable.h` | 新增 `GetAll7fResources` 方法，遍历所有 `-I` 加载的 APK，收集 packageId==0x7F 的全部资源 name+ID 对 | 预填充阶段的数据源。需要知道 bundle 中有哪些 0x7F 资源以及它们的原始 ID |
| 16 | `SymbolTable.cpp` | `ResourceTableSymbolSource::FindByName` 中 attr 类型条目如果 `values.empty()`（预填充的空条目），返回 nullptr | 预填充的 attr 只有 ID 没有 Attribute 值。返回 nullptr 使 SymbolTable 回退到 AssetManagerSymbolSource 从 bundle arsc bag 数据获取完整 Attribute 信息。**既保住了 ID 位置（IdAssigner 层面），又保住了语义正确性（ReferenceLinker 需要 Attribute 的 type flags/enum symbols 来验证 style 值）** |

**5. 可见性控制（2 项）**

| # | 文件 | 改动 | 必要性 |
|---|------|------|--------|
| 17 | `Link.h` / `Link.cpp` | 新增 `--disable-visibility-check` CLI 标志（默认 true） | bundle 中的资源未必标记为 PUBLIC。Portal 宿主需要引用这些资源，必须跳过可见性检查 |
| 18 | `ReferenceLinker.cpp` | `ResolveSymbolCheckVisibility` 中 `is private` 的 `return nullptr` 受 `GetDisableVisibilityCheck()` 控制 | 配合上述标志。bundle 资源不一定标为 PUBLIC，宿主仍需正常引用 |

**6. R 文件正确性（1 项）**

| # | 文件 | 改动 | 必要性 |
|---|------|------|--------|
| 19 | `JavaClassGenerator.cpp` | `IsValidSymbol` 始终返回 true；`ProcessStyleable` 中跳过的 attr 仍输出 R.txt child 行 | bundle 资源名可能包含 Java 保留字不能跳过；R.txt 中 styleable 数组长度和 child 行数必须一致，否则下游工具解析出错 |

### 核心机制：0x7F 资源预填充

```
aapt2 link 流程：
  1. 加载 -I 包（含 bundle .bundle 文件）
  2. 收集所有 bundle 0x7F 资源（GetAll7fResources）
  3. 预填充到 host final_table_（SetId 固定 entry position）
     - 已有同名资源：pin existing ID
     - 新增资源：空条目占位（offset=-1）
  4. IdAssigner 运行：跳过已预留 ID，其他资源填空位
  5. ReferenceLinker：非限定引用通过 fallback 搜索 bundle 包名解析
  6. 输出 arsc：bundle 资源 entry 位置与原始 bundle 完全一致
```

后续 pipeline：`RemapHostResourceIdsTask`（仅 Type ID rewrite）→ `MergeBundleResourcesTask`（index 对齐注入 bundle 值）

### 生成/更新 patch 的方法

由于 `search_all_include_packages.patch` 依赖 `apktool_ibotpeaches.patch` 作为基线，推荐直接从 submodule 工作目录生成：

```bash
# 在 submodule 中已有所有修改的情况下，直接导出 aapt2 目录的 diff
cd submodules/base
git diff -- tools/aapt2/ > ../../patches/search_all_include_packages.patch
```

验证 patch 能干净应用：
```bash
cd submodules/base && git checkout -- .
cd ../../ && ./patch_local.sh
ninja -C build-host-arm64 aapt2
```

## Host 编译（macOS/Linux 本机 aapt2）

用于生成本机架构的 aapt2 可执行文件（供 Gradle 插件通过 `android.aapt2FromMavenOverride` 使用）：

```bash
# 打补丁 + 编译（首次或 submodule 代码变更后）
./patch_local.sh
./build_host.sh

# 产物位于 build/bin/aapt2
./build/bin/aapt2 version
```

`build_host.sh` 会自动检测当前架构（arm64/x86_64），使用 `CMakeLists_host.txt` 配置 cmake，编译静态链接的 aapt2。依赖 `protoc 21.12`（通过 `PROTOC_PATH` 环境变量指定，默认 `/tmp/protoc-21.12/bin/protoc`）。

快速重编译（仅修改了源码，无需重新 configure）：

```bash
ninja -C build-host-arm64 aapt2
cp build-host-arm64/bin/aapt2 build/bin/aapt2
```

macOS 编译 universal binary（同时支持 arm64 + x86_64）：

```bash
./build_host.sh universal
```

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

## 自定义 CLI 标志

| 标志 | 默认 | 说明 |
|------|------|------|
| `--search-all-include-packages` | false | 非限定引用查找失败时搜索所有 -I 包（Portal 模式必须） |
| `--disable-visibility-check` | true | 允许引用 -I 包中非 PUBLIC 资源 |
| `-e <file>` | — | 从文件读取不压缩扩展名列表 |
