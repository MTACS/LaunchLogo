#import <Foundation/Foundation.h>
#import "LLPRootListController.h"
#import <rootless.h>
#import "spawn.h"

@import SafariServices;

CGFloat progress;

@implementation LLPRootListController
- (id)init {
	self = [super init];
	if (self) {
		self.enableSwitch = [[LLPSwitch alloc] initWithSize:LLPSwitchSizeBig state:LLPSwitchStateOff]; 
		self.enableSwitch.delegate = self;
		self.enableSwitch.thumbOnTintColor = [UIColor labelColor];
		self.enableSwitch.thumbOffTintColor = [UIColor labelColor];
		self.enableSwitch.trackOnTintColor = [UIColor secondaryLabelColor];
		self.enableSwitch.trackOffTintColor = [UIColor secondaryLabelColor];

		self.navigationController.navigationBar.prefersLargeTitles = YES;
		self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeAlways;

        UIAction *respringAction = [UIAction actionWithTitle:@"Apply" image:[UIImage systemImageNamed:@"checkmark.circle.fill"] identifier:nil handler:^(__kindof UIAction *_Nonnull action) {
			[self respring];
		}];
	
		UIMenu *menuActions = [UIMenu menuWithTitle:@"" children:@[respringAction]];

		UIBarButtonItem *applyItem = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"checkmark.circle.fill"] menu:menuActions];
		applyItem.tintColor = [UIColor secondaryLabelColor];

        self.navigationItem.rightBarButtonItems = @[applyItem];
	}
	return self;
}
- (NSArray *)specifiers {
	if (!_specifiers) {
		_specifiers = [self loadSpecifiersFromPlistName:@"Root" target:self];
	}
	for (PSSpecifier *specifier in _specifiers) {
		if (specifier.properties[@"iconImageSystem"] != nil) {
			NSDictionary *systemIconDict = specifier.properties[@"iconImageSystem"];
			UIImageSymbolConfiguration *configuration = [UIImageSymbolConfiguration configurationWithPointSize:25 weight:UIImageSymbolWeightSemibold scale:UIImageSymbolScaleMedium];
			UIImage *systemIcon = [[UIImage systemImageNamed:systemIconDict[@"name"] withConfiguration:configuration] imageWithTintColor:[UIColor labelColor]];
			[specifier setProperty:systemIcon forKey:@"iconImage"];
		}
	}
	return _specifiers;
}
- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	[self setEnableSwitchState];
	[self.navigationController.navigationItem.navigationBar sizeToFit];
   	_table.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;

	if ([self.view respondsToSelector:@selector(setTintColor:)]) {
		UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
		keyWindow.tintColor = [UIColor secondaryLabelColor];
	}

	progress = 0.0;
	[self updateProgress];
}
- (void)updateProgress {
	progress += 0.1;
	[self.progressView setProgress:progress animated:YES];
	if (progress != 1.0) {
		[self performSelector:@selector(updateProgress) withObject:nil afterDelay:0.2];
    }
}
- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
	if ([self.view respondsToSelector:@selector(setTintColor:)]) {
		UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
		keyWindow.tintColor = nil;
	}
}
- (void)viewDidLoad {
    [super viewDidLoad];
	
	self.headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 200, 250)];
    self.headerImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 80, 80)];
    self.headerImageView.contentMode = UIViewContentModeScaleAspectFit;
	self.headerImageView.translatesAutoresizingMaskIntoConstraints = NO;
    self.enableSwitch.translatesAutoresizingMaskIntoConstraints = NO;

	self.progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
	self.progressView.progressTintColor = [UIColor labelColor];
	self.progressView.trackTintColor = [UIColor secondaryLabelColor];
	self.progressView.translatesAutoresizingMaskIntoConstraints = NO;
	
	[self setHeaderImage];

	[self.headerView addSubview:self.headerImageView];
	[self.headerView addSubview:self.enableSwitch];
	[self.headerView addSubview:self.progressView];

    [NSLayoutConstraint activateConstraints:@[
        [self.headerImageView.topAnchor constraintEqualToAnchor:self.headerView.topAnchor constant:30],
        [self.headerImageView.centerXAnchor constraintEqualToAnchor:self.headerView.centerXAnchor],
        [self.headerImageView.widthAnchor constraintEqualToConstant:80],
        [self.headerImageView.heightAnchor constraintEqualToConstant:80],
		[self.enableSwitch.bottomAnchor constraintEqualToAnchor:self.headerView.bottomAnchor constant:-30],
		[self.enableSwitch.centerXAnchor constraintEqualToAnchor:self.headerView.centerXAnchor],
		[self.enableSwitch.widthAnchor constraintEqualToConstant:50],
		[self.enableSwitch.heightAnchor constraintEqualToConstant:40],
		[self.progressView.topAnchor constraintEqualToAnchor:self.headerImageView.bottomAnchor constant:16],
		[self.progressView.widthAnchor constraintEqualToConstant:80],
		[self.progressView.centerXAnchor constraintEqualToAnchor:self.headerImageView.centerXAnchor],
	]];
	_table.tableHeaderView = self.headerView;
}
- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
	[self setHeaderImage];
}
- (void)setHeaderImage {
	self.headerImageView.tintColor = [UIColor labelColor];
	self.headerImageView.image = [[[UIImage systemImageNamed:@"applelogo"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] imageWithTintColor:[UIColor labelColor]];
}
- (void)respring {
	UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"LaunchLogo\n" message:@"Applying changes requires device to respring" preferredStyle:UIAlertControllerStyleAlert];
	UIAlertAction *confirm = [UIAlertAction actionWithTitle:@"Respring" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
		pid_t pid;
        const char* args[] = {"killall", "backboardd", NULL};
        posix_spawn(&pid, ROOT_PATH("/usr/bin/killall"), NULL, NULL, (char* const*)args, NULL);	
	}];		
	
	UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
		return;
	}];
	[alert addAction:confirm];
	[alert addAction:cancel];
	[self presentViewController:alert animated:YES completion:nil];
}
- (void)viewSource {
	[[NSBundle bundleWithPath:ROOT_PATH_NS(@"/System/Library/Frameworks/SafariServices.framework")] load];
	if ([SFSafariViewController class] != nil) {
		SFSafariViewController *safariView = [[SFSafariViewController alloc] initWithURL:[NSURL URLWithString:@"https://github.com/MTACS/LaunchLogo"]];
		if ([safariView respondsToSelector:@selector(setPreferredControlTintColor:)]) {
			safariView.preferredControlTintColor = [UIColor secondaryLabelColor];
		}
		[self.navigationController presentViewController:safariView animated:YES completion:nil];
	}
}
- (void)setEnableSwitchState {
	if (![[[NSUserDefaults standardUserDefaults] objectForKey:@"enabled" inDomain:domain] boolValue]) {
		[[self enableSwitch] setOn:NO animated:NO];
	} else {
		[[self enableSwitch] setOn:YES animated:NO];
	}
}
- (void)switchStateChanged:(LLPSwitchState)currentState {
	[self toggleState:self.enableSwitch];
}
- (void)toggleState:(LLPSwitch *)sender {
	if (!sender.isOn) {
		[[NSUserDefaults standardUserDefaults] setObject:@YES forKey:@"enabled" inDomain:domain];
	} else {
		[[NSUserDefaults standardUserDefaults] setObject:@NO forKey:@"enabled" inDomain:domain];
	}
	[self reloadSpecifiers];
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	tableView.tableHeaderView = self.headerView;
	PSTableCell *cell = (PSTableCell *)[super tableView:tableView cellForRowAtIndexPath:indexPath];
	cell.backgroundColor = [[UIColor tableCellGroupedBackgroundColor] colorWithAlphaComponent:0.5];
	if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"enabled" inDomain:domain] boolValue] == NO) {
		[cell setCellEnabled:NO];
	}
    if ([cell.specifier.properties[@"id"] isEqualToString:@"backgroundColor"]) {
        if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"useCustomColor" inDomain:domain] boolValue] == NO) {
		    [cell setCellEnabled:NO];
	    }
    }
	return cell;
}
- (void)setPreferenceValue:(id)value specifier:(PSSpecifier *)specifier {
	[super setPreferenceValue:value specifier:specifier];
	if ([specifier.properties[@"id"] isEqualToString:@"useCustomColor"]) {
		[self reloadSpecifiers];
	}
}
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
	if ([self tableView:tableView titleForHeaderInSection:section] != nil) {
		return 40;
	}
	return 10;
}
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 200, 30)];
	NSString *title = [self tableView:tableView titleForHeaderInSection:section];
	if (title != nil) {
		titleLabel.textColor = [UIColor secondaryLabelColor];
		titleLabel.font = [UIFont systemFontOfSize:20 weight:UIFontWeightSemibold];
		titleLabel.text = [NSString stringWithFormat:@" %@", title];
	}
	return titleLabel;
}
- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
	// NSInteger sectionIndex = settingsEnabled ? 1 : 3;
	if (section == [self numberOfGroups] - 1) {
		UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(([UIScreen mainScreen].bounds.size.width / 2) - 100, 0, 200, 100)];
		titleLabel.numberOfLines = 2;
		titleLabel.textColor = [UIColor secondaryLabelColor];
		titleLabel.textAlignment = NSTextAlignmentCenter;
		
		NSString *primary = @"LaunchLogo";
		NSString *secondary = @"v1.0 © MTAC";

		NSMutableAttributedString *final = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@\n%@", primary, secondary]];
		[final addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:18 weight:UIFontWeightSemibold] range:[final.string rangeOfString:primary]];
		[final addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:12 weight:UIFontWeightRegular] range:[final.string rangeOfString:secondary]];

		titleLabel.attributedText = final;
		return titleLabel;
	}
	return nil;
}
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    if (section == [self numberOfGroups] - 1) {
		return 50;
	}
	return 0;
}
@end

@implementation LLPSwitchTableCell
- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(id)identifier specifier:(PSSpecifier *)specifier {
	self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:identifier specifier:specifier];
	if (self) {
		self.detailTextLabel.text = specifier.properties[@"subtitle"] ?: @"";
		self.detailTextLabel.textAlignment = NSTextAlignmentLeft;
		self.detailTextLabel.textColor = [UIColor secondaryLabelColor];
		self.detailTextLabel.numberOfLines = [specifier.properties[@"lines"] integerValue] ?: 1;
		self.textLabel.textColor = [UIColor labelColor];
	}
	return self;
}
- (void)tintColorDidChange {
	[super tintColorDidChange];
	self.detailTextLabel.textColor = [UIColor secondaryLabelColor];
	self.textLabel.textColor = [UIColor labelColor];
}
- (void)refreshCellContentsWithSpecifier:(PSSpecifier *)specifier {
	[super refreshCellContentsWithSpecifier:specifier];
	if ([self respondsToSelector:@selector(tintColor)]) {
		self.detailTextLabel.textColor = [UIColor secondaryLabelColor];
		self.textLabel.textColor = [UIColor labelColor];
	}
}
- (id)newControl {
	LLPSwitch *switchControl = [[LLPSwitch alloc] initWithSize:LLPSwitchSizeNormal state:LLPSwitchStateOff];
	switchControl.delegate = self;
	switchControl.thumbOnTintColor = [UIColor labelColor];;
	switchControl.thumbOffTintColor = [UIColor labelColor];
	switchControl.trackOnTintColor = [UIColor secondaryLabelColor];
	switchControl.trackOffTintColor = [UIColor secondaryLabelColor];
	return switchControl;
}
- (void)switchStateChanged:(LLPSwitchState)currentState {
	AudioServicesPlaySystemSound(1519);
}
@end

@interface LLPSwitch ()
@property (nonatomic) CGFloat trackThickness;
@property (nonatomic) CGFloat thumbSize;
@end

@implementation LLPSwitch {
    float thumbOnPosition;
    float thumbOffPosition;
    float bounceOffset;
    LLPSwitchStyle thumbStyle;
}
- (id)init {
    self = [self initWithSize:LLPSwitchSizeNormal style:LLPSwitchStyleDefault state:LLPSwitchStateOn];
    return self;
}
- (id)initWithSize:(LLPSwitchSize)size state:(LLPSwitchState)state {
    self.thumbOnTintColor  = [UIColor colorWithRed:52./255. green:109./255. blue:241./255. alpha:1.0];
    self.thumbOffTintColor = [UIColor colorWithRed:249./255. green:249./255. blue:249./255. alpha:1.0];
    self.trackOnTintColor = [UIColor colorWithRed:143./255. green:179./255. blue:247./255. alpha:1.0];
    self.trackOffTintColor = [UIColor colorWithRed:193./255. green:193./255. blue:193./255. alpha:1.0];
    self.thumbDisabledTintColor = [UIColor colorWithRed:174./255. green:174./255. blue:174./255. alpha:1.0];
    self.trackDisabledTintColor = [UIColor colorWithRed:203./255. green:203./255. blue:203./255. alpha:1.0];
    self.isEnabled = YES;
    self.isBounceEnabled = YES;
    bounceOffset = 3.0f;
    
    CGRect frame;
    CGRect trackFrame = CGRectZero;
    CGRect thumbFrame = CGRectZero;
    switch (size) {
        case LLPSwitchSizeBig:
        frame = CGRectMake(0, 0, 50, 40);
        self.trackThickness = 23.0;
        self.thumbSize = 31.0;
        break;
        
        case LLPSwitchSizeNormal:
        frame = CGRectMake(0, 0, 40, 30);
        self.trackThickness = 17.0;
        self.thumbSize = 24.0;
        break;
        
        case LLPSwitchSizeSmall:
        frame = CGRectMake(0, 0, 30, 25);
        self.trackThickness = 13.0;
        self.thumbSize = 18.0;
        break;
        
        default:
        frame = CGRectMake(0, 0, 40, 30);
        self.trackThickness = 13.0;
        self.thumbSize = 20.0;
        break;
    }
    
    trackFrame.size.height = self.trackThickness;
    trackFrame.size.width = frame.size.width;
    trackFrame.origin.x = 0.0;
    trackFrame.origin.y = (frame.size.height-trackFrame.size.height)/2;
    thumbFrame.size.height = self.thumbSize;
    thumbFrame.size.width = thumbFrame.size.height;
    thumbFrame.origin.x = 0.0;
    thumbFrame.origin.y = (frame.size.height-thumbFrame.size.height)/2;
    
    self = [super initWithFrame:frame];
    
    self.track = [[UIView alloc] initWithFrame:trackFrame];
    self.track.backgroundColor = [UIColor grayColor];
    self.track.layer.cornerRadius = MIN(self.track.frame.size.height, self.track.frame.size.width)/2;
    [self addSubview:self.track];
    
    self.switchThumb = [[UIButton alloc] initWithFrame:thumbFrame];
    self.switchThumb.backgroundColor = [UIColor whiteColor];
    self.switchThumb.layer.cornerRadius = self.switchThumb.frame.size.height/2;
    self.switchThumb.layer.shadowOpacity = 0.5;
    self.switchThumb.layer.shadowOffset = CGSizeMake(0.0, 1.0);
    self.switchThumb.layer.shadowColor = [UIColor blackColor].CGColor;
    self.switchThumb.layer.shadowRadius = 2.0f;
    [self.switchThumb addTarget:self action:@selector(onTouchDown:withEvent:) forControlEvents:UIControlEventTouchDown];
    [self.switchThumb addTarget:self action:@selector(onTouchUpOutsideOrCanceled:withEvent:) forControlEvents:UIControlEventTouchUpOutside];
    [self.switchThumb addTarget:self action:@selector(switchThumbTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.switchThumb addTarget:self action:@selector(onTouchDragInside:withEvent:) forControlEvents:UIControlEventTouchDragInside];
    [self.switchThumb addTarget:self action:@selector(onTouchUpOutsideOrCanceled:withEvent:) forControlEvents:UIControlEventTouchCancel];
    
    [self addSubview:self.switchThumb];
    
    thumbOnPosition = self.frame.size.width - self.switchThumb.frame.size.width;
    thumbOffPosition = self.switchThumb.frame.origin.x;
    
    switch (state) {
        case LLPSwitchStateOn:
        self.isOn = YES;
        self.switchThumb.backgroundColor = self.thumbOnTintColor;
        CGRect thumbFrame = self.switchThumb.frame;
        thumbFrame.origin.x = thumbOnPosition;
        self.switchThumb.frame = thumbFrame;
        break;
        
        case LLPSwitchStateOff:
        self.isOn = NO;
        self.switchThumb.backgroundColor = self.thumbOffTintColor;
        break;
        
        default:
        self.isOn = NO;
        self.switchThumb.backgroundColor = self.thumbOffTintColor;
        break;
    }
    
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(switchAreaTapped:)];
    [self addGestureRecognizer:singleTap];
    return self;
}
- (id)initWithSize:(LLPSwitchSize)size style:(LLPSwitchStyle)style state:(LLPSwitchState)state {
    self = [self initWithSize:size state:state];
    if (self) {
        self.thumbOnTintColor = LIGHT_TINT;
        self.thumbOffTintColor = [UIColor systemGray3Color];
        self.trackOnTintColor = DARK_TINT;
        self.trackOffTintColor = [UIColor systemGrayColor];
        self.thumbDisabledTintColor = [UIColor systemGray2Color];
        self.trackDisabledTintColor = [UIColor systemGray2Color];
    }
    return self;
}
- (void)willMoveToSuperview:(UIView *)newSuperview {
    [super willMoveToSuperview:newSuperview];
    if (self.isOn == YES) {
        self.switchThumb.backgroundColor = self.thumbOnTintColor;
        self.track.backgroundColor = self.trackOnTintColor;
    }
    else {
        self.switchThumb.backgroundColor = self.thumbOffTintColor;
        self.track.backgroundColor = self.trackOffTintColor;
        // set initial position
        [self changeThumbStateOFFwithoutAnimation];
    }
  
    if (self.isEnabled == NO) {
        self.switchThumb.backgroundColor = self.thumbDisabledTintColor;
        self.track.backgroundColor = self.trackDisabledTintColor;
    }
  
  // Set bounce value, 3.0 if enabled and none for disabled
    if (self.isBounceEnabled == YES) {
        bounceOffset = 3.0f;
    } else {
        bounceOffset = 0.0f;
    }
}
- (BOOL)getSwitchState {
  return self.isOn;
}
- (void)setOn:(BOOL)on {
  [self setOn:on animated:NO];
}
- (void)setOn:(BOOL)on animated:(BOOL)animated {
    if (on == YES) {
        if (animated == YES) {
            [self changeThumbStateONwithAnimation];
        } else {
            [self changeThumbStateONwithoutAnimation];
        }
    } else {
        if (animated == YES) {
            [self changeThumbStateOFFwithAnimation];
        } else {
            [self changeThumbStateOFFwithoutAnimation];
        }
    }
}
- (void)setEnabled:(BOOL)enabled {
    [super setEnabled:enabled];
  
    [UIView animateWithDuration:0.1 animations:^{
        if (enabled == YES) {
            if (self.isOn == YES) {
                self.switchThumb.backgroundColor = self.thumbOnTintColor;
                self.track.backgroundColor = self.trackOnTintColor;
            } else {
                self.switchThumb.backgroundColor = self.thumbOffTintColor;
                self.track.backgroundColor = self.trackOffTintColor;
            }
            self.isEnabled = YES;
        } else {
            self.switchThumb.backgroundColor = self.thumbDisabledTintColor;
            self.track.backgroundColor = self.trackDisabledTintColor;
            self.isEnabled = NO;
        }
    }];
}
- (void)switchAreaTapped:(UITapGestureRecognizer *)recognizer {
    if ([self.delegate respondsToSelector:@selector(switchStateChanged:)]) {
        if (self.isOn == YES) {
            [self.delegate switchStateChanged:LLPSwitchStateOff];
        } else{
            [self.delegate switchStateChanged:LLPSwitchStateOn];
        }
    }
    [self changeThumbState];
}
- (void)changeThumbState {
    if (self.isOn == YES) {
        [self changeThumbStateOFFwithAnimation];
    } else {
        [self changeThumbStateONwithAnimation];
    }
}
- (void)changeThumbStateONwithAnimation {
    [UIView animateWithDuration:0.15f delay:0.05f options:UIViewAnimationOptionCurveEaseInOut animations:^{
        CGRect thumbFrame = self.switchThumb.frame;
        thumbFrame.origin.x = thumbOnPosition+bounceOffset;
        self.switchThumb.frame = thumbFrame;
        if (self.isEnabled == YES) {
            self.switchThumb.backgroundColor = self.thumbOnTintColor;
            self.track.backgroundColor = self.trackOnTintColor;
        } else {
            self.switchThumb.backgroundColor = self.thumbDisabledTintColor;
            self.track.backgroundColor = self.trackDisabledTintColor;
        }
        self.userInteractionEnabled = NO;
    } completion:^(BOOL finished) {
        if (self.isOn == NO) {
            self.isOn = YES;
            [self sendActionsForControlEvents:UIControlEventValueChanged];
        }
        self.isOn = YES;
        [UIView animateWithDuration:0.15f animations:^{
            CGRect thumbFrame = self.switchThumb.frame;
            thumbFrame.origin.x = thumbOnPosition;
            self.switchThumb.frame = thumbFrame;
        } completion:^(BOOL finished) {
            self.userInteractionEnabled = YES;
        }];
    }];
}
- (void)changeThumbStateOFFwithAnimation {
    [UIView animateWithDuration:0.15f delay:0.05f options:UIViewAnimationOptionCurveEaseInOut animations:^{
        CGRect thumbFrame = self.switchThumb.frame;
        thumbFrame.origin.x = thumbOffPosition-bounceOffset;
        self.switchThumb.frame = thumbFrame;
        if (self.isEnabled == YES) {
            self.switchThumb.backgroundColor = self.thumbOffTintColor;
            self.track.backgroundColor = self.trackOffTintColor;
        } else {
            self.switchThumb.backgroundColor = self.thumbDisabledTintColor;
            self.track.backgroundColor = self.trackDisabledTintColor;
        }
        self.userInteractionEnabled = NO;
    } completion:^(BOOL finished) {
        if (self.isOn == YES) {
            self.isOn = NO;
            [self sendActionsForControlEvents:UIControlEventValueChanged];
        }
        self.isOn = NO;
        [UIView animateWithDuration:0.15f animations:^{
            CGRect thumbFrame = self.switchThumb.frame;
            thumbFrame.origin.x = thumbOffPosition;
            self.switchThumb.frame = thumbFrame;
        } completion:^(BOOL finished) {
            self.userInteractionEnabled = YES;
        }];
    }];
}

- (void)changeThumbStateONwithoutAnimation {
    CGRect thumbFrame = self.switchThumb.frame;
    thumbFrame.origin.x = thumbOnPosition;
    self.switchThumb.frame = thumbFrame;
    if (self.isEnabled == YES) {
        self.switchThumb.backgroundColor = self.thumbOnTintColor;
        self.track.backgroundColor = self.trackOnTintColor;
    } else {
        self.switchThumb.backgroundColor = self.thumbDisabledTintColor;
        self.track.backgroundColor = self.trackDisabledTintColor;
    }
  
    if (self.isOn == NO) {
        self.isOn = YES;
        [self sendActionsForControlEvents:UIControlEventValueChanged];
    }
    self.isOn = YES;
}

- (void)changeThumbStateOFFwithoutAnimation {
    CGRect thumbFrame = self.switchThumb.frame;
    thumbFrame.origin.x = thumbOffPosition;
    self.switchThumb.frame = thumbFrame;
    if (self.isEnabled == YES) {
        self.switchThumb.backgroundColor = self.thumbOffTintColor;
        self.track.backgroundColor = self.trackOffTintColor;
    } else {
        self.switchThumb.backgroundColor = self.thumbDisabledTintColor;
        self.track.backgroundColor = self.trackDisabledTintColor;
    }
  
    if (self.isOn == YES) {
        self.isOn = NO;
        [self sendActionsForControlEvents:UIControlEventValueChanged];
    }
    self.isOn = NO;
}
- (void)onTouchDown:(UIButton *)btn withEvent:(UIEvent *)event {

}
- (void)switchThumbTapped: (id)sender {
    if ([self.delegate respondsToSelector:@selector(switchStateChanged:)]) {
        if (self.isOn == YES) {
            [self.delegate switchStateChanged:LLPSwitchStateOff];
        } else{
            [self.delegate switchStateChanged:LLPSwitchStateOn];
        }
    }
    [self changeThumbState];
}

- (void)onTouchUpOutsideOrCanceled:(UIButton *)btn withEvent:(UIEvent *)event {
    UITouch *touch = [[event touchesForView:btn] anyObject];
    CGPoint prevPos = [touch previousLocationInView:btn];
    CGPoint pos = [touch locationInView:btn];
    float dX = pos.x-prevPos.x;
    float newXOrigin = btn.frame.origin.x + dX;
 
    if (newXOrigin > (self.frame.size.width - self.switchThumb.frame.size.width)/2) {
        [self changeThumbStateONwithAnimation];
    } else {
        [self changeThumbStateOFFwithAnimation];
    }
}
- (void)onTouchDragInside:(UIButton *)btn withEvent:(UIEvent *)event {
    UITouch *touch = [[event touchesForView:btn] anyObject];
    CGPoint prevPos = [touch previousLocationInView:btn];
    CGPoint pos = [touch locationInView:btn];
    float dX = pos.x-prevPos.x;
    
    CGRect thumbFrame = btn.frame;
    
    thumbFrame.origin.x += dX;
    thumbFrame.origin.x = MIN(thumbFrame.origin.x,thumbOnPosition);
    thumbFrame.origin.x = MAX(thumbFrame.origin.x,thumbOffPosition);
    
    if (thumbFrame.origin.x != btn.frame.origin.x) {
        btn.frame = thumbFrame;
    }
}
@end

@implementation LLPTableCell
- (void)tintColorDidChange {
	[super tintColorDidChange];
	self.textLabel.textColor = [UIColor labelColor];
	self.textLabel.highlightedTextColor = [UIColor labelColor];
	self.detailTextLabel.textColor = [UIColor secondaryLabelColor];
	self.detailTextLabel.highlightedTextColor = [UIColor secondaryLabelColor];;
}
- (void)refreshCellContentsWithSpecifier:(PSSpecifier *)specifier {
	[super refreshCellContentsWithSpecifier:specifier];
	if ([self respondsToSelector:@selector(tintColor)]) {
		self.detailTextLabel.textColor = [UIColor secondaryLabelColor];;
		self.detailTextLabel.highlightedTextColor = [UIColor secondaryLabelColor];;
		self.textLabel.textColor = [UIColor labelColor];
		self.textLabel.highlightedTextColor = [UIColor labelColor];
	}
}
- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(id)identifier specifier:(PSSpecifier *)specifier {
	self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:identifier specifier:specifier];
	if (self) {
		self.detailTextLabel.text = specifier.properties[@"subtitle"] ?: @"";
		self.detailTextLabel.textColor = [UIColor secondaryLabelColor];
		self.detailTextLabel.numberOfLines = 1;
		self.detailTextLabel.highlightedTextColor = [UIColor secondaryLabelColor];
	}
	return self;
}
@end

@implementation LLPColorCell
@dynamic control;
- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier specifier:(PSSpecifier *)specifier {
	self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier specifier:specifier];
	if (self) {
		self.accessoryView = self.control;
		self.detailTextLabel.text = [specifier.properties objectForKey:@"subtitle"];
		self.detailTextLabel.numberOfLines = 2;
	}
	return self;
}
- (void)setCellEnabled:(BOOL)cellEnabled {
	[super setCellEnabled:cellEnabled];
	self.control.backgroundColor = cellEnabled ? [self selectedColor] : [UIColor secondaryLabelColor];
	// self.control.hidden = !cellEnabled;
}
- (void)refreshCellContentsWithSpecifier:(PSSpecifier *)specifier {
	[super refreshCellContentsWithSpecifier:specifier];
	self.control.backgroundColor = [self cellEnabled] ? [self selectedColor] : [UIColor secondaryLabelColor];
}
- (UIButton *)newControl {
	UIButton *colorButton = [UIButton buttonWithType:UIButtonTypeCustom];
	colorButton.frame = CGRectMake(0, 0, 30, 30);
	colorButton.backgroundColor = [self selectedColor];
	colorButton.layer.masksToBounds = NO;
	colorButton.layer.cornerRadius = colorButton.frame.size.width / 2;
    colorButton.layer.borderWidth = 1;
    colorButton.layer.borderColor = [UIColor secondaryLabelColor].CGColor;
	[colorButton addTarget:self action:@selector(selectColor) forControlEvents:UIControlEventTouchUpInside];
	return colorButton;
}
- (void)selectColor {
	UIColorPickerViewController *colorPickerController = [[UIColorPickerViewController alloc] init];
	colorPickerController.delegate = self;
	colorPickerController.supportsAlpha = NO;
	colorPickerController.modalPresentationStyle = UIModalPresentationPageSheet;
	colorPickerController.modalInPresentation = YES;
	colorPickerController.selectedColor = [self selectedColor];
	[[self _viewControllerForAncestor] presentViewController:colorPickerController animated:YES completion:nil]; 
}
- (UIColor *)selectedColor {
	NSDictionary *colorDict = [[NSUserDefaults standardUserDefaults] objectForKey:self.specifier.properties[@"key"] inDomain:domain];
	return colorDict ? [UIColor colorWithRed:[colorDict[@"red"] floatValue] green:[colorDict[@"green"] floatValue] blue:[colorDict[@"blue"] floatValue] alpha:1.0] : [UIColor blackColor];
}
- (void)colorPickerViewControllerDidSelectColor:(UIColorPickerViewController *)viewController {
	[[NSUserDefaults standardUserDefaults] setObject:[self dictionaryForColor:viewController.selectedColor] forKey:self.specifier.properties[@"key"] inDomain:domain];
	[[NSUserDefaults standardUserDefaults] synchronize];
	self.control.backgroundColor = [self selectedColor];
	CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), (CFStringRef)@"com.mtac.launchlogo.preferences/preferences.changed", nil, nil, true);
}
- (NSDictionary *)dictionaryForColor:(UIColor *)color {
	const CGFloat *components = CGColorGetComponents(color.CGColor);
	NSMutableDictionary *colorDict = [NSMutableDictionary new];
	[colorDict setObject:[NSNumber numberWithFloat:components[0]] forKey:@"red"];
	[colorDict setObject:[NSNumber numberWithFloat:components[1]] forKey:@"green"];
	[colorDict setObject:[NSNumber numberWithFloat:components[2]] forKey:@"blue"];
	return colorDict;
}
@end
