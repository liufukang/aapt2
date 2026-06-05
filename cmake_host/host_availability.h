// host 构建兼容头：修复各编译器和平台的兼容性问题
// 通过 -include 全局注入到所有编译单元

#ifndef HOST_AVAILABILITY_H
#define HOST_AVAILABILITY_H

// 0. fmtlib 10.2 的 consteval 在 Clang 21+ 上有 bug，禁用
#ifndef FMT_CONSTEVAL
#define FMT_CONSTEVAL
#endif

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
#include <memory>
#endif

// 4. Windows (MinGW/CLANG64) 缺少 POSIX localtime_r
#if defined(_WIN32) && !defined(localtime_r)
#include <time.h>
static inline struct tm* localtime_r(const time_t* timep, struct tm* result) {
    localtime_s(result, timep);
    return result;
}
#endif

// 5. Windows 缺少 POSIX strptime，提供简化实现
#if defined(_WIN32) && !defined(strptime)
#include <time.h>
#include <ctype.h>
#include <string.h>
static inline char* strptime(const char* s, const char* format, struct tm* tm) {
    // 简化实现：支持 %Y %m %d %H %M %S 等基本格式
    const char* sp = s;
    const char* fp = format;
    while (*fp && *sp) {
        if (*fp == '%') {
            fp++;
            switch (*fp) {
                case 'Y':
                    tm->tm_year = 0;
                    while (isdigit((unsigned char)*sp)) { tm->tm_year = tm->tm_year * 10 + (*sp++ - '0'); }
                    tm->tm_year -= 1900;
                    break;
                case 'm':
                    tm->tm_mon = 0;
                    while (isdigit((unsigned char)*sp)) { tm->tm_mon = tm->tm_mon * 10 + (*sp++ - '0'); }
                    tm->tm_mon -= 1;
                    break;
                case 'd':
                    tm->tm_mday = 0;
                    while (isdigit((unsigned char)*sp)) { tm->tm_mday = tm->tm_mday * 10 + (*sp++ - '0'); }
                    break;
                case 'H':
                    tm->tm_hour = 0;
                    while (isdigit((unsigned char)*sp)) { tm->tm_hour = tm->tm_hour * 10 + (*sp++ - '0'); }
                    break;
                case 'M':
                    tm->tm_min = 0;
                    while (isdigit((unsigned char)*sp)) { tm->tm_min = tm->tm_min * 10 + (*sp++ - '0'); }
                    break;
                case 'S':
                    tm->tm_sec = 0;
                    while (isdigit((unsigned char)*sp)) { tm->tm_sec = tm->tm_sec * 10 + (*sp++ - '0'); }
                    break;
                default:
                    if (*sp == *fp) sp++;
                    break;
            }
            fp++;
        } else {
            if (*sp == *fp) { sp++; fp++; }
            else break;
        }
    }
    return const_cast<char*>(sp);
}
#endif

#endif // HOST_AVAILABILITY_H
