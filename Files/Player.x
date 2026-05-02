#import "Headers.h"

%hook YTMainAppControlsOverlayView
// Hide autoplay Switch
- (void)setAutoplaySwitchButtonRenderer:(id)arg1 { if (!IS_ENABLED(HideAutoPlayToggle)) %orig; }
// Hide captions Button
- (void)setClosedCaptionsOrSubtitlesButtonAvailable:(BOOL)arg1 { if (!IS_ENABLED(HideCaptionsButton)) %orig; }
// Hide cast button
- (id)playbackRouteButton { return IS_ENABLED(HideCastButtonPlayer) ? nil : %orig; }
- (void)setPreviousButtonHidden:(BOOL)arg { IS_ENABLED(HidePrevButton) ? %orig(YES) : %orig; }
- (void)setNextButtonHidden:(BOOL)arg { IS_ENABLED(HideNextButton) ? %orig(YES) : %orig; }
// Hide video title in full screen
- (BOOL)titleViewHidden { return IS_ENABLED(HideFullvidTitle) ? YES : %orig; }
%end

%hook YTAutonavEndscreenController
- (void)showEndscreen { if (!IS_ENABLED(HideSuggestedVideo)) %orig; }
- (void)showEndscreenControlsInPlayerBar:(BOOL)arg { IS_ENABLED(HideSuggestedVideo) ? %orig(NO) : %orig; }
%end

%hook YTSettings
- (BOOL)isAutoplayEnabled { return IS_ENABLED(HideAutoPlayToggle) ? NO : %orig; }
%end

%hook YTSettingsImpl
- (BOOL)isAutoplayEnabled { return IS_ENABLED(HideAutoPlayToggle) ? NO : %orig; }
%end

/* idk what is this thing does
%hook YTColdConfig
- (BOOL)isLandscapeEngagementPanelEnabled {
    return NO;
}
%end
*/

/*
%hook YTHeaderView
- (BOOL)stickyNavHeaderEnabled { return IS_ENABLED(YTPremiumLogo) ? YES : NO; } // idk what is this does, the nav is already sticky... Or this thing only happens in iPhone?
- (void)setStickyNavHeaderEnabled:(BOOL)arg { IS_ENABLED(YTPremiumLogo) ? %orig(YES) : %orig(NO); }
%end
*/

// Remove Dark Background in Overlay
%hook YTMainAppVideoPlayerOverlayView
- (void)setBackgroundVisible:(BOOL)arg1 isGradientBackground:(BOOL)arg2 { IS_ENABLED(RemoveDarkOverlay) ? %orig(NO, arg2) : %orig; }
// Hide Watermarks
- (BOOL)isWatermarkEnabled { return IS_ENABLED(HideWaterMark) ? NO : %orig; }
- (void)setWatermarkEnabled:(BOOL)arg { IS_ENABLED(HideWaterMark) ? %orig(NO) : %orig; }
- (id)playbackRouteButton { return IS_ENABLED(HideCastButtonPlayer) ? nil : %orig; }
%end

// No Endscreen Cards
%hook YTCreatorEndscreenView
- (void)setHidden:(BOOL)arg1 { IS_ENABLED(HideEndScreenCards) ? %orig(YES) : %orig; }
- (void)setHoverCardHidden:(BOOL)arg { IS_ENABLED(HideEndScreenCards) ? %orig(YES) : %orig; }
- (void)setHoverCardRenderer:(id)arg { if (!IS_ENABLED(HideEndScreenCards)) %orig; }
%end

%hook YTMainAppVideoPlayerOverlayViewController
// Disable Double Tap To Seek
- (BOOL)allowDoubleTapToSeekGestureRecognizer { return IS_ENABLED(DisablesDoubleTap) ? NO : %orig; }
// Disable long hold
- (BOOL)allowLongPressGestureRecognizerInView:(id)arg { return IS_ENABLED(DisablesLongHold) ? NO : %orig; }
%end

// YTNoPaidPromo (https://github.com/PoomSmart/YTNoPaidPromo)
%group PaidPromoOverlay
%hook YTMainAppVideoPlayerOverlayViewController
- (void)setPaidContentWithPlayerData:(id)data {}
- (void)playerOverlayProvider:(YTPlayerOverlayProvider *)provider didInsertPlayerOverlay:(YTPlayerOverlay *)overlay {
    if ([[overlay overlayIdentifier] isEqualToString:@"player_overlay_paid_content"]) return;
    %orig;
}
%end

%hook YTInlineMutedPlaybackPlayerOverlayViewController
- (void)setPaidContentWithPlayerData:(id)data {}
%end
%end

// Remove Watermarks
%hook YTAnnotationsViewController
- (void)loadFeaturedChannelWatermark { if (!IS_ENABLED(HideWaterMark)) %orig; }
%end

// Exit Fullscreen on Finish
%hook YTWatchFlowController
- (BOOL)shouldExitFullScreenOnFinish { return IS_ENABLED(AutoExitFullScreen) ? YES : %orig; }
%end

// Disable toggle time remaining - @bhackel
%hook YTInlinePlayerBarContainerView
- (void)setShouldDisplayTimeRemaining:(BOOL)arg1 { 
    if (IS_ENABLED(DisablesShowRemaining)) {
        %orig(NO);
        return;
    }
    IS_ENABLED(AlwaysShowRemaining) ? %orig(YES) : %orig;
}
%end

// Always use remaining time in the video player - @bhackel
%hook YTPlayerBarController
// When a new video is played, enable time remaining flag
- (void)setActiveSingleVideo:(id)arg1 {
    %orig;
    if (IS_ENABLED(AlwaysShowRemaining) && !IS_ENABLED(DisablesShowRemaining)) {
        // Get the player bar view
        YTInlinePlayerBarContainerView *playerBar = self.playerBar;
        if (playerBar) {
            // Enable the time remaining flag
            playerBar.shouldDisplayTimeRemaining = YES;
        }
    }
}
%end

// Disable Fullscreen Actions
%hook YTFullscreenActionsView
- (BOOL)enabled { return IS_ENABLED(HideFullAction) ? NO : %orig; }
- (void)setEnabled:(BOOL)arg1 { IS_ENABLED(HideFullAction) ? %orig(NO) : %orig; }
%end

// Disable Autoplay 
%hook YTPlaybackConfig
- (void)setStartPlayback:(BOOL)arg1 { IS_ENABLED(StopAutoplayVideo) ? %orig(NO) : %orig; }
%end

// Skip Content Warning (https://github.com/qnblackcat/uYouPlus/blob/main/uYouPlus.xm#L452-L454)
%hook YTPlayabilityResolutionUserActionUIController
- (void)showConfirmAlert { IS_ENABLED(HideContentWarning) ? [self confirmAlertDidPressConfirm] : %orig; }
%end

%hook YTPlayabilityResolutionUserActionUIControllerImpl
- (void)showConfirmAlert { IS_ENABLED(HideContentWarning) ? [self confirmAlertDidPressConfirm] : %orig; }
%end

/*
%hook YTInlinePlayerBarContainerView
- (void)setPlayerBarAlpha:(CGFloat)alpha { %orig(1.0); } // Force seek bar i guess
%end
*/

// Portrait Fullscreen
%hook YTWatchViewController
- (unsigned long long)allowedFullScreenOrientations { return IS_ENABLED(PortFull) ? UIInterfaceOrientationMaskAllButUpsideDown : %orig; }
%end

// Disable Snap To Chapter (https://github.com/qnblackcat/uYouPlus/blob/main/uYouPlus.xm#L457-464) - GOT REMOVED
// %hook YTSegmentableInlinePlayerBarView
// - (void)didMoveToWindow { %orig; if (ytlBool(@"dontSnapToChapter")) self.enableSnapToChapter = NO; }
// %end

/*
%hook YTModularPlayerBarController
- (void)setEnableSnapToChapter:(BOOL)arg { %orig(NO); } // idk this works or not
%end
*/

// Extra speed - adapted from YouSpeed
%group Speed

#define itemCount 13

%hook YTMenuController

- (NSMutableArray <YTActionSheetAction *> *)actionsForRenderers:(NSMutableArray <YTIMenuItemSupportedRenderers *> *)renderers fromView:(UIView *)fromView entry:(id)entry shouldLogItems:(BOOL)shouldLogItems firstResponder:(id)firstResponder {
    NSUInteger index = [renderers indexOfObjectPassingTest:^BOOL(YTIMenuItemSupportedRenderers *renderer, NSUInteger idx, BOOL *stop) {
        YTIMenuItemSupportedRenderersElementRendererCompatibilityOptionsExtension *extension = (YTIMenuItemSupportedRenderersElementRendererCompatibilityOptionsExtension *)[renderer.elementRenderer.compatibilityOptions messageForFieldNumber:396644439];
        BOOL isVideoSpeed = [extension.menuItemIdentifier isEqualToString:@"menu_item_playback_speed"];
        if (isVideoSpeed) *stop = YES;
        return isVideoSpeed;
    }];
    NSMutableArray <YTActionSheetAction *> *actions = %orig;
    if (index != NSNotFound) {
        YTActionSheetAction *action = actions[index];
        action.handler = ^{
            [firstResponder didPressVarispeed:fromView];
        };
        UIView *elementView = [action.button valueForKey:@"_elementView"];
        elementView.userInteractionEnabled = NO;
    }
    return actions;
}

%end

%hook YTVarispeedSwitchController

- (id)init {
    self = %orig;
    float speeds[] = {0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0, 2.5, 3.0, 5.0, 7.5, 10.0};
    id options[itemCount];
    Class YTVarispeedSwitchControllerOptionClass = %c(YTVarispeedSwitchControllerOption);
    for (int i = 0; i < itemCount; ++i) {
        NSString *title = [NSString stringWithFormat:@"%.2fx", speeds[i]];
        options[i] = [[YTVarispeedSwitchControllerOptionClass alloc] initWithTitle:title rate:speeds[i]];
    }
    [self setValue:[NSArray arrayWithObjects:options count:itemCount] forKey:@"_options"];
    return self;
}

%end

%hook YTVarispeedSwitchControllerImpl

- (id)init {
    self = %orig;
    float speeds[] = {0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0, 2.5, 3.0, 5.0, 7.5, 10.0};
    id options[itemCount];
    Class YTVarispeedSwitchControllerOptionClass = %c(YTVarispeedSwitchControllerOption);
    for (int i = 0; i < itemCount; ++i) {
        NSString *title = [NSString stringWithFormat:@"%.2fx", speeds[i]];
        options[i] = [[YTVarispeedSwitchControllerOptionClass alloc] initWithTitle:title rate:speeds[i]];
    }
    [self setValue:[NSArray arrayWithObjects:options count:itemCount] forKey:@"_options"];
    return self;
}

%end

%hook YTIPlayerHotConfig

%new(f@:)
- (float)maximumPlaybackRate {
    return 10.0;
}

%end

%hook YTIGranularVariableSpeedConfig

%new(d@:)
- (int)maximumPlaybackRate {
    return 10.0 * 100;
}

%end
%end

%hook YTPlayerViewController
- (void)loadWithPlayerTransition:(id)arg1 playbackConfig:(id)arg2 {
    %orig;
    if (IS_ENABLED(AutoFullScreen)) [self performSelector:@selector(YouModAutoFullscreen) withObject:nil afterDelay:0.75];
    // if (ytlBool(@"shortsToRegular")) [self performSelector:@selector(shortsToRegular) withObject:nil afterDelay:0.75];
    // if (ytlBool(@"disableAutoCaptions")) [self performSelector:@selector(turnOffCaptions) withObject:nil afterDelay:1.0];
}

- (void)prepareToLoadWithPlayerTransition:(id)arg1 expectedLayout:(id)arg2 {
    %orig;
    if (IS_ENABLED(AutoFullScreen)) [self performSelector:@selector(YouModAutoFullscreen) withObject:nil afterDelay:0.75];
    // if (ytlBool(@"shortsToRegular")) [self performSelector:@selector(shortsToRegular) withObject:nil afterDelay:0.75];
    // if (ytlBool(@"disableAutoCaptions")) [self performSelector:@selector(turnOffCaptions) withObject:nil afterDelay:1.0];
}

%new
- (void)YouModAutoFullscreen {
    YTWatchController *watchController = [self valueForKey:@"_UIDelegate"];
    [watchController showFullScreen];
}

%end

/*
%new
- (void)shortsToRegular {
    if (self.contentVideoID != nil && [self.parentViewController isKindOfClass:NSClassFromString(@"YTShortsPlayerViewController")]) {
        NSString *vidLink = [NSString stringWithFormat:@"vnd.youtube://%@", self.contentVideoID]; // idk about this
        if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:vidLink]]) {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:vidLink] options:@{} completionHandler:nil];
        }
    }
}

%new
- (void)turnOffCaptions {
    if ([self.view.superview isKindOfClass:NSClassFromString(@"YTWatchView")]) {
        [self setActiveCaptionTrack:nil]; // will try this - got removed
    }
}
%end

// Fix Playlist Mini-bar Height For Small Screens
%hook YTPlaylistMiniBarView
- (void)setFrame:(CGRect)frame {
    if (frame.size.height < 54.0) frame.size.height = 54.0; // what
    %orig(frame);
}
%end
*/

// YTClassicVideoQuality (https://github.com/PoomSmart/YTClassicVideoQuality)
%group OldVideoQuality
%hook YTIMediaQualitySettingsHotConfig
%new(B@:)
- (BOOL)enableQuickMenuVideoQualitySettings { return NO; }
%end

%hook YTVideoQualitySwitchOriginalController
%property (retain, nonatomic) YTVideoQualitySwitchRedesignedController *redesignedController;
- (void)setUserSelectableFormats:(NSArray <MLFormat *> *)formats {
    if (self.redesignedController == nil)
        self.redesignedController = [[%c(YTVideoQualitySwitchRedesignedController) alloc] initWithServiceRegistryScope:nil parentResponder:nil];
    [self.redesignedController setValue:[self valueForKey:@"_video"] forKey:@"_video"];
    NSArray <MLFormat *> *newFormats = [self.redesignedController respondsToSelector:@selector(addRestrictedFormats:)] ? [self.redesignedController addRestrictedFormats:formats] : formats;
    %orig(newFormats);
}
- (void)dealloc {
    self.redesignedController = nil;
    %orig;
}
%end

%hook YTMenuController
- (NSMutableArray <YTActionSheetAction *> *)actionsForRenderers:(NSMutableArray <YTIMenuItemSupportedRenderers *> *)renderers fromView:(UIView *)fromView entry:(id)entry shouldLogItems:(BOOL)shouldLogItems firstResponder:(id)firstResponder {
    NSUInteger index = [renderers indexOfObjectPassingTest:^BOOL(YTIMenuItemSupportedRenderers *renderer, NSUInteger idx, BOOL *stop) {
        YTIMenuItemSupportedRenderersElementRendererCompatibilityOptionsExtension *extension = (YTIMenuItemSupportedRenderersElementRendererCompatibilityOptionsExtension *)[renderer.elementRenderer.compatibilityOptions messageForFieldNumber:396644439];
        BOOL isVideoQuality = [extension.menuItemIdentifier isEqualToString:@"menu_item_video_quality"];
        if (isVideoQuality) *stop = YES;
        return isVideoQuality;
    }];
    NSMutableArray <YTActionSheetAction *> *actions = %orig;
    if (index != NSNotFound) {
        YTActionSheetAction *action = actions[index];
        action.handler = ^{
            [firstResponder didPressVideoQuality:fromView];
        };
        UIView *elementView = [action.button valueForKey:@"_elementView"];
        elementView.userInteractionEnabled = NO;
    }
    return actions;
}
%end
%end

// Gestures - @bhackel (YTLitePlus)
%group Gestures
%hook YTWatchLayerViewController
// invoked when the player view controller is either created or destroyed
- (void)watchController:(YTWatchController *)watchController didSetPlayerViewController:(YTPlayerViewController *)playerViewController {
    if (playerViewController) {
        // check to see if the pan gesture is already created
        if (!playerViewController.YouModPanGesture) {
            playerViewController.YouModPanGesture = [[UIPanGestureRecognizer alloc] initWithTarget:playerViewController action:@selector(YouModHandlePanGesture:)];
            playerViewController.YouModPanGesture.delegate = playerViewController;
            [playerViewController.playerView addGestureRecognizer:playerViewController.YouModPanGesture];
        }        
    }
    %orig;
}
%end

%hook YTPlayerViewController
%property (nonatomic, retain) UIPanGestureRecognizer *YouModPanGesture;
%new
- (void)YouModHandlePanGesture:(UIPanGestureRecognizer *)panGestureRecognizer {
    static float initialVolume;
    static float initialBrightness;
    static BOOL isValidHorizontalPan = NO; 
    static GestureSection gestureSection = GestureSectionInvalid;
    static CGPoint startLocation;
    static CGFloat deadzoneStartingXTranslation;
    static CGFloat adjustedTranslationX;
    static CGFloat deadzoneRadius = 20.0;
    static CGFloat sensitivityFactor = 1.0;

    static MPVolumeView *volumeView;
    static UISlider *volumeViewSlider;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        volumeView = [[MPVolumeView alloc] initWithFrame:CGRectZero];
        for (UIView *view in volumeView.subviews) {
            if ([view isKindOfClass:[UISlider class]]) {
                volumeViewSlider = (UISlider *)view;
                break;
            }
        }
    });

    if (panGestureRecognizer.state == UIGestureRecognizerStateBegan) {
        startLocation = [panGestureRecognizer locationInView:self.view];
        CGFloat viewHeight = self.view.bounds.size.height;

        if (startLocation.y <= viewHeight / 2.0) {
            gestureSection = GestureSectionTop; 
        } else {
            gestureSection = GestureSectionBottom;
        }
        
        isValidHorizontalPan = NO;
    }

    if (panGestureRecognizer.state == UIGestureRecognizerStateChanged) {
        CGPoint translation = [panGestureRecognizer translationInView:self.view];
        
        if (!isValidHorizontalPan) {
            if (fabs(translation.x) > fabs(translation.y)) {
                CGFloat distanceFromStart = hypot(translation.x, translation.y);
                if (distanceFromStart < deadzoneRadius) return;

                isValidHorizontalPan = YES;
                deadzoneStartingXTranslation = translation.x;
                
                if (gestureSection == GestureSectionTop) {
                    initialBrightness = [UIScreen mainScreen].brightness;
                } else {
                    initialVolume = [[AVAudioSession sharedInstance] outputVolume];
                }
            } else {
                panGestureRecognizer.state = UIGestureRecognizerStateCancelled;
                return;
            }
        }

        if (isValidHorizontalPan) {
            adjustedTranslationX = translation.x - deadzoneStartingXTranslation;
            
            // Calculate delta based on screen width
            float delta = (adjustedTranslationX / self.view.bounds.size.width) * sensitivityFactor;
            
            if (gestureSection == GestureSectionTop) {
                float newBrightness = fmaxf(fminf(initialBrightness + delta, 1.0), 0.0);
                [[UIScreen mainScreen] setBrightness:newBrightness];
            } else if (gestureSection == GestureSectionBottom) {
                float newVolume = fmaxf(fminf(initialVolume + delta, 1.0), 0.0);
                volumeViewSlider.value = newVolume;
            }
        }
    }
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    if ([gestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]] && [otherGestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]]) {
        YTMainAppVideoPlayerOverlayViewController *mainVideoPlayerController = (YTMainAppVideoPlayerOverlayViewController *)self.childViewControllers.firstObject;
        YTPlayerBarController *playerBarController = mainVideoPlayerController.playerBarController;
        YTInlinePlayerBarContainerView *playerBar = playerBarController.playerBar;
        
        // Priority to seeking and scrubbing
        if (otherGestureRecognizer == playerBar.scrubGestureRecognizer) return NO;
        
        YTFineScrubberFilmstripView *fineScrubberFilmstrip = playerBar.fineScrubberFilmstrip;
        if (!fineScrubberFilmstrip) return YES;
        
        YTFineScrubberFilmstripCollectionView *filmstripCollectionView = [fineScrubberFilmstrip valueForKey:@"_filmstripCollectionView"];
        if (filmstripCollectionView && otherGestureRecognizer == filmstripCollectionView.panGestureRecognizer) return NO;
    }
    return YES;
}
%end
%end

%ctor {
    %init;
    if (IS_ENABLED(OldQualityPicker)) {
        %init(OldVideoQuality);
    }
    if (IS_ENABLED(ExtraSpeed)) {
        %init(Speed);
    }
    if (IS_ENABLED(HidePaidPromoOverlay)) {
        %init(PaidPromoOverlay);
    }
    if (IS_ENABLED(GestureControls)) {
        %init(Gestures);
    }
}