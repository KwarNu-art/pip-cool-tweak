#import "PipStats.h"
#import <QuartzCore/QuartzCore.h>
#import <mach/mach.h>
#import <sys/sysctl.h>

@implementation PipStats {
    CFTimeInterval _lastTime;
    NSUInteger _frameCount;
    double _fps;
    double _cpuPercent;
    double _memoryMB;
    NSString *_thermalLabel;
    NSInteger _thermalLevel;
    mach_timebase_info_data_t _timebase;
    uint64_t _lastCPUTime;
    uint64_t _lastWallTime;
}

+ (instancetype)shared {
    static PipStats *s;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ s = [PipStats new]; });
    return s;
}

- (instancetype)init {
    if ((self = [super init])) {
        _lastTime = CACurrentMediaTime();
        _thermalLabel = @"Nominal";
        mach_timebase_info(&_timebase);
        _lastCPUTime = 0;
        _lastWallTime = mach_absolute_time();
    }
    return self;
}

- (void)tick {
    _frameCount++;
    CFTimeInterval now = CACurrentMediaTime();
    CFTimeInterval dt = now - _lastTime;
    if (dt >= 0.5) {
        _fps = _frameCount / dt;
        _frameCount = 0;
        _lastTime = now;
        [self refreshCPU];
        [self refreshMemory];
        [self refreshThermal];
    }
}

- (void)refreshCPU {
    task_info_data_t tinfo;
    mach_msg_type_number_t task_info_count = TASK_INFO_MAX;
    if (task_info(mach_task_self(), TASK_BASIC_INFO, (task_info_t)tinfo, &task_info_count) != KERN_SUCCESS) {
        return;
    }

    thread_array_t threadList;
    mach_msg_type_number_t threadCount;
    if (task_threads(mach_task_self(), &threadList, &threadCount) != KERN_SUCCESS) return;

    double totalUser = 0, totalSystem = 0;
    for (mach_msg_type_number_t i = 0; i < threadCount; i++) {
        thread_info_data_t thinfo;
        mach_msg_type_number_t thinfoCount = THREAD_INFO_MAX;
        if (thread_info(threadList[i], THREAD_BASIC_INFO, (thread_info_t)thinfo, &thinfoCount) == KERN_SUCCESS) {
            thread_basic_info_t basic = (thread_basic_info_t)thinfo;
            if (!(basic->flags & TH_FLAGS_IDLE)) {
                totalUser += basic->user_time.seconds + basic->user_time.microseconds * 1e-6;
                totalSystem += basic->system_time.seconds + basic->system_time.microseconds * 1e-6;
            }
        }
    }
    vm_deallocate(mach_task_self(), (vm_address_t)threadList, threadCount * sizeof(thread_t));

    // Rough instantaneous-ish CPU for this process (not perfect system-wide GPU).
    static double prev = 0;
    double cur = totalUser + totalSystem;
    double delta = cur - prev;
    prev = cur;
    // Scale into a soft 0–100 range for HUD display.
    _cpuPercent = MIN(100.0, MAX(0.0, delta * 40.0));
}

- (void)refreshMemory {
    task_vm_info_data_t info;
    mach_msg_type_number_t count = TASK_VM_INFO_COUNT;
    if (task_info(mach_task_self(), TASK_VM_INFO, (task_info_t)&info, &count) == KERN_SUCCESS) {
        _memoryMB = info.phys_footprint / (1024.0 * 1024.0);
    }
}

- (void)refreshThermal {
    if (@available(iOS 11.0, *)) {
        NSProcessInfoThermalState state = NSProcessInfo.processInfo.thermalState;
        switch (state) {
            case NSProcessInfoThermalStateNominal:
                _thermalLabel = @"Nominal";
                _thermalLevel = 0;
                break;
            case NSProcessInfoThermalStateFair:
                _thermalLabel = @"Fair";
                _thermalLevel = 1;
                break;
            case NSProcessInfoThermalStateSerious:
                _thermalLabel = @"Serious";
                _thermalLevel = 2;
                break;
            case NSProcessInfoThermalStateCritical:
                _thermalLabel = @"Critical";
                _thermalLevel = 3;
                break;
            default:
                _thermalLabel = @"Unknown";
                _thermalLevel = 0;
                break;
        }
    }
}

- (double)fps { return _fps; }
- (double)cpuPercent { return _cpuPercent; }
- (double)memoryMB { return _memoryMB; }
- (NSString *)thermalLabel { return _thermalLabel ?: @"—"; }
- (NSInteger)thermalLevel { return _thermalLevel; }

@end
