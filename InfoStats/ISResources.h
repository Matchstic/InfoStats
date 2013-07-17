//
//  ISResources.h
//  InfoStats
//
//  Created by Matt Clarke on 07/07/2013.
//
//

#import <Foundation/Foundation.h>

@interface ISResources : NSObject

+(BOOL)ramEnabled;
+(double)ramInterval;

+(BOOL)batteryEnabled;
+(double)batteryInterval;

+(void)reloadSettings;
+(void)loadSettings;

@end
