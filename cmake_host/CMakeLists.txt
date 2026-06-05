# host 构建：支持 macOS / Linux / Windows (MinGW)
# 裁掉了 selinux/sepol/processgroup 等 Android/Linux 专有部分

set(EXECUTABLE_OUTPUT_PATH ${CMAKE_BINARY_DIR}/bin)

# ========================= liblog (精简，去掉 Android 专有的 pmsg/logd) ============================
add_library(liblog STATIC
    ${SRC}/logging/liblog/log_event_list.cpp
    ${SRC}/logging/liblog/log_event_write.cpp
    ${SRC}/logging/liblog/logger_name.cpp
    ${SRC}/logging/liblog/logger_write.cpp
    ${SRC}/logging/liblog/properties.cpp
    ${SRC}/logging/liblog/logprint.cpp
    ${SRC}/logging/liblog/event_tag_map.cpp
    ${SRC}/logging/liblog/log_time.cpp
    )
target_compile_definitions(liblog PRIVATE
    -DLIBLOG_LOG_TAG=1006
    -DFAKE_LOG_DEVICE=1
    -DSNET_EVENT_LOG_TAG=1397638686
    -DANDROID_DEBUGGABLE=0
    )
target_include_directories(liblog PRIVATE
    ${SRC}/core/include
    ${SRC}/logging/liblog/include
    ${SRC}/core/libcutils/include
    ${SRC}/libbase/include
    )

# ========================= libbase ============================
set(LIBBASE_SOURCES
    ${SRC}/libbase/abi_compatibility.cpp
    ${SRC}/libbase/chrono_utils.cpp
    ${SRC}/libbase/file.cpp
    ${SRC}/libbase/hex.cpp
    ${SRC}/libbase/logging.cpp
    ${SRC}/libbase/mapped_file.cpp
    ${SRC}/libbase/parsebool.cpp
    ${SRC}/libbase/parsenetaddress.cpp
    ${SRC}/libbase/process.cpp
    ${SRC}/libbase/properties.cpp
    ${SRC}/libbase/result.cpp
    ${SRC}/libbase/stringprintf.cpp
    ${SRC}/libbase/strings.cpp
    ${SRC}/libbase/threads.cpp
    ${SRC}/libbase/test_utils.cpp
    )
if(WIN32)
    list(APPEND LIBBASE_SOURCES
        ${SRC}/libbase/errors_windows.cpp
        ${SRC}/libbase/utf8.cpp
        )
else()
    list(APPEND LIBBASE_SOURCES
        ${SRC}/libbase/errors_unix.cpp
        ${SRC}/libbase/posix_strerror_r.cpp
        )
endif()
add_library(libbase STATIC ${LIBBASE_SOURCES})
target_include_directories(libbase PRIVATE
    ${SRC}/libbase/include
    ${SRC}/core/include
    ${SRC}/fmtlib/include
    ${SRC}/logging/liblog/include
    )

# ========================= libcutils (精简，加上 trace-host stub) ============================
set(LIBCUTILS_SOURCES
    ${SRC}/core/libcutils/config_utils.cpp
    ${SRC}/core/libcutils/hashmap.cpp
    ${SRC}/core/libcutils/load_file.cpp
    ${SRC}/core/libcutils/native_handle.cpp
    ${SRC}/core/libcutils/trace-host.cpp
    )
if(NOT WIN32)
    # POSIX socket 相关文件仅在 Unix 系统编译
    list(APPEND LIBCUTILS_SOURCES
        ${SRC}/core/libcutils/fs.cpp
        ${SRC}/core/libcutils/multiuser.cpp
        ${SRC}/core/libcutils/properties.cpp
        ${SRC}/core/libcutils/record_stream.cpp
        ${SRC}/core/libcutils/socket_inaddr_any_server_unix.cpp
        ${SRC}/core/libcutils/socket_local_client_unix.cpp
        ${SRC}/core/libcutils/socket_local_server_unix.cpp
        ${SRC}/core/libcutils/socket_network_client_unix.cpp
        ${SRC}/core/libcutils/sockets_unix.cpp
        ${SRC}/core/libcutils/sockets.cpp
        ${SRC}/core/libcutils/str_parms.cpp
        )
endif()
add_library(libcutils STATIC ${LIBCUTILS_SOURCES})
target_compile_definitions(libcutils PRIVATE -D_GNU_SOURCE)
target_include_directories(libcutils PRIVATE
    ${SRC}/core/libutils/include
    ${SRC}/core/libcutils/include
    ${SRC}/logging/liblog/include
    ${SRC}/libbase/include
    )

# ========================= libutils (精简，去掉 Looper) ============================
add_library(libutils STATIC
    ${SRC}/core/libutils/FileMap.cpp
    ${SRC}/core/libutils/JenkinsHash.cpp
    ${SRC}/core/libutils/LightRefBase.cpp
    ${SRC}/core/libutils/NativeHandle.cpp
    ${SRC}/core/libutils/Printer.cpp
    ${SRC}/core/libutils/StopWatch.cpp
    ${SRC}/core/libutils/SystemClock.cpp
    ${SRC}/core/libutils/Threads.cpp
    ${SRC}/core/libutils/Timers.cpp
    ${SRC}/core/libutils/Tokenizer.cpp
    ${SRC}/core/libutils/misc.cpp
    ${SRC}/core/libutils/Trace.cpp
    ${SRC}/core/libutils/binder/Errors.cpp
    ${SRC}/core/libutils/binder/RefBase.cpp
    ${SRC}/core/libutils/binder/SharedBuffer.cpp
    ${SRC}/core/libutils/binder/String16.cpp
    ${SRC}/core/libutils/binder/String8.cpp
    ${SRC}/core/libutils/binder/StrongPointer.cpp
    ${SRC}/core/libutils/binder/Unicode.cpp
    ${SRC}/core/libutils/binder/VectorImpl.cpp
    )
target_include_directories(libutils PRIVATE
    ${SRC}/core/include
    ${SRC}/core/libutils/include
    ${SRC}/core/libvndksupport/include
    ${SRC}/logging/liblog/include
    ${SRC}/libbase/include
    ${SRC}/unwinding/libbacktrace/include
    )

# ========================= libandroidfw ============================
add_library(libandroidfw STATIC
    ${SRC}/base/libs/androidfw/ApkAssets.cpp
    ${SRC}/base/libs/androidfw/ApkParsing.cpp
    ${SRC}/base/libs/androidfw/Asset.cpp
    ${SRC}/base/libs/androidfw/AssetDir.cpp
    ${SRC}/base/libs/androidfw/AssetManager.cpp
    ${SRC}/base/libs/androidfw/AssetManager2.cpp
    ${SRC}/base/libs/androidfw/AssetsProvider.cpp
    ${SRC}/base/libs/androidfw/AttributeResolution.cpp
    ${SRC}/base/libs/androidfw/BigBuffer.cpp
    ${SRC}/base/libs/androidfw/BigBufferStream.cpp
    ${SRC}/base/libs/androidfw/ChunkIterator.cpp
    ${SRC}/base/libs/androidfw/ConfigDescription.cpp
    ${SRC}/base/libs/androidfw/FileStream.cpp
    ${SRC}/base/libs/androidfw/Idmap.cpp
    ${SRC}/base/libs/androidfw/LoadedArsc.cpp
    ${SRC}/base/libs/androidfw/Locale.cpp
    ${SRC}/base/libs/androidfw/LocaleData.cpp
    ${SRC}/base/libs/androidfw/misc.cpp
    ${SRC}/base/libs/androidfw/NinePatch.cpp
    ${SRC}/base/libs/androidfw/ObbFile.cpp
    ${SRC}/base/libs/androidfw/PosixUtils.cpp
    ${SRC}/base/libs/androidfw/Png.cpp
    ${SRC}/base/libs/androidfw/PngChunkFilter.cpp
    ${SRC}/base/libs/androidfw/PngCrunch.cpp
    ${SRC}/base/libs/androidfw/ResourceTimer.cpp
    ${SRC}/base/libs/androidfw/ResourceTypes.cpp
    ${SRC}/base/libs/androidfw/ResourceUtils.cpp
    ${SRC}/base/libs/androidfw/StreamingZipInflater.cpp
    ${SRC}/base/libs/androidfw/StringPool.cpp
    ${SRC}/base/libs/androidfw/TypeWrappers.cpp
    ${SRC}/base/libs/androidfw/Util.cpp
    ${SRC}/base/libs/androidfw/ZipFileRO.cpp
    ${SRC}/base/libs/androidfw/ZipUtils.cpp
    ${SRC}/base/libs/androidfw/PathUtils.cpp
    )
target_compile_definitions(libandroidfw PRIVATE
    -DSTATIC_ANDROIDFW_FOR_TOOLS
    -D_GNU_SOURCE -DNDEBUG
    )
target_include_directories(libandroidfw PUBLIC
    ${SRC}/base/libs/androidfw/include
    ${SRC}/base/libs/androidfw/include_pathutils
    ${SRC}/core/libcutils/include
    ${SRC}/logging/liblog/include
    ${SRC}/core/libsystem/include
    ${SRC}/core/libutils/include
    ${SRC}/libpng
    ${SRC}/libbase/include
    ${SRC}/native/include
    ${SRC}/native/libs/binder/include
    ${SRC}/libziparchive/include
    ${SRC}/incremental_delivery/incfs/util/include
    ${SRC}/incremental_delivery/incfs/kernel-headers
    )
target_link_libraries(libandroidfw PUBLIC fmt::fmt)

# ========================= libincfs (仅 map_ptr 工具类) ============================
add_library(libincfs STATIC
    ${SRC}/incremental_delivery/incfs/util/map_ptr.cpp
    )
target_include_directories(libincfs PRIVATE
    ${SRC}/incremental_delivery/incfs/include
    ${SRC}/incremental_delivery/incfs/util/include
    ${SRC}/incremental_delivery/incfs/kernel-headers
    ${SRC}/libbase/include
    ${SRC}/core/libutils/include
    ${SRC}/logging/liblog/include
    )

# ========================= libziparchive ============================
add_library(libziparchive STATIC
    ${SRC}/libziparchive/zip_archive.cc
    ${SRC}/libziparchive/zip_archive_stream_entry.cc
    ${SRC}/libziparchive/zip_cd_entry_map.cc
    ${SRC}/libziparchive/zip_writer.cc
    ${SRC}/libziparchive/zip_error.cpp
    )
target_compile_definitions(libziparchive PRIVATE
    -DZLIB_CONST
    -D_FILE_OFFSET_BITS=64
    -DZIPARCHIVE_DISABLE_CALLBACK_API=1
    )
target_include_directories(libziparchive PRIVATE
    ${SRC}/libziparchive/include
    ${SRC}/libziparchive/incfs_support/include
    ${SRC}/libbase/include
    ${SRC}/logging/liblog/include
    ${SRC}/googletest/googletest/include
    )

# ========================= libbuildversion ============================
# 通过 AAPT2_BUILD_NUMBER 环境变量或 CMake 变量注入版本号
# 格式：日期+序号，如 2026060501
if(NOT DEFINED AAPT2_BUILD_NUMBER)
    if(DEFINED ENV{AAPT2_BUILD_NUMBER})
        set(AAPT2_BUILD_NUMBER "$ENV{AAPT2_BUILD_NUMBER}")
    else()
        string(TIMESTAMP AAPT2_BUILD_NUMBER "%Y%m%d01")
    endif()
endif()
message(STATUS "aapt2 build number: ${AAPT2_BUILD_NUMBER}")

# 生成带版本号的源文件替代原始 libbuildversion.cpp
file(WRITE "${CMAKE_BINARY_DIR}/libbuildversion_host.cpp"
"#include <build/version.h>
namespace android {
namespace build {
extern \"C\" {
  char soong_build_number[128] = \"${AAPT2_BUILD_NUMBER}\";
}
std::string GetBuildNumber() {
  return soong_build_number;
}
}  // namespace build
}  // namespace android
")

add_library(libbuildversion STATIC
    ${CMAKE_BINARY_DIR}/libbuildversion_host.cpp
    )
target_include_directories(libbuildversion PRIVATE
    ${SRC}/soong/cc/libbuildversion/include
    )

# ========================= aapt2 proto ============================
set(AAPT2_PROTO_SRC)
set(AAPT2_PROTO_HDRS)
set(AAPT2_PROTO_DIR ${SRC}/base/tools/aapt2)

file(GLOB_RECURSE PROTO_FILES ${AAPT2_PROTO_DIR}/*.proto)

find_package(Protobuf)

if(NOT EXISTS ${Protobuf_PROTOC_EXECUTABLE})
    message(FATAL_ERROR "Invalid protoc: ${Protobuf_PROTOC_EXECUTABLE}")
endif()

foreach(proto ${PROTO_FILES})
    get_filename_component(FIL_WE ${proto} NAME_WE)
    execute_process(
        COMMAND ${Protobuf_PROTOC_EXECUTABLE} ${proto}
        --proto_path=${AAPT2_PROTO_DIR}
        --cpp_out=${AAPT2_PROTO_DIR}
        COMMAND_ECHO STDOUT
        RESULT_VARIABLE RESULT
        WORKING_DIRECTORY ${PROJECT_SOURCE_DIR}
    )
    set(TARGET_CPP_FILE "${AAPT2_PROTO_DIR}/${FIL_WE}.pb.cc")
    set(TARGET_HEAD_FILE "${AAPT2_PROTO_DIR}/${FIL_WE}.pb.h")
    if(EXISTS ${TARGET_CPP_FILE} AND EXISTS ${TARGET_HEAD_FILE})
        list(APPEND AAPT2_PROTO_SRC ${TARGET_CPP_FILE})
        list(APPEND AAPT2_PROTO_HDRS ${TARGET_HEAD_FILE})
    endif()
endforeach()

set_source_files_properties(${AAPT2_PROTO_SRC} ${AAPT2_PROTO_HDRS} PROPERTIES GENERATED TRUE)

# ========================= libaapt2 ============================
set(COMPILE_FLAGS
    -Wno-unused-parameter
    -Wno-missing-field-initializers
    -fno-exceptions
    -fno-rtti)

set(INCLUDES
    ${SRC}/base/tools/aapt2
    ${SRC}/protobuf/src
    ${SRC}/logging/liblog/include
    ${SRC}/expat/lib
    ${SRC}/fmtlib/include
    ${SRC}/native/include
    ${SRC}/libpng
    ${SRC}/libbase/include
    ${SRC}/base/libs/androidfw/include
    ${SRC}/base/libs/androidfw/include_pathutils
    ${SRC}/base/cmds/idmap2/libidmap2_policies/include
    ${SRC}/core/libsystem/include
    ${SRC}/core/libutils/include
    ${SRC}/googletest/googletest/include
    ${SRC}/libziparchive/include
    ${SRC}/soong/cc/libbuildversion/include
    ${SRC}/incremental_delivery/incfs/util/include
    ${SRC}/incremental_delivery/incfs/kernel-headers
    )

add_library(libaapt2 STATIC
    ${SRC}/base/tools/aapt2/compile/IdAssigner.cpp
    ${SRC}/base/tools/aapt2/compile/InlineXmlFormatParser.cpp
    ${SRC}/base/tools/aapt2/compile/PseudolocaleGenerator.cpp
    ${SRC}/base/tools/aapt2/compile/Pseudolocalizer.cpp
    ${SRC}/base/tools/aapt2/compile/XmlIdCollector.cpp
    ${SRC}/base/tools/aapt2/configuration/ConfigurationParser.cpp
    ${SRC}/base/tools/aapt2/dump/DumpManifest.cpp
    ${SRC}/base/tools/aapt2/filter/AbiFilter.cpp
    ${SRC}/base/tools/aapt2/filter/ConfigFilter.cpp
    ${SRC}/base/tools/aapt2/format/Archive.cpp
    ${SRC}/base/tools/aapt2/format/Container.cpp
    ${SRC}/base/tools/aapt2/format/binary/BinaryResourceParser.cpp
    ${SRC}/base/tools/aapt2/format/binary/ResChunkPullParser.cpp
    ${SRC}/base/tools/aapt2/format/binary/ResEntryWriter.cpp
    ${SRC}/base/tools/aapt2/format/binary/TableFlattener.cpp
    ${SRC}/base/tools/aapt2/format/binary/XmlFlattener.cpp
    ${SRC}/base/tools/aapt2/format/proto/ProtoDeserialize.cpp
    ${SRC}/base/tools/aapt2/format/proto/ProtoSerialize.cpp
    ${SRC}/base/tools/aapt2/io/File.cpp
    ${SRC}/base/tools/aapt2/io/FileSystem.cpp
    ${SRC}/base/tools/aapt2/io/StringStream.cpp
    ${SRC}/base/tools/aapt2/io/Util.cpp
    ${SRC}/base/tools/aapt2/io/ZipArchive.cpp
    ${SRC}/base/tools/aapt2/link/AutoVersioner.cpp
    ${SRC}/base/tools/aapt2/link/FeatureFlagsFilter.cpp
    ${SRC}/base/tools/aapt2/link/ManifestFixer.cpp
    ${SRC}/base/tools/aapt2/link/NoDefaultResourceRemover.cpp
    ${SRC}/base/tools/aapt2/link/PrivateAttributeMover.cpp
    ${SRC}/base/tools/aapt2/link/ReferenceLinker.cpp
    ${SRC}/base/tools/aapt2/link/ResourceExcluder.cpp
    ${SRC}/base/tools/aapt2/link/TableMerger.cpp
    ${SRC}/base/tools/aapt2/link/XmlCompatVersioner.cpp
    ${SRC}/base/tools/aapt2/link/XmlNamespaceRemover.cpp
    ${SRC}/base/tools/aapt2/link/XmlReferenceLinker.cpp
    ${SRC}/base/tools/aapt2/optimize/MultiApkGenerator.cpp
    ${SRC}/base/tools/aapt2/optimize/ResourceDeduper.cpp
    ${SRC}/base/tools/aapt2/optimize/ResourceFilter.cpp
    ${SRC}/base/tools/aapt2/optimize/Obfuscator.cpp
    ${SRC}/base/tools/aapt2/optimize/VersionCollapser.cpp
    ${SRC}/base/tools/aapt2/process/ProductFilter.cpp
    ${SRC}/base/tools/aapt2/process/SymbolTable.cpp
    ${SRC}/base/tools/aapt2/split/TableSplitter.cpp
    ${SRC}/base/tools/aapt2/text/Printer.cpp
    ${SRC}/base/tools/aapt2/text/Unicode.cpp
    ${SRC}/base/tools/aapt2/text/Utf8Iterator.cpp
    ${SRC}/base/tools/aapt2/util/Files.cpp
    ${SRC}/base/tools/aapt2/util/Util.cpp
    ${SRC}/base/tools/aapt2/Debug.cpp
    ${SRC}/base/tools/aapt2/DominatorTree.cpp
    ${SRC}/base/tools/aapt2/java/AnnotationProcessor.cpp
    ${SRC}/base/tools/aapt2/java/ClassDefinition.cpp
    ${SRC}/base/tools/aapt2/java/JavaClassGenerator.cpp
    ${SRC}/base/tools/aapt2/java/ManifestClassGenerator.cpp
    ${SRC}/base/tools/aapt2/java/ProguardRules.cpp
    ${SRC}/base/tools/aapt2/LoadedApk.cpp
    ${SRC}/base/tools/aapt2/Resource.cpp
    ${SRC}/base/tools/aapt2/ResourceParser.cpp
    ${SRC}/base/tools/aapt2/ResourceTable.cpp
    ${SRC}/base/tools/aapt2/ResourceUtils.cpp
    ${SRC}/base/tools/aapt2/ResourceValues.cpp
    ${SRC}/base/tools/aapt2/SdkConstants.cpp
    ${SRC}/base/tools/aapt2/trace/TraceBuffer.cpp
    ${SRC}/base/tools/aapt2/xml/XmlActionExecutor.cpp
    ${SRC}/base/tools/aapt2/xml/XmlDom.cpp
    ${SRC}/base/tools/aapt2/xml/XmlPullParser.cpp
    ${SRC}/base/tools/aapt2/xml/XmlUtil.cpp
    ${SRC}/base/tools/aapt2/ValueTransformer.cpp
    ${AAPT2_PROTO_SRC}
    ${AAPT2_PROTO_HDRS}
    )

target_include_directories(libaapt2 PRIVATE ${INCLUDES})
target_compile_options(libaapt2 PRIVATE ${COMPILE_FLAGS})

# ========================= aapt2 可执行文件 ============================
set(TOOL_SOURCE
    ${SRC}/base/tools/aapt2/cmd/ApkInfo.cpp
    ${SRC}/base/tools/aapt2/cmd/Command.cpp
    ${SRC}/base/tools/aapt2/cmd/Compile.cpp
    ${SRC}/base/tools/aapt2/cmd/Convert.cpp
    ${SRC}/base/tools/aapt2/cmd/Diff.cpp
    ${SRC}/base/tools/aapt2/cmd/Dump.cpp
    ${SRC}/base/tools/aapt2/cmd/Link.cpp
    ${SRC}/base/tools/aapt2/cmd/Optimize.cpp
    ${SRC}/base/tools/aapt2/cmd/Util.cpp
    )

add_executable(aapt2
    ${SRC}/base/tools/aapt2/Main.cpp
    ${TOOL_SOURCE}
    )

target_include_directories(aapt2 PRIVATE ${INCLUDES})
target_compile_options(aapt2 PRIVATE ${COMPILE_FLAGS})

target_link_libraries(aapt2
    libaapt2
    libandroidfw
    libincfs
    libutils
    libcutils
    libziparchive
    libbase
    libbuildversion
    liblog
    libprotoc
    libprotobuf
    expat
    png_static
    ZLIB::ZLIB
    )

# Windows 额外链接库
if(WIN32)
    target_link_libraries(aapt2 ws2_32 shlwapi)
endif()
