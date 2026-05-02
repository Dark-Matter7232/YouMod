// SponsorBlockSettings.x
#import "Headers.h"

#define SB_LOC(x) [SBSettingsBundle() localizedStringForKey:x value:nil table:nil]

static NSBundle *SBSettingsBundle() {
    static NSBundle *bundle = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *tweakBundlePath = [[NSBundle mainBundle] pathForResource:@"YouMod" ofType:@"bundle"];
        if (tweakBundlePath)
            bundle = [NSBundle bundleWithPath:tweakBundlePath];
        else
            bundle = [NSBundle bundleWithPath:[NSString stringWithFormat:PS_ROOT_PATH_NS(@"/Library/Application Support/%@.bundle"), @"YouMod"]];
    });
    return bundle;
}

static NSString *SBActionName(NSInteger action) {
    switch (action) {
        case SBSegmentActionAutoSkip: return SB_LOC(@"SB_ACTION_AUTO_SKIP");
        case SBSegmentActionAsk:      return SB_LOC(@"SB_ACTION_ASK");
        case SBSegmentActionDisplay:   return SB_LOC(@"SB_ACTION_DISPLAY");
        case SBSegmentActionSkipTo:    return SB_LOC(@"SB_ACTION_SKIP_TO");
        default:                       return SB_LOC(@"SB_ACTION_DISABLE");
    }
}

static NSArray<NSDictionary *> *SBColorPresets() {
    static NSArray *presets;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        presets = @[
            @{@"name": @"Green",  @"hex": @"#00D400"},
            @{@"name": @"Cyan",   @"hex": @"#00FFFF"},
            @{@"name": @"Blue",   @"hex": @"#0202ED"},
            @{@"name": @"Purple", @"hex": @"#CC00FF"},
            @{@"name": @"Yellow", @"hex": @"#FFFF00"},
            @{@"name": @"Orange", @"hex": @"#FF9900"},
            @{@"name": @"Sky",    @"hex": @"#008FD6"},
            @{@"name": @"White",  @"hex": @"#FFFFFF"},
            @{@"name": @"Violet", @"hex": @"#7300FF"},
            @{@"name": @"Red",    @"hex": @"#FF0000"},
            @{@"name": @"Pink",   @"hex": @"#FF69B4"},
            @{@"name": @"Teal",   @"hex": @"#008080"},
        ];
    });
    return presets;
}

static NSArray<NSString *> *sbSettingsCategories() {
    return @[@"sponsor", @"intro", @"outro", @"interaction", @"selfpromo",
             @"music_offtopic", @"preview", @"poi_highlight", @"filler"];
}

@interface YTSettingsSectionItemManager (SponsorBlock)
- (void)updateSponsorBlockSectionWithEntry:(id)entry;
@end

%hook YTSettingsSectionItemManager

%new(v@:@)
- (void)updateSponsorBlockSectionWithEntry:(id)entry {
    NSMutableArray <YTSettingsSectionItem *> *sectionItems = [NSMutableArray array];
    NSBundle *tweakBundle = SBSettingsBundle();
    Class YTSettingsSectionItemClass = %c(YTSettingsSectionItem);
    YTSettingsViewController *settingsViewController = [self valueForKey:@"_settingsViewControllerDelegate"];

    // Header
    YTSettingsSectionItem *header = [YTSettingsSectionItemClass itemWithTitle:@"SponsorBlock"
        titleDescription:SB_LOC(@"SB_DESCRIPTION")
        accessibilityIdentifier:nil
        detailTextBlock:nil
        selectBlock:^BOOL (YTSettingsCell *cell, NSUInteger arg1) {
            return NO;
        }];
    [sectionItems addObject:header];

    // Master toggle: Enable SponsorBlock
    YTSettingsSectionItem *enableToggle = [YTSettingsSectionItemClass switchItemWithTitle:SB_LOC(@"SB_ENABLE")
        titleDescription:SB_LOC(@"SB_ENABLE_DESC")
        accessibilityIdentifier:nil
        switchOn:IS_ENABLED(SBEnabled)
        switchBlock:^BOOL (YTSettingsCell *cell, BOOL enabled) {
            [[NSUserDefaults standardUserDefaults] setBool:enabled forKey:SBEnabled];
            return YES;
        }
        settingItemId:0];
    [sectionItems addObject:enableToggle];

    // Toggle: Show overlay button
    YTSettingsSectionItem *showButton = [YTSettingsSectionItemClass switchItemWithTitle:SB_LOC(@"SB_SHOW_BUTTON")
        titleDescription:SB_LOC(@"SB_SHOW_BUTTON_DESC")
        accessibilityIdentifier:nil
        switchOn:IS_ENABLED(SBShowButton)
        switchBlock:^BOOL (YTSettingsCell *cell, BOOL enabled) {
            [[NSUserDefaults standardUserDefaults] setBool:enabled forKey:SBShowButton];
            return YES;
        }
        settingItemId:0];
    [sectionItems addObject:showButton];

    // Toggle: Show notifications
    YTSettingsSectionItem *showNotif = [YTSettingsSectionItemClass switchItemWithTitle:SB_LOC(@"SB_SHOW_NOTIFICATIONS")
        titleDescription:SB_LOC(@"SB_SHOW_NOTIFICATIONS_DESC")
        accessibilityIdentifier:nil
        switchOn:IS_ENABLED(SBShowNotifications)
        switchBlock:^BOOL (YTSettingsCell *cell, BOOL enabled) {
            [[NSUserDefaults standardUserDefaults] setBool:enabled forKey:SBShowNotifications];
            return YES;
        }
        settingItemId:0];
    [sectionItems addObject:showNotif];

    // Toggle: Haptic feedback
    YTSettingsSectionItem *haptic = [YTSettingsSectionItemClass switchItemWithTitle:SB_LOC(@"SB_HAPTIC_FEEDBACK")
        titleDescription:SB_LOC(@"SB_HAPTIC_FEEDBACK_DESC")
        accessibilityIdentifier:nil
        switchOn:IS_ENABLED(SBAudioNotification)
        switchBlock:^BOOL (YTSettingsCell *cell, BOOL enabled) {
            [[NSUserDefaults standardUserDefaults] setBool:enabled forKey:SBAudioNotification];
            return YES;
        }
        settingItemId:0];
    [sectionItems addObject:haptic];

    // Toggle: Segments in feed
    YTSettingsSectionItem *segFeed = [YTSettingsSectionItemClass switchItemWithTitle:SB_LOC(@"SB_SEGMENTS_IN_FEED")
        titleDescription:SB_LOC(@"SB_SEGMENTS_IN_FEED_DESC")
        accessibilityIdentifier:nil
        switchOn:IS_ENABLED(SBSegmentsInFeed)
        switchBlock:^BOOL (YTSettingsCell *cell, BOOL enabled) {
            [[NSUserDefaults standardUserDefaults] setBool:enabled forKey:SBSegmentsInFeed];
            return YES;
        }
        settingItemId:0];
    [sectionItems addObject:segFeed];

    // Toggle: Segments in mini-player
    YTSettingsSectionItem *segMini = [YTSettingsSectionItemClass switchItemWithTitle:SB_LOC(@"SB_SEGMENTS_IN_MINIPLAYER")
        titleDescription:SB_LOC(@"SB_SEGMENTS_IN_MINIPLAYER_DESC")
        accessibilityIdentifier:nil
        switchOn:IS_ENABLED(SBSegmentsInMiniPlayer)
        switchBlock:^BOOL (YTSettingsCell *cell, BOOL enabled) {
            [[NSUserDefaults standardUserDefaults] setBool:enabled forKey:SBSegmentsInMiniPlayer];
            return YES;
        }
        settingItemId:0];
    [sectionItems addObject:segMini];

    // Toggle: Show duration without segments
    YTSettingsSectionItem *showDur = [YTSettingsSectionItemClass switchItemWithTitle:SB_LOC(@"SB_SHOW_DURATION")
        titleDescription:SB_LOC(@"SB_SHOW_DURATION_DESC")
        accessibilityIdentifier:nil
        switchOn:IS_ENABLED(SBShowDuration)
        switchBlock:^BOOL (YTSettingsCell *cell, BOOL enabled) {
            [[NSUserDefaults standardUserDefaults] setBool:enabled forKey:SBShowDuration];
            return YES;
        }
        settingItemId:0];
    [sectionItems addObject:showDur];

    // Section header: Segment categories
    YTSettingsSectionItem *catHeader = [YTSettingsSectionItemClass itemWithTitle:nil
        titleDescription:SB_LOC(@"SB_CATEGORIES_HEADER")
        accessibilityIdentifier:nil
        detailTextBlock:nil
        selectBlock:^BOOL (YTSettingsCell *cell, NSUInteger arg1) {
            return NO;
        }];
    [sectionItems addObject:catHeader];

    // Per-category rows
    for (NSString *category in sbSettingsCategories()) {
        NSString *catLocKey = [NSString stringWithFormat:@"SB_CAT_%@", category];
        NSString *catDescKey = [NSString stringWithFormat:@"SB_CAT_%@_DESC", category];
        NSString *actionKey = SB_ACTION_KEY(category);
        NSString *colorKey = SB_COLOR_KEY(category);
        BOOL isHighlight = [category isEqualToString:@"poi_highlight"];

        YTSettingsSectionItem *catRow = [YTSettingsSectionItemClass itemWithTitle:[tweakBundle localizedStringForKey:catLocKey value:category table:nil]
            accessibilityIdentifier:nil
            detailTextBlock:^NSString *() {
                NSInteger currentAction = INTFORVAL(actionKey);
                return SBActionName(currentAction);
            }
            selectBlock:^BOOL (YTSettingsCell *cell, NSUInteger arg1) {
                NSMutableArray <YTSettingsSectionItem *> *catRows = [NSMutableArray array];

                // Description header
                YTSettingsSectionItem *descItem = [YTSettingsSectionItemClass itemWithTitle:nil
                    titleDescription:[tweakBundle localizedStringForKey:catDescKey value:nil table:nil]
                    accessibilityIdentifier:nil
                    detailTextBlock:nil
                    selectBlock:^BOOL (YTSettingsCell *cell, NSUInteger arg1) {
                        return NO;
                    }];
                [catRows addObject:descItem];

                // Action checkmark items
                NSArray *actions;
                if (isHighlight) {
                    actions = @[
                        @[@(SBSegmentActionDisable), @"SB_ACTION_DISABLE"],
                        @[@(SBSegmentActionSkipTo), @"SB_ACTION_SKIP_TO"],
                        @[@(SBSegmentActionDisplay), @"SB_ACTION_DISPLAY"],
                    ];
                } else {
                    actions = @[
                        @[@(SBSegmentActionDisable), @"SB_ACTION_DISABLE"],
                        @[@(SBSegmentActionAutoSkip), @"SB_ACTION_AUTO_SKIP"],
                        @[@(SBSegmentActionAsk), @"SB_ACTION_ASK"],
                        @[@(SBSegmentActionDisplay), @"SB_ACTION_DISPLAY"],
                    ];
                }

                NSInteger currentAction = INTFORVAL(actionKey);
                NSUInteger selectedIdx = 0;
                for (NSUInteger i = 0; i < actions.count; i++) {
                    NSNumber *actionVal = actions[i][0];
                    NSString *actionLocKey = actions[i][1];

                    if ([actionVal integerValue] == currentAction) selectedIdx = i;

                    YTSettingsSectionItem *actionItem = [YTSettingsSectionItemClass checkmarkItemWithTitle:[tweakBundle localizedStringForKey:actionLocKey value:nil table:nil]
                        titleDescription:nil
                        selectBlock:^BOOL (YTSettingsCell *cell, NSUInteger arg1) {
                            [[NSUserDefaults standardUserDefaults] setInteger:[actionVal integerValue] forKey:actionKey];
                            [settingsViewController reloadData];
                            return YES;
                        }];
                    [catRows addObject:actionItem];
                }

                // Segment color row
                YTSettingsSectionItem *colorRow = [YTSettingsSectionItemClass itemWithTitle:SB_LOC(@"SB_SEGMENT_COLOR")
                    accessibilityIdentifier:nil
                    detailTextBlock:^NSString *() {
                        NSString *currentHex = [[NSUserDefaults standardUserDefaults] stringForKey:colorKey];
                        for (NSDictionary *preset in SBColorPresets()) {
                            if ([preset[@"hex"] isEqualToString:currentHex]) return preset[@"name"];
                        }
                        return currentHex ?: @"";
                    }
                    selectBlock:^BOOL (YTSettingsCell *cell, NSUInteger arg1) {
                        NSMutableArray <YTSettingsSectionItem *> *colorRows = [NSMutableArray array];
                        NSString *currentHex = [[NSUserDefaults standardUserDefaults] stringForKey:colorKey];
                        NSUInteger colorSelectedIdx = 0;

                        for (NSUInteger ci = 0; ci < SBColorPresets().count; ci++) {
                            NSDictionary *preset = SBColorPresets()[ci];
                            NSString *presetName = preset[@"name"];
                            NSString *presetHex = preset[@"hex"];

                            if ([presetHex isEqualToString:currentHex]) colorSelectedIdx = ci;

                            YTSettingsSectionItem *colorItem = [YTSettingsSectionItemClass checkmarkItemWithTitle:presetName
                                titleDescription:presetHex
                                selectBlock:^BOOL (YTSettingsCell *cell, NSUInteger arg1) {
                                    [[NSUserDefaults standardUserDefaults] setObject:presetHex forKey:colorKey];
                                    [settingsViewController reloadData];
                                    return YES;
                                }];
                            [colorRows addObject:colorItem];
                        }

                        YTSettingsPickerViewController *colorPicker = [[%c(YTSettingsPickerViewController) alloc]
                            initWithNavTitle:SB_LOC(@"SB_SEGMENT_COLOR")
                            pickerSectionTitle:nil
                            rows:colorRows
                            selectedItemIndex:colorSelectedIdx
                            parentResponder:[self parentResponder]];
                        [settingsViewController pushViewController:colorPicker];
                        return YES;
                    }];
                [catRows addObject:colorRow];

                YTSettingsPickerViewController *catPicker = [[%c(YTSettingsPickerViewController) alloc]
                    initWithNavTitle:[tweakBundle localizedStringForKey:catLocKey value:category table:nil]
                    pickerSectionTitle:nil
                    rows:catRows
                    selectedItemIndex:selectedIdx + 1
                    parentResponder:[self parentResponder]];
                [settingsViewController pushViewController:catPicker];
                return YES;
            }];
        [sectionItems addObject:catRow];
    }

    YTSettingsPickerViewController *picker = [[%c(YTSettingsPickerViewController) alloc]
        initWithNavTitle:@"SponsorBlock"
        pickerSectionTitle:nil
        rows:sectionItems
        selectedItemIndex:0
        parentResponder:[self parentResponder]];
    [settingsViewController pushViewController:picker];
}

%end

%ctor {
    [[NSUserDefaults standardUserDefaults] registerDefaults:@{
        SBEnabled: @YES,
        SBShowButton: @YES,
        SBShowNotifications: @YES,
        SBAudioNotification: @NO,
        SBSegmentsInFeed: @NO,
        SBSegmentsInMiniPlayer: @YES,
        SBShowDuration: @NO,
        SB_ACTION_KEY(@"sponsor"): @(SBSegmentActionAutoSkip),
        SB_ACTION_KEY(@"intro"): @(SBSegmentActionAutoSkip),
        SB_ACTION_KEY(@"outro"): @(SBSegmentActionAutoSkip),
        SB_ACTION_KEY(@"interaction"): @(SBSegmentActionAutoSkip),
        SB_ACTION_KEY(@"selfpromo"): @(SBSegmentActionAutoSkip),
        SB_ACTION_KEY(@"music_offtopic"): @(SBSegmentActionAutoSkip),
        SB_ACTION_KEY(@"preview"): @(SBSegmentActionAutoSkip),
        SB_ACTION_KEY(@"poi_highlight"): @(SBSegmentActionSkipTo),
        SB_ACTION_KEY(@"filler"): @(SBSegmentActionDisplay),
        SB_COLOR_KEY(@"sponsor"): @"#00D400",
        SB_COLOR_KEY(@"intro"): @"#00FFFF",
        SB_COLOR_KEY(@"outro"): @"#0202ED",
        SB_COLOR_KEY(@"interaction"): @"#CC00FF",
        SB_COLOR_KEY(@"selfpromo"): @"#FFFF00",
        SB_COLOR_KEY(@"music_offtopic"): @"#FF9900",
        SB_COLOR_KEY(@"preview"): @"#008FD6",
        SB_COLOR_KEY(@"poi_highlight"): @"#FFFFFF",
        SB_COLOR_KEY(@"filler"): @"#7300FF",
    }];
    %init;
}
