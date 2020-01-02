//  Flexy.xm
//  Flexy
//
//  This is a /heavily/ modified fork of the Flex12 Project
//  Original Copyright notice by Shyam Lad preserved below:
//  
//
//  FLEX12
//
//  Created by Shyam Lad
//  Copyright © 2019 Shyam Lad. All rights reserved.
//

#import "FLEXManager.h"
#import "Flexy.h"
#import <AudioToolbox/AudioToolbox.h>
#define kSettingsPath [NSHomeDirectory() stringByAppendingPathComponent:@"/Library/Preferences/me.kritanta.flexy.plist"]

static BOOL hasBeenForceTapped = NO;
static BOOL enabled = YES;
static BOOL enabled_Locked = YES;
static BOOL enabled_LongPress = YES;
static float FLXForce = 2;
static BOOL gestureLoaded = NO;


@interface NSUserDefaults (Tweak_Category)
- (id)objectForKey:(NSString *)key inDomain:(NSString *)domain;
- (void)setObject:(id)value forKey:(NSString *)key inDomain:(NSString *)domain;
@end

static NSString *nsDomainString = @"me.kritanta.Flexy";
static NSString *nsNotificationString = @"me.kritanta.Flexy/preferences.changed";

static void notificationCallback(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) 
{
	NSNumber *n1 = (NSNumber *)[[NSUserDefaults standardUserDefaults] objectForKey:@"FLXEnabled" inDomain:nsDomainString];
	enabled = (n1)? [n1 boolValue]:YES;
    NSNumber *n2 = (NSNumber *)[[NSUserDefaults standardUserDefaults] objectForKey:@"FLXLocked" inDomain:nsDomainString];
    enabled_Locked = (n2)? [n2 boolValue]:YES;
    NSNumber *n3 = (NSNumber *)[[NSUserDefaults standardUserDefaults] objectForKey:@"FLXForce" inDomain:nsDomainString];
    FLXForce = (n3)? [n3 floatValue]:2;
    NSNumber *n4 = (NSNumber *)[[NSUserDefaults standardUserDefaults] objectForKey:@"FLXLongPress" inDomain:nsDomainString];
	enabled_LongPress = (n4)? [n4 boolValue]:YES;
}


static void respring(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) 
{
  [[%c(FBSystemService) sharedInstance] exitAndRelaunch:YES];
}


%hook SBDashBoardIdleTimerProvider

// On iOS 13, disable the lock screen idle timer when editing.

- (instancetype)initWithDelegate:(id)arg1 
{
    %orig;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(stopTimeout) name:@"STOP_IDLE_TIMER" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(startTimeout) name:@"START_IDLE_TIMER" object:nil];
    return self;
}

%new 
- (void)stopTimeout
{
    [self addDisabledIdleTimerAssertionReason:@"FLEXYEDITORENABLED"];
}

%new 
- (void)startTimeout
{
    [self removeDisabledIdleTimerAssertionReason:@"FLEXYEDITORENABLED"];
}

%end


%hook UIWindow

- (BOOL)_shouldCreateContextAsSecure 
{
    if (enabled_Locked) 
    {
        return [self isKindOfClass:%c(FLEXWindow)] ? YES : %orig;
    }
    return %orig;
}

%end


%hook UISystemGestureView

// iOS 

- (void)layoutSubviews
{
    %orig;
    UIView *hp_hitbox_window = [[UIView alloc] initWithFrame:CGRectMake(60, 0, 60, 50)];

    UIView *hp_hitbox = [[UIView alloc] init];
    hp_hitbox.backgroundColor = [UIColor.lightGrayColor colorWithAlphaComponent:0.1];
    [hp_hitbox setValue:@NO forKey:@"deliversTouchesForGesturesToSuperview"];

    UISwipeGestureRecognizer *swipeDownGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(act)];
    [swipeDownGesture setDirection:UISwipeGestureRecognizerDirectionDown];
    [hp_hitbox addGestureRecognizer: swipeDownGesture];

    UISwipeGestureRecognizer *swipeUpGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(act)];
    [swipeUpGesture setDirection:UISwipeGestureRecognizerDirectionUp];
    [hp_hitbox addGestureRecognizer: swipeUpGesture];

    CGSize hitboxSize = CGSizeMake(60, 50);
    hp_hitbox.frame = CGRectMake(60, 0, hitboxSize.width, hitboxSize.height);
    [hp_hitbox_window addSubview:hp_hitbox];
    //[self addSubview:hp_hitbox_window];

    hp_hitbox_window.hidden = YES;
}

%new 
- (void)act 
{
    [[FLEXManager sharedManager] showExplorer];
}

%end


%hook _UIStatusBar
- (void)layoutSubviews 
{
    %orig;
    if(enabled_LongPress && !gestureLoaded) 
    {
        UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc]
                                                initWithTarget:self
                                                action:@selector(handleLongPress:)];
            longPress.minimumPressDuration = 2.0;
            [self addGestureRecognizer:longPress];
            gestureLoaded = YES;
    }

}

%new 
- (void)handleLongPress:(UILongPressGestureRecognizer*)recognizer
{
    if([recognizer state] == UIGestureRecognizerStateBegan) 
    {
        AudioServicesPlaySystemSound(1520);
        [[FLEXManager sharedManager] showExplorer];
    }
}

%end

@interface UIStatusBar : UIView 
@end
%hook UIStatusBar
-(void)layoutSubviews 
{
    %orig;
    if(enabled_LongPress && !gestureLoaded) 
    {
        UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc]
                                                initWithTarget:self
                                                action:@selector(handleLongPress:)];
            longPress.minimumPressDuration = 2.0;
            [self addGestureRecognizer:longPress];
            gestureLoaded = YES;
    }

}

%new 
- (void)handleLongPress:(UILongPressGestureRecognizer*)recognizer
{
    if ([recognizer state] == UIGestureRecognizerStateBegan) 
    {
        AudioServicesPlaySystemSound(1520);
        [[FLEXManager sharedManager] showExplorer];
    }
}

%end

%hook _UIStatusBarForegroundView

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event 
{
  // NSLog(@"FLEXing12: We are touching");
  if (enabled) 
  {
        UITouch *currentTouch = [touches anyObject];
        CGFloat currentForce = currentTouch.force;
        // NSLog(@"forceForward: The Current Force is: %@", @(currentForce));

        float toggleForce = FLXForce;
        if (currentForce < toggleForce) 
        {
            hasBeenForceTapped = NO;
        }

        // HBLogDebug(@"hasBeenForceTapped: %d", hasBeenForceTapped);
        if (currentForce >= toggleForce && !(hasBeenForceTapped)) 
        {
            hasBeenForceTapped = YES;
            AudioServicesPlaySystemSound(1520);
            [[FLEXManager sharedManager] showExplorer];
        }
    }
    %orig(touches,event);
}


%end

%hook UIStatusBarForegroundView

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event 
{
    if (enabled) 
    {
        UITouch *currentTouch = [touches anyObject];
        CGFloat currentForce = currentTouch.force;

        float toggleForce = FLXForce;
        if (currentForce < toggleForce) 
        {
            hasBeenForceTapped = NO;
        }

        if (currentForce >= toggleForce && !(hasBeenForceTapped)) 
        {
            hasBeenForceTapped = YES;
            AudioServicesPlaySystemSound(1520);
            [[FLEXManager sharedManager] showExplorer];
        }
    }
    %orig(touches,event);
}


%end

%ctor{

    NSLog(@"Loading Flexy");
    notificationCallback(NULL, NULL, NULL, NULL, NULL);

    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
        NULL,
        &respring,
        CFSTR("respring"),
        NULL, 0);

	// Register for 'PostNotification' notifications
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
		NULL,
		notificationCallback,
		(CFStringRef)nsNotificationString,
		NULL,
		CFNotificationSuspensionBehaviorCoalesce);
}
