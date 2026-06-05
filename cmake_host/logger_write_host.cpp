// host 桩文件：替代 AOSP logger_write.cpp
// 避免 GCC C++20 模式下 <stdatomic.h> 中 atomic_int 类型不兼容的问题
// 提供 libbase/logging.cpp 所需的全部 __android_log_* 函数

#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <android/log.h>
#include <log/log.h>
#include <private/android_logger.h>

static __android_logger_function g_logger_function = nullptr;
static __android_aborter_function g_aborter_function = nullptr;
static int32_t g_minimum_priority = ANDROID_LOG_DEFAULT;
static char g_default_tag[128] = "";

void __android_log_close() {
}

void __android_log_set_default_tag(const char* tag) {
  if (tag) {
    strncpy(g_default_tag, tag, sizeof(g_default_tag) - 1);
    g_default_tag[sizeof(g_default_tag) - 1] = '\0';
  }
}

int32_t __android_log_set_minimum_priority(int32_t priority) {
  int32_t old = g_minimum_priority;
  g_minimum_priority = priority;
  return old;
}

int32_t __android_log_get_minimum_priority() {
  return g_minimum_priority;
}

void __android_log_set_logger(__android_logger_function logger) {
  g_logger_function = logger;
}

void __android_log_default_aborter(const char* abort_message) {
  fprintf(stderr, "Abort: %s\n", abort_message);
  abort();
}

void __android_log_set_aborter(__android_aborter_function aborter) {
  g_aborter_function = aborter;
}

void __android_log_call_aborter(const char* abort_message) {
  if (g_aborter_function) {
    g_aborter_function(abort_message);
  } else {
    __android_log_default_aborter(abort_message);
  }
}

// 输出到 stderr 的 logger 实现
void __android_log_stderr_logger(const struct __android_log_message* log_message) {
  const char* prio_char = "?";
  switch (log_message->priority) {
    case ANDROID_LOG_VERBOSE: prio_char = "V"; break;
    case ANDROID_LOG_DEBUG:   prio_char = "D"; break;
    case ANDROID_LOG_INFO:    prio_char = "I"; break;
    case ANDROID_LOG_WARN:    prio_char = "W"; break;
    case ANDROID_LOG_ERROR:   prio_char = "E"; break;
    case ANDROID_LOG_FATAL:   prio_char = "F"; break;
    default: break;
  }
  fprintf(stderr, "%s/%s: %s\n", prio_char,
          log_message->tag ? log_message->tag : "???",
          log_message->message ? log_message->message : "");
}

// logd logger 在 host 上退化为 stderr 输出
void __android_log_logd_logger(const struct __android_log_message* log_message) {
  __android_log_stderr_logger(log_message);
}

void __android_log_write_log_message(__android_log_message* log_message) {
  if (g_logger_function) {
    g_logger_function(log_message);
  } else {
    __android_log_stderr_logger(log_message);
  }
}

int __android_log_write(int prio, const char* tag, const char* msg) {
  __android_log_message log_message = {
      sizeof(__android_log_message), LOG_ID_DEFAULT, prio, tag, nullptr, 0, msg};
  __android_log_write_log_message(&log_message);
  return 0;
}

int __android_log_buf_write(int bufID, int prio, const char* tag, const char* msg) {
  (void)bufID;
  return __android_log_write(prio, tag, msg);
}

int __android_log_vprint(int prio, const char* tag, const char* fmt, va_list ap) {
  char buf[1024];
  vsnprintf(buf, sizeof(buf), fmt, ap);
  return __android_log_write(prio, tag, buf);
}

int __android_log_print(int prio, const char* tag, const char* fmt, ...) {
  va_list ap;
  va_start(ap, fmt);
  int result = __android_log_vprint(prio, tag, fmt, ap);
  va_end(ap);
  return result;
}

int __android_log_buf_print(int bufID, int prio, const char* tag, const char* fmt, ...) {
  (void)bufID;
  va_list ap;
  va_start(ap, fmt);
  int result = __android_log_vprint(prio, tag, fmt, ap);
  va_end(ap);
  return result;
}

void __android_log_assert(const char* cond, const char* tag, const char* fmt, ...) {
  char buf[1024];
  if (fmt) {
    va_list ap;
    va_start(ap, fmt);
    vsnprintf(buf, sizeof(buf), fmt, ap);
    va_end(ap);
  } else if (cond) {
    snprintf(buf, sizeof(buf), "Assertion failed: %s", cond);
  } else {
    snprintf(buf, sizeof(buf), "Unspecified assertion failed");
  }
  __android_log_write(ANDROID_LOG_FATAL, tag, buf);
  __android_log_call_aborter(buf);
  abort();
}

// 以下为 binary event 系列桩（host 上不使用）
int __android_log_bwrite(int32_t, const void*, size_t) { return 0; }
int __android_log_stats_bwrite(int32_t, const void*, size_t) { return 0; }
int __android_log_security_bwrite(int32_t, const void*, size_t) { return 0; }
int __android_log_btwrite(int32_t, char, const void*, size_t) { return 0; }
int __android_log_bswrite(int32_t, const char*) { return 0; }
int __android_log_security_bswrite(int32_t, const char*) { return 0; }
