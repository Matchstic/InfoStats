//
//  ISMain.m
//  InfoStats
//
//  Created by Matt Clarke on 07/07/2013.
//
//
#import "ISMain.h"
#import "ISResources.h"
#import <mach/mach.h>
#import <mach/mach_host.h>
#import <UIKit/UIKit.h>
#import <SpringBoard/SBUIController.h>
#import <objc/runtime.h>

#include <sys/sysctl.h>
#define BUNDLE @"/Library/Application Support/Stats/InfoStats.bundle"

/*
 TODO
 
 
 Device temp
 Time remaining on battery
 App notifications
 Calendar events
 Alarms
 Reminders
 Rotation lock
 Mute enabled
 Usage times
 VPN connection
 Game centre score (?)
 
*/

@implementation ISMain

static NSTimer *batterytimer;
static NSTimer *ramTimer;

+(void)launchRamTimer {
    if ([ISResources ramEnabled])
        ramTimer = [NSTimer scheduledTimerWithTimeInterval:[ISResources ramInterval] target:self selector:@selector(ramChanged) userInfo:nil repeats:YES];
}
+(void)cancelRamTimer {
    [ramTimer invalidate];
}

+(void)launchBatteryTimer {
    if ([ISResources batteryEnabled]) {
        [UIDevice currentDevice].batteryMonitoringEnabled = YES;
    
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(batteryStateChanged:) name:@"UIDeviceBatteryStateDidChangeNotification" object:[UIDevice currentDevice]];
        batterytimer = [NSTimer scheduledTimerWithTimeInterval:[ISResources batteryInterval] target:self selector:@selector(batteryLevelChanged) userInfo:nil repeats:YES];
    }
}
+(void)cancelBatteryTimer {
    [batterytimer invalidate];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

+(void)updateAfterSleep {
    if ([ISResources ramEnabled])
        [self ramChanged];
    if ([ISResources batteryEnabled]) {
        [self batteryLevelChanged];
        [self batteryStateChanged:nil];
    }
}

+(void)ramChanged {
    mach_port_t host_port;
    mach_msg_type_number_t host_size;
    vm_size_t pagesize;
    
    host_port = mach_host_self();
    host_size = sizeof(vm_statistics_data_t) / sizeof(integer_t);
    host_page_size(host_port, &pagesize);
    
    vm_statistics_data_t vm_stat;
    
    if (host_statistics(host_port, HOST_VM_INFO, (host_info_t)&vm_stat, &host_size) != KERN_SUCCESS)
        NSLog(@"Failed to fetch vm statistics");
        
    /* Stats in bytes */
    NSUInteger giga = 1024*1024;
        
    NSUInteger ram_total_usable = [self getSysInfo:HW_USERMEM] / giga;
    NSUInteger ram_total_physical = [self getSysInfo:HW_PHYSMEM] / giga;
    natural_t wired = vm_stat.wire_count * (natural_t)pagesize / (1024 * 1024);
    natural_t active = vm_stat.active_count * (natural_t)pagesize / (1024 * 1024);
    natural_t inactive = vm_stat.inactive_count * (natural_t)pagesize / (1024 * 1024);
    natural_t ram_free = vm_stat.free_count * (natural_t)pagesize / (1024 * 1024) + inactive; // Inactive is treated as free by iOS
    natural_t ram_used = active + wired;
        
    NSString *used = [NSString stringWithFormat:@"%.2u", ram_used];
    NSString *free = [NSString stringWithFormat:@"%.2u", ram_free];
    NSString *total_usable = [NSString stringWithFormat:@"%.2lu", (unsigned long)ram_total_usable];
    NSString *total_physical = [NSString stringWithFormat:@"%.2lu", (unsigned long)ram_total_physical];
        
    // Write to txt file
    NSError *error;
    NSString *filePath = @"/var/mobile/Library/Stats/RAMStats.txt";
    
    // Check if file exists, create if not
    if (![[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        system("touch /var/mobile/Library/Stats/RAMStats.txt");
        NSMutableArray *array = [[NSMutableArray alloc] init];
        
        [array insertObject:@"Free: nil" atIndex:0];
        [array insertObject:@"Used: nil" atIndex:1];
        [array insertObject:@"Total usable: nil" atIndex:2];
        [array insertObject:@"Total physical: nil" atIndex:3];
        
        NSString *writeable = [array componentsJoinedByString:@"\n"];
        
        [writeable writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:&error];
        [array release];
    }
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:@"/var/mobile/Library/RAMStats.txt"]) {
        system("ln -s '/var/mobile/Library/Stats/RAMStats.txt' '/var/mobile/Library/RAMStats.txt'");
    }
    
    NSString *fileString = [NSString stringWithContentsOfFile:filePath
                                                     encoding:NSUTF8StringEncoding
                                                        error:nil];
    
    NSMutableArray *lines = [NSMutableArray arrayWithArray:[fileString componentsSeparatedByString:@"\n"]];
    if (!lines) {
        lines = [NSMutableArray array];
    } else {
        @try {
            [lines removeObjectAtIndex:0];
            [lines removeObjectAtIndex:1];
            [lines removeObjectAtIndex:2];
            [lines removeObjectAtIndex:3];
        }
        @catch (NSException *exception) {
            NSLog(@"Whiskey. Tango. Foxtrot.");
        }
    }
    
    // Free
    [lines insertObject:[@"Free: " stringByAppendingString:free] atIndex:0];
    
    // Used
    [lines insertObject:[@"Used: " stringByAppendingString:used] atIndex:1];
    
    // Total usable
    [lines insertObject:[@"Total usable: " stringByAppendingString:total_usable] atIndex:2];
    
    // Total physical
    [lines insertObject:[@"Total physical: " stringByAppendingString:total_physical] atIndex:3];
    
    NSString *write = [lines componentsJoinedByString:@"\n"];
    
    [write writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:&error];
    
    // Done!
}

+(NSUInteger)getSysInfo:(uint)typeSpecifier {
    size_t size = sizeof(int);
    int results;
    int mib[2] = {CTL_HW, typeSpecifier};
    sysctl(mib, 2, &results, &size, NULL, 0);
    return (NSUInteger) results;
}

// Battery stuff!
+(void)batteryStateChanged:(NSNotification *)notification {
    // Get charging state
    int m = [UIDevice currentDevice].batteryState; // iOS 3.0+
    NSString *state = nil;
    NSBundle *bundle = [[NSBundle alloc] initWithPath:BUNDLE];
    switch (m) {
        case UIDeviceBatteryStateUnplugged: {
            state = [@"State: " stringByAppendingString:[bundle localizedStringForKey:@"UNPLUGGED" value:@"Unplugged" table:nil]];
            break;
        }
        case UIDeviceBatteryStateCharging: {
            state = [@"State: " stringByAppendingString:[bundle localizedStringForKey:@"CHARGING" value:@"Charging" table:nil]];
            break;
        }
        case UIDeviceBatteryStateFull: {
            state = [@"State: " stringByAppendingString:[bundle localizedStringForKey:@"FULL_CHARGED" value:@"Fully Charged" table:nil]];
            break;
        }
        default: {
            state = [@"State: " stringByAppendingString:[bundle localizedStringForKey:@"UNKNOWN" value:@"Unknown" table:nil]];
            break;
        }
    } [bundle release];
    
    // Write to txt file
    // We should load the contents of the file into an array, edit as appropriate, then write the resulting strings to the file.
    NSError *error;
    NSString *filePath = @"/var/mobile/Library/Stats/BatteryStats.txt";
    
    /*NSMutableArray *lines = [[NSString stringWithContentsOfFile:filePath
     encoding:NSUTF8StringEncoding
     error:nil]
     componentsSeparatedByString:@"\n"];*/
    
    // Check if file exists, create if not
    if (![[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        system("touch /var/mobile/Library/Stats/BatteryStats.txt");
        NSMutableArray *array = [[NSMutableArray alloc] init];
        
        [array insertObject:@"Level: nil" atIndex:0];
        [array insertObject:@"State: nil" atIndex:1];
        
        NSString *writeable = [array componentsJoinedByString:@"\n"];
        
        [writeable writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:&error];
        [array release];
    }
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:@"/var/mobile/Library/BatteryStats.txt"]) {
        system("ln -s '/var/mobile/Library/Stats/BatteryStats.txt' '/var/mobile/Library/BatteryStats.txt'");
    }
    
    NSString *fileString = [NSString stringWithContentsOfFile:filePath
                                                     encoding:NSUTF8StringEncoding
                                                        error:nil];
    
    NSMutableArray *lines = [NSMutableArray arrayWithArray:[fileString componentsSeparatedByString:@"\n"]];
    if (!lines) {
        lines = [NSMutableArray array];
    } else {
        [lines removeObjectAtIndex:1];
    }
    
    // Crashes here
    [lines insertObject:state atIndex:1];
    
    NSString *write = [lines componentsJoinedByString:@"\n"];
    
    [write writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:&error];
    
    // Done!
}

+(void)batteryLevelChanged {
    // Get battery value
    
    // breakage point, good for iOS 4.3+, even 7.0!
    int percent = [(SBUIController*)[objc_getClass("SBUIController") sharedInstance] displayBatteryCapacityAsPercentage];
    
    NSString *finalLevel = [@"Level: " stringByAppendingString:[NSString stringWithFormat:@"%d",percent]];
    
    NSError *error;
    NSString *filePath = @"/var/mobile/Library/Stats/BatteryStats.txt";
    
    // Check if file exists, create if not
    if (![[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        system("touch /var/mobile/Library/Stats/BatteryStats.txt");
        NSMutableArray *array = [[NSMutableArray alloc] init];
        
        [array insertObject:@"Level: nil" atIndex:0];
        [array insertObject:@"State: nil" atIndex:1];
        
        NSString *writeable = [array componentsJoinedByString:@"\n"];
        
        [writeable writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:&error];
        [array release];
    }
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:@"/var/mobile/Library/BatteryStats.txt"]) {
        system("ln -s '/var/mobile/Library/Stats/BatteryStats.txt' '/var/mobile/Library/BatteryStats.txt'");
    }
    
    NSString *fileString = [NSString stringWithContentsOfFile:filePath
                                                     encoding:NSUTF8StringEncoding
                                                        error:nil];
    
    NSMutableArray *lines = [NSMutableArray arrayWithArray:[fileString componentsSeparatedByString:@"\n"]];
    
    // Crashes here
    [lines removeObjectAtIndex:0];
    [lines insertObject:finalLevel atIndex:0];
    
    NSString *write = [lines componentsJoinedByString:@"\n"];
    
    [write writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:&error];
}

+(void)updateRotationLockState:(BOOL)locked {
    // System.txt
}

+(void)updateMuteEnabled:(BOOL)enabled {
    // System.txt
}

+(void)updateDeviceTemperature {
    // System.txt
}

@end
