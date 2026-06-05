// host 构建兼容头：修复 GCC C++20 下的兼容性问题
// 通过 -include 全局注入到所有编译单元

#ifndef HOST_AVAILABILITY_H
#define HOST_AVAILABILITY_H

// 1. GCC 不支持 Clang 的 __builtin_available(android 30, *) 语法
#ifndef __has_builtin
#define __has_builtin(x) 0
#endif

#if !__has_builtin(__builtin_available)
#define __builtin_available(...) (true)
#endif

// 2. GCC C++20 下 <stdatomic.h> 不暴露 atomic_bool/atomic_int 裸类型名
//    AOSP 头文件（cutils/trace.h, logger.h）使用了这些 C11 类型
#if defined(__cplusplus) && !defined(__clang__)
#include <atomic>
using atomic_bool = std::atomic<bool>;
using atomic_int = std::atomic<int>;
#endif

// 3. Windows (MinGW) 缺少 POSIX localtime_r
#if defined(_WIN32) && !defined(localtime_r)
#include <time.h>
static inline struct tm* localtime_r(const time_t* timep, struct tm* result) {
    localtime_s(result, timep);
    return result;
}
#endif

#endif // HOST_AVAILABILITY_H
