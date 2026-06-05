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

// 2. GCC C++20 下 <stdatomic.h> 不暴露 C11 atomic 裸类型名
//    AOSP 头文件（cutils/trace.h, cutils/atomic.h, logger.h）大量使用这些 C11 类型
#if defined(__cplusplus) && !defined(__clang__)
#include <atomic>
using std::atomic_bool;
using std::atomic_int;
using std::atomic_int_least32_t;
using std::memory_order;
using std::memory_order_relaxed;
using std::memory_order_acquire;
using std::memory_order_release;
using std::memory_order_seq_cst;
using std::atomic_thread_fence;
using std::atomic_load_explicit;
using std::atomic_store_explicit;
using std::atomic_fetch_add_explicit;
using std::atomic_fetch_sub_explicit;
using std::atomic_fetch_and_explicit;
using std::atomic_fetch_or_explicit;
using std::atomic_compare_exchange_strong_explicit;
#endif

// 3. AOSP 源码部分文件依赖隐式 include，Linux 标准库不提供
#if defined(__cplusplus)
#include <cstring>
#include <cstdlib>
#include <limits>
#endif

// 4. Windows (MinGW) 缺少 POSIX localtime_r
#if defined(_WIN32) && !defined(localtime_r)
#include <time.h>
static inline struct tm* localtime_r(const time_t* timep, struct tm* result) {
    localtime_s(result, timep);
    return result;
}
#endif

#endif // HOST_AVAILABILITY_H
