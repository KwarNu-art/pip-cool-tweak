#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface PipStats : NSObject

+ (instancetype)shared;

/// Call once per display link tick from the HUD.
- (void)tick;

@property (nonatomic, assign, readonly) double fps;
@property (nonatomic, assign, readonly) double cpuPercent;   // rough process CPU %
@property (nonatomic, assign, readonly) double memoryMB;
@property (nonatomic, copy, readonly) NSString *thermalLabel; // Nominal / Fair / Serious / Critical
@property (nonatomic, assign, readonly) NSInteger thermalLevel; // 0..3

@end

NS_ASSUME_NONNULL_END
