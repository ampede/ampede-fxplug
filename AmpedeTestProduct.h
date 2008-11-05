//
//  AmpedeTestProduct.h
//  AmpedeFxPlug
//
//  Created by Erich Ocean on 12/11/06.
//  Copyright 2006 Erich Atlas Ocean. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <PluginManager/PROPlugInBundleRegistration.h>

@interface AmpedeTestProduct : NSObject < PROPlugInRegistering >
{
    NSMutableArray *pluginInfoPlists;
}

- (NSArray *)
registerPlugInItemsWithKey: (NSString *) key;

@end
