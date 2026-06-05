// host 桩文件：替代 trace-host.cpp
// 避免 cutils/trace.h 中 atomic_bool 在 GCC C++20 下不兼容的问题

#include <stdint.h>
#include <stdbool.h>

extern "C" {

// 提供 trace.h 中声明的全局变量（不 include trace.h 以避免 atomic 问题）
bool                    atrace_is_ready      = true;
int                     atrace_marker_fd     = -1;
uint64_t                atrace_enabled_tags  = 0;

void atrace_set_tracing_enabled(bool) {}
void atrace_update_tags() {}
void atrace_setup() {}
void atrace_begin_body(const char*) {}
void atrace_end_body() {}
void atrace_async_begin_body(const char*, int32_t) {}
void atrace_async_end_body(const char*, int32_t) {}
void atrace_async_for_track_begin_body(const char*, const char*, int32_t) {}
void atrace_async_for_track_end_body(const char*, int32_t) {}
void atrace_instant_body(const char*) {}
void atrace_instant_for_track_body(const char*, const char*) {}
void atrace_int_body(const char*, int32_t) {}
void atrace_int64_body(const char*, int64_t) {}
void atrace_init() {}
uint64_t atrace_get_enabled_tags() { return 0; }

} // extern "C"