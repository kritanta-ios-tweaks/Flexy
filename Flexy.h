

@interface FBSystemService : NSObject
+ (id)sharedInstance;
- (void)exitAndRelaunch:(BOOL)unknown;
@end
@interface UIStatusBar_Modern: UIView
@end

@interface _UIStatusBar: UIView
@end

@interface SBDashBoardIdleTimerProvider : NSObject
-(void)addDisabledIdleTimerAssertionReason:(NSString *)arg;
-(void)removeDisabledIdleTimerAssertionReason:(NSString *)arg;
@end

@interface UISystemGestureView : UIView 
@end