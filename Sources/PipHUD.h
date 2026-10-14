#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PipHUD : NSObject

+ (instancetype)shared;
- (void)installIfNeeded;
- (void)reloadFromPrefs;

@end

NS_ASSUME_NONNULL_END
