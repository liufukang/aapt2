// host 桩：提供 posix_strerror_r
// Linux 定义 _GNU_SOURCE 时 strerror_r 返回 char*，macOS/BSD 返回 int

#include <string.h>
#include <stdio.h>

namespace android {
namespace base {

extern "C" int posix_strerror_r(int errnum, char* buf, size_t buflen) {
#ifdef _WIN32
  return strerror_s(buf, buflen, errnum);
#elif defined(__GLIBC__) && defined(_GNU_SOURCE)
  // GNU glibc strerror_r 返回 char*，可能指向 buf 或静态缓冲区
  char* result = strerror_r(errnum, buf, buflen);
  if (result != buf) {
    snprintf(buf, buflen, "%s", result);
  }
  return 0;
#else
  // POSIX (macOS/BSD) strerror_r 返回 int
  return strerror_r(errnum, buf, buflen);
#endif
}

}  // namespace base
}  // namespace android
