#import "Headers.h"
#import <objc/message.h>

static const CGFloat kSBMarkerHeight = 4.0;

#pragma mark - SBSkipNotificationView Implementation

@implementation SBSkipNotificationView

+ (instancetype)showInView:(UIView *)parentView message:(NSString *)message buttonTitle:(NSString *)buttonTitle action:(void (^)(void))action duration:(NSTimeInterval)duration {
    if (!parentView) return nil;

    SBSkipNotificationView *view = [[SBSkipNotificationView alloc] initWithFrame:CGRectZero];
    view.translatesAutoresizingMaskIntoConstraints = NO;
    view.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.75];
    view.layer.cornerRadius = 8.0;
    view.clipsToBounds = YES;
    view.onAction = action;

    // Message label
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.text = message;
    label.textColor = [UIColor whiteColor];
    label.font = [UIFont systemFontOfSize:13.0 weight:UIFontWeightMedium];
    label.numberOfLines = 1;
    view.messageLabel = label;
    [view addSubview:label];

    // Action button (optional)
    UIButton *button = nil;
    if (buttonTitle.length > 0) {
        button = [UIButton buttonWithType:UIButtonTypeSystem];
        button.translatesAutoresizingMaskIntoConstraints = NO;
        [button setTitle:buttonTitle forState:UIControlStateNormal];
        [button setTitleColor:[UIColor colorWithRed:0.4 green:0.6 blue:1.0 alpha:1.0] forState:UIControlStateNormal];
        button.titleLabel.font = [UIFont systemFontOfSize:13.0 weight:UIFontWeightBold];
        [button addTarget:view action:@selector(actionButtonTapped) forControlEvents:UIControlEventTouchUpInside];
        view.actionButton = button;
        [view addSubview:button];
    }

    [parentView addSubview:view];

    // Layout constraints
    [NSLayoutConstraint activateConstraints:@[
        [view.centerXAnchor constraintEqualToAnchor:parentView.centerXAnchor],
        [view.bottomAnchor constraintEqualToAnchor:parentView.bottomAnchor constant:-60.0]
    ]];

    // Internal padding
    [NSLayoutConstraint activateConstraints:@[
        [label.leadingAnchor constraintEqualToAnchor:view.leadingAnchor constant:12.0],
        [label.topAnchor constraintEqualToAnchor:view.topAnchor constant:8.0],
        [label.bottomAnchor constraintEqualToAnchor:view.bottomAnchor constant:-8.0]
    ]];

    if (button) {
        [NSLayoutConstraint activateConstraints:@[
            [button.leadingAnchor constraintEqualToAnchor:label.trailingAnchor constant:12.0],
            [button.trailingAnchor constraintEqualToAnchor:view.trailingAnchor constant:-12.0],
            [button.centerYAnchor constraintEqualToAnchor:view.centerYAnchor]
        ]];
    } else {
        [label.trailingAnchor constraintEqualToAnchor:view.trailingAnchor constant:-12.0].active = YES;
    }

    // Fade in
    view.alpha = 0.0;
    [UIView animateWithDuration:0.2 animations:^{
        view.alpha = 1.0;
    }];

    // Auto-dismiss
    if (duration > 0) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(duration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [view dismiss];
        });
    }

    return view;
}

- (void)actionButtonTapped {
    if (self.onAction) {
        self.onAction();
    }
    [self dismiss];
}

- (void)dismiss {
    [UIView animateWithDuration:0.2 animations:^{
        self.alpha = 0.0;
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
    }];
}

@end

#pragma mark - YTSegmentableInlinePlayerBarView Hook (Seek Bar Markers)

%hook YTSegmentableInlinePlayerBarView
%property (nonatomic, strong) NSArray *sbMarkerViews;

- (void)layoutSubviews {
    %orig;
    if (self.sbMarkerViews.count > 0) {
        // Call %new method via objc_msgSend to avoid compiler warning
        ((void (*)(id, SEL))objc_msgSend)(self, @selector(sbRepositionMarkers));
    }
}

%new
- (void)sbRenderSegments:(NSArray<SBSegment *> *)segments {
    [self sbClearSegments];

    CGFloat totalTime = 0;
    @try {
        totalTime = [[self valueForKey:@"totalTime"] floatValue];
    } @catch (NSException *e) { return; }
    if (totalTime <= 0 || segments.count == 0) return;

    CGFloat barWidth = self.bounds.size.width;
    CGFloat barHeight = self.bounds.size.height;
    if (barWidth <= 0) return;

    NSMutableArray *markers = [NSMutableArray array];

    for (SBSegment *segment in segments) {
        SBSegmentAction action = [segment configuredAction];
        if (action == SBSegmentActionDisable) continue;

        CGFloat startFrac = segment.startTime / totalTime;
        CGFloat endFrac = segment.endTime / totalTime;
        CGFloat x = startFrac * barWidth;
        CGFloat w = (endFrac - startFrac) * barWidth;
        if (w < 2.0) w = 2.0;

        UIView *marker = [[UIView alloc] initWithFrame:CGRectMake(x, barHeight - kSBMarkerHeight, w, kSBMarkerHeight)];
        marker.backgroundColor = [segment segmentColor];
        marker.userInteractionEnabled = NO;
        marker.layer.name = [NSString stringWithFormat:@"%f|%f", segment.startTime, segment.endTime];

        [self addSubview:marker];
        [markers addObject:marker];
    }

    self.sbMarkerViews = [markers copy];
}

%new
- (void)sbRepositionMarkers {
    CGFloat totalTime = 0;
    @try {
        totalTime = [[self valueForKey:@"totalTime"] floatValue];
    } @catch (NSException *e) { return; }
    if (totalTime <= 0) return;

    CGFloat barWidth = self.bounds.size.width;
    CGFloat barHeight = self.bounds.size.height;
    if (barWidth <= 0) return;

    for (UIView *marker in self.sbMarkerViews) {
        NSString *name = marker.layer.name;
        NSArray *parts = [name componentsSeparatedByString:@"|"];
        if (parts.count < 2) continue;

        CGFloat startTime = [parts[0] floatValue];
        CGFloat endTime = [parts[1] floatValue];
        CGFloat startFrac = startTime / totalTime;
        CGFloat endFrac = endTime / totalTime;
        CGFloat x = startFrac * barWidth;
        CGFloat w = (endFrac - startFrac) * barWidth;
        if (w < 2.0) w = 2.0;

        marker.frame = CGRectMake(x, barHeight - kSBMarkerHeight, w, kSBMarkerHeight);
    }
}

%new
- (void)sbClearSegments {
    for (UIView *marker in self.sbMarkerViews) {
        [marker removeFromSuperview];
    }
    self.sbMarkerViews = nil;
}

%end

#pragma mark - YTInlinePlayerBarContainerView Hook (Marker Positioning & Visibility)

%hook YTInlinePlayerBarContainerView
%property (nonatomic, strong) UIView *sbMarkerContainer;

- (void)layoutSubviews {
    %orig;
    UIView *container = self.sbMarkerContainer;
    if (!container || container.subviews.count == 0) return;

    CGFloat barWidth = self.bounds.size.width;
    CGFloat barHeight = self.bounds.size.height;
    if (barWidth <= 0 || barHeight <= 0) return;

    container.frame = CGRectMake(0, 0, barWidth, barHeight);

    for (UIView *marker in container.subviews) {
        NSArray *data = objc_getAssociatedObject(marker, @selector(sbSegmentData));
        if (!data || data.count < 2) continue;

        CGFloat startFrac = [data[0] floatValue];
        CGFloat endFrac = [data[1] floatValue];
        CGFloat x = startFrac * barWidth;
        CGFloat w = (endFrac - startFrac) * barWidth;
        if (w < 2.0) w = 2.0;

        marker.frame = CGRectMake(x, barHeight - kSBMarkerHeight, w, kSBMarkerHeight);
    }
}

- (void)setAlpha:(CGFloat)alpha {
    %orig;
    self.sbMarkerContainer.alpha = alpha;
}

- (void)setHidden:(BOOL)hidden {
    %orig;
    self.sbMarkerContainer.hidden = hidden;
}

- (void)setPlayerBarAlpha:(CGFloat)alpha {
    %orig;
    self.sbMarkerContainer.alpha = alpha;
}

%end

// YTModularPlayerBarView hook removed — class may not exist in YT 21.17.3
// Seek bar markers will use YTInlinePlayerBarContainerView directly instead

#pragma mark - YTPlayerViewController Hook (Notification Observer)

%group SBObserver
%hook YTPlayerViewController

- (void)viewDidLoad {
    %orig;
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(sbSegmentsDidLoad:)
                                                 name:@"SBSegmentsDidLoad"
                                               object:self];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"SBSegmentsDidLoad" object:nil];
    %orig;
}

%new
- (void)sbSegmentsDidLoad:(NSNotification *)notification {
    @try {
        NSArray<SBSegment *> *segments = notification.userInfo[@"segments"];

        id overlay = [self activeVideoPlayerOverlay];
        if (!overlay) return;

        YTPlayerBarController *barController = nil;
        if ([overlay respondsToSelector:@selector(playerBarController)]) {
            barController = [overlay playerBarController];
        }
        if (!barController) return;

        YTInlinePlayerBarContainerView *containerView = barController.playerBar;
        if (!containerView) return;

        // Get or create marker container
        UIView *markerContainer = containerView.sbMarkerContainer;
        if (!markerContainer) {
            markerContainer = [[UIView alloc] initWithFrame:containerView.bounds];
            markerContainer.userInteractionEnabled = NO;
            markerContainer.clipsToBounds = YES;
            containerView.sbMarkerContainer = markerContainer;
            [containerView addSubview:markerContainer];
        }

        // Remove old markers
        for (UIView *sub in [markerContainer.subviews copy]) {
            [sub removeFromSuperview];
        }

        if (!segments || segments.count == 0) return;

        CGFloat totalTime = [self currentVideoTotalMediaTime];
        if (totalTime <= 0) return;

        CGFloat barWidth = containerView.bounds.size.width;
        CGFloat barHeight = containerView.bounds.size.height;
        if (barWidth <= 0) return;

        markerContainer.frame = CGRectMake(0, 0, barWidth, barHeight);

        for (SBSegment *segment in segments) {
            SBSegmentAction action = [segment configuredAction];
            if (action == SBSegmentActionDisable) continue;

            CGFloat startFrac = segment.startTime / totalTime;
            CGFloat endFrac = segment.endTime / totalTime;
            CGFloat x = startFrac * barWidth;
            CGFloat w = (endFrac - startFrac) * barWidth;
            if (w < 2.0) w = 2.0;

            UIView *marker = [[UIView alloc] initWithFrame:CGRectMake(x, barHeight - kSBMarkerHeight, w, kSBMarkerHeight)];
            marker.backgroundColor = [segment segmentColor];
            marker.userInteractionEnabled = NO;
            objc_setAssociatedObject(marker, @selector(sbSegmentData), @[@(startFrac), @(endFrac)], OBJC_ASSOCIATION_RETAIN_NONATOMIC);

            [markerContainer addSubview:marker];
        }
    } @catch (NSException *e) {}
}

%end
%end

#pragma mark - YTMainAppControlsOverlayView Hook (Toggle Button)

%hook YTMainAppControlsOverlayView

- (void)layoutSubviews {
    %orig;

    if (!IS_ENABLED(SBEnabled) || !IS_ENABLED(SBShowButton)) {
        UIView *existing = [self viewWithTag:9901];
        if (existing) [existing removeFromSuperview];
        return;
    }

    UIButton *btn = (UIButton *)[self viewWithTag:9901];
    if (!btn) {
        btn = [UIButton buttonWithType:UIButtonTypeCustom];
        btn.tag = 9901;
        btn.frame = CGRectMake(0, 0, 40, 40);

        UIImageSymbolConfiguration *config = [UIImageSymbolConfiguration configurationWithPointSize:20 weight:UIImageSymbolWeightMedium];
        UIImage *icon = [UIImage systemImageNamed:@"shield.fill" withConfiguration:config];
        [btn setImage:icon forState:UIControlStateNormal];
        btn.tintColor = [UIColor colorWithRed:0.4 green:0.8 blue:1.0 alpha:1.0];

        [btn addTarget:self action:@selector(sbButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:btn];
    }

    // Position: top-right
    CGFloat rightPad = 12.0;
    CGFloat topPad = 52.0;
    btn.frame = CGRectMake(self.bounds.size.width - 40 - rightPad, topPad, 40, 40);
}

%new
- (void)sbButtonTapped:(UIButton *)sender {
    YTPlayerViewController *pvc = nil;
    if ([self respondsToSelector:@selector(playerViewController)]) {
        pvc = [self performSelector:@selector(playerViewController)];
    }
    if (!pvc) {
        // Try to find player VC via responder chain
        UIResponder *responder = self;
        while (responder) {
            if ([responder isKindOfClass:%c(YTPlayerViewController)]) {
                pvc = (YTPlayerViewController *)responder;
                break;
            }
            responder = [responder nextResponder];
        }
    }
    if (!pvc) {
        NSLog(@"[YouMod SponsorBlock] Unable to find YTPlayerViewController from button tap");
        return;
    }

    BOOL newState = !pvc.sbEnabledForVideo;
    pvc.sbEnabledForVideo = newState;

    sender.tintColor = newState ? [UIColor colorWithRed:0.4 green:0.8 blue:1.0 alpha:1.0] : [UIColor grayColor];

    if (!newState) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"SBSegmentsDidLoad"
                                                            object:pvc
                                                          userInfo:@{@"segments": @[]}];
    } else {
        NSArray *segments = pvc.sbSegments;
        if (segments.count > 0) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"SBSegmentsDidLoad"
                                                                object:pvc
                                                              userInfo:@{@"segments": segments}];
        }
    }
}

%end

#pragma mark - Constructor

%ctor {
    %init;
    %init(SBObserver);
}
