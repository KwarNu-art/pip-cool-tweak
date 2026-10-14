#import "PipHUD.h"
#import "PipPrefs.h"
#import "PipStats.h"

@interface PipPassthroughView : UIView
@end
@implementation PipPassthroughView
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *v = [super hitTest:point withEvent:event];
    return (v == self) ? nil : v;
}
@end

@interface PipHUD ()
@property (nonatomic, strong) UIWindow *window;
@property (nonatomic, strong) UIButton *pill;
@property (nonatomic, strong) UIView *panel;
@property (nonatomic, strong) UILabel *statsLabel;
@property (nonatomic, strong) CADisplayLink *link;
@property (nonatomic, assign) BOOL panelOpen;
@end

@implementation PipHUD

+ (instancetype)shared {
    static PipHUD *s;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ s = [PipHUD new]; });
    return s;
}

- (void)installIfNeeded {
    if (self.window) {
        [self reloadFromPrefs];
        return;
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.window) return;

        CGRect screen = UIScreen.mainScreen.bounds;
        CGFloat pillW = 56.0, pillH = 28.0;
        CGFloat x = (screen.size.width - pillW) * 0.5;
        CGFloat y = screen.size.height - pillH - 18.0 - (UIApplication.sharedApplication.keyWindow.safeAreaInsets.bottom ?: 0);

        UIWindow *w = [[UIWindow alloc] initWithFrame:screen];
        w.windowLevel = UIWindowLevelStatusBar + 120.0;
        w.backgroundColor = UIColor.clearColor;
        w.userInteractionEnabled = YES;
        w.hidden = NO;

        PipPassthroughView *root = [[PipPassthroughView alloc] initWithFrame:screen];
        root.backgroundColor = UIColor.clearColor;
        root.userInteractionEnabled = YES;
        w.rootViewController = [UIViewController new];
        w.rootViewController.view = root;

        UIButton *pill = [UIButton buttonWithType:UIButtonTypeSystem];
        pill.frame = CGRectMake(x, y, pillW, pillH);
        pill.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.55];
        pill.layer.cornerRadius = pillH * 0.5;
        pill.clipsToBounds = YES;
        [pill setTitle:@"pip" forState:UIControlStateNormal];
        [pill setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
        pill.titleLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightSemibold];
        [pill addTarget:self action:@selector(togglePanel) forControlEvents:UIControlEventTouchUpInside];

        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(onPan:)];
        [pill addGestureRecognizer:pan];

        UIView *panel = [[UIView alloc] initWithFrame:CGRectMake(16, y - 150, screen.size.width - 32, 140)];
        panel.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.82];
        panel.layer.cornerRadius = 14;
        panel.hidden = YES;

        UILabel *label = [[UILabel alloc] initWithFrame:CGRectInset(panel.bounds, 12, 10)];
        label.numberOfLines = 0;
        label.textColor = UIColor.whiteColor;
        label.font = [UIFont monospacedDigitSystemFontOfSize:12 weight:UIFontWeightRegular];
        label.text = @"Pip starting…";
        [panel addSubview:label];

        [root addSubview:panel];
        [root addSubview:pill];

        self.window = w;
        self.pill = pill;
        self.panel = panel;
        self.statsLabel = label;

        self.link = [CADisplayLink displayLinkWithTarget:self selector:@selector(onTick:)];
        if (@available(iOS 10.0, *)) {
            self.link.preferredFramesPerSecond = 30; // HUD itself stays light
        }
        [self.link addToRunLoop:NSRunLoop.mainRunLoop forMode:NSRunLoopCommonModes];

        [self reloadFromPrefs];
    });
}

- (void)reloadFromPrefs {
    PipPrefs *p = PipPrefs.shared;
    BOOL show = p.enabled && p.showHUD;
    self.window.hidden = !show;
    self.pill.hidden = !show;
    if (!show) {
        self.panel.hidden = YES;
        self.panelOpen = NO;
    }
}

- (void)onPan:(UIPanGestureRecognizer *)g {
    UIView *v = g.view;
    CGPoint t = [g translationInView:v.superview];
    v.center = CGPointMake(v.center.x + t.x, v.center.y + t.y);
    [g setTranslation:CGPointZero inView:v.superview];

    // Keep on screen
    CGRect b = v.superview.bounds;
    CGFloat halfW = v.bounds.size.width * 0.5;
    CGFloat halfH = v.bounds.size.height * 0.5;
    v.center = CGPointMake(
        MIN(MAX(v.center.x, halfW), b.size.width - halfW),
        MIN(MAX(v.center.y, halfH), b.size.height - halfH)
    );

    if (!self.panel.hidden) {
        CGRect pf = self.panel.frame;
        pf.origin.y = CGRectGetMinY(v.frame) - pf.size.height - 8;
        if (pf.origin.y < 40) pf.origin.y = CGRectGetMaxY(v.frame) + 8;
        self.panel.frame = pf;
    }
}

- (void)togglePanel {
    self.panelOpen = !self.panelOpen;
    self.panel.hidden = !self.panelOpen;
    if (self.panelOpen) {
        CGRect pf = self.panel.frame;
        pf.origin.y = CGRectGetMinY(self.pill.frame) - pf.size.height - 8;
        if (pf.origin.y < 40) pf.origin.y = CGRectGetMaxY(self.pill.frame) + 8;
        self.panel.frame = pf;
        [self refreshLabel];
    }
}

- (void)onTick:(CADisplayLink *)link {
    [[PipStats shared] tick];
    if (self.panelOpen) [self refreshLabel];
}

- (void)refreshLabel {
    PipStats *s = PipStats.shared;
    PipPrefs *p = PipPrefs.shared;
    NSString *fpsCap = p.fpsCap > 0 ? [NSString stringWithFormat:@"%ld", (long)p.fpsCap] : @"off";
    NSString *gfx = @[@"Normal", @"Small", @"Smaller", @"Smallest"][MIN(3, MAX(0, p.graphicsLevel))];

    self.statsLabel.text = [NSString stringWithFormat:
        @"Pip  ·  your cool helper\n"
        @"FPS      %.0f   (cap %@)\n"
        @"CPU      ~%.0f%%\n"
        @"Memory   %.0f MB\n"
        @"Thermal  %@\n"
        @"Graphics %@\n"
        @"Note: iPhone 7 Plus max = 60 Hz",
        s.fps, fpsCap, s.cpuPercent, s.memoryMB, s.thermalLabel, gfx];
}

@end
