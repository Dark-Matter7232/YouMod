#import "Headers.h"

// OLEDKeyboard (https://github.com/dayanch96/OledKeyboard)
static BOOL isDarkMode(UIView *view) {
    if ([view respondsToSelector:@selector(_mapkit_isDarkModeEnabled)]) {
        return view._mapkit_isDarkModeEnabled;
    }
    return view._viewControllerForAncestor.traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark;
}

%hook UIKeyboard
- (void)displayLayer:(id)arg1 {
    %orig;
    self.backgroundColor = isDarkMode(self) ? [UIColor blackColor] : [UIColor clearColor];
}
%end

%hook UIPredictionViewController
- (id)_currentTextSuggestions {
    UIKeyboard *keyboard = [%c(UIKeyboard) activeKeyboard];
    if (isDarkMode(keyboard)) {
        [self.view setBackgroundColor:[UIColor blackColor]];
        keyboard.backgroundColor = [UIColor blackColor];
    } else {
        [self.view setBackgroundColor:[UIColor clearColor]];
        keyboard.backgroundColor = [UIColor clearColor];
    }
    return %orig;
}
%end

%hook UIKeyboardDockView
- (void)layoutSubviews {
    %orig;
    self.backgroundColor = isDarkMode(self) ? [UIColor blackColor] : [UIColor clearColor];
}
%end

// Since we can't hook a private framework class from UIKit, we check the class name through the nearest available from UIKit class
%hook UIInputView
- (void)layoutSubviews {
    %orig;
    if ([self isKindOfClass:NSClassFromString(@"TUIEmojiSearchInputView")] // Emoji searching panel
     || [self isKindOfClass:NSClassFromString(@"_SFAutoFillInputView")]) { // Autofill password
        self.backgroundColor = isDarkMode(self) ? [UIColor blackColor] : [UIColor clearColor];
    }
}
%end

%hook UIKBVisualEffectView
- (void)layoutSubviews {
    %orig;
    if (isDarkMode(self)) {
        self.backgroundEffects = nil;
        self.backgroundColor = [UIColor blackColor];
    }
}
%end

%ctor {
    if (!IS_ENABLED(OLEDKeyboard)) return;
    %init;
}