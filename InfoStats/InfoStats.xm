#import "ISMain.h"
#import "ISResources.h"

%hook SpringBoard

// Breakage point with iOS releases, good for iOS 5.0+, 7.0 works!
-(void)_performDeferredLaunchWork {
    %orig;
    
    [ISResources loadSettings];
    
    [ISMain launchRamTimer];
    [ISMain launchBatteryTimer];
}

%end

%hook SBAwayController

// Works on 6.0 - 6.1.5
-(void)undimScreen:(BOOL)arg1 {
    [ISMain updateAfterSleep];
    %orig;
}

// iOS 5.0+ compatibilty
-(void)undimScreen {
    [ISMain updateAfterSleep];
    %orig;
}

%end

%hook SBLockScreenViewController

-(void)_handleDisplayTurnedOn {
    [ISMain updateAfterSleep];
    %orig;
}

%end

static void settingsChanged(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
	[ISResources reloadSettings];
}

%ctor {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	%init;
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, settingsChanged, CFSTR("com.matchstic.infostats/settingschanged"), NULL, CFNotificationSuspensionBehaviorCoalesce);
	[pool release];
}