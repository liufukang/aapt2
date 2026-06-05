// host 构建兼容头：将 Clang 专有的 __builtin_available 替换为 true
// GCC 不支持 __builtin_available(android 30, *) 语法
#ifndef __has_builtin
#define __has_builtin(x) 0
#endif

#if !__has_builtin(__builtin_available)
#define __builtin_available(...) (true)
#endif
