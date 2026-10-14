#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Shared preferences for Pip (read from /var/mobile/Library/Preferences/com.pip.cool.plist)
@interface PipPrefs : NSObject

+ (instancetype)shared;

@property (nonatomic, assign, readonly) BOOL enabled;
@property (nonatomic, assign, readonly) BOOL showHUD;
@property (nonatomic, assign, readonly) NSInteger fpsCap;          // 0 = off, 60, 30, 20, 15
@property (nonatomic, assign, readonly) NSInteger graphicsLevel;   // 0 = normal, 1 = small, 2 = smaller, 3 = smallest
@property (nonatomic, assign, readonly) BOOL reduceBlur;
@property (nonatomic, assign, readonly) BOOL reduceAnimations;
@property (nonatomic, assign, readonly) BOOL lowPowerHints;

- (void)reload;
- (CGFloat)renderScaleFactor; // 1.0 .. ~0.5 based on graphicsLevel

@end

NS_ASSUME_NONNULL_END
