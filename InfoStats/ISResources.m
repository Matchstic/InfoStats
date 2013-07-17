//
//  ISResources.m
//  InfoStats
//
//  Created by Matt Clarke on 07/07/2013.
//
//

#import "ISResources.h"
#import "ISMain.h"

#define settingsFile @"/var/mobile/Library/Preferences/com.matchstic.infostats.plist"

static NSDictionary *settings = nil;

@implementation ISResources

+(BOOL)ramEnabled {
    id temp = [settings objectForKey:@"ramEnabled"];
    return (temp ? [temp boolValue] : YES);
}

+(double)ramInterval {
    id temp = [settings objectForKey:@"ramInterval"];
    return (temp ? [temp doubleValue] : 10);
}

+(BOOL)batteryEnabled {
    id temp = [settings objectForKey:@"batteryEnabled"];
    return (temp ? [temp boolValue] : YES);
}

+(double)batteryInterval {
    id temp = [settings objectForKey:@"batteryInterval"];
    return (temp ? [temp doubleValue] : 30);
}

+(void)reloadSettings {
    // Update settings dict - save old first though for next step
    NSMutableDictionary *old = [settings mutableCopy];
    
    [settings release];
    settings = nil;
    settings = [[NSDictionary alloc] initWithContentsOfFile:settingsFile];
    
    // Adjust timers as appropriate
    // Compare old to new
    if ([settings objectForKey:@"ramEnabled"] != [old objectForKey:@"ramEnabled"]) {
        if ([[settings objectForKey:@"ramEnabled"] boolValue] == YES) {
            [ISMain launchRamTimer];
            [ISMain ramChanged]; // Update RAM values instantly
        } else {
            [ISMain cancelRamTimer];
        }
    }
    if ([settings objectForKey:@"batteryEnabled"] != [old objectForKey:@"batteryEnabled"]) {
        if ([[settings objectForKey:@"batteryEnabled"] boolValue] == YES) {
            [ISMain launchBatteryTimer];
            [ISMain batteryLevelChanged]; // Update instantly
            [ISMain batteryStateChanged:nil]; // Again.
        } else {
            [ISMain cancelBatteryTimer];
        }
    }
    // Adjust intervals
    if ([[settings objectForKey:@"ramInterval"] doubleValue] != [[old objectForKey:@"ramInterval"] doubleValue]) {
        if ([self ramEnabled]) {
            [ISMain cancelRamTimer];
            [ISMain launchRamTimer];
        }
    }
    if ([[settings objectForKey:@"batteryInterval"] doubleValue] != [[old objectForKey:@"batteryInterval"] doubleValue]) {
        if ([self batteryEnabled]) {
            [ISMain cancelBatteryTimer];
            [ISMain launchBatteryTimer];
        }
    }
    
    [old release];
}

+(void)loadSettings {
    [settings release];
    settings = nil;
    settings = [[NSDictionary alloc] initWithContentsOfFile:settingsFile];
}

@end
