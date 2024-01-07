#import <CoreFoundation/CoreFoundation.h>
#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>
#import <mach-o/dyld.h>
#import <rootless.h>
#import <UIKit/UIKit.h>
#include <stdlib.h>

extern "C" void BKSDisplayServicesSetScreenBlanked(bool arg1);
extern "C" void BKSHIDServicesSetBacklightFactorWithFadeDuration(float arg1, int arg2, Boolean arg3);
extern "C" void BKSDisplayBrightnessRestoreSystemBrightness();
extern "C" void BKSDisplayBrightnessSet(float level, int __unknown0);
extern "C" void BKSDisplayBrightnessSetAutoBrightnessEnabled(Boolean enabled);

// #define SYSTEM_VERSION_LESS_THAN(v) ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)

static NSString *domain = @"com.mtac.launchlogo.preferences";
static NSString *preferencesNotification = @"com.mtac.launchlogo.preferences/preferences.changed";

BOOL enabled;
BOOL invertLogo;
BOOL useCustomColor;
UIColor *backgroundColor;

@interface NSUserDefaults (LaunchLogo)
- (id)objectForKey:(NSString *)key inDomain:(NSString *)domain;
- (void)setObject:(id)value forKey:(NSString *)key inDomain:(NSString *)domain;
@end

@interface NSDistributedNotificationCenter : NSNotificationCenter
@end

@interface CAContext : NSObject
@property (retain) CALayer *layer;
@property (copy) NSDictionary *payload;
@end

@interface CALayer (LaunchLogo)
- (void)setFlipped:(BOOL)arg0;
@end

@interface PUIProgressWindow : NSObject {
    CALayer *_progressLayer;
    CALayer *_ioSurfaceLayer;
    BOOL _showsProgressBar;
    BOOL _isSecurityResearchDevice;
    BOOL _sideways;
}
@property (readonly, nonatomic) CALayer *layer;
- (id)initWithProgressBarVisibility:(BOOL)arg0 createContext:(BOOL)arg1 contextLevel:(float)arg2 appearance:(NSInteger)arg3;
- (id)initWithProgressBar:(BOOL)arg0 white:(BOOL)arg1;
- (void)drawLayer:(id)arg0 inContext:(CGContext *)arg1;
- (void)_createLayer;
- (void)setVisible:(BOOL)arg0;
- (void)hide:(NSNotification *)notification;
- (void)setProgressValue:(float)arg0;
- (void)startDismissTimer;
- (void)setStatusText:(id)arg0;
@end

@interface BKSDisplayProgressIndicatorProperties : NSObject
+ (id)progressIndicatorWithStyle:(NSInteger)arg0 position:(struct CGPoint )arg1;
@end

@interface BKSDisplayRenderOverlayDescriptor : NSObject
@property (retain, nonatomic) PUIProgressWindow *window;
@property (retain, nonatomic) BKSDisplayProgressIndicatorProperties *progressIndicatorProperties;
@end

PUIProgressWindow *window;

%group LaunchLogo
%hook PUIProgressWindow
- (id)init {
    self = %orig;
    if (self) {
        [[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(hide:) name:@"com.mtac.launchlogo.hide" object:nil];
    }
    return self;
}
%new
- (id)initWithProgressBar:(BOOL)arg0 white:(BOOL)arg1 {
    window = [self init];
    if (window) {
        MSHookIvar<BOOL>(self, "_showsProgressBar") = arg0;
        MSHookIvar<BOOL>(self, "_white") = arg1;
    }
    return window;
}
%new
- (void)hide:(NSNotification *)notification {
    [self setVisible:NO];
}
%new
- (void)startDismissTimer { // Fix for window not disappearing in safemode 
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self setVisible:NO];
    });
}
- (void)_createLayer {
    %orig;
    if (useCustomColor) {
        self.layer.backgroundColor = backgroundColor.CGColor;
    }
}
%end

%hook BKSDisplayRenderOverlayDescriptor
%property (retain, nonatomic) PUIProgressWindow *window;
- (id)initWithName:(id)arg0 display:(id)arg1 {
    window = nil;
    if (enabled) {
        if (!self.window) self.window = [[%c(PUIProgressWindow) alloc] initWithProgressBar:NO white:invertLogo];
        [self.window _createLayer];
        [self.window setVisible:YES];
        [self.window startDismissTimer]; // Fix for window not disappearing in safemode
    }
    return %orig;
}
- (BOOL)lockBacklight {
    if ([[NSProcessInfo processInfo] operatingSystemVersion].majorVersion < 16) {
        return NO;
    }
    return %orig;
}
%end

%hook FBSystemService
- (void)exitAndRelaunch:(BOOL)arg0 withOptions:(NSUInteger)arg1 {
    %orig(arg0, 1);
}
%end

%hook SpringBoard
- (void)applicationDidFinishLaunching:(id)arg0 { // Obviously is not called if hooking is disable via safemode, use timer instead
    %orig;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
		[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"com.mtac.launchlogo.hide" object:nil];
	});
}
%end

%hook BKSDisplayInterstitialRenderOverlayDismissAction
- (void)dismissWithAnimation:(id)arg0 {
    %orig;
    [[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"com.mtac.launchlogo.hide" object:nil];
}
%end
%end

static void loadPreferences(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
	NSNumber *enabledValue = (NSNumber *)[[NSUserDefaults standardUserDefaults] objectForKey:@"enabled" inDomain:domain];
	enabled = (enabledValue) ? [enabledValue boolValue] : NO;
    NSNumber *invertLogoValue = (NSNumber *)[[NSUserDefaults standardUserDefaults] objectForKey:@"invertLogo" inDomain:domain];
	invertLogo = (invertLogoValue) ? [invertLogoValue boolValue] : NO;
    NSNumber *useCustomColorValue = (NSNumber *)[[NSUserDefaults standardUserDefaults] objectForKey:@"useCustomColor" inDomain:domain];
	useCustomColor = (useCustomColorValue) ? [useCustomColorValue boolValue] : NO;

    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"backgroundColor" inDomain:domain]) {
        NSDictionary *backgroundColorDict = (NSDictionary *)[[NSUserDefaults standardUserDefaults] objectForKey:@"backgroundColor" inDomain:domain];
        backgroundColor = [UIColor colorWithRed:[backgroundColorDict[@"red"] floatValue] green:[backgroundColorDict[@"green"] floatValue] blue:[backgroundColorDict[@"blue"] floatValue] alpha:1.0] ?: [UIColor blackColor];
    }
}

%ctor {
    loadPreferences(NULL, NULL, NULL, NULL, NULL);
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, loadPreferences, (CFStringRef)preferencesNotification, NULL, CFNotificationSuspensionBehaviorCoalesce);
    if (enabled) {
        %init(LaunchLogo);
    }
}