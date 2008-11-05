//
//  AmpedeProductManager.m
//  AmpedeFxPlug
//
//  Created by Erich Ocean on 12/11/06.
//  Copyright 2006 Erich Atlas Ocean. All rights reserved.
//

#import "AmpedeProductManager.h"


@implementation AmpedeProductManagerWeak

+ (void) initialize
{
    LOG
    
    static BOOL isInitialized = NO;
    
    if ( !isInitialized )
    {
        isInitialized = YES;
        
    }
}

- init
{
    LOG
    
    if ( self = [super init] )
    {
        pluginInfoPlists = [[NSMutableDictionary alloc] init];
        
        [[NSNotificationCenter defaultCenter] postNotificationName: @"DSAmpedeProductManagerRegisterPlugInsNotification"
                                              object:               self                                               ];
    }
    return self;
}

- (void) dealloc
{
    release( pluginInfoPlists );
    
    [super dealloc];
}

+ productManager
{
    LOG
    
    static id sharedInstance = nil;
    
    if ( !sharedInstance ) sharedInstance = [[self alloc] init];

    return sharedInstance;
}

- (void)
registerPlugInInfoPlist: (NSDictionary *) infoPlist
{
    LOGO( infoPlist );
    
    NSString *bundleIdentifier = [infoPlist valueForKey: @"CFBundleIdentifier"];
    
    if ( bundleIdentifier )
    {
        NSDictionary *existingInfoPlist = [pluginInfoPlists valueForKey: bundleIdentifier];
        
        if ( existingInfoPlist )
        {
            // keep the plugin that's most recent
            NSNumber *existingVersion = [NSNumber numberWithInt: [[existingInfoPlist valueForKey: @"DSAmpedeFxPlugPlugInVersion"] intValue]];
            NSNumber *newVersion = [NSNumber numberWithInt: [[infoPlist valueForKey: @"DSAmpedeFxPlugPlugInVersion"] intValue]];
            
            if ( [newVersion isGreaterThan: existingVersion] )
            {
                [pluginInfoPlists setValue: infoPlist
                                  forKey:   bundleIdentifier];
            }
        }
        else
        {
            [pluginInfoPlists setValue: infoPlist
                              forKey:   bundleIdentifier];
        }
    }
}

- (BOOL)
loadPlugInWithBundleIdentifier: (NSString *) bundleIdentifier
{
    LOGO( bundleIdentifier );
    
    NSDictionary *infoPlist = [pluginInfoPlists valueForKey: bundleIdentifier];
    
    if ( infoPlist )
    {
        NSBundle *pluginBundle = [NSBundle bundleWithPath: [infoPlist valueForKey: @"NSBundleResolvedPath"]];
        
        if ( pluginBundle )
        {
            return [pluginBundle load];
        }
        else return NO;
    }
    else return NO;
}

@end
