#import <UIKit/UIKit.h>
#import <Preferences/PSListController.h>
#import <Preferences/PSTableCell.h>
#import <Preferences/PSSpecifier.h>
#import <Preferences/PSSwitchTableCell.h>
#import <AudioToolbox/AudioServices.h>
#import <mach-o/dyld.h>

static NSString *domain = @"com.mtac.launchlogo.preferences";

#define LIGHT_TINT [UIColor colorWithRed: 0.20 green: 0.60 blue: 0.86 alpha: 1.00]
#define DARK_TINT [UIColor colorWithRed: 0.36 green: 0.68 blue: 0.89 alpha: 1.00]

@interface BSAction : NSObject
@end

@interface SBSRelaunchAction : BSAction
+ (id)actionWithReason:(id)arg1 options:(unsigned long long)arg2 targetURL:(id)arg3;
@end

@interface FBSSystemService : NSObject
+ (id)sharedService;
- (void)sendActions:(id)arg1 withResult:(id)arg2;
@end

@interface UINavigationItem (LaunchLogo)
@property (assign, nonatomic) UINavigationBar *navigationBar; 
@end

@interface UIColor (LaunchLogo) 
+ (id)tableCellGroupedBackgroundColor;
+ (id)opaqueSeparatorColor;
@end

@interface NSUserDefaults (LaunchLogo)
- (id)objectForKey:(NSString *)key inDomain:(NSString *)domain;
- (NSInteger)integerForKey:(NSString *)key inDomain:(NSString *)domain;
- (void)setObject:(id)value forKey:(NSString *)key inDomain:(NSString *)domain;
@end

@interface UIView (LaunchLogo)
- (id)_viewControllerForAncestor;
@end

typedef enum {
    LLPSwitchStyleLight,
    LLPSwitchStyleDark,
    LLPSwitchStyleDefault
} LLPSwitchStyle;

typedef enum {
    LLPSwitchStateOn,
    LLPSwitchStateOff
} LLPSwitchState;

typedef enum {
    LLPSwitchSizeBig,
    LLPSwitchSizeNormal,
    LLPSwitchSizeSmall
} LLPSwitchSize;

@protocol LLPSwitchDelegate <NSObject>
- (void)switchStateChanged:(LLPSwitchState)currentState;
@end

@interface LLPSwitch : UIControl
@property (nonatomic, assign) id<LLPSwitchDelegate> delegate;
@property (nonatomic, assign) BOOL isOn;
@property (nonatomic, assign) BOOL isEnabled;
@property (nonatomic, assign) BOOL isBounceEnabled;
@property (nonatomic, strong) UIColor *thumbOnTintColor;
@property (nonatomic, strong) UIColor *thumbOffTintColor;
@property (nonatomic, strong) UIColor *trackOnTintColor;
@property (nonatomic, strong) UIColor *trackOffTintColor;
@property (nonatomic, strong) UIColor *thumbDisabledTintColor;
@property (nonatomic, strong) UIColor *trackDisabledTintColor;
@property (nonatomic, strong) UIButton *switchThumb;
@property (nonatomic, strong) UIView *track;
- (id)init;
- (id)initWithSize:(LLPSwitchSize)size state:(LLPSwitchState)state;
- (id)initWithSize:(LLPSwitchSize)size style:(LLPSwitchStyle)style state:(LLPSwitchState)state;
- (BOOL)getSwitchState;
- (void)setOn:(BOOL)on;
- (void)setOn:(BOOL)on animated:(BOOL)animated;
@end

@interface LLPRootListController : PSListController <LLPSwitchDelegate> {
    UITableView *_table;
}
@property (nonatomic, strong) UIView *headerView;
@property (nonatomic, strong) UIImageView *headerImageView;
@property (nonatomic, strong) LLPSwitch *enableSwitch;
@property (nonatomic, strong) UIProgressView *progressView;
- (void)respring;
@end

@interface LLPSwitchTableCell: PSSwitchTableCell <LLPSwitchDelegate>
@end

@interface LLPTableCell: PSTableCell
@end

@interface LLPColorCell : PSControlTableCell <UIColorPickerViewControllerDelegate>
@property (nonatomic, retain) UIButton *control;
- (NSDictionary *)dictionaryForColor:(UIColor *)color;
- (void)selectColor;
@end