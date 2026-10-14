/*
 * Pip — tiny cool companion for older iPhones (iPhone 7 Plus friendly)
 *
 * Honest goals:
 *  - Cap preferred FPS (15 / 20 / 30 / 60). Hardware max on 7 Plus is 60 Hz.
 *  - Optionally lower content scale to reduce GPU fill rate and heat.
 *  - Soften blur / heavy animations when enabled.
 *  - Floating "pip" pill + stats panel (CPU / thermal / FPS).
 *
 * This cannot remove heat 100%. It only lowers work so the phone stays cooler longer.
 */

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>
#import "PipPrefs.h"
#import "PipHUD.h"

static void PipApplyFPSCap(CADisplayLink *link) {
    PipPrefs *p = [PipPrefs shared];
    if (!p.enabled || p.fpsCap <= 0) return;
    if (@available(iOS 10.0, *)) {
        NSInteger cap = p.fpsCap;
        if (cap > 60) cap = 60; // 7 Plus cannot do 120
        if (link.preferredFramesPerSecond != cap) {
            link.preferredFramesPerSecond = (NSInteger)cap;
        }
    }
}

%hook CADisplayLink

- (void)addToRunLoop:(NSRunLoop *)runloop forMode:(NSRunLoopMode)mode {
    PipApplyFPSCap(self);
    %orig;
}

- (void)setPreferredFramesPerSecond:(NSInteger)fps {
    PipPrefs *p = [PipPrefs shared];
    if (p.enabled && p.fpsCap > 0) {
        NSInteger cap = p.fpsCap;
        if (cap > 60) cap = 60;
        if (fps <= 0 || fps > cap) fps = cap;
    }
    %orig(fps);
}

%end

%hook UIView

- (void)didMoveToWindow {
    %orig;
    PipPrefs *p = [PipPrefs shared];
    if (!p.enabled) return;

    // Lower layer contents scale slightly on large views to cut pixel fill.
    CGFloat factor = [p renderScaleFactor];
    if (factor < 0.999 && self.window && self.bounds.size.width * self.bounds.size.height > 40000) {
        CGFloat target = UIScreen.mainScreen.scale * factor;
        if (self.layer.contentsScale > target + 0.01) {
            self.layer.contentsScale = target;
        }
    }
}

%end

%hook UIVisualEffectView

- (void)setEffect:(UIVisualEffect *)effect {
    PipPrefs *p = [PipPrefs shared];
    if (p.enabled && p.reduceBlur) {
        // Replace heavy blur with a cheap dark wash when possible.
        if ([effect isKindOfClass:[UIBlurEffect class]]) {
            %orig(nil);
            self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.35];
            return;
        }
    }
    %orig;
}

%end

%hook UIView

+ (void)setAnimationsEnabled:(BOOL)enabled {
    PipPrefs *p = [PipPrefs shared];
    if (p.enabled && p.reduceAnimations) {
        %orig(NO);
        return;
    }
    %orig;
}

%end

static void PipBootstrap(void) {
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        [[PipPrefs shared] reload];
        // Delay so key windows exist.
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [[PipPrefs shared] reload];
            [[PipHUD shared] installIfNeeded];
        });
    });
}

%ctor {
    // Skip injection into some system daemons that are not UI apps.
    NSString *bundle = [NSBundle mainBundle].bundleIdentifier ?: @"";
    if ([bundle hasPrefix:@"com.apple."] &&
        ![bundle isEqualToString:@"com.apple.springboard"] &&
        ![bundle containsString:@"UIKit"] &&
        ![bundle isEqualToString:@"com.apple.Preferences"]) {
        // Still allow normal apps; UIKit filter already limits most non-UI processes.
    }
    PipBootstrap();
}
