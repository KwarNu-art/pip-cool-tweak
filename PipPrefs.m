#import "PipPrefs.h"

static NSString * const kDomain = @"com.pip.cool";

@implementation PipPrefs {
    BOOL _enabled;
    BOOL _showHUD;
    NSInteger _fpsCap;
    NSInteger _graphicsLevel;
    BOOL _reduceBlur;
    BOOL _reduceAnimations;
    BOOL _lowPowerHints;
}

+ (instancetype)shared {
    static PipPrefs *s;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ s = [PipPrefs new]; [s reload]; });
    return s;
}

- (void)reload {
    NSDictionary *d = [NSDictionary dictionaryWithContentsOfFile:
        @"/var/mobile/Library/Preferences/com.pip.cool.plist"] ?: @{};

    id (^b)(NSString *, BOOL) = ^id(NSString *k, BOOL def) {
        id v = d[k];
        if ([v isKindOfClass:[NSNumber class]]) return v;
        return @(def);
    };
    id (^i)(NSString *, NSInteger) = ^id(NSString *k, NSInteger def) {
        id v = d[k];
        if ([v isKindOfClass:[NSNumber class]]) return v;
        return @(def);
    };

    _enabled = [b(@"enabled", YES) boolValue];
    _showHUD = [b(@"showHUD", YES) boolValue];
    _fpsCap = [i(@"fpsCap", 30) integerValue];
    _graphicsLevel = [i(@"graphicsLevel", 1) integerValue];
    _reduceBlur = [b(@"reduceBlur", YES) boolValue];
    _reduceAnimations = [b(@"reduceAnimations", YES) boolValue];
    _lowPowerHints = [b(@"lowPowerHints", YES) boolValue];

    // Safety: iPhone 7 Plus is 60 Hz max. Never advertise 120.
    if (_fpsCap > 60) _fpsCap = 60;
    if (_fpsCap < 0) _fpsCap = 0;
    if (_graphicsLevel < 0) _graphicsLevel = 0;
    if (_graphicsLevel > 3) _graphicsLevel = 3;
}

- (BOOL)enabled { return _enabled; }
- (BOOL)showHUD { return _showHUD; }
- (NSInteger)fpsCap { return _fpsCap; }
- (NSInteger)graphicsLevel { return _graphicsLevel; }
- (BOOL)reduceBlur { return _reduceBlur; }
- (BOOL)reduceAnimations { return _reduceAnimations; }
- (BOOL)lowPowerHints { return _lowPowerHints; }

- (CGFloat)renderScaleFactor {
    switch (_graphicsLevel) {
        case 1: return 0.85;
        case 2: return 0.70;
        case 3: return 0.55;
        default: return 1.0;
    }
}

@end
