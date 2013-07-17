//
//  ISMain.h
//  InfoStats
//
//  Created by Matt Clarke on 07/07/2013.
//
//

#import <Foundation/Foundation.h>

@interface ISMain : NSObject

+(void)launchRamTimer;
+(void)cancelRamTimer;
+(void)launchBatteryTimer;
+(void)cancelBatteryTimer;

+(void)ramChanged;
+(void)batteryLevelChanged;
+(void)batteryStateChanged:(NSNotification *)notification;

+(void)updateAfterSleep;

@end
