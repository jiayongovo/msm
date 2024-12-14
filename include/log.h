// 定义日志级别
#define INFO 1
#define WARN 2
#define ERROR 3

// 定义是否启用日志（0为禁用，非0为启用）
#define ENABLE_LOGGING 1

// 获取日志级别字符串
#define LOG_LEVEL_STRING(level) \
    (level == INFO ? "INFO" : \
    (level == WARN ? "WARN" : \
    (level == ERROR ? "ERROR" : "UNKNOWN")))

// 日志宏定义
#if ENABLE_LOGGING
    #define LOG(level, fmt, ...) \
        do { \
        if (level >= INFO && level <= ERROR) {  \
                printf("[%s:%d](%s) [%s] " fmt "\n", __FILE__, __LINE__, __FUNCTION__, LOG_LEVEL_STRING(level), ##__VA_ARGS__); \
            } \
        } while(0)
#else
    #define LOG(level, fmt, ...)
#endif

