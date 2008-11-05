//
//  AmpedeBaseEffectFxPlug.m
//  AmpedeFxPlug
//
//  Created by Erich Ocean on 12/11/06.
//  Copyright 2006 Erich Atlas Ocean. All rights reserved.
//

#import "AmpedeBaseEffectFxPlug.h"


@implementation AmpedeBaseEffectFxPlug

#pragma mark -
#pragma mark PROAPIAccessing informal protocol

//
//  This method is called when a plug-in is first loaded, and is a good point to conduct any checks for anti-piracy or
//  system compatibility. Returning NULL means that a plug-in chooses not to be accessible for some reason.
//

- initWithAPIManager: (id < PROAPIAccessing >) theApiManager
{
    if ( self = [super init] )
    {
        apiManager = theApiManager; // just caching the value here, don't need to retain
        
        // launch our license-controlled application
//        NSBundle *pluginBundle = [NSBundle bundleForClass: [self class]];
//        NSString *bundlePath = [pluginBundle bundlePath];
//        NSString *appPath = [bundlePath stringByAppendingPathComponent: [NSString stringWithFormat: @"Contents/Resources/%@.app", NSStringFromClass( [self class] )]];
            // thus, the principalClass for the fxplug bundle must be named the same as the embedded, license-controlled application
        
//        NSLog( @"appPath is: %@", appPath );
//        
//        NSURL *appURL = [[[NSURL alloc] initFileURLWithPath: appPath] autorelease];
        
//        if ( !LaunchBackgroundAppWithURL( appURL ) )
//        {
//            NSLog( @"\nAmpedeFxPlug Error: failed to launch plugin application at URL:\n    %@", appURL );
//            return nil;
//        }
//        else
//        {
            // establish a DO connection 
//            NSString *bundleIdentifier = [pluginBundle bundleIdentifier]; // our DO name's are based on this prefix, which must be unique for each plugin bundle
            
            // check the licensing
            
//        }
    }
    return self;
}

#pragma mark -
#pragma mark FxBaseEffect protocol

//
//  This method should return YES if the plug-in's output can vary over time even when all of its parameter values remain
//  constant. Returning NO means that a rendered frame can be cached and reused for other frames with the same parameter
//  values.
//

- (BOOL) variesOverTime
{
    return NO;
}

//
//  This method should return an NSDictionary defining the properties of the effect.
//

- (NSDictionary *) properties
{
    return nil;
}

//
//  This method is where a plug-in defines its list of parameters.
//

- (BOOL) addParameters
{
    return NO;
}

//
//  This method will be called whenever a parameter value has changed. This provides a plug-in an opportunity to respond
//  by changing the value or state of some other parameter.
//

- (BOOL)
parameterChanged: (UInt32) parmId
{
    return YES;
}

#pragma mark -
#pragma mark FxCustomParameterViewHost protocol

//
//  This plug-in method is called by the host application during the parameter-list setup sequence, once for each plug-in
//  parameter that has the kFxParameterFlag_CUSTOM_UI parameter flag set.
//

- (NSView *)
createViewForParm: (UInt32) parmId
{
    return nil;
}

@end
