#line 1 "/Users/Matt/iOS/Projects/InfoStats/InfoStats/InfoStats.xm"
#import "ISMain.h"
#import "ISResources.h"

#include <logos/logos.h>
#include <substrate.h>
@class SBAwayController; @class SpringBoard; 
static void (*_logos_orig$_ungrouped$SpringBoard$_performDeferredLaunchWork)(SpringBoard*, SEL); static void _logos_method$_ungrouped$SpringBoard$_performDeferredLaunchWork(SpringBoard*, SEL); static void (*_logos_orig$_ungrouped$SBAwayController$undimScreen$)(SBAwayController*, SEL, BOOL); static void _logos_method$_ungrouped$SBAwayController$undimScreen$(SBAwayController*, SEL, BOOL); static void (*_logos_orig$_ungrouped$SBAwayController$undimScreen)(SBAwayController*, SEL); static void _logos_method$_ungrouped$SBAwayController$undimScreen(SBAwayController*, SEL); 

#line 4 "/Users/Matt/iOS/Projects/InfoStats/InfoStats/InfoStats.xm"



static void _logos_method$_ungrouped$SpringBoard$_performDeferredLaunchWork(SpringBoard* self, SEL _cmd) {
    _logos_orig$_ungrouped$SpringBoard$_performDeferredLaunchWork(self, _cmd);
    
    [ISResources loadSettings];
    
    [ISMain launchRamTimer];
    [ISMain launchBatteryTimer];
}






static void _logos_method$_ungrouped$SBAwayController$undimScreen$(SBAwayController* self, SEL _cmd, BOOL arg1) {
    _logos_orig$_ungrouped$SBAwayController$undimScreen$(self, _cmd, arg1);
    [ISMain updateAfterSleep];
}


static void _logos_method$_ungrouped$SBAwayController$undimScreen(SBAwayController* self, SEL _cmd) {
    _logos_orig$_ungrouped$SBAwayController$undimScreen(self, _cmd);
    [ISMain updateAfterSleep];
}



static void settingsChanged(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
	[ISResources reloadSettings];
}

static __attribute__((constructor)) void _logosLocalCtor_3b47fc20() {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	{Class _logos_class$_ungrouped$SpringBoard = objc_getClass("SpringBoard"); MSHookMessageEx(_logos_class$_ungrouped$SpringBoard, @selector(_performDeferredLaunchWork), (IMP)&_logos_method$_ungrouped$SpringBoard$_performDeferredLaunchWork, (IMP*)&_logos_orig$_ungrouped$SpringBoard$_performDeferredLaunchWork);Class _logos_class$_ungrouped$SBAwayController = objc_getClass("SBAwayController"); MSHookMessageEx(_logos_class$_ungrouped$SBAwayController, @selector(undimScreen:), (IMP)&_logos_method$_ungrouped$SBAwayController$undimScreen$, (IMP*)&_logos_orig$_ungrouped$SBAwayController$undimScreen$);MSHookMessageEx(_logos_class$_ungrouped$SBAwayController, @selector(undimScreen), (IMP)&_logos_method$_ungrouped$SBAwayController$undimScreen, (IMP*)&_logos_orig$_ungrouped$SBAwayController$undimScreen);}
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, settingsChanged, CFSTR("com.matchstic.infostats/settingschanged"), NULL, CFNotificationSuspensionBehaviorCoalesce);
	[pool release];
}
