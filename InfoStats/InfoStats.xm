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

// Works on 7.0, 6.0+ :)
-(void)undimScreen:(BOOL)arg1 {
    %orig;
    [ISMain updateAfterSleep];
}

// iOS 5.0+ compatibilty
-(void)undimScreen {
    %orig;
    [ISMain updateAfterSleep];
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