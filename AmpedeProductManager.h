//
//  AmpedeProductManager.h
//  AmpedeFxPlug
//
//  Created by Erich Ocean on 12/11/06.
//  Copyright 2006 Erich Atlas Ocean. All rights reserved.
//

@interface AmpedeProductManagerWeak : NSObject
{
    NSMutableDictionary *pluginInfoPlists;
}

+ productManager;

- (void)
registerPlugInInfoPlist: (NSDictionary *) infoPlist;

- (BOOL)
loadPlugInWithBundleIdentifier: (NSString *) bundleIdentifier;

@end
